local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Roact = require(ReplicatedStorage.SuperCommand.Roact)
local RoactRodux = require(ReplicatedStorage.SuperCommand.RoactRodux)
local RoactSpring = require(ReplicatedStorage.SuperCommand["Roact-spring"])
local Actions = require(ReplicatedStorage.SuperCommand.Actions)
local Types = require(script.Parent.Types)

local Player = Players.LocalPlayer

local e = Roact.createElement

local Component = Roact.Component:extend(script.Name)

local SuperCommand = ReplicatedStorage:WaitForChild("SuperCommand")
local RemotesFolder = SuperCommand:WaitForChild("Remotes")
local CommandsFolder = SuperCommand:WaitForChild("Commands")
local OperatorsFolder = SuperCommand:WaitForChild("Operators")
local TypesFolder = SuperCommand:WaitForChild("Types")

local function ReplaceMagicCharacters(Str: string, Replacement: string): string
	return Str:gsub("([%$%%%^%*%(%)%.%[%]%+%-%?])", Replacement)
end

function Component:init()
	self.Ref = Roact.createRef()

	UserInputService.InputBegan:Connect(function(InputObject: InputObject, GP: boolean)
		local Input: TextBox = self.Ref.current
		if not (Input) then return end
		if not (Input:IsFocused()) then return end

		if (InputObject.KeyCode == Enum.KeyCode.Left) then
			if (self.LastCursorPosition == Input.CursorPosition) and (Input.CursorPosition == 1) then
				self.props.SetCurrentArgumentVariable("Index", math.clamp(self.props.Index - 1, 1, 100))
			end
			self.LastCursorPosition = Input.CursorPosition
		elseif (InputObject.KeyCode == Enum.KeyCode.Right) then
			if (self.LastCursorPosition == Input.CursorPosition) and (Input.CursorPosition == (#Input.Text + 1)) then
				self.props.SetCurrentArgumentVariable("Index", math.clamp(self.props.Index + 1, 1, 100))
			end
			self.LastCursorPosition = Input.CursorPosition
		end
	end)

	self.style, self.api = RoactSpring.Controller.new{
		BackgroundColor3 = Color3.fromRGB(46,49,62);

		config = {
			tension = 4000;
			friction = 200;
		};
	}
end

function Component:didUpdate(lastProps, lastState)
	if (lastProps.CurrentArgument.Index ~= self.props.CurrentArgument.Index) then
		if (self.props.CurrentArgument.Index == self.props.Index) then
			local Input: TextBox = self.Ref.current
			Input:CaptureFocus()
		else
			self.api:start{
				BackgroundColor3 = Color3.fromRGB(46,49,62);
			}
		end
	end
end

function Component:render()
	return e("TextBox",{
		Size = UDim2.fromScale(.01,1);
		AutomaticSize = Enum.AutomaticSize.X;

		BackgroundColor3 = self.style.BackgroundColor3;
		BorderSizePixel = 0;

		Text = "";
		TextColor3 = Color3.fromRGB(255,255,255);
		PlaceholderText = self.props.Type;
		PlaceholderColor3 = Color3.fromRGB(80,86,108);
		FontFace = Font.new(
			"rbxasset://fonts/families/Inconsolata.json",
			Enum.FontWeight.Regular,
			Enum.FontStyle.Normal
		);
		TextScaled = true;
		ClearTextOnFocus = false;
		TextWrapped = true;
		TextXAlignment = Enum.TextXAlignment.Left;

		LayoutOrder = self.props.Index;

		[Roact.Ref] = self.Ref;

		[Roact.Event.Focused] = function(Rbx: TextBox)
			self.props.SetCurrentArgumentVariable("Index", (self.props.Index or 1))

			self.api:start{
				BackgroundColor3 = Color3.fromRGB(41, 43, 55);
			}
		end;

		[Roact.Event.FocusLost] = function(Rbx: TextBox, EnterPressed: boolean)
			self.api:start{
				BackgroundColor3 = Color3.fromRGB(46,49,62);
			}

			if not (EnterPressed) then return end
				
			self.props.SetCurrentArgumentVariable("Index", (self.props.Index or 0) + 1)
		end;

		[Roact.Change.Text] = function(Input: TextBox)
			local BeforeRemovedTab: string = Input.Text
			local RemovedTab: string = Input.Text:gsub("\t", "")

			local Error: string?, Suggestions: {string} = self:GetAutoComplete(RemovedTab)
			local AutoComplete: string = (Suggestions or {})[1] or ""

			self.props.SetCurrentArgumentVariable("AutoComplete", AutoComplete)
			
			if (string.find(Input.Text, "\t$")) then
				Input.Text = AutoComplete

				-- Set Cursor to end
				Input.CursorPosition = (#AutoComplete + 1)
			end
		end;

		-- [Roact.Change.CursorPosition] = function(Input: TextBox)
		-- 	self.LastCursorPosition = Input.CursorPosition
		-- end;
	},{
		e(require(script.Parent.UICorner));
		e("UIPadding",{
			PaddingTop = UDim.new(0,0);
			PaddingBottom = UDim.new(0,0);
			PaddingRight = UDim.new(0,5);
			PaddingLeft = UDim.new(0,5);
		});
		AutoComplete = e("TextLabel",{
			Size = UDim2.fromScale(0,1);
			AutomaticSize = Enum.AutomaticSize.X;

			Position = UDim2.fromScale(0,0);
			AnchorPoint = Vector2.new(0,0);

			BackgroundTransparency = 1;

			Text = (function()
				if (self.props.CurrentArgument.Index ~= self.props.Index) then return end

				local Input: TextBox = self.Ref.current
				if not (Input) then return end

				local Text: string = Input.Text
				local AutoComplete: string = self.props.CurrentArgument.AutoComplete or ""

				return AutoComplete:gsub(".", " ", #Text)
			end)() or "";
			TextScaled = true;
			TextColor3 = Color3.fromRGB(80,86,108);
			TextXAlignment = Enum.TextXAlignment.Left;
			Font = Enum.Font.Code;

			ZIndex = 0;

			Visible = (self.props.CurrentArgument.Index == self.props.Index);
		});
	});
end

function Component:GetCommands(): {Types.Command}
	local Commands = {}
	for _, Command in pairs(CommandsFolder:GetChildren()) do
		local Sorted: {Types.CommandArgument} = {}

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

function Component:GetCommand(CommandName: string): Types.Command?
	if not (CommandName) then return end

	local Commands = self:GetCommands()
	for _, Command: Types.Command in Commands do
		if (string.lower(Command.Name) ~= string.lower(CommandName)) then continue end

		return Command
	end
end

function Component:GetSuggestionsFor(Table: {string}, String: string): {string}
	local Suggestions: {string} = {}

	for _, Argument in ipairs(Table or {}) do
		if not (Argument:lower():match("^"..ReplaceMagicCharacters(String:lower(), "%%%1"))) then continue end

		table.insert(Suggestions, Argument)
	end

	return Suggestions
end

-- (Text: string): (Error: string?, AutoComplete: string?)
function Component:GetAutoComplete(Text: string): (string?, string?)
	-- Get the CommandName
	local CommandName: string = if (self.props.Index == 1) then Text else self.props.CurrentArgument.CommandName or ""

	-- Get the Command
	local Command: Types.Command = self:GetCommand(CommandName)
	if (Command) then
		self.props.SetCurrentArgumentVariable("CommandName", CommandName)
	end
	self.props.SetCurrentArgumentVariable("Command", Command)

	-- Get the Command Arguments
	local CommandArguments: {Types.CommandArgument} = (if (Command) then Command.Arguments else self:GetCommands()) or {}

	-- Get the current Argument (The focused argument)
	local CurrentArgument: Types.CommandArgument = CommandArguments[math.clamp(self.props.Index - 1, 1, 100)] or {}

	-- Get the Type of the Argument
	local TypeModule: ModuleScript = TypesFolder:FindFirstChild(CurrentArgument.Type or "")
	local Type: Types.Type = if (TypeModule) then require(TypeModule) else nil
	
	-- Do Type.Get() to get Suggestions
	local Suggestions: {string} = if (Type) and (type(Type.Get) == "function") then
		Type.Get(Player, Text)
	elseif (self.props.Index == 1) then (function()
		local Suggestions = {}

		for _, Command: Types.Command in pairs(CommandArguments) do
			table.insert(Suggestions, Command.Name)
		end

		return Suggestions
	end)()
	else {}

	-- Get AutoComplete Suggestions
	local AutoCompleteSuggestions = self:GetSuggestionsFor(Suggestions, Text)

	return nil, AutoCompleteSuggestions
end

function Component:GetAutoComplete2()
	-- local Text = self:GetPortion(self:ConvertOperators(Text))
	local Text = self.props.CurrentArgument.Text

	local CurrentArguments = self.props.Arguments--self:SplitString(Text, true)
	local CurrentString = CurrentArguments[#CurrentArguments]
	
	-- local Whitespace = #string.sub(Text, 0, #Text:split("") - #CurrentString:split("")):split("")
	local Whitespace = 0

	-- local CurrentCommand = self:GetCurrentCommand(Text)
	local CurrentCommand = if (self.props.Index == 1) then Text else (self.props.Arguments or {})[1] or ""

	-- Start at the bottom (the available commands)
	local ArgumentsNeeded = self:GetCommands()

	if (#CurrentArguments > 1) then
		if not (CurrentCommand) then return ("Didn't find a command with the name '%s'!"):format(CurrentArguments[1]) end

		-- If command is already written, then take the arguments instead
		ArgumentsNeeded = CurrentCommand.Arguments
	end

	local CurrentArgumentNeeded = ArgumentsNeeded[math.clamp(#CurrentArguments - 1, 1, math.huge)]
	if not (CurrentArgumentNeeded) then return ("No argument found with Index #%d"):format(#CurrentArguments) end

	local ArgumentName = tostring(CurrentArgumentNeeded.Name)
	local ArgumentType = tostring(CurrentArgumentNeeded.Type)

	self.props.SetVariable("CurrentType", ArgumentType)

	local ArgumentTypeText: string = if (ArgumentName == ArgumentType) then ArgumentName elseif (ArgumentType == "nil") then "" else ("<font color='rgb(0,170,255)'>%s:</font> %s"):format(ArgumentName, ArgumentType)

	-- Loop through all arguments and check for errors

	-- for Index = 1, #CurrentArguments do
	-- 	local StringArgument = CurrentArguments[Index]
	-- 	local Argument = ArgumentsNeeded[Index - 1]

	-- 	if (typeof(StringArgument) ~= "string") then continue end
	-- 	if not (Argument) then continue end
	-- 	if (StringArgument == "") then continue end

	-- 	local Type = self:GetType(Argument.Type)
	-- 	if not (Type) then continue end
	-- 	if (typeof(Type.Convert) ~= "function") then continue end
	-- 	if (Type.Convert(Player, StringArgument) ~= nil) then continue end

	-- 	-- Argument should error, but lets check for mistakes

	-- 	local CanError = true

	-- 	-- Has suggestions?
	-- 	if (typeof(Type.Get) == "function") and (typeof(Type.Get) == "function") and (#self:GetSuggestionsFor(Type.Get(Player, CurrentString), StringArgument) > 0) then
	-- 		CanError = false
	-- 	end

	-- 	if not (CanError) then continue end

	-- 	return ("'%s' is not a valid '%s' in Argument #%d!"):format(StringArgument, Argument.Type, Index)
	-- end

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
				if not (String:lower():match("^"..ReplaceMagicCharacters(CurrentString:lower(), "%%%1"))) then continue end

				DidFind = true
				break
			end
			if not (DidFind) then
				return ("'%s' is not a valid type '%s'"):format(CurrentString, ArgumentType)
			end
		end
	end

	local Suggestions = self:GetSuggestionsFor(List or {}, CurrentString)
	table.sort(Suggestions)

	if ((List and #List > 0 and #Suggestions > 0) or (SuggestionText))
		or
		((Type) and (typeof(Type.Convert) == "function") and ((Type.Convert(Player, CurrentString) or nil) ~= nil)) -- Argument Typechecking: Argument is correct type
		or
		(CurrentString == "") -- Player hasn't started writing the argument yet
	then
		-- No error
		self.props.SetVariable("SuggestionIndex", math.clamp(self.props.Variables.SuggestionIndex, 1, math.clamp(#Suggestions, 1, math.huge)))
		return nil, (SuggestionText or Suggestions[self.props.Variables.SuggestionIndex]), Whitespace, false, Suggestions, ArgumentsNeeded, ArgumentTypeText
	end

	return ("Invalid argument #%s '%s' in '%s'"):format(#CurrentArguments, CurrentString, (CurrentCommand ~= nil) and CurrentCommand.Name or "Commands")
end

return RoactRodux.connect(
	function(State, Props)
		return {
			Variables = State.Variables;
			CurrentArgument = State.CurrentArgument;
		}
	end,
	function(Dispatch)
		return {
			SetVariable = function(Name: string, Value: any)
				Dispatch(Actions.SetVariable(Name, Value))
			end;
			SetArgument = function(Index: number, Value: any)
				Dispatch(Actions.SetArgument(Index, Value))
			end;
			SetCurrentArgumentVariable = function(Name: string, Value: any)
				Dispatch(Actions.SetCurrentArgumentVariable(Name, Value))
			end;
		}
	end
)(Component)