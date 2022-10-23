local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.SuperCommand.Roact)
local RoactSpring = require(ReplicatedStorage.SuperCommand["Roact-spring"])

local e = Roact.createElement

local Component = Roact.Component:extend(script.Name)

function Component:init()
	self.style, self.api = RoactSpring.Controller.new{

	}
end

function Component:render()
	return e("Frame",{
		Size = UDim2.fromScale(1,0);
		AutomaticSize = Enum.AutomaticSize.Y;

		BackgroundTransparency = 1;

		LayoutOrder = self.props.Index;
	},{
		e("UIPadding",{
			PaddingTop = UDim.new(0,0);
			PaddingBottom = UDim.new(0,0);
			PaddingRight = UDim.new(0,5);
			PaddingLeft = UDim.new(0,5);
		});
		Suggestion = e("TextLabel",{
			Size = UDim2.fromScale(1,0);
			AutomaticSize = Enum.AutomaticSize.Y;

			Position = UDim2.fromScale(.5,0);
			AnchorPoint = Vector2.new(.5,0);

			BackgroundTransparency = 1;

			Text = self.props.Text or "";
			TextSize = self.props.TextSize or 20;
			TextColor3 = self.props.TextColor3 or if (self.props.SelectedIndex == self.props.Index) then Color3.fromRGB(0, 170, 255) else Color3.fromRGB(255,255,255);
			TextXAlignment = Enum.TextXAlignment.Left;
			Font = Enum.Font.Code;
		});
	});
end

return Component