local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local StarterPlayer = game:GetService("StarterPlayer")
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
	for _, Component in pairs(StarterPlayer.StarterPlayerScripts.Source.AutoRequire:GetDescendants()) do
		if (Component:IsA("ModuleScript")) then
			RequireModule(Component):catch(warn)
		end
	end
	
	-- for _, Module in pairs(ServerStorage.Source.Modules:GetChildren()) do
	-- 	if (Module:IsA("ModuleScript")) then
	-- 		RequireModule(Module):catch(warn)
	-- 	end
	-- end
end