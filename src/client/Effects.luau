-- Brainrot Isles: client effects.
-- One job: the full-screen flashes that make the wave feel dangerous — a
-- red wash when the wave sweeps, an amber wash while it is warned. No game
-- decisions live here; the server tells it when to flash.

local Effects = {}

local flashFrame = nil

function Effects.build(player)
	local playerGui = player:WaitForChild("PlayerGui")
	local gui = Instance.new("ScreenGui")
	gui.Name = "BrainrotEffects"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 0
	gui.IgnoreGuiInset = true
	gui.Parent = playerGui

	flashFrame = Instance.new("Frame")
	flashFrame.Name = "Flash"
	flashFrame.Size = UDim2.new(1, 0, 1, 0)
	flashFrame.Position = UDim2.new(0, 0, 0, 0)
	flashFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	flashFrame.BackgroundTransparency = 1
	flashFrame.BorderSizePixel = 0
	flashFrame.Parent = gui
end

-- Fade a colored wash in and out over this many seconds.
function Effects.flash(color, seconds)
	if flashFrame == nil then
		return
	end
	flashFrame.BackgroundColor3 = color
	flashFrame.BackgroundTransparency = 0.45
	task.spawn(function()
		local steps = 20
		for i = 1, steps do
			task.wait(seconds / steps)
			if flashFrame.Parent == nil then
				return
			end
			flashFrame.BackgroundTransparency = 0.45 + (0.55 * i / steps)
		end
		flashFrame.BackgroundTransparency = 1
	end)
end

return Effects
