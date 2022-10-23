local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.SuperCommand.Roact)
local RoactSpring = require(ReplicatedStorage.SuperCommand["Roact-spring"])
local RoactRodux = require(ReplicatedStorage.SuperCommand.RoactRodux)

local Actions = require(ReplicatedStorage.SuperCommand.Actions)

local e = Roact.createElement

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local Component = Roact.Component:extend(script.Name)

function Component:init()
	self.style, self.api = RoactSpring.Controller.new{

	}
end

function Component:render()
	return e("Frame",{
		Size = UDim2.fromScale(1,1);

		Position = UDim2.fromScale(.5,.5);
		AnchorPoint = Vector2.new(.5,.5);

		BackgroundTransparency = 1;

		[Roact.Event.MouseEnter] = function()
			self.ShowTooltipThread = task.delay(.75,function()
				self.props.SetVariable("TooltipPosition", UDim2.fromOffset(Mouse.X, Mouse.Y))
				self.props.SetVariable("TooltipText", self.props.Text or "nil")
				self.props.SetVariable("TooltipVisible", true)
			end)
		end;
		[Roact.Event.MouseLeave] = function()
			if (self.ShowTooltipThread) then
				task.cancel(self.ShowTooltipThread)
			end
			self.props.SetVariable("TooltipVisible", false)
		end;
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