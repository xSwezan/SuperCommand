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

local CommandsFolder = SuperCommand:WaitForChild("Commands", 10)
if not (CommandsFolder) then return {} end

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

function Component:SplitMessage(Message: string): {string}
	local Format = "(%b\"\")"
	local ReplacementFormat = "|\"|\"|"
	local SpaceReplacement = "?|?"

	local Formatted = Message:gsub(Format, ReplacementFormat):gsub(" ", SpaceReplacement)
	
	for Replacement: string in Message:gmatch(Format) do
		Formatted = Formatted:gsub(ReplacementFormat, Replacement:gsub("\"", ""), 1)
	end

	return Formatted:split(SpaceReplacement)
end

local function Count(Table: {})
	local Length = 0
	table.foreach(Table or {}, function()
		Length += 1
	end)
	return Length
end

function Component:GetCurrentCommand(Text)
	local CurrentArguments = self:SplitMessage(Text)
	local CommandName = CurrentArguments[1]

	local Commands = self:GetCommands()
	
	for _, Command in pairs(Commands) do
		if (Command.Name == CommandName) then
			return Command
		end
	end
end

function Component:MatchesOneInList(String: string, List: {string}): boolean | nil
	if not (String) then return end
	for _, Argument in pairs(List or {}) do
		if (Argument:match("^"..String)) then
			return true
		end
	end
	return false
end

function Component:GetSuggestionsFor(Table: {}, String: string)
	local Suggestions = {}
	for _, Argument in pairs(Table or {}) do
		if (Argument:match("^"..String)) then
			table.insert(Suggestions, Argument)
		end
	end
	return Suggestions
end

function Component:IsSuggestion()
	
end

function Component:GetAutoComplete(Text)
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

	for Index = 1, #CurrentArguments do
		local StringArgument = CurrentArguments[Index]
		local Argument = ArgumentsNeeded[Index - 1]

		if (StringArgument) and (Argument) and (StringArgument ~= "") then
			local TypeModule = TypesFolder:FindFirstChild(Argument.Type)
			if (TypeModule) and (TypeModule:IsA("ModuleScript")) then
				local Type = require(TypeModule)
				if (Type) and (typeof(Type.Convert) == "function") and (Type.Convert(StringArgument) == nil) then
					local CanError = true
					if (typeof(Type.Get) == "function") and (typeof(Type.Get) == "function") then
						if (#self:GetSuggestionsFor(Type.Get(), StringArgument) > 0) then
							CanError = false
						end
					end
					if (CanError) then
						return ("Expected type '%s' in Argument #%d!"):format(Argument.Type, Index)
					end
				end
			end
		end
	end

	local Suggestions = {}
	local List
	local SuggestionText

	local TypeModule: ModuleScript = ReplicatedStorage.SuperCommand:WaitForChild("Types"):FindFirstChild(CurrentArgumentNeeded.Type or "")
	local Type: {}? = if (TypeModule) then require(TypeModule) else nil

	if (#ArgumentsNeeded == 0) then
		return nil, "", 0
	elseif (#CurrentArguments == 1) then
		List = {}
		for _, Command in pairs(ArgumentsNeeded) do
			table.insert(List, Command.Name)
		end
	elseif (#ArgumentsNeeded > 0) then
		if (TypeModule) and (Type) and (typeof(Type.Get) == "function") then
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
			SuggestionText = if (CurrentString == "") then
				(if (CurrentArgumentNeeded.Name == CurrentArgumentNeeded.Type) then
					CurrentArgumentNeeded.Type
				else
					("%s: %s"):format(CurrentArgumentNeeded.Name, CurrentArgumentNeeded.Type))
			else
				SuggestionText
		end
	end

	for _, Argument in pairs(List or {}) do
		if (Argument:match("^"..CurrentString)) then
			table.insert(Suggestions, Argument)
		end
	end

	-- Check if Argument is correct then return true
	-- print("\n\n\n")
	-- print(CurrentArgumentNeeded)
	-- print(CurrentString)
	-- print(Type)
	-- if (Type) and (typeof(Type.Convert) == "function") and (typeof(Type.Convert(CurrentString)) == CurrentArgumentNeeded.Type) then
	-- 	return nil
	-- end
	
	if
		((List and #List > 0 and #Suggestions > 0) or (SuggestionText))
		or
		((Type) and (typeof(Type.Convert) == "function") and (typeof(Type.Convert(CurrentString)) == CurrentArgumentNeeded.Type)) -- Argument is correct type
	then
		-- No error
		self.SuggestionsIndex = math.clamp(self.SuggestionsIndex, 1, math.clamp(#Suggestions, 1, math.huge))
		return nil, SuggestionText or Suggestions[self.SuggestionsIndex], Whitespace, false, Suggestions, ArgumentsNeeded
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

	for Index, Info in pairs(SyntaxHighlighting_Patterns) do
		local FinalString = ""
		local LastEnd = 0
		for _, Pattern in pairs(Info.Patterns) do
			string.gsub(Text, Pattern, function(String)
				local Start, End = string.find(Text, String, LastEnd)
				local Whitespace = (Start - LastEnd - 1)
				LastEnd = End
				FinalString = FinalString..(" "):rep(Whitespace)..String
	
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

			ZIndex = 100 + Index;
		});
	end

	return Roact.createFragment(Props)
end

function Component:GetSuggestionComponents()
	local _, CurrentAutoComplete, _, _, Suggestions = self:GetAutoComplete(self.state.CurrentText)
	if not (Suggestions) then return end

	local Props = {}

	for Index, SuggestionText in pairs(Suggestions) do
		Props[SuggestionText] = e("Frame",{
			Size = UDim2.fromScale(1,1);

			BorderSizePixel = 0;
			BackgroundTransparency = .25;
			BackgroundColor3 = (CurrentAutoComplete == SuggestionText) and Color3.fromRGB(50,50,50) or Color3.fromRGB();

			LayoutOrder = Index;
		},{
			e("TextLabel",{
				Size = UDim2.fromScale(1,.7);

				Position = UDim2.fromScale(.5,.5);
				AnchorPoint = Vector2.new(.5,.5);

				BackgroundTransparency = 1;

				Text = (" %s "):format(SuggestionText);
				TextScaled = true;
				TextColor3 = Color3.fromRGB(255,255,255);
				TextXAlignment = Enum.TextXAlignment.Left;
				Font = Enum.Font.Code;
			});
		});
	end

	return Roact.createFragment(Props)
end

function Component:init()
	self:setState{
		HoldingOnBar = false;

		AutoCompleteText = "";
		AutoCompleteFound = false;

		ErrorText = "";

		ArgumentDescriptionPosition = 0;
		ArgumentDescription = "";

		NormalTextColor = Color3.fromRGB(255,255,255);
		ErrorTextColor = Color3.fromRGB(255,0,0);
		CompleteTextColor = Color3.fromRGB(0,255,0);

		CurrentText = "";
	}

	self.SuggestionsIndex = 1
	self.LastDeepIndex = 0

	self.BarTopPosition = UDim2.fromScale(.5,.05)
	self.BarBottomPosition = UDim2.fromScale(.5,.95)

	UserInputService.InputBegan:Connect(function(Input, GP)
		if not (GP) then return end
		if (Input.KeyCode == Enum.KeyCode.Up) or (Input.KeyCode == Enum.KeyCode.Down) then
			local ToAdd = (Input.KeyCode == Enum.KeyCode.Up) and -1 or 1
			self.SuggestionsIndex = math.clamp(self.SuggestionsIndex + ToAdd, 1, math.huge)

			local _, AutoComplete, Whitespace = self:GetAutoComplete(self.state.CurrentText)
			self:setState{
				AutoCompleteText = (" "):rep(Whitespace or 0)..(AutoComplete or "");
			}
		end
	end)

	self.style, self.api = RoactSpring.Controller.new{
		BarPosition = self.BarBottomPosition;
		BarExtraAnchorPoint = Vector2.new(0,1);

		config = {
			tension = 2000;
			friction = 70;
		}
	}
end

function Component:render()
	return e("Frame",{
		Size = UDim2.fromScale(.95,.05);

		Position = self.style.BarPosition;
		AnchorPoint = Vector2.new(.5,.5);

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
					BarPosition = (IsOnTop == true) and self.BarTopPosition or self.BarBottomPosition;
				}
			end
		end;
		[Roact.Event.InputEnded] = function(_, Input, GP)
			if (GP) then return end
			if not (Input.UserInputType == Enum.UserInputType.MouseButton1) then return end

			self:setState{HoldingOnBar = false}
		end;
	},{
		Inside = e("Frame",{
			Size = UDim2.fromScale(1,1);

			Position = UDim2.fromScale(.5,.5);
			AnchorPoint = Vector2.new(.5,.5);

			BackgroundTransparency = 1;
		},{
			e("UIPadding",{
				PaddingTop = UDim.new(.2,0);
				PaddingBottom = UDim.new(.2,0);
				PaddingRight = UDim.new(.006,0);
				PaddingLeft = UDim.new(.006,0);
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

						local AutoComplete = Suggestions[self.SuggestionsIndex]
						if not (AutoComplete) then return end

						if (typeof(AvailableArguments) == "function") then
							AvailableArguments = AvailableArguments()
						end

						local NextArguments = AvailableArguments[AutoComplete]
						if (typeof(NextArguments) == "function") then
							NextArguments = NextArguments()
						end

						local SpaceEnd = (Count(NextArguments) > 0) and " " or ""

						if (#AutoComplete:split(" ") > 1) then
							AutoComplete = ("\"%s\""):format(AutoComplete)
						end

						local Cutout = TextBox.Text:sub(0, #TextBox.Text:split("") - #CurrentArg:split("") + 1)
	
						TextBox.Text = Cutout..AutoComplete..SpaceEnd
						TextBox.CursorPosition = #TextBox.Text:split("") + 1
					end
					local Error, AutoComplete, Whitespace, IsComplete = self:GetAutoComplete(TextBox.Text)
					self:setState{
						AutoCompleteText = (" "):rep(Whitespace or 0)..(AutoComplete or "");
						AutoCompleteFound = (AutoComplete ~= nil);

						ErrorText = Error or "";
						IsComplete = (IsComplete == true);

						CurrentText = TextBox.Text;

						ArgumentDescriptionPosition = (TextBox.TextBounds.X / TextBox.AbsoluteSize.X) * (TextBox.AbsoluteSize.X / TextBox.Parent.AbsoluteSize.X);
						ArgumentDescription = "yes";
					}
				end;
				[Roact.Event.FocusLost] = function(Rbx: TextBox, EnterPressed: boolean)
					if not (EnterPressed) then return end
					
					Rbx.Text = ""
				end
			},{

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
			Size = UDim2.fromScale(0,.8);
			AutomaticSize = Enum.AutomaticSize.X;

			Position = UDim2.fromScale(0,-.05);
			AnchorPoint = self.style.BarExtraAnchorPoint; --Vector2.new(0,1);

			BorderSizePixel = 0;
			BackgroundTransparency = .25;
			BackgroundColor3 = Color3.fromRGB();

			ZIndex = 0;

			Visible = (self.state.ErrorText ~= "");
		},{
			ErrorLabel = e("TextLabel",{
				Size = UDim2.fromScale(0,.55);
				AutomaticSize = Enum.AutomaticSize.X;
	
				Position = UDim2.fromScale(0,.5);
				AnchorPoint = Vector2.new(0,.5);
	
				BackgroundTransparency = 1;
	
				Text = (" %s "):format(self.state.ErrorText);
				TextScaled = true;
				TextColor3 = Color3.fromRGB(255,0,0);
				TextXAlignment = Enum.TextXAlignment.Left;
				Font = Enum.Font.Code;

				LayoutOrder = 1;
	
				ZIndex = 0;
	
				Visible = (self.state.ErrorText ~= "");
			});
		});
		ArgumentDescription = e("Frame",{
			Size = UDim2.fromScale(0,.8);
			AutomaticSize = Enum.AutomaticSize.X;

			Position = UDim2.fromScale(self.state.ArgumentDescriptionPosition,-.05);
			AnchorPoint = self.style.BarExtraAnchorPoint; --Vector2.new(0,1);

			BorderSizePixel = 0;
			BackgroundTransparency = .25;
			BackgroundColor3 = Color3.fromRGB();

			ZIndex = 0;

			Visible = (self.state.ArgumentDescription ~= "") and (self.state.ErrorText == "");
		},{
			ArgumentDescription = e("TextLabel",{
				Size = UDim2.fromScale(0,.55);
				AutomaticSize = Enum.AutomaticSize.X;
	
				Position = UDim2.fromScale(0,.5);
				AnchorPoint = Vector2.new(0,.5);
	
				BackgroundTransparency = 1;
	
				Text = (" %s "):format(self.state.ArgumentDescription);
				TextScaled = true;
				TextColor3 = Color3.fromRGB(255,0,0);
				TextXAlignment = Enum.TextXAlignment.Left;
				Font = Enum.Font.Code;

				LayoutOrder = 1;
	
				ZIndex = 0;
	
				Visible = (self.state.ArgumentDescription ~= "");
			});
		});
		Suggestions = e("Frame",{
			Size = UDim2.fromScale(.2,.7);

			Position = UDim2.fromScale(0,-.05);
			AnchorPoint = self.style.BarExtraAnchorPoint;

			BorderSizePixel = 0;
			BackgroundTransparency = 1;
			BackgroundColor3 = Color3.fromRGB();

			ZIndex = 0;

			Visible = true;
		},{
			e("UIListLayout",{
				VerticalAlignment = Enum.VerticalAlignment.Bottom;
				HorizontalAlignment = Enum.HorizontalAlignment.Left;

				SortOrder = Enum.SortOrder.LayoutOrder;
			});
			self:GetSuggestionComponents();
		});
	});
end

return Component