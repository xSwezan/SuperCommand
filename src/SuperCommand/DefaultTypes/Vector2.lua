local Pattern = "^(%d+),%s?(%d+)$"

return {
	Tooltip = Pattern;
	Convert = function(Executor: Player, Message: string): Vector2?
		if not (Message) then return end
		
		local X, Y = Message:match(Pattern)
		if not (X) or not (Y) then return end

		return Vector2.new(tonumber(X), tonumber(Y))
	end;
	Get = function(Executor: Player)
		
	end;
}