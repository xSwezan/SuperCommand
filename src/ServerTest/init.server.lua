local StarterPack = game:GetService("StarterPack")
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

		if (workspace:FindFirstChild("Map")) then
			workspace.Map:Destroy()
		end

		local Map = Map:Clone()
		Map.Name = "Map"
		Map.Parent = workspace
	end;
}

SuperCommand:CreateCommand{
	Name = "Up";
	Arguments = {"Player", {"number", "Studs"}};
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
		{"Player", "Player to Kick"};
		{"string", "Reason"};
	};
	Permission = "Admin";
	Execute = function(Player: Player, Reason: string)
		if not (Player) then return end

		Player:Kick(Reason)
	end;
}

SuperCommand:CreateCommand{
	Name = "Teleport";
	Arguments = {
		"Player";
		{"Player", "To"};
	};
	Permission = "Admin";
	Execute = function(Player1: Player, Player2: Player)
		local C1 = Player1.Character
		if not (C1) then return end

		local C2 = Player2.Character
		if not (C2) then return end

		C1:PivotTo(C2:GetPivot())
	end;
}

SuperCommand:CreateCommand{
	Name = "ColorBaseplate";
	Arguments = {"Color"};
	Execute = function(Color: Color3)
		workspace.Baseplate.Color = Color
	end;
}

SuperCommand:CreateCommand{
	Name = "MaterialBaseplate";
	Arguments = {"Material"};
	Execute = function(Material: Enum.Material)
		workspace.Baseplate.Material = Material
	end;
}

SuperCommand:CreateCommand{
	Name = "Print";
	Arguments = {"string"};
	Execute = function(...)
		print(...)
	end;
}

SuperCommand:CreateCommand{
	Name = "Warn";
	Arguments = {"string"};
	Execute = function(...)
		warn(...)
	end;
}

SuperCommand:CreateOperator("random%((%d+),(%d+)%)",function(Min: string, Max: string)
	return math.random(tonumber(Min), tonumber(Max))
end,"number")

SuperCommand:CreateOperator("foo",function()
	return "bar"
end)

SuperCommand.CommandExecuted:Connect(function(Player: Player, Command: SuperCommand.CommandType)
	print(Player)
	print(Command)
end)