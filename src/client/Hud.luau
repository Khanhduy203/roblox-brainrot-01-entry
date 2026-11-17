-- Brainrot Isles: the HUD.
-- One job: the whole ScreenGui over the 3D world — cash and income on top,
-- base lock, rebirth and slot buttons on the side, the wave banner, what
-- you are carrying, and how to play. It never decides anything: every
-- button asks the server, and every number comes from the server's tick.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Net = require(ReplicatedStorage.Shared.Net)

local Hud = {}

local gui = nil
local cashLabel = nil
local incomeLabel = nil
local rebirthLabel = nil
local lockButton = nil
local rebirthButton = nil
local slotButton = nil
local banner = nil
local bannerUntil = 0
local carryLabel = nil

local function makeButton(name, text, position, size)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
	button.BackgroundTransparency = 0.15
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.TextSize = 16
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Text = text
	button.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button
	return button
end

local function makeTopLabel(name, position, width)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.new(0, width, 0, 44)
	label.Position = position
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 20
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.2
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.Parent = gui
	return label
end

function Hud.build(player, requestFn)
	local playerGui = player:WaitForChild("PlayerGui")
	gui = Instance.new("ScreenGui")
	gui.Name = "BrainrotHud"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 1
	gui.Parent = playerGui

	-- Cash bar, top center: clear of the top-left corner where Roblox
	-- puts its own menu buttons.
	local bar = Instance.new("Frame")
	bar.Name = "TopBar"
	bar.Size = UDim2.new(0, 560, 0, 54)
	bar.Position = UDim2.new(0.5, -280, 0, 8)
	bar.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
	bar.BackgroundTransparency = 0.15
	bar.BorderSizePixel = 0
	bar.Parent = gui
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 10)
	barCorner.Parent = bar

	-- Positions below are relative to the bar, not the screen.
	cashLabel = makeTopLabel("CashLabel", UDim2.new(0, 12, 0, 5), 220)
	cashLabel.Text = GameConfig.formatCash(GameConfig.START_CASH)
	cashLabel.TextXAlignment = Enum.TextXAlignment.Left
	cashLabel.Parent = bar
	incomeLabel = makeTopLabel("IncomeLabel", UDim2.new(0, 220, 0, 5), 160)
	incomeLabel.Text = "+$0/s"
	incomeLabel.TextColor3 = Color3.fromRGB(120, 255, 140)
	incomeLabel.Parent = bar
	rebirthLabel = makeTopLabel("RebirthLabel", UDim2.new(0, 380, 0, 5), 168)
	rebirthLabel.Text = "Rebirths: 0  x1"
	rebirthLabel.TextColor3 = Color3.fromRGB(255, 220, 90)
	rebirthLabel.TextXAlignment = Enum.TextXAlignment.Right
	rebirthLabel.Parent = bar

	-- Side buttons, right edge.
	lockButton = makeButton("LockButton", "Lock Base (45s)", UDim2.new(1, -200, 0, 80), UDim2.new(0, 180, 0, 48))
	rebirthButton = makeButton("RebirthButton", "Rebirth", UDim2.new(1, -200, 0, 136), UDim2.new(0, 180, 0, 48))
	slotButton = makeButton("SlotButton", "Buy Slot", UDim2.new(1, -200, 0, 192), UDim2.new(0, 180, 0, 48))

	lockButton.MouseButton1Click:Connect(function()
		requestFn(Net.REQUEST_LOCK)
	end)
	rebirthButton.MouseButton1Click:Connect(function()
		requestFn(Net.REQUEST_REBIRTH)
	end)
	slotButton.MouseButton1Click:Connect(function()
		requestFn(Net.REQUEST_BUY_SLOT)
	end)

	-- Wave banner and toasts, center under the cash bar.
	banner = Instance.new("TextLabel")
	banner.Name = "Banner"
	banner.Size = UDim2.new(0, 560, 0, 40)
	banner.Position = UDim2.new(0.5, -280, 0, 70)
	banner.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
	banner.BackgroundTransparency = 0.25
	banner.BorderSizePixel = 0
	banner.Font = Enum.Font.GothamBold
	banner.TextSize = 18
	banner.TextColor3 = Color3.fromRGB(255, 255, 255)
	banner.TextStrokeTransparency = 0.2
	banner.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	banner.Visible = false
	banner.Parent = gui

	-- What you are carrying, bottom center.
	carryLabel = Instance.new("TextLabel")
	carryLabel.Name = "CarryLabel"
	carryLabel.Size = UDim2.new(0, 560, 0, 36)
	carryLabel.Position = UDim2.new(0.5, -280, 1, -88)
	carryLabel.BackgroundTransparency = 1
	carryLabel.Font = Enum.Font.GothamBold
	carryLabel.TextSize = 18
	carryLabel.TextColor3 = Color3.fromRGB(255, 220, 90)
	carryLabel.TextStrokeTransparency = 0.2
	carryLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	carryLabel.Text = ""
	carryLabel.Parent = gui

	-- How to play, bottom left.
	local help = Instance.new("TextLabel")
	help.Name = "HelpLabel"
	help.Size = UDim2.new(0, 420, 0, 72)
	help.Position = UDim2.new(0, 12, 1, -84)
	help.BackgroundTransparency = 1
	help.Font = Enum.Font.Gotham
	help.TextSize = 14
	help.TextColor3 = Color3.fromRGB(230, 230, 230)
	help.TextStrokeTransparency = 0.3
	help.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	help.TextXAlignment = Enum.TextXAlignment.Left
	help.TextYAlignment = Enum.TextYAlignment.Top
	help.Text = "Buy brainrots off the belt, they earn on your base.\nTake your own to sell it, a stranger's to steal it.\nLock your base (L), rebirth (R), and run home when the wave comes."
	help.Parent = gui

	task.spawn(function()
		while gui.Parent ~= nil do
			task.wait(0.5)
			if banner.Visible and os.clock() > bannerUntil then
				banner.Visible = false
			end
		end
	end)
end

function Hud.setState(state)
	if cashLabel == nil then
		return
	end
	cashLabel.Text = GameConfig.formatCash(state.Cash)
	incomeLabel.Text = "+" .. GameConfig.formatCash(state.IncomePerSec) .. "/s"
	rebirthLabel.Text = "Rebirths: " .. tostring(state.Rebirths) .. "  x" .. tostring(state.Multiplier)
	if state.LockLeft > 0 then
		lockButton.Text = "Locked (" .. tostring(state.LockLeft) .. "s)"
	elseif state.LockCooldownLeft > 0 then
		lockButton.Text = "Lock ready in " .. tostring(state.LockCooldownLeft) .. "s"
	else
		lockButton.Text = "Lock Base (45s)"
	end
	local rebirthCost = GameConfig.REBIRTH_BASE * math.pow(2, state.Rebirths)
	if state.Rebirths >= GameConfig.REBIRTH_MAX then
		rebirthButton.Text = "Max rebirths"
	else
		rebirthButton.Text = "Rebirth — " .. GameConfig.formatCash(rebirthCost)
	end
	if state.OwnedSlots >= GameConfig.MAX_SLOTS then
		slotButton.Text = "All slots owned"
	else
		local priceIndex = state.OwnedSlots - GameConfig.START_SLOTS + 1
		local price = GameConfig.SLOT_PRICES[priceIndex]
		if price ~= nil then
			slotButton.Text = "Buy Slot — " .. GameConfig.formatCash(price)
		end
	end
end

function Hud.showBanner(text, seconds)
	if banner == nil then
		return
	end
	banner.Text = text
	banner.Visible = true
	bannerUntil = os.clock() + seconds
end

function Hud.setCarry(displayName)
	if carryLabel == nil then
		return
	end
	if displayName == nil or displayName == "" then
		carryLabel.Text = ""
	else
		carryLabel.Text = "Carrying: " .. displayName .. " — bring it home!"
	end
end

return Hud
