local ReplicatedStorage = game:GetService("ReplicatedStorage")

export type CommandType = {
	Name: string;
	Description: string?;

	Arguments: {string?}?;
	Permission: string?;
	Execute: (Player: Player, any) -> any;
}

local Command = {}
Command.__index = Command

function Command:Create(Info: CommandType): CommandType
	local self = setmetatable({}, Command)

	self.Name = Info.Name
	self.Description = Info.Description or "";

	self.Arguments = Info.Arguments
	self.Permission = Info.Permission
	self.__Execute = Info.Execute

	local NewCommand = Instance.new("StringValue")
	NewCommand.Name = self.Name

	NewCommand:SetAttribute("Description", self.Description)

	for Index, Argument in pairs(self.Arguments) do
		-- local Type = Argument
		-- local Name = Type
		-- if (typeof(Argument) == "table") then
		-- 	Type = Argument[1]
		-- 	Name = Argument[2]
		-- end

		local NewArgument = Instance.new("IntValue")
		NewArgument.Name = Argument.Name or Argument.Type
		NewArgument:SetAttribute("Type", Argument.Type)
		NewArgument.Value = Index
		NewArgument.Parent = NewCommand
	end

	NewCommand.Parent = ReplicatedStorage.SuperCommand.Commands

	return self
end

function Command:Execute(Executor: Player, ...: any)
	if not (typeof(self.__Execute) == "function") then return end

	return self.__Execute(Executor, ...)
end

return Command
