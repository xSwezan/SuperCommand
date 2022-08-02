export type OperatorType = {
	Pattern: string;

	Get: (Arguments...) -> string;
}

local Operator = {}
Operator.__index = Operator

function Operator:Create(Pattern: string, Get: (FoundPattern: string) -> string): OperatorType
	local self = setmetatable({}, Operator)

	self.Pattern = Pattern
	self.__Get = Get
	
	return self
end

function Operator:Get(...): string
	if not (typeof(self.__Get) == "function") then return end

	return self.__Get(...)
end

return Operator
