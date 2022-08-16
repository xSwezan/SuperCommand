local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Classes

local Command = require(script.Command)
local Group = require(script.Group)
local Type = require(script.Type)
local Operator = require(script.Operator)

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
	CreateType: (SuperCommandType, ModuleScript: ModuleScript--[[Name: string, Info: Type.TypeInfo]]) -> Type.Type | nil;
	--CreateTypeFromModule: (SuperCommandType, ModuleScript: ModuleScript) -> Type.Type | nil;
	CreateTypesFromFolder: (SuperCommandType, Directory: Instance) -> nil;

	-- Operators
	CreateOperator: (SuperCommandType, Pattern: string, Get: (string) -> any) -> Operator.OperatorType | nil;
	CreateOperatorFromModule: (SuperCommandType, ModuleScript: ModuleScript) -> Operator.OperatorType | nil;
	CreateOperatorsFromFolder: (SuperCommandType, Directory: Instance) -> nil;
}

export type CommandType = Command.CommandType;
export type GroupType = Group.GroupType;
export type TypeType = Type.Type;

--[=[
	@class SuperCommand


]=]
local SuperCommand: SuperCommandType = {
	Storage = {
		Groups = {} :: {GroupType};
		Commands = {} :: {CommandType};
		Types = {} :: {TypeType};
		Operators = {} :: {Operator.OperatorType};
	
		Events = {} :: {BindableEvent};
	};
	CommandPrefix = "!";
} :: SuperCommandType
SuperCommand.__index = SuperCommand

function SuperCommand.Start(): SuperCommandType
	local self = setmetatable({}, SuperCommand)

	self:NewEvent("CommandExecuted")

	if not (ReplicatedStorage:FindFirstChild("SuperCommand")) then
		local RS = script.ReplicatedStorage
		RS.Name = "SuperCommand"
		RS.Parent = ReplicatedStorage
	end
	
	if not (ReplicatedStorage.SuperCommand:FindFirstChild("Commands")) then
		local Commands = Instance.new("Folder")
		Commands.Name = "Commands"
		Commands.Parent = ReplicatedStorage.SuperCommand
	end

	-- self:CreateGroupsFromFolder(script.DefaultGroups)
	-- self:CreateCommandsFromFolder(script.DefaultGroups)

	if not (ReplicatedStorage.SuperCommand:FindFirstChild("Types")) then
		local DefaultTypes = script.DefaultTypes
		DefaultTypes.Name = "Types"
		DefaultTypes.Parent = ReplicatedStorage.SuperCommand
	end

	self:CreateTypesFromFolder(ReplicatedStorage.SuperCommand.Types)

	local function SetupPlayer(Player: Player)
		if not (Player:WaitForChild("PlayerGui"):FindFirstChild("SuperCommand")) then
			local Commandbar = script.Commandbar:Clone()
			Commandbar.Name = "SuperCommand"
			Commandbar.Parent = Player:WaitForChild("PlayerGui")
		end

		Player.Chatted:Connect(function(Message: string)
			local CommandName = Message:match("^%"..self.CommandPrefix.."(%w+)")
			if not (CommandName) then return end

			local Command = self:FindCommand(CommandName)
			if not (Command) then return end

			if not (self:PlayerCanExecuteCommand(Player, Command)) then warn("Not enough permission!") return end

			local Arguments = Util:GetArguments(self:InitiateOperators(Message), self.Storage.Types, Command.Arguments)

			Command:Execute(unpack(Arguments))
			self:FireEvent("CommandExecuted", Player, Command)
		end)
	end

	Players.PlayerAdded:Connect(function(Player: Player)
		SetupPlayer(Player)
	end)
	for _, Player: Player in pairs(Players:GetPlayers()) do
		SetupPlayer(Player)
	end

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

function SuperCommand:CreateType(ModuleScript: ModuleScript): Type.Type | nil
	if not (ModuleScript) then return end

	ModuleScript:Clone().Parent = ReplicatedStorage:WaitForChild("SuperCommand"):WaitForChild("Types")

	local Name = ModuleScript.Name
	local Info = require(ModuleScript)

	local NewType = Type:Create(Name, Info)
	self.Storage.Types[Name] = NewType

	return NewType
end

-- function SuperCommand:CreateTypeFromModule(ModuleScript: ModuleScript): Type.Type | nil
-- 	if not (typeof(ModuleScript) == "Instance") then return end
-- 	if not (ModuleScript:IsA("ModuleScript")) then return end

-- 	local TypeInfo = require(ModuleScript)
-- 	if not (typeof(TypeInfo) == "table") then return end

-- 	return self:CreateType(ModuleScript.Name, TypeInfo)
-- end

function SuperCommand:CreateTypesFromFolder(Directory: Instance)
	if not (typeof(Directory) == "Instance") then return end

	for _, ModuleScript: ModuleScript in pairs(Directory:GetChildren() :: {}) do
		self:CreateType(ModuleScript)
	end
end

-- Operators

function SuperCommand:CreateOperator(Pattern: string, Get: (FoundPattern: string) -> string): Operator.OperatorType | nil
	if not (typeof(Pattern) == "string") then return end
	if not (typeof(Get) == "function") then return end

	local NewOperator = Operator:Create(Pattern, Get)
	table.insert(self.Storage.Operators, NewOperator)

	return NewOperator
end

function SuperCommand:CreateOperatorFromModule(ModuleScript: ModuleScript): Operator.OperatorType | nil
	if not (typeof(ModuleScript) == "Instance") then return end
	if not (ModuleScript:IsA("ModuleScript")) then return end

	local OperatorGet = require(ModuleScript)
	if not (typeof(OperatorGet) == "function") then return end

	return self:CreateOperator(ModuleScript.Name, OperatorGet)
end

function SuperCommand:CreateOperatorsFromFolder(Directory: Instance)
	if not (typeof(Directory) == "Instance") then return end

	for _, ModuleScript: ModuleScript in pairs(Directory:GetChildren() :: {}) do
		self:CreateOperatorFromModule(ModuleScript)
	end
end

function SuperCommand:InitiateOperators(Message: string)
	for _, Operator: Operator.OperatorType in pairs(self.Storage.Operators) do
		Message = Message:gsub(Operator.Pattern, function(...)
			return Operator:Get(...)
		end)
	end
	return Message
end

return SuperCommand :: SuperCommandType