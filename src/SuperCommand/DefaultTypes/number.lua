return {
	Tooltip = "(%d+)";
	Convert = function(Executor: Player, Message: string): number?
		if not (Message) then return end
	
		return tonumber(Message)
	end;
	Get = function(Executor: Player)
		
	end;
}