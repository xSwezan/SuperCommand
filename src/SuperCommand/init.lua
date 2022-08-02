local Players = game:GetService("Players")

-- Classes

local Command = require(script.Command)
local Group = require(script.Group)
local Type = require(script.Type)

-- Extra

local Util = require(script.Util)

-- Main

type SuperCommandType = {
	GroupCreated: RBXScriptSignal;
}

local SuperCommand = {
	Storage = {
		Groups = {};
		Commands = {};
		Types = {};
	};
	CommandPrefix = "!";
}

function SuperCommand:Start()
	self:CreateGroupsFromFoler(script.DefaultGroups)
	self:CreateCommandsFromFolder(script.DefaultGroups)
	self:CreateTypesFromFolder(script.DefaultTypes)

	Players.PlayerAdded:Connect(function(Player: Player)
		Player.Chatted:Connect(function(Message: string)
			local CommandName = Message:match(SuperCommand.CommandPrefix.."(%w+)")
			if not (CommandName) then return end

			local Command = self:FindCommand(CommandName)
			if not (Command) then return end

			if not (SuperCommand:PlayerCanExecuteCommand(Player, Command)) then warn("Not enough permission!") return end

			local Arguments = Util:GetArguments(Message, SuperCommand.Storage.Types, Command.Arguments)

			Command:Execute(unpack(Arguments))
		end)
	end)
end

-- Groups

function SuperCommand:CreateGroup(Name: string, Weight: number): Group.GroupType
	if not (Name) then return end
	if not (Weight) then return end

	local NewGroup = Group:Create(Name, Weight)
	table.insert(SuperCommand.Storage.Groups, NewGroup)

	return NewGroup
end

function SuperCommand:CreateGroupFromModule(ModuleScript: ModuleScript)
	if not (typeof(ModuleScript) == "Instance") then return end
	if not (ModuleScript:IsA("ModuleScript")) then return end

	local Info = require(ModuleScript)
	if not (typeof(Info) == "table") then return end

	return self:CreateGroup(Info.Name, Info.Weight)
end

function SuperCommand:CreateGroupsFromFoler(Directory: Instance)
	if not (typeof(Directory) == "Instance") then return end

	for _, ModuleScript: ModuleScript in pairs(Directory:GetDescendants()) do
		self:CreateGroupFromModule(ModuleScript)
	end
end

function SuperCommand:FindGroup(GroupName: string)
	if not (typeof(GroupName) == "string") then return end

	for _, Group in pairs(SuperCommand.Storage.Groups) do
		if (Group.Name:lower() == GroupName:lower()) then
			return Group
		end
	end
end

-- Commands

function SuperCommand:CreateCommand(Info: Command.CommandType): Command.CommandType
	if not (Info) then return end

	local NewCommand = Command:Create(Info)
	table.insert(SuperCommand.Storage.Commands, NewCommand)

	return NewCommand
end

function SuperCommand:CreateCommandFromModule(ModuleScript: ModuleScript)
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

function SuperCommand:FindCommand(CommandName: string)
	if not (typeof(CommandName) == "string") then return end

	for _, Command in pairs(SuperCommand.Storage.Commands) do
		if (Command.Name:lower() == CommandName:lower()) then
			return Command
		end
	end
end

function SuperCommand:PlayerCanExecuteCommand(Player: Player, CommandToCheck: {}): boolean | nil
	if not (CommandToCheck) then return end

	local GroupToCheck = self:FindGroup(CommandToCheck.Permission)
	if not (GroupToCheck) then return true end

	for _, Command in pairs(SuperCommand.Storage.Commands) do
		for _, Group in pairs(SuperCommand.Storage.Groups) do
			if not (Group) or ((Group.Weight >= GroupToCheck.Weight) and Group:PlayerIsInGroup(Player)) then
				return true
			end
		end
	end

	return false
end

-- Types

function SuperCommand:CreateType(Name: string, Get: (string) -> any): Type.Type
	if not (typeof(Name) == "string") then return end
	if not (typeof(Get) == "function") then return end

	local NewType = Type:Create(Name, Get)
	SuperCommand.Storage.Types[Name] = NewType

	return NewType
end

function SuperCommand:CreateTypeFromModule(ModuleScript: ModuleScript): Type.Type
	if not (typeof(ModuleScript) == "Instance") then return end
	if not (ModuleScript:IsA("ModuleScript")) then return end

	local TypeGet = require(ModuleScript)
	if not (typeof(TypeGet) == "function") then return end

	return self:CreateType(ModuleScript.Name, TypeGet)
end

function SuperCommand:CreateTypesFromFolder(Directory: Instance)
	if not (typeof(Directory) == "Instance") then return end

	for _, ModuleScript: ModuleScript in pairs(Directory:GetChildren()) do
		self:CreateTypeFromModule(ModuleScript)
	end
end

return SuperCommand-- :: SuperCommandType