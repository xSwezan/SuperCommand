return {
	Tooltip = "true | false";
	Convert = function(Executor: Player, String: string): boolean?
		if not (String) then return end
		
		if (String:lower() == "true") then
			return true
		elseif (String:lower() == "false") then
			return false
		end
	end;
	Get = function(Executor: Player)
		return {true, false}
	end;
}