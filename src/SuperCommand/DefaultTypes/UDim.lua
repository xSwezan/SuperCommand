local Pattern = "^(%d+),%s?(%d+)$"

return {
	Tooltip = Pattern;
	Convert = function(Executor: Player, Message: string): Vector2?
		if not (Message) then return end
		
		local Scale, Offset = Message:match(Pattern)
		if not (Scale) or not (Offset) then return end

		return UDim.new(tonumber(Scale), tonumber(Offset))
	end;
	Get = function(Executor: Player)
		
	end;
}