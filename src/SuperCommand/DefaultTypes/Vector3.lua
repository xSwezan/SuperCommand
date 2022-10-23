local Pattern = "^(%d+),%s?(%d+),%s?(%d+)$"

return {
	Tooltip = Pattern;
	Convert = function(Executor: Player, Message: string): Vector3?
		if not (Message) then return end
		
		local X, Y, Z = Message:match(Pattern)
		if not (X) or not (Y) or not (Z) then return end

		return Vector3.new(tonumber(X), tonumber(Y), tonumber(Z))
	end;
	Get = function(Executor: Player)
		
	end;
}