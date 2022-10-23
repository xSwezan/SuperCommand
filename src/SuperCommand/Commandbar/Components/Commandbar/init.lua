local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Roact = require(ReplicatedStorage.SuperCommand.Roact)
local RoactSpring = require(ReplicatedStorage.SuperCommand["Roact-spring"])
local RoactRodux = require(ReplicatedStorage.SuperCommand.RoactRodux)

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local Camera = workspace.CurrentCamera

local e = Roact.createElement

local Component = Roact.Component:extend(script.Name)

local SuperCommand = ReplicatedStorage:WaitForChild("SuperCommand", 10)
if not (SuperCommand) then return {} end

local RemotesFolder = SuperCommand:WaitForChild("Remotes", 10)
if not (RemotesFolder) then return {} end

local CommandsFolder = SuperCommand:WaitForChild("Commands", 10)
if not (CommandsFolder) then return {} end

local OperatorsFolder = SuperCommand:WaitForChild("Operators", 10)
if not (OperatorsFolder) then return {} end

local TypesFolder = SuperCommand:WaitForChild("Types", 10)
if not (TypesFolder) then return {} end

local Actions = require(ReplicatedStorage.SuperCommand.Actions)

--[[
local CommandsLayout = {
	{
		Name = "kick";
		Description = "Kick a player";
		Arguments = {
			{
				Name = "Player to kick";
				Type = "Player";
			};
			{
				Name = "Reason";
				Type = "string";
			};
		};
	};
}
]]

function Component:ReplaceMagicCharacters(Str: string, Replacement: string): string
	return Str:gsub("([%$%%%^%*%(%)%.%[%]%+%-%?])", Replacement)
end

function Component:CommandCanBeExecuted(Text: string): boolean
	local CurrentArguments = self:SplitString(self:ConvertOperators(Text))
	local CurrentString = CurrentArguments[#CurrentArguments]

	local CurrentCommand = self:GetCurrentCommand(Text)
	if not (CurrentCommand) then return false, ("Didn't find a command with the name '%s'!"):format(CurrentArguments[1]) end

	-- local ArgumentsNeeded = self:GetCommands()

	-- if (#CurrentArguments > 1) then
	-- 	ArgumentsNeeded = CurrentCommand.Arguments
	-- end

	local ArgumentsNeeded = CurrentCommand.Arguments

	for Index = 1, #ArgumentsNeeded do
		local StringArgument = CurrentArguments[Index + 1]
		local Argument = ArgumentsNeeded[Index]

		if (typeof(StringArgument) ~= "string") or (StringArgument == "") then return false, ("Argument #%s has not been filled in!"):format(Index + 1) end
		-- if (StringArgument == "") then continue end
		if not (Argument) then continue end

		local Type = self:GetType(Argument.Type)
		if not (Type) then continue end
		if (typeof(Type.Convert) ~= "function") then continue end
		if (Type.Convert(Player, StringArgument) ~= nil) then continue end

		-- Argument should error, but lets check for mistakes

		local CanError = true

		-- Has suggestions?
		if (typeof(Type.Get) == "function") and (typeof(Type.Get) == "function") and (#self:GetSuggestionsFor(Type.Get(Player, StringArgument), StringArgument) > 0) then
			CanError = false
		end

		if not (CanError) then continue end

		return false, ("'%s' is not a valid '%s' in Argument #%d!"):format(StringArgument, Argument.Type, Index)
	end

	return true
end

function Component:GetPortions(String: string): {string}
	local Portions: {string} = String:split("; ")

	if (#Portions <= 1) then return {String} end

	local SearchedPortions = {}
	for Index: number, Portion: string in Portions do
		if (Index == #Portions) then continue end
		table.insert(SearchedPortions, Portion)

		local Can, Error = self:CommandCanBeExecuted(Portion)
		if (Error) then
			local FinalPortion = ("%s; "):format(Portion)
			if (#Portions > Index) then
				for i = Index + 1, #Portions do
					FinalPortion = ("%s%s"):format(FinalPortion, Portions[i])
				end
			end
			SearchedPortions[Index] = FinalPortion
			return SearchedPortions
		end
	end

	if (String:match("; $")) then
		table.insert(Portions, "")
	end

	return Portions
end

function Component:GetPortion(String: string): string
	local Portions: {string} = self:GetPortions(String)

	return Portions[#Portions], #Portions
end

function Component:GetWhitespace(): number
	return self.InputRef:getValue().CursorPosition - 1
end

function Component:SplitString(String: string, DontRemoveMagic: boolean): {string}
	local Portion = self:GetPortion(String)
	local String: string = Portion or String

	local Format = "(%b\"\")"
	local ReplacementFormat = "|\"|\"|"
	local SpaceReplacement = "?|?"

	local Formatted: string = String:gsub(Format, ReplacementFormat):gsub(" ", SpaceReplacement)
	
	for Replacement: string in string.gmatch(--[[Util:ReplaceMagicCharacters(String, "%%%1")]]String, Format) do
		local Replacement = string.gsub(Replacement:gsub("%%","%%%%"), '"', "")

		-- warn(("string.gsub('%s', '%s', '%s', 1)"):format(Formatted, ReplacementFormat, Replacement))

		Formatted = string.gsub(Formatted, ReplacementFormat, Replacement, 1)
	end

	return Formatted:split(SpaceReplacement)
end

function Component:GetCommands()
	local Commands = {}
	for _, Command in pairs(CommandsFolder:GetChildren()) do
		local Sorted = {}

		for _, Argument in pairs(Command:GetChildren()) do
			Sorted[Argument.Value] = {
				Name = Argument.Name,
				Type = Argument:GetAttribute("Type")
			}
		end

		table.insert(Commands,{
			Name = Command.Name;
			Description = Command:GetAttribute("Description");
			Arguments = Sorted;
		})
	end
	return Commands
end

function Component:GetCurrentCommand(Text: string)
	local CurrentArguments: {string} = self:SplitString(Text)
	local CommandName: string = CurrentArguments[1]

	local Commands = self:GetCommands()
	
	for _, Command in Commands do
		if (string.lower(Command.Name) ~= string.lower(CommandName)) then continue end

		return Command
	end
end

function Component:MatchesOneInList(String: string, List: {string}): boolean | nil
	if not (String) then return end
	for _, Argument in pairs(List or {}) do
		if not (Argument:match("^"..String)) then continue end

		return true
	end
	return false
end

function Component:GetSuggestionsFor(Table: {}, String: string)
	local Suggestions = {}

	for _, Argument in ipairs(Table or {}) do
		if not (Argument:lower():match("^"..self:ReplaceMagicCharacters(String:lower(), "%%%1"))) then continue end

		table.insert(Suggestions, Argument)
	end

	return Suggestions
end

function Component:IsAnOperator(Text: string, ArgumentIndex: string, Type: string)
	for _, OperatorValue: StringValue in OperatorsFolder:GetChildren() do
		if (OperatorValue.Value ~= Type) then continue end

		local Args = self:SplitString(Text, true)
		if not (string.match(Args[ArgumentIndex], "^"..OperatorValue.Name.."$")) then continue end

		return true
	end
end

function Component:ConvertOperators(Text: string)
	local TypeConversions = {
		number = 0;
	}

	for _, OperatorValue: StringValue in OperatorsFolder:GetChildren() do
		local Type = OperatorValue.Value
		Text = Text:gsub(OperatorValue.Name, TypeConversions[Type] or Type)
	end

	return Text
end

function Component:GetArgumentDescriptionPosition(): UDim2
	local TextBox: TextBox = self.InputRef:getValue()
	if not (TextBox) then return end

	local ArgumentDescriptionRef: Frame = self.ArgumentDescriptionRef:getValue()
	local ADSize: Vector2 = ArgumentDescriptionRef.AbsoluteSize

	local SuggestionsList: Frame = self.SuggestionsRef:getValue()
	local SuggestionsSize: Vector2 = SuggestionsList.AbsoluteSize

	local _, _, _, _, Suggestions = self:GetAutoComplete(self.state.CurrentText)

	local ExtraMin = if (Suggestions) and (#Suggestions > 0) then ((SuggestionsSize.X + 1) / TextBox.Parent.AbsoluteSize.X) else 0

	local WidthHalf = ((ADSize.X / 2) / TextBox.Parent.AbsoluteSize.X)

	return UDim2.new(
		math.clamp(
			((TextBox.TextBounds.X + (TextBox.Parent.AbsoluteSize.X - TextBox.AbsoluteSize.X)) / TextBox.AbsoluteSize.X) * (TextBox.AbsoluteSize.X / TextBox.Parent.AbsoluteSize.X) - .006,
			0 + WidthHalf + ExtraMin,
			1 - WidthHalf
		),
		0,
		if (self.state.IsTop) then 1 else 0,
		if (self.state.IsTop) then 2 else -2
	)
end

function Component:GetAutoComplete(Text: string)
	local Text = self:GetPortion(self:ConvertOperators(Text))

	local CurrentArguments = self:SplitString(Text, true)
	local CurrentString = CurrentArguments[#CurrentArguments]
	
	local Whitespace = #string.sub(Text, 0, #Text:split("") - #CurrentString:split("")):split("")

	local CurrentCommand = self:GetCurrentCommand(Text)
	local ArgumentsNeeded = self:GetCommands()

	if (#CurrentArguments > 1) then
		if not (CurrentCommand) then return ("Didn't find a command with the name '%s'!"):format(CurrentArguments[1]) end

		ArgumentsNeeded = CurrentCommand.Arguments
	end

	local CurrentArgumentNeeded = ArgumentsNeeded[math.clamp(#CurrentArguments - 1, 1, math.huge)]
	if not (CurrentArgumentNeeded) then return ("No argument found with Index #%d"):format(#CurrentArguments) end

	local ArgumentName = tostring(CurrentArgumentNeeded.Name)
	local ArgumentType = tostring(CurrentArgumentNeeded.Type)

	self.props.SetVariable("CurrentType", ArgumentType)

	local ArgumentTypeText: string = if (ArgumentName == ArgumentType) then ArgumentName elseif (ArgumentType == "nil") then "" else ("<font color='rgb(0,170,255)'>%s:</font> %s"):format(ArgumentName, ArgumentType)

	for Index = 1, #CurrentArguments do
		local StringArgument = CurrentArguments[Index]
		local Argument = ArgumentsNeeded[Index - 1]

		if (typeof(StringArgument) ~= "string") then continue end
		if not (Argument) then continue end
		if (StringArgument == "") then continue end

		local Type = self:GetType(Argument.Type)
		if not (Type) then continue end
		if (typeof(Type.Convert) ~= "function") then continue end
		if (Type.Convert(Player, StringArgument) ~= nil) then continue end

		-- Argument should error, but lets check for mistakes

		local CanError = true

		-- Has suggestions?
		if (typeof(Type.Get) == "function") and (typeof(Type.Get) == "function") and (#self:GetSuggestionsFor(Type.Get(Player, CurrentString), StringArgument) > 0) then
			CanError = false
		end

		if not (CanError) then continue end

		return ("'%s' is not a valid '%s' in Argument #%d!"):format(StringArgument, Argument.Type, Index)
	end

	local List
	local SuggestionText

	local TypeModule: ModuleScript? = TypesFolder:FindFirstChild(ArgumentType or "")
	local Type: {}? = if (TypeModule) then require(TypeModule) else nil

	if (#ArgumentsNeeded == 0) then
		return nil, "", 0
	elseif (#CurrentArguments == 1) then
		List = {}
		for _, Command in pairs(ArgumentsNeeded) do
			table.insert(List, Command.Name)
		end
	elseif (#ArgumentsNeeded > 0) and (TypeModule) and (Type) and (typeof(Type.Get) == "function") then
		List = Type.Get(Player, CurrentString)
		if (typeof(List) == "table") then
			table.sort(List)
			local DidFind = false
			for _, String in pairs(List) do
				if not (String:lower():match("^"..self:ReplaceMagicCharacters(CurrentString:lower(), "%%%1"))) then continue end

				DidFind = true
				break
			end
			if not (DidFind) then
				return ("'%s' is not a valid type '%s'"):format(CurrentString, ArgumentType)
			end
		end
	end

	-- for _, Argument: string in List or {} do
	-- 	if not (Argument:lower():match("^"..self:ReplaceMagicCharacters(CurrentString:lower(), "%%%1"))) then continue end

	-- 	table.insert(Suggestions, Argument)
	-- end

	local Suggestions = self:GetSuggestionsFor(List or {}, CurrentString)
	table.sort(Suggestions)

	if ((List and #List > 0 and #Suggestions > 0) or (SuggestionText))
		or
		((Type) and (typeof(Type.Convert) == "function") and ((Type.Convert(Player, CurrentString) or nil) ~= nil)) -- Argument Typechecking: Argument is correct type
		or
		(CurrentString == "") -- Player hasn't started writing the argument yet
	then
		-- No error
		self.state.SuggestionIndex = math.clamp(self.state.SuggestionIndex, 1, math.clamp(#Suggestions, 1, math.huge))
		return nil, (SuggestionText or Suggestions[self.state.SuggestionIndex]), Whitespace, false, Suggestions, ArgumentsNeeded, ArgumentTypeText
	end

	return ("Invalid argument #%s '%s' in '%s'"):format(#CurrentArguments, CurrentString, (CurrentCommand ~= nil) and CurrentCommand.Name or "Commands")
end

local SHPatterns = {
	{
		Name = "String";
		Patterns = {'(%b"")'};
		Color = Color3.fromRGB(0,150,0)
	};
	{
		Name = "boolean";
		Type = "Word";
		Patterns = {"true", "false"};
		Color = Color3.fromRGB(223, 150, 41)
	};
}

function Component:SyntaxHighlighting(Text)
	if not (Text) then return end
	if (self.state.ErrorText ~= "") then return end

	local Props = {}

	Text = self:ReplaceMagicCharacters(Text, "§½%1")

	local Words = Text:split(" ")

	for Index, Info in pairs(SHPatterns) do
		local FinalString = ""
		local LastEnd = 0
		for _, Pattern: string in ipairs(Info.Patterns) do
			if (Info.Type == "Word") then
				local CurrentCharacterIndex = 0
				for _, Word: string in Words do
					local Start: number = CurrentCharacterIndex
					local CharAmount: number = #Word:split("")
					CurrentCharacterIndex += CharAmount

					if (Word ~= Pattern) then continue end

					local Whitespace = (Start - LastEnd + 1)
					LastEnd = CurrentCharacterIndex

					FinalString = FinalString..(" "):rep(Whitespace)..Word:gsub("§½%%", "")
				end
				continue
			end
			string.gsub(self:ReplaceMagicCharacters(Text, "%%%1"), Pattern, function(String)
				local Start, End = string.find(Text, String, if (LastEnd == 0) then LastEnd else LastEnd + 1)
				if not (Start) or not (End) then return end

				local Whitespace = (Start - LastEnd - 1)
				LastEnd = End

				FinalString = FinalString..(" "):rep(Whitespace)..(String):gsub("§½%%", "")
	
				return ""
			end)
		end

		Props[Info.Name] = e("TextLabel",{
			Size = UDim2.fromScale(1,1);
	
			Position = UDim2.fromScale(1,0);
			AnchorPoint = Vector2.new(1,0);

			BackgroundTransparency = 1;

			Text = FinalString;
			TextScaled = true;
			TextColor3 = Info.Color or Color3.fromRGB(50,50,50);
			TextXAlignment = Enum.TextXAlignment.Left;
			Font = Enum.Font.Code;

			ZIndex = (100 + Index);
		});
	end

	return Roact.createFragment(Props)
end

function Component:AddToOutput(String: string)
	if (typeof(String) ~= "string") then return end

	table.insert(self.OutputContent, String)

	self:setState{OutputEnoughContent = true}
end

function Component:GetOutputComponents()
	local Props = {}

	for Index, String: string in ipairs(self.OutputContent or {}) do
		Props[Index] = e(require(script.OutputLabel),{
			Text = String;
			LayoutOrder = Index;
		});
	end

	return Roact.createFragment(Props)
end

function Component:GetSuggestionComponents(OnlySuggestions: boolean?)
	local _, CurrentAutoComplete, _, _, Suggestions = self:GetAutoComplete(self.state.CurrentText)

	if not (typeof(Suggestions) == "table") then return end
	if (OnlySuggestions) then return Suggestions end
	if (#Suggestions < 1) then return end

	local Props = {}

	local From = math.clamp(self.state.SuggestionStartIndex, 1, #Suggestions)
	local To = math.clamp(self.state.SuggestionStartIndex + self.state.MaxVisibleSuggestions - 1, 1, #Suggestions)

	for Index = From, To do
		local SuggestionText: string = Suggestions[Index]

		SuggestionText = SuggestionText:gsub(self:ReplaceMagicCharacters(SuggestionText:sub(0, #self.state.CurrentArgument), "%%%1"), self.state.CurrentArgument:sub(0, #self.state.CurrentArgument), 1)

		if (self.state.SuggestionIndex == Index) then
			self.CurrentSuggestion = SuggestionText
		end

		if (#Suggestions == 1) then continue end

		Props[SuggestionText] = e(require(script.SuggestionLabel),{
			Text = SuggestionText;
			Index = Index;
			SelectedIndex = self.state.SuggestionIndex;
		});
	end

	local EdgeIndex = (self.state.SuggestionStartIndex + self.state.MaxVisibleSuggestions - 1) -- Last Visible Index
	local AmountMore: number = (#Suggestions - EdgeIndex)
	if (#Suggestions > self.state.MaxVisibleSuggestions) and (AmountMore > 0) then
		Props["__Max"] = e(require(script.SuggestionLabel),{
			Text = ("+%s More..."):format(AmountMore);
			TextSize = 15;
			TextColor3 = Color3.fromRGB(150,150,150);
			Index = 999999;
		});
	end

	return Roact.createFragment(Props)
end

function Component:GetType(TypeName: string)
	if not (TypeName) then return end

	local TypeModule = TypesFolder:FindFirstChild(TypeName)
	if not (typeof(TypeModule) == "Instance") then return end
	if not (TypeModule:IsA("ModuleScript")) then return end

	return require(TypeModule)
end

-- function Component:GetArguments(): {{Name: string, Value: any}}
-- 	local Arguments = {}
-- 	local CurrentArguments = self:SplitString(self.state.CurrentText)

-- 	local Command = self:GetCurrentCommand(self.state.CurrentText)
-- 	if not (Command) then return end

-- 	for Index, ArgumentText: string in CurrentArguments do
-- 		if (Index == 1) then continue end

-- 		local ArgumentInfo: {Name: string, Type: string} = Command.Arguments[Index - 1]
-- 		local Type = self:GetType(ArgumentInfo.Type)

-- 		table.insert(Arguments,{
-- 			Name = ArgumentInfo.Name;
-- 			Type = ArgumentInfo.Type;
-- 			Value = Type.Convert(Player, ArgumentText);
-- 		})
-- 	end

-- 	return Arguments
-- end

function Component:init()
	self:setState{
		HoldingOnBar = false;
		Focused = false;

		AutoCompleteText = "";

		MaxVisibleSuggestions = 6;
		SuggestionStartIndex = 1;
		SuggestionIndex = 1;

		ErrorText = "";

		ArgumentDescription = "";

		NormalTextColor = Color3.fromRGB(255,255,255);
		ErrorTextColor = Color3.fromRGB(255,0,0);
		CompleteTextColor = Color3.fromRGB(0,255,0);

		CurrentText = "";
		CurrentArgument = "";
	}

	self.ArgumentDescriptionRef = Roact.createRef()
	self.SuggestionsRef = Roact.createRef()
	self.InputRef = Roact.createRef()

	self.LastDeepIndex = 0

	self.BarTopPosition = UDim2.new(.5,0,0,5)
	self.BarBottomPosition = UDim2.new(.5,0,1,-5)

	self.OutputContent = {}

	UserInputService.InputBegan:Connect(function(Input, GP)
		if not (GP) then return end
		if (Input.KeyCode == Enum.KeyCode.Up) or (Input.KeyCode == Enum.KeyCode.Down) then
			local Suggestions: {string} = self:GetSuggestionComponents(true) or {}

			local ToAdd: number = if (Input.KeyCode == Enum.KeyCode.Up) then -1 else 1
			local Final: number = (self.state.SuggestionIndex + ToAdd)

			self:setState{SuggestionIndex = if (#Suggestions == 0) then 0 elseif (Final > #Suggestions) then 1 elseif (Final < 1) then #Suggestions else Final}

			local EdgeIndex = (self.state.SuggestionStartIndex + self.state.MaxVisibleSuggestions - 1) -- Last Visible Index

			local _, AutoComplete = self:GetAutoComplete(self.state.CurrentText)

			local Whitespace = self:GetWhitespace()

			self:setState{
				SuggestionStartIndex = if (EdgeIndex >= self.state.SuggestionIndex) and (self.state.SuggestionIndex >= self.state.SuggestionStartIndex) then
					self.state.SuggestionStartIndex -- In view
				elseif (EdgeIndex < self.state.SuggestionIndex) then
					self.state.SuggestionStartIndex + (self.state.SuggestionIndex - EdgeIndex) -- Under View
				elseif (self.state.SuggestionStartIndex > self.state.SuggestionIndex) then
					self.state.SuggestionStartIndex - (self.state.SuggestionStartIndex - self.state.SuggestionIndex) -- Over View
				else
					1; -- At the top
				AutoCompleteText = if (AutoComplete) then ("%s%s"):format((" "):rep(Whitespace), AutoComplete:gsub(".", "", #self.state.CurrentArgument)) else "";
			}
		end
	end)

	self.style, self.api = RoactSpring.Controller.new{
		BarPosition = self.BarBottomPosition;
		BarAnchorPoint = Vector2.new(.5,1);
		BarExtraAnchorPoint = Vector2.new(0,1);

		IsTop = false;

		ArgumentDescriptionPosition = UDim2.fromOffset(0,-2);

		config = {
			tension = 2000;
			friction = 70;
		}
	}
end

function Component:render()
	return e("Frame",{
		Size = UDim2.fromScale(1,1);

		Position = UDim2.fromScale(.5,.5);
		AnchorPoint = Vector2.new(.5,.5);

		BackgroundTransparency = 1;
	},{
		List = e("UIListLayout",{
			VerticalAlignment = Enum.VerticalAlignment.Bottom;
			HorizontalAlignment = Enum.HorizontalAlignment.Center;

			FillDirection = Enum.FillDirection.Vertical;

			SortOrder = Enum.SortOrder.LayoutOrder;
			Padding = UDim.new(0,5);
		});
		e("UIPadding",{
			PaddingTop = UDim.new(0,5);
			PaddingBottom = UDim.new(0,5);
			PaddingRight = UDim.new(0,5);
			PaddingLeft = UDim.new(0,5);
		});
		Commandbar = e("Frame",{
			Size = UDim2.new(1,0,.04,0);
	
			BorderSizePixel = 0;
			BackgroundTransparency = .25;
			BackgroundColor3 = Color3.fromRGB();

			LayoutOrder = 1;
	
			[Roact.Event.InputBegan] = function(_, Input, GP)
				if (GP) then return end
				if not (Input.UserInputType == Enum.UserInputType.MouseButton1) then return end
	
				self:setState{HoldingOnBar = true}
				while task.wait() and (self.state.HoldingOnBar) do
					local MouseY = Mouse.Y
					local MaxY = Camera.ViewportSize.Y
	
					local IsOnTop = (MouseY < (MaxY / 2))
					self.api:start{
						BarPosition = if (IsOnTop) then self.BarTopPosition else self.BarBottomPosition;
						BarAnchorPoint = if (IsOnTop) then Vector2.new(.5,0) else Vector2.new(.5,1)
					}
	
					self:setState{
						IsTop = (IsOnTop == true);
					}
				end
			end;
			[Roact.Event.InputEnded] = function(_, Input, GP)
				if (GP) then return end
				if not (Input.UserInputType == Enum.UserInputType.MouseButton1) then return end
	
				self:setState{HoldingOnBar = false}
			end;
		},{
			e(require(script.UICorner));
			Inside = e("Frame",{
				Size = UDim2.fromScale(1,1);
	
				Position = UDim2.fromScale(.5,.5);
				AnchorPoint = Vector2.new(.5,.5);
	
				BackgroundTransparency = 1;
			},{
				e("UIPadding",{
					PaddingTop = UDim.new(0,10);
					PaddingBottom = UDim.new(0,10);
					PaddingRight = UDim.new(0,10);
					PaddingLeft = UDim.new(0,10);
				});
				e("TextLabel",{
					Size = UDim2.fromScale(.01,1);
		
					Position = UDim2.fromScale(0,0);
					AnchorPoint = Vector2.new(0,0);
		
					BackgroundTransparency = 1;
		
					Text = "$";
					TextScaled = true;
					TextColor3 = Color3.fromRGB(0, 170, 255);
					TextXAlignment = Enum.TextXAlignment.Left;
					Font = Enum.Font.Code;
				});
				Input = e("TextBox",{
					Size = UDim2.fromScale(.99,1);
		
					Position = UDim2.fromScale(1,0);
					AnchorPoint = Vector2.new(1,0);
		
					BackgroundTransparency = 1;
		
					ClearTextOnFocus = false;
		
					Text = "";
					TextScaled = true;
					TextColor3 = (self.state.IsComplete) and self.state.CompleteTextColor or ((self.state.ErrorText == "") and self.state.NormalTextColor or self.state.ErrorTextColor);
					TextXAlignment = Enum.TextXAlignment.Left;
					Font = Enum.Font.Code;
		
					[Roact.Change.Text] = function(TextBox: TextBox)
						local RemovedTab = TextBox.Text:gsub("\t", "")
						local Args = self:SplitString(RemovedTab)
						local CurrentArg = Args[#Args]
	
						local FinalString: string = RemovedTab
		
						if (TextBox.Text:sub(TextBox.CursorPosition - 1, TextBox.CursorPosition) == "\t") then -- Tab Pressed
							local Error, Suggestion, Whitespace, IsComplete, Suggestions, AvailableArguments = self:GetAutoComplete(RemovedTab)
							if not (Suggestions) then return end
	
							local AutoComplete = self.CurrentSuggestion or Suggestions[self.state.SuggestionIndex]
							if not (AutoComplete) then return end
	
							local SpaceEnd = ""
							local Cutout = FinalString:sub(0, #FinalString:split("") - #CurrentArg:split(""))
	
							AutoComplete = if (#AutoComplete:split(" ") > 1) then ("\"%s\""):format(AutoComplete) else AutoComplete
	
							FinalString = ("%s%s%s"):format(Cutout, AutoComplete, SpaceEnd)
						end
	
						TextBox.Text = FinalString
						if (FinalString ~= RemovedTab) then
							TextBox.CursorPosition = (#FinalString + 1)
						end
	
						local Error, AutoComplete, _Whitespace, IsComplete, Suggestions, AvailableArguments, ArgumentTypeText: string = self:GetAutoComplete(TextBox.Text)
	
						AutoComplete = AutoComplete or ""
						local Whitespace = self:GetWhitespace()
	
						local Args = self:SplitString(FinalString)
						local CurrentArg = Args[#Args]
	
						self:setState{
							AutoCompleteText = ("%s%s"):format((" "):rep(Whitespace), AutoComplete:gsub(".", "", #CurrentArg));
	
							ErrorText = Error or "";
							IsComplete = (IsComplete == true);
	
							CurrentText = TextBox.Text;
							CurrentArgument = CurrentArg;
	
							ArgumentDescription = ArgumentTypeText or "";
	
							NewSuggestions = not self.state.NewSuggestions;
						}
					end;
					[Roact.Event.Focused] = function()
						self:setState{Focused = true}
					end;
					[Roact.Event.FocusLost] = function(Rbx: TextBox, EnterPressed: boolean)
						self:setState{Focused = false}
	
						if not (EnterPressed) then return end
	
						local Portions = self:GetPortions(Rbx.Text)
						if not (Portions) then return end
	
						for _, Portion: string in ipairs(Portions) do
							local Command = self:GetCurrentCommand(Portion)
							if not (Command) then continue end
	
							local Can, Error = self:CommandCanBeExecuted(Portion)
							if not (Can) then warn(Error) continue end
	
							local Execute: RemoteFunction = RemotesFolder:WaitForChild("Execute")

							print(Portion)
	
							local Output = Execute:InvokeServer(Command.Name, Portion)
							self:AddToOutput(Output)
							-- RemotesFolder:WaitForChild("Execute"):FireServer(Command.Name, Portion)
						end
	
						Rbx.Text = ""
					end;
	
					[Roact.Ref] = self.InputRef;
				},{
					AutoComplete = e("TextLabel",{
						Size = UDim2.fromScale(1,1);
			
						Position = UDim2.fromScale(1,0);
						AnchorPoint = Vector2.new(1,0);
			
						BackgroundTransparency = 1;
			
						Text = self.state.AutoCompleteText;
						TextScaled = true;
						TextColor3 = Color3.fromRGB(50,50,50);
						TextXAlignment = Enum.TextXAlignment.Left;
						Font = Enum.Font.Code;
			
						ZIndex = 0;
					});
					self:SyntaxHighlighting(self.state.CurrentText);
				});
			});
			ArgumentDescription = e("Frame",{
				Size = UDim2.fromScale(0,.7);
				AutomaticSize = Enum.AutomaticSize.XY;
	
				Position = self:GetArgumentDescriptionPosition();
				AnchorPoint = if (self.state.IsTop) then Vector2.new(.5,0) else Vector2.new(.5,1);
	
				BorderSizePixel = 0;
				BackgroundTransparency = .25;
				BackgroundColor3 = Color3.fromRGB();
	
				ZIndex = 0;
	
				Visible = (self.state.Focused) and (self.state.ArgumentDescription ~= "") and (self.state.ErrorText == "");

				[Roact.Event.MouseEnter] = function()
					
				end;
				[Roact.Event.MouseLeave] = function()
					
				end;
	
				[Roact.Ref] = self.ArgumentDescriptionRef;
			},{
				TooltipTrigger = e(require(script.TooltipTrigger),{
					Text = (function()
						local Type = self:GetType(self.props.Variables.CurrentType)
						if not (Type) then return end

						return Type.Tooltip or '(%S+) | (%b"")'
					end)();
				});
				e("UIPadding",{
					PaddingTop = UDim.new(0,5);
					PaddingBottom = UDim.new(0,5);
					PaddingRight = UDim.new(0,5);
					PaddingLeft = UDim.new(0,5);
				});
				e(require(script.UICorner));
				Label = e("TextLabel",{
					Size = UDim2.fromScale(0,0);
					AutomaticSize = Enum.AutomaticSize.XY;
		
					Position = UDim2.fromScale(0,0);
					AnchorPoint = Vector2.new(0,0);
		
					BackgroundTransparency = 1;
		
					Text = self.state.ArgumentDescription;
					TextSize = 20;
					TextColor3 = Color3.fromRGB(255,255,255);
					RichText = true;
					TextXAlignment = Enum.TextXAlignment.Center;
					TextYAlignment = Enum.TextYAlignment.Center;
					Font = Enum.Font.Code;
	
					LayoutOrder = 1;
		
					ZIndex = 0;
		
					Visible = (self.state.ArgumentDescription ~= "");
				});
			});
			Suggestions = e("Frame",{
				Size = UDim2.fromScale(.2,.7);
	
				Position = if (self.state.IsTop) then UDim2.new(0,0,1,2) else UDim2.fromOffset(0,-2);
				AnchorPoint = if (self.state.IsTop) then Vector2.new(0,1) else Vector2.new(0,1);
	
				BackgroundTransparency = 1;
	
				ZIndex = 0;
	
				Visible = (function()
					local Suggestions = self:GetSuggestionComponents(true) or {}
					return (self.state.Focused) and (#Suggestions > 1);
				end)();
	
				[Roact.Ref] = self.SuggestionsRef;
			},{
				Container = e("Frame",{
					Size = UDim2.fromScale(1,0);
					AutomaticSize = Enum.AutomaticSize.Y;
	
					Position = UDim2.fromScale(.5,1);
					AnchorPoint = if (self.state.IsTop) then Vector2.new(.5,0) else Vector2.new(.5,1);
	
					BorderSizePixel = 0;
					BackgroundTransparency = .25;
					BackgroundColor3 = Color3.fromRGB();
				},{
					e("UIPadding",{
						PaddingTop = UDim.new(0,5);
						PaddingBottom = UDim.new(0,5);
						PaddingRight = UDim.new(0,5);
						PaddingLeft = UDim.new(0,5);
					});
					e(require(script.UICorner));
					e("UIListLayout",{
						VerticalAlignment = Enum.VerticalAlignment.Bottom;
						HorizontalAlignment = Enum.HorizontalAlignment.Left;
		
						SortOrder = Enum.SortOrder.LayoutOrder;
					});
					self:GetSuggestionComponents();
				});
			});
			ErrorFrame = e("Frame",{
				Size = UDim2.fromScale(0,0);
				AutomaticSize = Enum.AutomaticSize.XY;
	
				Position = if (self.state.IsTop) then UDim2.new(0,0,1,2) else UDim2.fromOffset(0,-2);
				AnchorPoint = if (self.state.IsTop) then Vector2.new(0,0) else Vector2.new(0,1);
	
				BorderSizePixel = 0;
				BackgroundTransparency = .25;
				BackgroundColor3 = Color3.fromRGB();
	
				ZIndex = 0;
	
				Visible = (self.state.Focused) and (self.state.ErrorText ~= "");
			},{
				e("UIPadding",{
					PaddingTop = UDim.new(0,5);
					PaddingBottom = UDim.new(0,5);
					PaddingRight = UDim.new(0,5);
					PaddingLeft = UDim.new(0,5);
				});
				e(require(script.UICorner));
				Label = e("TextLabel",{
					Size = UDim2.fromScale(0,0);
					AutomaticSize = Enum.AutomaticSize.XY;
		
					Position = UDim2.fromScale(0,0);
					AnchorPoint = Vector2.new(0,0);
		
					BackgroundTransparency = 1;
		
					Text = self.state.ErrorText;
					TextSize = 20;
					TextColor3 = Color3.fromRGB(255,0,0);
					TextXAlignment = Enum.TextXAlignment.Center;
					TextYAlignment = Enum.TextYAlignment.Center;
					Font = Enum.Font.Code;
	
					LayoutOrder = 1;
		
					ZIndex = 0;
		
					Visible = (self.state.ErrorText ~= "");
				});
			});
		});
		Output = e("Frame",{
			Size = UDim2.fromScale(1,0);
			AutomaticSize = Enum.AutomaticSize.Y;

			BorderSizePixel = 0;
			BackgroundTransparency = .25;
			BackgroundColor3 = Color3.fromRGB();

			LayoutOrder = 2;

			Visible = (self.state.OutputEnoughContent == true);
		},{
			e(require(script.UICorner));
			e("UIPadding",{
				PaddingTop = UDim.new(0,5);
				PaddingBottom = UDim.new(0,5);
				PaddingRight = UDim.new(0,5);
				PaddingLeft = UDim.new(0,5);
			});
			List = e("UIListLayout",{
				VerticalAlignment = Enum.VerticalAlignment.Bottom;
				HorizontalAlignment = Enum.HorizontalAlignment.Center;
	
				FillDirection = Enum.FillDirection.Vertical;
	
				SortOrder = Enum.SortOrder.LayoutOrder;
				Padding = UDim.new(0,0);
			});
			self:GetOutputComponents();
		});
	});
end

function Component:didUpdate(LastProps, LastState)
	if (LastState.NewSuggestions ~= self.state.NewSuggestions) then
		self:setState{
			SuggestionIndex = 1;
			SuggestionStartIndex = 1;
		}
		self.CurrentSuggestion = ""
	end
end

return RoactRodux.connect(
	function(State, Props)
		return {
			Variables = State.Variables;
		}
	end,
	function(Dispatch)
		return {
			SetVariable = function(Name: string, Value: any)
				Dispatch(Actions.SetVariable(Name, Value))
			end;
		}
	end
)(Component)