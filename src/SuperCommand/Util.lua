local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Util = {}

function Util:ReplaceMagicCharacters(Str: string, Replacement: string): string
	return Str:gsub("([%$%%%^%*%(%)%.%[%]%+%-%?])", Replacement)
end

function Util:SplitString(String: string, DontRemoveMagic: boolean): {string}
	local Format = "(%b\"\")"
	local ReplacementFormat = "|\"|\"|"
	local SpaceReplacement = "?|?"

	local Formatted: string = String:gsub(Format, ReplacementFormat):gsub(" ", SpaceReplacement)
	
	for Replacement: string in string.gmatch(--[[Util:ReplaceMagicCharacters(String, "%%%1")]]String, Format) do
		local Replacement = string.gsub(Replacement:gsub("%%","%%%%"), '"', "")

		-- warn(("string.gsub('%s', '%s', '%s', 1)"):format(Formatted, ReplacementFormat, Replacement))

		Formatted = string.gsub(Formatted, ReplacementFormat, Replacement, 1)
	end

	return Formatted:split(SpaceReplacement)
end

function Util:GetArguments(Executor: Player, Message: string, CommandArguments: {{Type: string, Name: string?, Multiple: boolean?}}): {any}
	local Split = Util:SplitString(Message)
	table.remove(Split, 1)

	local SuperCommandFolder = ReplicatedStorage:WaitForChild("SuperCommand")
	local Types = SuperCommandFolder:WaitForChild("Types")

	local Arguments = {}

	for Index, TypeInfo in ipairs(CommandArguments) do
		local TypeModule: ModuleScript = Types:FindFirstChild(TypeInfo.Type or "")
		if not (TypeModule) then return end

		local Type = require(TypeModule)
		if not (Type) then return end

		local Argument = if (Type ~= nil) then Type.Convert(Executor, Split[Index]) else Split[Index]
		table.insert(Arguments, Argument)
	end

	return Arguments
end

function Util:IgnoreMagicCharacters(Str: string): string
	return Str:gsub("([%$%%%^%*%(%)%.%[%]%+%-%?])", "%%%1")
end

return Util