local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.SuperCommand.Roact)

local e = Roact.createElement

local Component = Roact.Component:extend(script.Name)

function Component:init()
	
end

function Component:render()
	return e("UICorner",{
		CornerRadius = UDim.new(0,5);
	});
end

return Component