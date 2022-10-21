local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Roact = require(ReplicatedStorage.SuperCommand.Roact)
local RoactSpring = require(ReplicatedStorage.SuperCommand["Roact-spring"])

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

local function ReplaceMagicCharacters(Str: string, Replacement: string): string
	return Str:gsub("([%$%%%^%*%(%)%.%[%]%+%-%?])", Replacement)
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

function Component:SplitMessage(Message: string, DontRemoveMagic: boolean): {string}
	local Format = "(%b\"\")"
	local ReplacementFormat = "|\"|\"|"
	local SpaceReplacement = "?|?"

	-- Message = IgnoreMagicCharacters(Message:gsub("%p", ""))
	Message = if (DontRemoveMagic) then Message else ReplaceMagicCharacters(Message, "")

	local Formatted: string = Message:gsub(Format, ReplacementFormat):gsub(" ", SpaceReplacement)
	
	for Replacement: string in string.gmatch(Message, Format) do
		Formatted = string.gsub(
			Formatted,
			ReplacementFormat,
			string.gsub(Replacement, "\"", ""),
			1
		)
	end

	return Formatted:split(SpaceReplacement)
end

function Component:GetCurrentCommand(Text: string)
	local CurrentArguments: {string} = self:SplitMessage(Text)
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
	for _, Argument in pairs(Table or {}) do
		if not (Argument:match("^"..String)) then continue end

		table.insert(Suggestions, Argument)
	end
	return Suggestions
end

function Component:IsAnOperator(Text: string, ArgumentIndex: string, Type: string)
	for _, OperatorValue: StringValue in OperatorsFolder:GetChildren() do
		if (OperatorValue.Value ~= Type) then continue end

		local Args = self:SplitMessage(Text, true)
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

function Component:GetArgumentDescriptionPosition(TextBox: TextBox): UDim2
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
	Text = self:ConvertOperators(Text)

	local CurrentArguments = self:SplitMessage(Text)
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

	local ArgumentTypeText: string = if (ArgumentName == ArgumentType) then ArgumentName elseif (ArgumentType == "nil") then "" else ("<font color='rgb(0,170,255)'>%s:</font> %s"):format(ArgumentName, ArgumentType)

	for Index = 1, #CurrentArguments do
		local StringArgument = CurrentArguments[Index]
		local Argument = ArgumentsNeeded[Index - 1]

		if not (StringArgument) then continue end
		if not (Argument) then continue end
		if (StringArgument == "") then continue end

		local Type = self:GetType(Argument.Type)
		if not (Type) then continue end
		if (typeof(Type.Convert) ~= "function") then continue end
		if (Type.Convert(StringArgument) ~= nil) then continue end

		-- Argument should error, but lets check for mistakes

		local CanError = true

		-- Has suggestions?
		if (typeof(Type.Get) == "function") and (typeof(Type.Get) == "function") and (#self:GetSuggestionsFor(Type.Get(), StringArgument) > 0) then
			CanError = false
		end

		-- Is an Operator?
		--[[ OLD
		if (self:IsAnOperator(Text, Index, Argument.Type)) then
			CanError = false
		end
		]]

		if not (CanError) then continue end

		return ("Expected type '%s' in Argument #%d!"):format(Argument.Type, Index)
	end

	local Suggestions = {}
	local List
	local SuggestionText

	local TypeModule: ModuleScript? = TypesFolder:FindFirstChild(CurrentArgumentNeeded.Type or "")
	local Type: {}? = if (TypeModule) then require(TypeModule) else nil

	if (#ArgumentsNeeded == 0) then
		return nil, "", 0
	elseif (#CurrentArguments == 1) then
		List = {}
		for _, Command in pairs(ArgumentsNeeded) do
			table.insert(List, Command.Name)
		end
	elseif (#ArgumentsNeeded > 0) and (TypeModule) and (Type) and (typeof(Type.Get) == "function") then
		List = Type.Get()
		if (typeof(List) == "table") then
			local DidFind = false
			for _, String in pairs(List) do
				if not (String:match("^"..CurrentString)) then continue end

				DidFind = true
				break
			end
			if not (DidFind) then
				return ("'%s' is not a valid type '%s'"):format(CurrentString, CurrentArgumentNeeded.Type)
			end
		end
	end

	for _, Argument in pairs(List or {}) do
		if not (Argument:match("^"..CurrentString)) then continue end

		table.insert(Suggestions, Argument)
	end

	if
		((List and #List > 0 and #Suggestions > 0) or (SuggestionText))
		or
		((Type) and (typeof(Type.Convert) == "function") and ((Type.Convert(CurrentString) or nil) ~= nil)) -- Argument Typechecking: Argument is correct type
		or
		(CurrentString == "") -- Player hasn't started writing the argument yet
		-- or
		-- (self:IsAnOperator(Text, #CurrentArguments, CurrentArgumentNeeded.Type)) -- Is an Operator
	then
		-- No error
		self.SuggestionsIndex = math.clamp(self.SuggestionsIndex, 1, math.clamp(#Suggestions, 1, math.huge))
		return nil, (SuggestionText or Suggestions[self.SuggestionsIndex]), Whitespace, false, Suggestions, ArgumentsNeeded, ArgumentTypeText
	end

	return ("Invalid argument #%s '%s' in '%s'"):format(#CurrentArguments, CurrentString, (CurrentCommand ~= nil) and CurrentCommand.Name or "Commands")
end

local SyntaxHighlighting_Patterns = {
	{
		Name = "String";
		Patterns = {"(%b\"\")"};
		Color = Color3.fromRGB(0,150,0)
	};
	{
		Name = "boolean";
		Patterns = {"true", "false"};
		Color = Color3.fromRGB(223, 150, 41)
	};
}

function Component:SyntaxHighlighting(Text)
	if not (Text) then return end
	if not (self.state.ErrorText == "") then return end

	local Props = {}

	Text = ReplaceMagicCharacters(Text, "´´``å%1")

	for Index, Info in pairs(SyntaxHighlighting_Patterns) do
		local FinalString = ""
		local LastEnd = 0
		for _, Pattern in pairs(Info.Patterns) do
			string.gsub(ReplaceMagicCharacters(Text, "%%%1"), Pattern, function(String)
				local Start, End = string.find(Text, String, if (LastEnd == 0) then LastEnd else LastEnd + 1)
				if not (Start) or not (End) then return end

				local Whitespace = (Start - LastEnd - 1)
				LastEnd = End

				FinalString = FinalString..(" "):rep(Whitespace)..String:gsub("´´``å%%", "")
	
				return ""
			end)
		end

		Props[Info.Name] = e("TextLabel",{
			Size = UDim2.fromScale(.98,1);
	
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

function Component:GetSuggestionComponents(OnlySuggestions: boolean?)
	local _, CurrentAutoComplete, _, _, Suggestions = self:GetAutoComplete(self.state.CurrentText)
	if not (Suggestions) then return end

	if (OnlySuggestions) then
		return Suggestions
	end

	local Props = {}

	for Index, SuggestionText in pairs(Suggestions) do
		Props[SuggestionText] = e("Frame",{
			Size = UDim2.fromScale(1,0);
			AutomaticSize = Enum.AutomaticSize.Y;

			BorderSizePixel = 0;
			BackgroundTransparency = 1;--.25;
			BackgroundColor3 = (CurrentAutoComplete == SuggestionText) and Color3.fromRGB(10,10,10) or Color3.fromRGB();

			LayoutOrder = Index;
		},{
			Suggestion = e("TextLabel",{
				Size = UDim2.fromScale(1,0);
				AutomaticSize = Enum.AutomaticSize.Y;

				Position = UDim2.fromScale(.5,0);
				AnchorPoint = Vector2.new(.5,0);

				BackgroundTransparency = 1;

				Text = SuggestionText;
				TextSize = 20;
				-- TextScaled = true;
				TextColor3 = if (CurrentAutoComplete == SuggestionText) then Color3.fromRGB(0, 170, 255) else Color3.fromRGB(255,255,255);
				TextXAlignment = Enum.TextXAlignment.Left;
				Font = Enum.Font.Code;
			});
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

function Component:GetArguments(): {{Name: string, Value: any}}
	local Arguments = {}
	local CurrentArguments = self:SplitMessage(self.state.CurrentText)

	local Command = self:GetCurrentCommand(self.state.CurrentText)
	if not (Command) then return end

	for Index, ArgumentText: string in CurrentArguments do
		if (Index == 1) then continue end

		local ArgumentInfo: {Name: string, Type: string} = Command.Arguments[Index - 1]
		local Type = self:GetType(ArgumentInfo.Type)

		table.insert(Arguments,{
			Name = ArgumentInfo.Name;
			Type = ArgumentInfo.Type;
			Value = Type.Convert(ArgumentText);
		})
	end
	return Arguments
end

function Component:init()
	self:setState{
		HoldingOnBar = false;
		Focused = false;

		AutoCompleteText = "";
		AutoCompleteFound = false;

		ErrorText = "";

		ArgumentDescription = "";

		NormalTextColor = Color3.fromRGB(255,255,255);
		ErrorTextColor = Color3.fromRGB(255,0,0);
		CompleteTextColor = Color3.fromRGB(0,255,0);

		CurrentText = "";
	}

	self.ArgumentDescriptionRef = Roact.createRef()
	self.SuggestionsRef = Roact.createRef()

	self.SuggestionsIndex = 1
	self.LastDeepIndex = 0

	self.BarTopPosition = UDim2.new(.5,0,0,5)
	self.BarBottomPosition = UDim2.new(.5,0,1,-5)

	UserInputService.InputBegan:Connect(function(Input, GP)
		if not (GP) then return end
		if (Input.KeyCode == Enum.KeyCode.Up) or (Input.KeyCode == Enum.KeyCode.Down) then
			local ToAdd = (Input.KeyCode == Enum.KeyCode.Up) and -1 or 1
			self.SuggestionsIndex = math.clamp(self.SuggestionsIndex + ToAdd, 1, math.huge)

			local _, AutoComplete, Whitespace = self:GetAutoComplete(self.state.CurrentText)
			self:setState{AutoCompleteText = (" "):rep(Whitespace or 0)..(AutoComplete or "")}
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
		Size = UDim2.new(1,-10,.04,0);

		Position = self.style.BarPosition;
		AnchorPoint = self.style.BarAnchorPoint;

		BorderSizePixel = 0;
		BackgroundTransparency = .25;
		BackgroundColor3 = Color3.fromRGB();

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
				Size = UDim2.fromScale(.02,1);
	
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
				Size = UDim2.fromScale(.98,1);
	
				Position = UDim2.fromScale(1,0);
				AnchorPoint = Vector2.new(1,0);
	
				BackgroundTransparency = 1;
	
				ClearTextOnFocus = false;
	
				Text = "";
				TextScaled = true;
				TextColor3 = (self.state.IsComplete) and self.state.CompleteTextColor or ((self.state.ErrorText == "") and self.state.NormalTextColor or self.state.ErrorTextColor);
				TextXAlignment = Enum.TextXAlignment.Left;
				Font = Enum.Font.Code;
	
				[Roact.Event.Changed] = function(TextBox: TextBox, Property: string)
					if not (Property == "Text") then return end
	
					if (TextBox.Text:sub(TextBox.CursorPosition - 1, TextBox.CursorPosition) == "\t") then
						local Args = self:SplitMessage(TextBox.Text)
						local CurrentArg = Args[#Args]
						local RemovedTab = TextBox.Text:gsub("\t", "")
						local Error, Suggestion, Whitespace, IsComplete, Suggestions, AvailableArguments = self:GetAutoComplete(RemovedTab)
						
						TextBox.Text = RemovedTab

						if not (Suggestions) then return end

						local AutoComplete = Suggestions[self.SuggestionsIndex]
						if not (AutoComplete) then return end

						-- print(AvailableArguments)

						local SpaceEnd = ""-- (Count(NextArguments) > 0) and " " or ""
						local Cutout = TextBox.Text:sub(0, #TextBox.Text:split("") - #CurrentArg:split("") + 1)

						AutoComplete = if (#AutoComplete:split(" ") > 1) then ("\"%s\""):format(AutoComplete) else AutoComplete

						TextBox.Text = Cutout..AutoComplete..SpaceEnd
						TextBox.CursorPosition = #TextBox.Text:split("") + 1
					end

					local Error, AutoComplete, Whitespace, IsComplete, Suggestions, AvailableArguments, ArgumentTypeText: string = self:GetAutoComplete(TextBox.Text)
					self:setState{
						AutoCompleteText = (" "):rep(Whitespace or 0)..(AutoComplete or "");
						AutoCompleteFound = (AutoComplete ~= nil);

						ErrorText = Error or "";
						IsComplete = (IsComplete == true);

						CurrentText = TextBox.Text;

						ArgumentDescription = ArgumentTypeText or "";
					}
					self.api:start{
						ArgumentDescriptionPosition = self:GetArgumentDescriptionPosition(TextBox);

						immediate = true;
					}
				end;
				[Roact.Event.Focused] = function()
					self:setState{Focused = true}
				end;
				[Roact.Event.FocusLost] = function(Rbx: TextBox, EnterPressed: boolean)
					self:setState{Focused = false}

					if not (EnterPressed) then return end

					local Command = self:GetCurrentCommand(Rbx.Text)
					if not (Command) then return end

					RemotesFolder:WaitForChild("Execute"):FireServer(Command.Name, self.state.CurrentText)

					Rbx.Text = ""
				end
			});
			AutoComplete = e("TextLabel",{
				Size = UDim2.fromScale(.98,1);
	
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
				-- TextScaled = true;
				TextColor3 = Color3.fromRGB(255,0,0);
				TextXAlignment = Enum.TextXAlignment.Center;
				TextYAlignment = Enum.TextYAlignment.Center;
				Font = Enum.Font.Code;

				LayoutOrder = 1;
	
				ZIndex = 0;
	
				Visible = (self.state.ErrorText ~= "");
			});
		});
		ArgumentDescription = e("Frame",{
			Size = UDim2.fromScale(0,.7);
			AutomaticSize = Enum.AutomaticSize.XY;

			Position = self.style.ArgumentDescriptionPosition;
			AnchorPoint = if (self.state.IsTop) then Vector2.new(.5,0) else Vector2.new(.5,1);

			BorderSizePixel = 0;
			BackgroundTransparency = .25;
			BackgroundColor3 = Color3.fromRGB();

			ZIndex = 0;

			Visible = (self.state.Focused) and (self.state.ArgumentDescription ~= "") and (self.state.ErrorText == "");

			[Roact.Ref] = self.ArgumentDescriptionRef;
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
	
				Text = self.state.ArgumentDescription;
				TextSize = 20;
				-- TextScaled = true;
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

			-- Position = UDim2.fromOffset(0,-2);
			-- AnchorPoint = self.style.BarExtraAnchorPoint;

			BackgroundTransparency = 1;

			ZIndex = 0;

			Visible = (function()
				local Suggestions = self:GetSuggestionComponents(true) or {}
				return (self.state.Focused) and (#Suggestions > 0);
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
	});
end

return Component