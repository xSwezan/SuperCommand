local Pattern = "^([%-%.%d]+),%s?([%-%.%d]+),%s?([%-%.%d]+),%s?([%-%.%d]+)$"

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

		local XScale, XOffset, YScale, YOffset = String:match(Pattern)
		if not (XScale) then return end
		if not (XOffset) then return end
		if not (YScale) then return end
		if not (YOffset) then return end

		return UDim2.new(tonumber(XScale),tonumber(XOffset),tonumber(YScale),tonumber(YOffset))
	end;
	Get = function(Executor: Player, String: string)
		local XScale, XOffset, YScale, YOffset = String:match("^([%-?%.%d]*),?%s?([%-?%.%d]*),?%s?([%-?%.%d]*),?%s?([%-?%.%d]*)$")
		local Space = if (String:find(", ")) then ", " else ","

		XScale = FixStringNumber(XScale or "")
		XOffset = FixStringNumber(XOffset or "")
		YScale = FixStringNumber(YScale or "")
		YOffset = FixStringNumber(YOffset or "")

		XScale = if (tonumber(XScale)) then XScale else 0
		XOffset = if (tonumber(XOffset)) then XOffset else 0
		YScale = if (tonumber(YScale)) then YScale else 0
		YOffset = if (tonumber(YOffset)) then YOffset else 0

		return {("%s%s%s%s%s%s%s"):format(XScale, Space, XOffset, Space, YScale, Space, YOffset)}
	end;
}