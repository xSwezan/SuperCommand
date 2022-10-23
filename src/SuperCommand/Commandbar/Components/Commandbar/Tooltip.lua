local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.SuperCommand.Roact)
local RoactSpring = require(ReplicatedStorage.SuperCommand["Roact-spring"])
local RoactRodux = require(ReplicatedStorage.SuperCommand.RoactRodux)

local Actions = require(ReplicatedStorage.SuperCommand.Actions)

local e = Roact.createElement

local Component = Roact.Component:extend(script.Name)

function Component:init()
	self.style, self.api = RoactSpring.Controller.new{

	}
end

function Component:render()
	return e("Frame",{
		Size = UDim2.fromScale(0,0);
		AutomaticSize = Enum.AutomaticSize.XY;

		Position = self.props.Variables.TooltipPosition;
		AnchorPoint = Vector2.new(0,1);

		BackgroundTransparency = .25;
		BackgroundColor3 = Color3.fromRGB();
		BorderSizePixel = 0;

		Visible = (self.props.Variables.TooltipVisible == true);
	},{
		e(require(script.Parent.UICorner));
		e("UIPadding",{
			PaddingTop = UDim.new(0,5);
			PaddingBottom = UDim.new(0,5);
			PaddingRight = UDim.new(0,5);
			PaddingLeft = UDim.new(0,5);
		});
		Label = e("TextLabel",{
			Size = UDim2.fromScale(0,0);
			AutomaticSize = Enum.AutomaticSize.XY;

			BackgroundTransparency = 1;

			Text = self.props.Variables.TooltipText;
			TextSize = 20;
			TextColor3 = Color3.fromRGB(255,255,255);
			Font = Enum.Font.Code;
		});
	});
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