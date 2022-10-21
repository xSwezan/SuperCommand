local MaterialNames = {}
for _, Material: Enum.Material in Enum.Material:GetEnumItems() do
	table.insert(MaterialNames, Material.Name)
end

return {
	Convert = function(Message: string)
		if not (table.find(MaterialNames, Message)) then return end

		return Enum.Material[Message]
	end;
	Get = function()
		return MaterialNames
	end;
}