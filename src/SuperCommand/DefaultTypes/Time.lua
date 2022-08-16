local Pattern = "(%d+)(%a)"

return {
	Convert = function(String: string)
		if not (String) then return end
		if not (string.match(String, Pattern)) then return end
	
		local TotalSeconds = 0
		local PatternValues = {
			["s"] = 1, -- seconds
			["m"] = 60, -- minutes
			["h"] = 3600, -- hours
			["d"] = 86400, -- days
			["w"] = 604800, -- weeks
			["o"] = 2628000, -- months
			["y"] = 31540000, -- years
		}
		for Value, Unit in String:gmatch(Pattern) do
			TotalSeconds += Value * PatternValues[Unit]
		end
	
		return TotalSeconds
	end;
	Get = function(String: string)
		
	end;
}