local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactSpring = require(ReplicatedStorage.Packages["Roact-spring"])

local e = Roact.createElement

local Component = Roact.Component:extend(script.Name)

function Component:init()
	self.GuiRef = Roact.createRef()

	self.style, self.api = RoactSpring.Controller.new{

	}
end

function Component:render()
	return e("ScreenGui",{
		IgnoreGuiInset = true;
	
		ResetOnSpawn = false;
	
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
	},{
		
	});
end

return Component