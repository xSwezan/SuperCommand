local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Promise = require(ReplicatedStorage.Packages.Promise)

function RequireModule(Component)
	return Promise.new(function(resolve, reject)
		local _, Error = pcall(function()
			require(Component)
		end)
		if (Error) then
			reject(Component.Name.." > "..Error)
		end
	end)
end

return function()
	for _, Component in pairs(ServerStorage.Source.AutoRequire:GetDescendants()) do
		if (Component:IsA("ModuleScript")) then
			RequireModule(Component):catch(warn)
		end
	end
end