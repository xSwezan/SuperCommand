local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

Knit.AddControllers(script.Parent:WaitForChild("Controllers"))

require(script.Parent.Modules.RequireComponents)()

Knit.Start({
	ServicePromises = false;
}):andThen(function()
	print("Knit Started")
end):catch(warn)