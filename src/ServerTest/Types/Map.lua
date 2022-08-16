local ReplicatedStorage = game:GetService("ReplicatedStorage")

return {
	Convert = function(MapName: string)
		if not (MapName) then return end

		return ReplicatedStorage.Maps:FindFirstChild(MapName)
	end;
	Get = function()
		local MapNames = {}
		for _, Map in pairs(ReplicatedStorage.Maps:GetChildren()) do
			table.insert(MapNames, Map.Name)
		end
		return MapNames
	end;
}