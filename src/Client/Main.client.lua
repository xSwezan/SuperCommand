local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Packages.Roact)
local e = Roact.createElement

local Player = game.Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local function Gui()
	
end

local Handle = Roact.mount(Gui(), PlayerGui)

RunService.Heartbeat:Connect(function()
	Roact.update(Handle, Gui())
end)