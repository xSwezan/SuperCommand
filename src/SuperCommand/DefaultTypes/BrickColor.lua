local BrickColorNames = {}
for Index = 0, 127 do
	local Color: BrickColorValue = BrickColor.palette(Index)
	table.insert(BrickColorNames, Color.Name)
end

return {
	Convert = function(Executor: Player, Message: string): Enum.Material
		if not (table.find(BrickColorNames, Message)) then return end

		return BrickColor.new(Message)
	end;
	Get = function(Executor: Player)
		return BrickColorNames
	end;
}