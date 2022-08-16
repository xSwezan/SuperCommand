local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local SuperCommand = require(script.Parent.SuperCommand).Start()

local Owner = SuperCommand:CreateGroup("Owner", 255)
local Admin = SuperCommand:CreateGroup("Admin", 254)
local Mod = SuperCommand:CreateGroup("Mod", 200)

SuperCommand.CommandPrefix = ""

Owner:AssignPlayer(116387673)

SuperCommand:CreateTypesFromFolder(script.Types)

SuperCommand:CreateCommand{
	Name = "LoadMap";
	Arguments = {"Map"};
	Permission = "Admin";
	Execute = function(Map: Folder)
		if not (Map) then return end

		Map:Clone().Parent = workspace
	end;
}

SuperCommand:CreateCommand{
	Name = "Up";
	Arguments = {"Player", "number"};
	Permission = "Admin";
	Execute = function(Player: Player, Height: number)
		if not (Player) then return end

		local Character = Player.Character
		if not (Character) then return end

		Character:PivotTo(Character.PrimaryPart.CFrame + Vector3.yAxis * Height)
	end;
}

SuperCommand:CreateCommand{
	Name = "Kick";
	Arguments = {
		{"Player", "Player to Kick"},
		{"string", "Reason"}
	};
	Permission = "Admin";
	Execute = function(Player: Player, Reason: string)
		if not (Player) then return end

		Player:Kick(Reason)
	end;
}

SuperCommand:CreateCommand{
	Name = "ColorBaseplate";
	Arguments = {"Color"};
	Execute = function(Color: Color3)
		if not (typeof(Color) == "Color3") then return end
		workspace.Baseplate.Color = Color
	end;
}

SuperCommand:CreateCommand{
	Name = "Print";
	Arguments = {"string"};
	Execute = function(...)
		print(...)
	end;
}

SuperCommand:CreateOperator("rand<(%d+),(%d+)>",function(Min: string, Max: string)
	return math.random(tonumber(Min), tonumber(Max))
end)

SuperCommand:CreateOperator("foo",function()
	return "bar"
end)

SuperCommand.CommandExecuted:Connect(function(Player: Player, Command: SuperCommand.CommandType)
	-- print(Player)
	-- print(Command)
end)