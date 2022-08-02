export type CommandType = {
	Name: string;
	Arguments: {string}?;
	Permission: string?;
	Execute: (any) -> any;
}

local Command = {}
Command.__index = Command

function Command:Create(Info: CommandType): CommandType
	local self = setmetatable({}, Command)

	self.Name = Info.Name
	self.Arguments = Info.Arguments
	self.Permission = Info.Permission
	self.__Execute = Info.Execute

	return self
end

function Command:Execute(...: any)
	if not (typeof(self.__Execute) == "function") then return end

	self.__Execute(...)
end

return Command
