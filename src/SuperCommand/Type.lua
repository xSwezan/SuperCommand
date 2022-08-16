export type Type = {
	Name: string;

	Get: (string) -> any;
}

export type TypeInfo = {
	Get: () -> any;
	Convert: () -> any;
}

--[=[
	@class Type

	Types are powerful, **they convert a string to a Type before processing the command**.
	An example of a Custom Type is Player, if your command has Player as an argument, SuperCommand will process the string to a Player and pass that as an argument to the Execute function in the command.

	```lua
	local SuperCommand = require(PARENT.SuperCommand)

	-- Create Type
	local NewType = SuperCommand:CreateType()
	```
]=]
local Type = {}
Type.__index = Type

--[=[
	@prop Name string
	@within Type

	Name of the Type
]=]

--[=[
	Creates a TypeClass

	@param Name string -- Name of the Type
	@param Get (StringToBeProcessed: string) -> any -- The processor function, processes the string and returns the argument that will be used in the command.
	@return TypeClass
]=]
function Type:Create(Name: string, Info: {})
	local self = setmetatable({}, Type)

	self.Name = Name
	self.__Get = Info.Get
	self.__Convert = Info.Convert

	return self
end

--[=[
	@private
	Returns a Processed Type

	@param StringToBeProcessed string -- The string that you want to be Processed
	@return ProcessedType
]=]
function Type:Convert(StringToBeProcessed: string): any
	return self.__Convert(StringToBeProcessed)
end

return Type
