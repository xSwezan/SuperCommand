export type OperatorType = {
	Pattern: string;

	Get: (Arguments...) -> string;
}

--[=[
	@class Operator

	Operators will format the command arguments before the final command output.
	Operators let you create a Pattern that SuperCommand checks for, SuperCommand will then replace that with the output from the given replacement function.
]=]
local Operator = {}
Operator.__index = Operator

--[=[
	@prop Pattern string
	@within Operator

	The Operator's set Pattern
]=]

--[=[
	Creates a OperatorClass

	@param Pattern string -- The Pattern that SuperCommand checks for
	@param Get (FoundPattern: string) -> string -- Function that will return the replacement for the pattern
	@return OperatorClass
]=]
function Operator:Create(Pattern: string, Get: (FoundPattern: string) -> string): OperatorType
	local self = setmetatable({}, Operator)

	self.Pattern = Pattern
	self.__Get = Get
	
	return self
end

--[=[
	@private
	Returns the Processed String Operator
	
	@param ... string -- The arguments sent in by the Pattern
	@return ProcessedString: string -- The string that was processed within the Operator's Get Method
]=]
function Operator:Get(...): string
	if not (typeof(self.__Get) == "function") then return end

	return self.__Get(...)
end

return Operator
