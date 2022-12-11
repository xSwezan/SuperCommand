local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rodux = require(ReplicatedStorage.SuperCommand.Rodux)

return Rodux.combineReducers{
	Variables = require(script.Variables);
	CurrentArgument = require(script.CurrentArgument);
	Arguments = require(script.Arguments);
}