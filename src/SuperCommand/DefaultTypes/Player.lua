local Players = game:GetService("Players")

return {
	Convert = function(PlayerName: string)
		if not (PlayerName) then return end

		return Players:FindFirstChild(PlayerName)
	end;
	Get = function()
		local PlayerNames = {}
		for _, Player in pairs(Players:GetPlayers()) do
			table.insert(PlayerNames, Player.Name)
		end
		return PlayerNames
	end;
}