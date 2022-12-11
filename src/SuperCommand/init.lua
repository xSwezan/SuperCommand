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

type ArgumentType = {
	Type: string;
	Name: string?;
	Multiple: boolean?;
}

type SuperCommandType = {
	Start: () -> SuperCommandType;

	-- Other
	CommandPrefix: string;

	-- Events
	CommandExecuted: RBXScriptSignal;

	-- Arguments
	CreateArgument: (SuperCommandType, Type: string, Name: string?, Multiple: boolean?) -> ArgumentType;

	-- Groups
	CreateGroup: (SuperCommandType, Name: string, Weight: number) -> Group.GroupType?;
	CreateGroupFromModule: (SuperCommandType, ModuleScript: ModuleScript) -> Group.GroupType?;
	CreateGroupsFromFolder: (SuperCommandType, Directory: Instance) -> nil;
	FindGroup: (SuperCommandType, Name: string) -> Group.GroupType;
	
	-- Commands
	CreateCommand: (SuperCommandType, Info: Command.CommandType) -> Command.CommandType?;
	CreateCommandFromModule: (SuperCommandType, ModuleScript: ModuleScript) -> Command.CommandType?;
	CreateCommandsFromFolder: (SuperCommandType, Directory: Instance) -> nil;
	ExecuteCommand: (SuperCommandType, Player: Player, Command: Command.CommandType, Arguments: {any}) -> string?;
	FindCommand: (SuperCommandType, CommandName: string) -> Command.CommandType?;
	GetCommands: (SuperCommandType) -> {Command.CommandType};
	PlayerCanExecuteCommand: (SuperCommandType, UserId: number, Command: Command.CommandType) -> boolean?;

	-- Types
	CreateType: (SuperCommandType, ModuleScript: ModuleScript--[[Name: string, Info: Type.TypeInfo]]) -> Type.Type?;
	--CreateTypeFromModule: (SuperCommandType, ModuleScript: ModuleScript) -> Type.Type?;
	CreateTypesFromFolder: (SuperCommandType, Directory: Instance) -> nil;

	-- Operators
	CreateOperator: (SuperCommandType, Pattern: string, Get: (string) -> any, ReturnType: string?) -> Operator.OperatorType?;
	CreateOperatorFromModule: (SuperCommandType, ModuleScript: ModuleScript) -> Operator.OperatorType?;
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

	if not (ReplicatedStorage.SuperCommand:FindFirstChild("Operators")) then
		local Operators = Instance.new("Folder")
		Operators.Name = "Operators"
		Operators.Parent = ReplicatedStorage.SuperCommand
	end

	if not (ReplicatedStorage:FindFirstChild("Remotes")) then
		local Remotes = ReplicatedStorage.SuperCommand:FindFirstChild("Remotes") or Instance.new("Folder")
		Remotes.Name = "Remotes"
		Remotes.Parent = ReplicatedStorage.SuperCommand
	end
	
	if not (ReplicatedStorage.SuperCommand:FindFirstChild("Types")) then
		local DefaultTypes = script.DefaultTypes
		DefaultTypes.Name = "Types"
		DefaultTypes.Parent = ReplicatedStorage.SuperCommand
	end

	for _, Obj: Instance in script.ReplicatedStorage:GetChildren() do
		Obj:Clone().Parent = ReplicatedStorage.SuperCommand
	end

	self:NewRemoteFunction("Execute",function(Player: Player, CommandName: string, Text: string)
		local Command = self:FindCommand(CommandName)
		if not (Command) then return warn(("Didn't find a command by the name '%s'"):format(CommandName)) end

		if not (self:PlayerCanExecuteCommand(Player.UserId, Command)) then return end

		local Arguments = Util:GetArguments(Player, self:InitiateOperators(Text), Command.Arguments)

		-- Typecheck all Arguments
		for Index: number, Argument: ArgumentType in Command.Arguments do
			print(Argument)

			local Type: TypeType = self:FindType(Argument.Name or "")
			if not (Type) then continue end

			print(1)

			if not (typeof(Type.Get) == "function") then continue end
			if (Type.Get(Player, Arguments[Index]) ~= nil) then continue end

			warn("ERROR")
			return -- Errored
		end

		-- return Command:Execute(unpack(Arguments))
		return self:ExecuteCommand(Player, Command, Arguments)
	end)

	-- self:CreateGroupsFromFolder(script.DefaultGroups)
	-- self:CreateCommandsFromFolder(script.DefaultGroups)


	self:CreateTypesFromFolder(ReplicatedStorage.SuperCommand.Types)

	local function SetupPlayer(Player: Player)
		if not (Player:WaitForChild("PlayerGui"):FindFirstChild("SuperCommand")) then


			local Commandbar = Instance.new("ScreenGui")
			Commandbar.Name = "SuperCommand"
			Commandbar.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
			Commandbar.ResetOnSpawn = false
			for _, Obj: Instance in script.Commandbar:GetChildren() do
				Obj:Clone().Parent = Commandbar
			end
			Commandbar.Parent = Player:WaitForChild("PlayerGui")
		end

		Player.Chatted:Connect(function(Message: string)
			local CommandName = Message:match("^"..self.CommandPrefix.."(%w+)")
			if not (CommandName) then return end

			local Command = self:FindCommand(CommandName)
			if not (Command) then return end

			if not (self:PlayerCanExecuteCommand(Player, Command)) then warn("Not enough permission!") return end

			local Arguments = Util:GetArguments(Player, self:InitiateOperators(Message), self.Storage.Types, Command.Arguments)

			-- Command:Execute(Player, unpack(Arguments))
			self:ExecuteCommand(Player, Command, Arguments)
			-- self:FireEvent("CommandExecuted", Player, Command, Arguments)
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

function SuperCommand:NewRemoteEvent(Name: string, Bind: () -> nil): RemoteEvent
	local NewEvent: RemoteEvent = Instance.new("RemoteEvent")

	NewEvent.Name = Name
	NewEvent.Parent = ReplicatedStorage.SuperCommand:WaitForChild("Remotes", 10)

	NewEvent.OnServerEvent:Connect(Bind)

	return NewEvent
end

function SuperCommand:NewRemoteFunction(Name: string, Bind: () -> nil): RemoteFunction
	local NewFunction: RemoteFunction = Instance.new("RemoteFunction")

	NewFunction.Name = Name
	NewFunction.Parent = ReplicatedStorage.SuperCommand:WaitForChild("Remotes", 10)

	NewFunction.OnServerInvoke = Bind

	return NewFunction
end

-- Arguments

function SuperCommand:CreateArgument(Type: string, Name: string?, Multiple: boolean?): ArgumentType
	return {
		Type = Type;
		Name = Name;
		Multiple = Multiple;
	}
end

-- Groups

function SuperCommand:CreateGroup(Name: string, Weight: number): Group.GroupType?
	if not (Name) then return end
	if not (Weight) then return end

	local NewGroup = Group:Create(Name, Weight)
	table.insert(self.Storage.Groups, NewGroup)

	return NewGroup
end

function SuperCommand:CreateGroupFromModule(ModuleScript: ModuleScript): Group.GroupType?
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
		if (Group.Name:lower() ~= GroupName:lower()) then continue end

		return Group
	end
end

-- Commands

function SuperCommand:CreateCommand(Info: Command.CommandType): Command.CommandType?
	if not (Info) then return end

	local NewCommand = Command:Create(Info)
	table.insert(self.Storage.Commands, NewCommand)

	return NewCommand
end

function SuperCommand:CreateCommandFromModule(ModuleScript: ModuleScript): Command.CommandType?
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

function SuperCommand:ExecuteCommand(Player: Player, Command: CommandType, Arguments: {any}): string?
	if not (typeof(Player) == "Instance") then return end
	if not (Player:IsA("Player")) then return end
	if not (typeof(Command) == "table") then return end
	if not (typeof(Arguments) == "table") then return end

	local Output: string? = Command:Execute(Player, unpack(Arguments))
	self:FireEvent("CommandExecuted", Player, Command, Arguments)

	return Output
end

function SuperCommand:FindCommand(CommandName: string): CommandType?
	if not (typeof(CommandName) == "string") then return end

	for _, Command: Command.CommandType in pairs(self.Storage.Commands) do
		if (Command.Name:lower() ~= CommandName:lower()) then continue end

		return Command
	end
end

function SuperCommand:GetCommands(): {CommandType}
	local Commands = {}

	for _, Command: CommandType in ipairs(self.Storage.Commands) do
		table.insert(Commands, Command)
	end

	return Commands
end

function SuperCommand:PlayerCanExecuteCommand(UserId: number, CommandToCheck: Command.CommandType): boolean?
	if not (CommandToCheck) then return end

	local GroupToCheck = self:FindGroup(CommandToCheck.Permission)
	if not (GroupToCheck) then return true end

	for _, Command in pairs(self.Storage.Commands) do
		for _, Group in pairs(self.Storage.Groups) do
			if not (Group) or ((Group.Weight >= GroupToCheck.Weight) and Group:PlayerIsInGroup(UserId)) then
				return true
			end
		end
	end

	return false
end

-- Types

function SuperCommand:CreateType(ModuleScript: ModuleScript): Type.Type?
	if not (ModuleScript) then return end

	local SuperCommandFolder = ReplicatedStorage:WaitForChild("SuperCommand")
	local Types = SuperCommandFolder:WaitForChild("Types")

	local Old = Types:FindFirstChild(ModuleScript.Name)
	if (Old) then Old:Destroy() end

	local New = ModuleScript:Clone()
	New.Parent = Types

	local Name = ModuleScript.Name
	local Info = require(ModuleScript)

	local NewType = Type:Create(Name, Info)
	self.Storage.Types[Name] = NewType

	return NewType
end

function SuperCommand:FindType(TypeName: string): Type.Type?
	if not (typeof(TypeName) == "string") then return end

	for _, Type in pairs(self.Storage.Types) do
		if (Type.Name:lower() ~= TypeName:lower()) then continue end

		return Type
	end
end

-- function SuperCommand:CreateTypeFromModule(ModuleScript: ModuleScript): Type.Type?
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

function SuperCommand:CreateOperator(Pattern: string, Get: (FoundPattern: string) -> string, ReturnType: string): Operator.OperatorType?
	if not (typeof(Pattern) == "string") then return end
	if not (typeof(Get) == "function") then return end

	local NewOperator = Operator:Create(Pattern, Get, ReturnType)
	table.insert(self.Storage.Operators, NewOperator)

	return NewOperator
end

function SuperCommand:CreateOperatorFromModule(ModuleScript: ModuleScript): Operator.OperatorType?
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