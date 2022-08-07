local RGBFormat = "^(%d+),[%s]?(%d+),[%s]?(%d+)$"

local function IsHex(Str: string)
	return Str:match("^%x%x%x%x%x%x$")
end

return function(Message: string): Color3 | nil
	if not (Message) then return end

	print(Message)

	local R, G, B = Message:match(RGBFormat)

	if (R) and (G) and (B) then
		return Color3.fromRGB(R,G,B)
	elseif (IsHex(Message)) then
		return Color3.fromHex(Message)
	end
end