local Players = game:GetService("Players")

-- Classes

local Command = require(script.Command)
local Group = require(script.Group)
local Type = require(script.Type)

-- Extra

local Util = require(script.Util)

-- Main

type SuperCommandType = {
	Start: () -> SuperCommandType;

	-- Other
	CommandPrefix: string;

	-- Events
	CommandExecuted: RBXScriptSignal;

	-- Groups
	CreateGroup: (SuperCommandType, Name: string, Weight: number) -> Group.GroupType | nil;
	CreateGroupFromModule: (SuperCommandType, ModuleScript: ModuleScript) -> Group.GroupType | nil;
	CreateGroupsFromFolder: (SuperCommandType, Directory: Instance) -> nil;
	FindGroup: (SuperCommandType, Name: string) -> Group.GroupType;
	
	-- Commands
	CreateCommand: (SuperCommandType, Info: Command.CommandType) -> Command.CommandType | nil;
	CreateCommandFromModule: (SuperCommandType, ModuleScript: ModuleScript) -> Command.CommandType | nil;
	CreateCommandsFromFolder: (SuperCommandType, Directory: Instance) -> nil;
	FindCommand: (SuperCommandType, CommandName: string) -> Command.CommandType | nil;
	PlayerCanExecuteCommand: (SuperCommandType, Player: Player, Command: Command.CommandType) -> boolean | nil;

	-- Types
	CreateType: (SuperCommandType, Name: string, Get: (string) -> any) -> Type.Type | nil;
	CreateTypeFromModule: (SuperCommandType, ModuleScript: ModuleScript) -> Type.Type | nil;
	CreateTypesFromFolder: (SuperCommandType, Directory: Instance) -> nil;
}

export type CommandType = Command.CommandType;
export type GroupType = Group.GroupType;
export type TypeType = Type.Type;

local SuperCommand: SuperCommandType = {
	Storage = {
		Groups = {} :: {GroupType};
		Commands = {} :: {CommandType};
		Types = {} :: {TypeType};
	
		Events = {} :: {BindableEvent};
	};
	CommandPrefix = "!";
} :: SuperCommandType
SuperCommand.__index = SuperCommand

function SuperCommand.Start(): SuperCommandType
	local self = setmetatable({}, SuperCommand)

	self:CreateGroupsFromFolder(script.DefaultGroups)
	self:CreateCommandsFromFolder(script.DefaultGroups)
	self:CreateTypesFromFolder(script.DefaultTypes)

	self:NewEvent("CommandExecuted")

	Players.PlayerAdded:Connect(function(Player: Player)
		Player.Chatted:Connect(function(Message: string)
			local CommandName = Message:match(self.CommandPrefix.."(%w+)")
			if not (CommandName) then return end

			local Command = self:FindCommand(CommandName)
			if not (Command) then return end

			if not (self:PlayerCanExecuteCommand(Player, Command)) then warn("Not enough permission!") return end

			local Arguments = Util:GetArguments(Message, self.Storage.Types, Command.Arguments)

			Command:Execute(unpack(Arguments))
			self:FireEvent("CommandExecuted", Player, Command)
		end)
	end)

	return self
end

function SuperCommand:FireEvent(Name: string, ...)
	local Event = self.Storage.Events[Name]
	if (typeof(Event) == "Instance") and (Event:IsA("BindableEvent")) then
		Event:Fire(...)
	end
end

function SuperCommand:NewEvent(Name: string)
	local NewEvent = Instance.new("BindableEvent")

	self.Storage.Events[Name] = NewEvent
	self[Name] = NewEvent.Event

	return NewEvent
end

-- Groups

function SuperCommand:CreateGroup(Name: string, Weight: number): Group.GroupType | nil
	if not (Name) then return end
	if not (Weight) then return end

	local NewGroup = Group:Create(Name, Weight)
	table.insert(self.Storage.Groups, NewGroup)

	return NewGroup
end

function SuperCommand:CreateGroupFromModule(ModuleScript: ModuleScript): Group.GroupType | nil
	if not (typeof(ModuleScript) == "Instance") then return end
	if not (ModuleScript:IsA("ModuleScript")) then return end

	local Info = require(ModuleScript)
	if not (typeof(Info) == "table") then return end

	return self:CreateGroup(Info.Name, Info.Weight)
end

function SuperCommand:CreateGroupsFromFolder(Directory: Instance)
	if not (typeof(Directory) == "Instance") then return end

	for _, ModuleScript: ModuleScript in pairs(Directory:GetDescendants()) do
		self:CreateGroupFromModule(ModuleScript)
	end
end

function SuperCommand:FindGroup(GroupName: string)
	if not (typeof(GroupName) == "string") then return end

	for _, Group in pairs(self.Storage.Groups) do
		if (Group.Name:lower() == GroupName:lower()) then
			return Group
		end
	end
end

-- Commands

function SuperCommand:CreateCommand(Info: Command.CommandType): Command.CommandType | nil
	if not (Info) then return end

	local NewCommand = Command:Create(Info)
	table.insert(self.Storage.Commands, NewCommand)

	return NewCommand
end

function SuperCommand:CreateCommandFromModule(ModuleScript: ModuleScript): Command.CommandType | nil
	if not (typeof(ModuleScript) == "Instance") then return end
	if not (ModuleScript:IsA("ModuleScript")) then return end

	local Info = require(ModuleScript)
	if not (typeof(Info) == "table") then return end

	return self:CreateCommand(Info)
end

function SuperCommand:CreateCommandsFromFolder(Directory: Instance)
	if not (typeof(Directory) == "Instance") then return end

	for _, ModuleScript: ModuleScript in pairs(Directory:GetChildren()) do
		self:CreateCommandFromModule(ModuleScript)
	end
end

function SuperCommand:FindCommand(CommandName: string): Command.CommandType | nil
	if not (typeof(CommandName) == "string") then return end

	for _, Command: Command.CommandType in pairs(self.Storage.Commands) do
		if (Command.Name:lower() == CommandName:lower()) then
			return Command
		end
	end
end

function SuperCommand:PlayerCanExecuteCommand(Player: Player, CommandToCheck: Command.CommandType): boolean | nil
	if not (CommandToCheck) then return end

	local GroupToCheck = self:FindGroup(CommandToCheck.Permission)
	if not (GroupToCheck) then return true end

	for _, Command in pairs(self.Storage.Commands) do
		for _, Group in pairs(self.Storage.Groups) do
			if not (Group) or ((Group.Weight >= GroupToCheck.Weight) and Group:PlayerIsInGroup(Player)) then
				return true
			end
		end
	end

	return false
end

-- Types

function SuperCommand:CreateType(Name: string, Get: (string) -> any): Type.Type | nil
	if not (typeof(Name) == "string") then return end
	if not (typeof(Get) == "function") then return end

	local NewType = Type:Create(Name, Get)
	self.Storage.Types[Name] = NewType

	return NewType
end

function SuperCommand:CreateTypeFromModule(ModuleScript: ModuleScript): Type.Type | nil
	if not (typeof(ModuleScript) == "Instance") then return end
	if not (ModuleScript:IsA("ModuleScript")) then return end

	local TypeGet = require(ModuleScript)
	if not (typeof(TypeGet) == "function") then return end

	return self:CreateType(ModuleScript.Name, TypeGet)
end

function SuperCommand:CreateTypesFromFolder(Directory: Instance)
	if not (typeof(Directory) == "Instance") then return end

	for _, ModuleScript: ModuleScript in pairs(Directory:GetChildren() :: {}) do
		self:CreateTypeFromModule(ModuleScript)
	end
end

return SuperCommand :: SuperCommandType