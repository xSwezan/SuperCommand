local Players = game:GetService("Players")

return function(PlayerName: string)
	if not (PlayerName) then return end

	return Players:FindFirstChild(PlayerName)
end