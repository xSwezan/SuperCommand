local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Packages.Roact)

return function(target)
	local Handle = Roact.mount(Roact.createElement(require(script.Parent.Gui),{
		
	}),target)
	
	return function()
		Roact.unmount(Handle)
	end
end