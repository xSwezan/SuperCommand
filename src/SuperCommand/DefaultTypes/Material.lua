local MaterialNames = {}
for _, Material: Enum.Material in Enum.Material:GetEnumItems() do
	table.insert(MaterialNames, Material.Name)
end

return {
	Convert = function(Executor: Player, Message: string): Enum.Material
		if not (table.find(MaterialNames, Message)) then return end

		return Enum.Material[Message]
	end;
	Get = function(Executor: Player)
		return MaterialNames
	end;
}