return {
	Tooltip = "true | false";
	Convert = function(Executor: Player, Message: string): boolean?
		if not (Message) then return end
		
		if (Message:lower() == "true") then
			return true
		elseif (Message:lower() == "false") then
			return false
		end
	end;
	Get = function(Executor: Player)
		return {true, false}
	end;
}