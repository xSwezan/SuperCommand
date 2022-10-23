local Pattern = "^(%d+),%s?(%d+),%s?(%d+),%s?(%d+)$"

return {
	Tooltip = Pattern;
	Convert = function(Executor: Player, Message: string): Vector2?
		if not (Message) then return end
		
		local XScale, XOffset, YScale, YOffset = Message:match(Pattern)
		if not (XScale) or not (XOffset) then return end
		if not (YScale) or not (YOffset) then return end

		return UDim2.new(XScale, XOffset, YScale, YOffset)
	end;
	Get = function(Executor: Player)
		
	end;
}