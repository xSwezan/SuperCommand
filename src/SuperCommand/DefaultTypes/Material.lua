local MaterialNames = {}
for _, Material: Enum.Material in Enum.Material:GetEnumItems() do
	table.insert(MaterialNames, Material.Name)
end

return {
	Convert = function(Executor: Player, String: string): Enum.Material
		if not (table.find(MaterialNames, String)) then return end

		return Enum.Material[String]
	end;
	Get = function(Executor: Player)
		return MaterialNames
	end;
}