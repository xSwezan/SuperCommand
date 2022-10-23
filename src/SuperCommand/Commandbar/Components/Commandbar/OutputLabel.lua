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

		LayoutOrder = self.props.LayoutOrder;
	},{
		e("UIPadding",{
			PaddingTop = UDim.new(0,5);
			PaddingBottom = UDim.new(0,5);
			PaddingRight = UDim.new(0,5);
			PaddingLeft = UDim.new(0,5);
		});
		Content = e("TextLabel",{
			Size = UDim2.fromScale(1,0);
			AutomaticSize = Enum.AutomaticSize.Y;

			Position = UDim2.fromScale(.5,.5);
			AnchorPoint = Vector2.new(.5,.5);

			BackgroundTransparency = 1;

			Text = ("<font color='rgb(0,170,255)' weight='extrabold'>></font> %s"):format(self.props.Text or "");
			RichText = true;
			TextSize = 20;
			TextColor3 = Color3.fromRGB(200,200,200);
			TextXAlignment = Enum.TextXAlignment.Left;
			Font = Enum.Font.Code;
		});
	});
end

return Component