local RGBFormat = "^([12]?[012345]?[012345]),%s?([12]?[012345]?[012345]),%s?([12]?[012345]?[012345])$"

local function HexMatch(String: string)
	return if ((String or ""):match("^%x$")) then String else "0"
end

local function IsHex(Str: string)
	return string.match(Str, "^#%x%x%x%x%x%x$")
end

return {
	Tooltip = "^([12]?[012345]?[012345]),%s?([12]?[012345]?[012345]),%s?([12]?[012345]?[012345])$ | ^#%x%x%x%x%x%x$";
	Convert = function(Executor: Player, String: string): Color3?
		if not (String) then return end
	
		local R, G, B = String:match(RGBFormat)
	
		if (R) and (G) and (B) then
			return Color3.fromRGB(R,G,B)
		elseif (IsHex(String)) then
			return Color3.fromHex(String)
		end
	end;
	Get = function(Executor: Player, String: string)
		if (String:match("^#")) then
			local H1, H2, E1, E2, X1, X2 = String:match("^#(%x?)(%x?)(%x?)(%x?)(%x?)(%x?)$")

			return {("#%s%s%s%s%s%s"):format(
				HexMatch(H1),
				HexMatch(H2),
				HexMatch(E1),
				HexMatch(E2),
				HexMatch(X1),
				HexMatch(X2)
			)}
		else
			local R, G, B = String:match("^([12]?[012345]?[012345]?),?%s?([12]?[012345]?[012345]?),?%s?([12]?[012345]?[012345]?)$")
			local Space = if (String:find(", ")) then ", " else ","

			R = if (tonumber(R)) then R else 0
			G = if (tonumber(G)) then G else 0
			B = if (tonumber(B)) then B else 0

			return {("%s%s%s%s%s"):format(R, Space, G, Space, B)}
		end
	end;
}