export type GroupType = {
	Players: {Player};
	Name: string;
	Weight: number;

	AssignPlayer: (UserId: number) -> nil;
	AssignPlayers: ({UserId: number}) -> nil;
	PlayerIsInGroup: (UserId: number) -> boolean | nil;
	AutoAssign: ((UserId: number) -> boolean | nil) -> boolean | nil;
}

--[=[
	@class Group

	Groups allow you to assign players **Manually or Automatically** to be able to run different commands.
	Groups are really useful when you want to make for example Admin Commands, that can only be ran by Admins.
]=]

local Group = {}
Group.__index = Group

--[=[
	@prop Players {UserId: number}
	@within Group

	Players that are in the group
]=]

--[=[
	@prop Name string
	@within Group

	Name of the Group
]=]

--[=[
	@prop Weight number
	@within Group

	Weight of the Group
]=]

--[=[
	Creates a GroupClass

	@param Name string -- Name of the Group
	@param Weight number -- Weight of the Group
	@return GroupClass -- Group
]=]
function Group:Create(Name: string, Weight: number): GroupType
	local self = setmetatable({}, Group)

	self.Players = {}

	self.Name = Name
	self.Weight = Weight

	return self
end

--[=[
	Assign player to the Group

	@param UserId number -- Player UserId
	@return nil
]=]
function Group:AssignPlayer(UserId: number)
	if not (typeof(UserId) == "number") then return end

	table.insert(self.Players, UserId)
end

--[=[
	Assign multiple players to the Group

	@param PlayerIds {UserId: number} -- Player UserIds
	@return nil
]=]
function Group:AssignPlayers(PlayerIds: {number})
	if not (PlayerIds) then return end

	for _, UserId: number in pairs(PlayerIds) do
		self:AssignPlayer(UserId)
	end
end

--[=[
	Check if certain player is in the Group

	@param UserId number -- Player to check for
	@return boolean | nil
]=]
function Group:PlayerIsInGroup(UserId: number): boolean | nil
	if not (UserId) then return end

	if (table.find(self.Players, UserId)) then
		return true
	end

	if (self.__IsMember) then
		return self.__IsMember(UserId)
	end

	return false
end

--[=[
	Auto Assigns players for you

	@param Get (UserId: number) -> boolean | nil -- Function that returns a boolean depending if the player should be assigned to the Group
	@return nil
]=]
function Group:AutoAssign(Get: (UserId: number) -> boolean | nil)
	if not (typeof(Get) == "function") then return end

	self.__IsMember = Get
end

return Group