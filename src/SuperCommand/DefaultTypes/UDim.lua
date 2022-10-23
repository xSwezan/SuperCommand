local Pattern = "^([%-%.%d]+),%s?([%-%.%d]+)$"

local function FixStringNumber(String: string)
	if (String:match("%.$")) or (String:match("%-$")) then
		return String .. "0"
	end
	return String
end

return {
	Tooltip = Pattern;
	Convert = function(Executor: Player, String: string): Vector2?
		if not (String) then return end

		local Scale, Offset = String:match(Pattern)
		if not (Scale) then return end
		if not (Offset) then return end

		return UDim.new(tonumber(Scale),tonumber(Offset))
	end;
	Get = function(Executor: Player, String: string)
		local Scale, Offset = String:match("^([%-?%.%d]*),?%s?([%-?%.%d]*)$")
		local Space = if (String:find(", ")) then ", " else ","

		Scale = FixStringNumber(Scale or "")
		Offset = FixStringNumber(Offset or "")

		Scale = if (tonumber(Scale)) then Scale else 0
		Offset = if (tonumber(Offset)) then Offset else 0

		return {("%s%s%s"):format(Scale, Space, Offset)}
	end;
}