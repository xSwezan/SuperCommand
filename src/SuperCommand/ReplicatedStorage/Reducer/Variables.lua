local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rodux = require(ReplicatedStorage.SuperCommand.Rodux)

local InitialState = {

}

return Rodux.createReducer(InitialState,{
	SetVariable = function(State, Action)
		State = State or InitialState

		local NewState = {}
		for k, v in State do
			NewState[k] = v
		end

		if (typeof(Action.payload) == "table") and (typeof(Action.payload[1]) == "string") then
			NewState[Action.payload[1]] = Action.payload[2]
		end

		return NewState
	end;
})