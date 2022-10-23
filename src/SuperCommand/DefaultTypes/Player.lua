local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

return {
	Convert = function(Executor: Player, PlayerName: string): Player?
		if (typeof(PlayerName) ~= "string") then return end

		if (PlayerName:lower() == "me") then
			return Executor
		end

		return Players:FindFirstChild(PlayerName)
	end;
	Get = function(Executor: Player)
		local PlayerNames = {}

		for _, Player in pairs(Players:GetPlayers()) do
			table.insert(PlayerNames, Player.Name)
		end

		if (RunService:IsClient()) then
			table.insert(PlayerNames, 1, "me")
		end

		return PlayerNames
	end;
}