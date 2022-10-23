local BrickColorNames = {}
for Index = 0, 127 do
	local Color: BrickColorValue = BrickColor.palette(Index)
	table.insert(BrickColorNames, Color.Name)
end

return {
	Convert = function(Executor: Player, String: string): Enum.Material
		if not (table.find(BrickColorNames, String)) then return end

		return BrickColor.new(String)
	end;
	Get = function(Executor: Player)
		return BrickColorNames
	end;
}