local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPack = game:GetService("StarterPack")
local Workspace = game:GetService("Workspace")
local SuperCommand = require(script.Parent.SuperCommand).Start()

local Owner = SuperCommand:CreateGroup("Owner", 255)
local Admin = SuperCommand:CreateGroup("Admin", 254)
local Mod = SuperCommand:CreateGroup("Mod", 200)

SuperCommand.CommandPrefix = ""

Owner:AssignPlayer(116387673)

SuperCommand:CreateTypesFromFolder(script.Types)

-- SuperCommand:CreateCommand{
-- 	Name = "LoadMap";
-- 	Arguments = {"Map"};
-- 	Permission = "Admin";
-- 	Execute = function(Executor: Player, Map: Folder)
-- 		if not (Map) then return end

-- 		if (workspace:FindFirstChild("Map")) then
-- 			workspace.Map:Destroy()
-- 		end

-- 		local MapName = Map.Name

-- 		local Map = Map:Clone()
-- 		Map.Name = "Map"
-- 		Map.Parent = workspace

-- 		return ("Loaded map '%s'"):format(MapName)
-- 	end;
-- }

-- SuperCommand:CreateCommand{
-- 	Name = "Up";
-- 	Arguments = {"Player", {"number", "Studs"}};
-- 	Permission = "Admin";
-- 	Execute = function(Executor: Player, Player: Player, Height: number)
-- 		if not (Player) then return end

-- 		local Character = Player.Character
-- 		if not (Character) then return end

-- 		Character:PivotTo(Character.PrimaryPart.CFrame + Vector3.yAxis * Height)

-- 		return ("Moved %s %s studs up"):format(Player.Name, Height)
-- 	end;
-- }

-- SuperCommand:CreateCommand{
-- 	Name = "Kick";
-- 	Arguments = {
-- 		{"Player", "Player to Kick"};
-- 		{"string", "Reason"};
-- 	};
-- 	Permission = "Admin";
-- 	Execute = function(Executor: Player, Player: Player, Reason: string)
-- 		if not (Player) then return end

-- 		Player:Kick(Reason)

-- 		return if (Reason) then ("Kicked %s for '%s'"):format(Player.Name, Reason) else ("Kicked %s"):format(Player.Name)
-- 	end;
-- }

-- SuperCommand:CreateCommand{
-- 	Name = "Teleport";
-- 	Arguments = {
-- 		"Player";
-- 		{"Player", "To"};
-- 	};
-- 	Permission = "Admin";
-- 	Execute = function(Executor: Player, PlayerFrom: Player, PlayerTo: Player)
-- 		local C1 = PlayerFrom.Character
-- 		if not (C1) then return end

-- 		local C2 = PlayerTo.Character
-- 		if not (C2) then return end

-- 		C1:PivotTo(C2:GetPivot())

-- 		return ("Teleported %s to %s"):format(PlayerFrom.Name, PlayerTo.Name)
-- 	end;
-- }

-- SuperCommand:CreateCommand{
-- 	Name = "ColorBaseplate";
-- 	Arguments = {"Color"};
-- 	Execute = function(Executor: Player, Color: Color3)
-- 		workspace.Baseplate.Color = Color

-- 		return ("Set Baseplate Color to <font color='#%s' weight='extrabold'>%s</font>"):format(Color:ToHex(), Color:ToHex())
-- 	end;
-- }

-- SuperCommand:CreateCommand{
-- 	Name = "MaterialBaseplate";
-- 	Arguments = {"Material"};
-- 	Execute = function(Executor: Player, Material: Enum.Material)
-- 		workspace.Baseplate.Material = Material

-- 		return ("Set Baseplate Material to <font color='#ffffff' weight='extrabold'>%s</font>"):format(Material.Name)
-- 	end;
-- }

-- SuperCommand:CreateCommand{
-- 	Name = "Print";
-- 	Arguments = {"string"};
-- 	Execute = function(Executor: Player, ...)
-- 		print(...)
-- 	end;
-- }

-- SuperCommand:CreateCommand{
-- 	Name = "Warn";
-- 	Arguments = {"string"};
-- 	Execute = function(Executor: Player, ...)
-- 		warn(...)
-- 	end;
-- }

SuperCommand:CreateCommand{
	Name = "SetTime";
	Description = "Set Time in ReplicatedStorage";
	Arguments = {
		SuperCommand:CreateArgument("Time");
	};
	Execute = function(Executor: Player, Time: number)
		print(Time)

		ReplicatedStorage:SetAttribute("Time", Time)

		return ("Time was set to %s seconds!"):format(Time)
	end;
}

SuperCommand:CreateCommand{
	Name = "Help";
	Description = "Get info about commands";
	Arguments = {};
	Execute = function(Executor: Player)
		local String = "<b>Commands:</b>"

		for _, Command: SuperCommand.CommandType in ipairs(SuperCommand:GetCommands()) do
			String = ("%s\n  <font color='rgb(0,170,255)'>%s</font> - %s"):format(String, Command.Name, Command.Description or "")
		end

		return String
	end;
}

SuperCommand:CreateOperator("random%((%d+),(%d+)%)",function(Min: string, Max: string)
	return math.random(tonumber(Min), tonumber(Max))
end,"number")

SuperCommand:CreateOperator("foo",function()
	return "bar"
end)

SuperCommand.CommandExecuted:Connect(function(Player: Player, Command: SuperCommand.CommandType)
	-- print(Player)
	-- print(Command)
end)