local Util = {}

function Util:SplitMessage(Message: string): {string}
	local Format = "(%b\"\")"
	local ReplacementFormat = "|\"|\"|"
	local SpaceReplacement = "?|?"

	local Formatted = Message:gsub(Format, ReplacementFormat):gsub(" ", SpaceReplacement)
	
	for Replacement: string in Message:gmatch(Format) do
		Formatted = Formatted:gsub(ReplacementFormat, Replacement:gsub("\"", ""), 1)
	end

	return Formatted:split(SpaceReplacement)
end

function Util:GetArguments(Message: string, AvailableTypes: {}, CommandArguments: {string}): {any}
	local Split = Util:SplitMessage(Message)
	table.remove(Split, 1)

	local Arguments = {}

	for Index, TypeInfo in pairs(CommandArguments) do
		local TypeName = TypeInfo
		if (typeof(TypeInfo) == "table") then
			TypeName = TypeInfo[1]
		end

		local Type = AvailableTypes[TypeName]
		local Argument = (Type ~= nil) and Type:Convert(Split[Index]) or Split[Index]
		table.insert(Arguments, Argument)
	end

	return Arguments
end

function Util:IgnoreMagicCharacters(Str: string): string
	return Str:gsub("([%$%%%^%*%(%)%.%[%]%+%-%?])", "%%%1")
end

return Util