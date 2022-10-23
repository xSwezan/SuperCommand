return {
	Tooltip = "(%d+)";
	Convert = function(Executor: Player, String: string): number?
		if not (String) then return end
	
		return tonumber(String)
	end;
	Get = function(Executor: Player, String: string)
		if (tonumber(String)) then return end

		return {"0"}
	end;
}