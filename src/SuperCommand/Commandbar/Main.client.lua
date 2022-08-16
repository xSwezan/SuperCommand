local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Components = script.Parent.Components
Components.Name = "UI"
Components.Parent = ReplicatedStorage:WaitForChild("SuperCommand")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Roact = require(ReplicatedStorage.SuperCommand.Roact)
local e = Roact.createElement

Roact.setGlobalConfig{
	elementTracing = true;
}

local function GetGui()
	return Roact.createFragment{
		SuperCommandbar = e("ScreenGui",{
			ResetOnSpawn = false;
		},{
			Main = e("Frame",{
				Size = UDim2.fromScale(1,1);
				
				Position = UDim2.fromScale(.5,.5);
				AnchorPoint = Vector2.new(.5,.5);
	
				BackgroundTransparency = 1;
			},{
				Commandbar = e(require(ReplicatedStorage.SuperCommand.UI.Commandbar),{

				});
			});
		});
	}
end

local Handle = Roact.mount(GetGui(), PlayerGui)

RunService.Heartbeat:Connect(function()
	Roact.update(Handle, GetGui())
end)