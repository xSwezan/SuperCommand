local SuperCommand = require(script.Parent.SuperCommand)

local Owner = SuperCommand:CreateGroup("Owner", 255)
local Admin = SuperCommand:CreateGroup("Admin", 254)
local Mod = SuperCommand:CreateGroup("Mod", 200)

Owner:AssignPlayer(116387673)

SuperCommand:CreateCommand{
	Name = "Up";
	Arguments = {"Player", "number"};
	Permission = "Admin";
	Execute = function(Player: Player, Height: number)
		if not (Player) then return end

		local Character = Player.Character
		if not (Character) then return end

		Character:SetPrimaryPartCFrame(Character.PrimaryPart.CFrame + Vector3.yAxis * Height)
	end;
}

SuperCommand:CreateCommand{
	Name = "Kick";
	Arguments = {"Player", "string"};
	Permission = "Admin";
	Execute = function(Player: Player, Reason: string)
		if not (Player) then return end

		Player:Kick(Reason)
	end;
}

SuperCommand:Start()