local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

require(ServerStorage.Source.Modules.RequireComponents)()

Knit.AddServices(ServerStorage.Source.Services)
Knit.Start():andThen(function()
	print("Knit Started")
end):catch(warn)