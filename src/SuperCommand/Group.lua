export type GroupType = {
	Players: {Player};
	Name: string;
	Weight: number;

	Connected: RBXScriptSignal;

	AssignPlayer: (number) -> nil;
	AssignPlayers: ({number}) -> nil;
	PlayerIsInGroup: (Player) -> boolean | nil;
	IsMember: ((Player) -> boolean | nil) -> boolean | nil;
}

local Group = {}
Group.__index = Group

function Group:Create(Name: string, Weight: number): GroupType
	local self = setmetatable({}, Group)

	self.Players = {}

	self.Name = Name
	self.Weight = Weight

	return self
end

function Group:AssignPlayer(UserId: number)
	if not (typeof(UserId) == "number") then return end

	table.insert(self.Players, UserId)
end

function Group:AssignPlayers(PlayerIds: {number})
	if not (PlayerIds) then return end

	for _, UserId: number in pairs(PlayerIds) do
		self:AssignPlayer(UserId)
	end
end

function Group:PlayerIsInGroup(Player: Player): boolean | nil
	if not (Player) then return end

	if (table.find(self.Players, Player.UserId)) then
		return true
	end

	if (self.__IsMember) then
		return self.__IsMember(Player)
	end
end

function Group:IsMember(Get: (Player) -> boolean | nil)
	if not (typeof(Get) == "function") then return end

	self.__IsMember = Get
end

return Group