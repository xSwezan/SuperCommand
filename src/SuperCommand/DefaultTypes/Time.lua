local Pattern = "^(%d+)([smhdwoy]?)$"
local PatternValues = {
	["s"] = 1, -- seconds
	["m"] = 60, -- minutes
	["h"] = 3600, -- hours
	["d"] = 86400, -- days
	["w"] = 604800, -- weeks
	["o"] = 2628000, -- months
	["y"] = 31540000, -- years
}

return {
	Tooltip = "^(%d+)([smhdwoy]?)$";
	Convert = function(Executor: Player, String: string): number?
		if not (String) then return end

		local Value, Unit = string.match(String, Pattern)
		if not (Value) then return end
		if not (Unit) then Unit = "s" end
		
		local Mul: number = PatternValues[Unit] or 1
		local TotalSeconds: number = (tonumber(Value) * Mul)
	
		return TotalSeconds
	end;
	Get = function(Executor: Player, String: string)
		if not (String) then return end

		local Value = string.match(String, Pattern)
		if not (Value) then return end

		local Values = {}

		for Unit: string in PatternValues do
			table.insert(Values, ("%s%s"):format(Value, Unit))
		end

		return Values
	end;
}