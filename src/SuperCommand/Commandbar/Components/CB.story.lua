local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.SuperCommand.Roact)

local e = Roact.createElement

return function(target)
	local Component = e(require(script.Parent.Commandbar),{
		
	})

	local Tree = Roact.mount(Component, target)

	return function()
		Roact.unmount(Tree)
	end
end