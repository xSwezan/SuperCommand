local Pattern = "^([%-%.%d]+),%s?([%-%.%d]+),%s?([%-%.%d]+)$"

local function FixStringNumber(String: string)
	if (String:match("%.$")) or (String:match("%-$")) then
		return String .. "0"
	end
	return String
end

return {
	Tooltip = Pattern;
	Convert = function(Executor: Player, String: string): Vector3?
		if not (String) then return end

		local X, Y, Z = String:match(Pattern)
		if not (X) then return end
		if not (Y) then return end
		if not (Z) then return end

		return Vector3.new(tonumber(X),tonumber(Y),tonumber(Z))
	end;
	Get = function(Executor: Player, String: string)
		local X, Y, Z = String:match("^([%-?%.%d]*),?%s?([%-?%.%d]*),?%s?([%-?%.%d]*)$")
		local Space = if (String:find(", ")) then ", " else ","

		X = FixStringNumber(X or "")
		Y = FixStringNumber(Y or "")
		Z = FixStringNumber(Z or "")

		X = if (tonumber(X)) then X else 0
		Y = if (tonumber(Y)) then Y else 0
		Z = if (tonumber(Z)) then Z else 0

		return {("%s%s%s%s%s"):format(X, Space, Y, Space, Z)}
	end;
}