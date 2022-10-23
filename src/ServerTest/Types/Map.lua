local ReplicatedStorage = game:GetService("ReplicatedStorage")

return {
	Convert = function(Executor: Player, MapName: string)
		if not (MapName) then return end

		return ReplicatedStorage.Maps:FindFirstChild(MapName)
	end;
	Get = function(Executor: Player)
		local MapNames = {}
		for _, Map in pairs(ReplicatedStorage.Maps:GetChildren()) do
			table.insert(MapNames, Map.Name)
		end
		return MapNames
	end;
}