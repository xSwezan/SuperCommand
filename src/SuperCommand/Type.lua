export type Type = {
	Name: string;

	Get: (string) -> any;
}

local Type = {}
Type.__index = Type

function Type:Create(Name: string, Get: (string) -> any)
	local self = setmetatable({}, Type)

	self.Name = Name
	self.__Get = Get

	return self
end

function Type:Get(Name: string): any
	return self.__Get(Name)
end

return Type
