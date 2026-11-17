-- Brainrot Isles: the world builder.
-- One job: finish the 3D world at runtime from the static parts Rojo laid
-- down (platforms, belt, trees) — slot pads on every plot, owner signs,
-- and the noodle wave that sweeps the map. The spawner and the economy
-- read the slot positions this module returns; nobody else places parts.

local Workspace = game:GetService("Workspace")

local GameConfig = require(game:GetService("ReplicatedStorage").Shared.GameConfig)

local WorldBuilder = {}

local SLOT_OFFSETS = {
	Vector3.new(-9, 0, -6),
	Vector3.new(-3, 0, -6),
	Vector3.new(3, 0, -6),
	Vector3.new(9, 0, -6),
	Vector3.new(-9, 0, 6),
	Vector3.new(-3, 0, 6),
	Vector3.new(3, 0, 6),
	Vector3.new(9, 0, 6),
}

local PAD_COLOR = Color3.fromRGB(90, 200, 120)

local function makePad(plotCenter, offset)
	local pad = Instance.new("Part")
	pad.Name = "SlotPad"
	pad.Size = Vector3.new(4, 0.4, 4)
	pad.Position = plotCenter + offset + Vector3.new(0, 0.7, 0)
	pad.Color = PAD_COLOR
	pad.Material = Enum.Material.Neon
	pad.Anchored = true
	pad.CanCollide = false
	pad.Parent = Workspace
	return pad
end

local function makeSign(post)
	local gui = Instance.new("BillboardGui")
	gui.Name = "PlotSign"
	gui.Size = UDim2.new(0, 220, 0, 56)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
	gui.AlwaysOnTop = false
	gui.Parent = post

	local label = Instance.new("TextLabel")
	label.Name = "OwnerLabel"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	label.BackgroundTransparency = 0.2
	label.Font = Enum.Font.GothamBold
	label.TextSize = 20
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.3
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.Text = "Empty plot"
	label.Parent = gui
	return label
end

-- Build the runtime pieces and return the world table the game plays on.
function WorldBuilder.buildWorld()
	local world = {}
	world.Plots = {}

	local plotsFolder = Workspace:WaitForChild("Plots")
	for i = 1, GameConfig.PLOT_COUNT do
		local plotModel = plotsFolder:WaitForChild("Plot" .. i)
		local platform = plotModel:WaitForChild("Platform")
		local center = platform.Position
		local plot = {}
		plot.Center = center
		plot.Slots = {}
		for j, offset in ipairs(SLOT_OFFSETS) do
			local pad = makePad(center, offset)
			-- The top of the pad: a brainrot's feet stand here.
			plot.Slots[j] = pad.Position + Vector3.new(0, 0.2, 0)
		end
		local post = plotModel:WaitForChild("SignPost")
		plot.SignLabel = makeSign(post)
		world.Plots[i] = plot
	end

	-- The noodle wave: parked far off the map, invisible, until it sweeps.
	local wave = Instance.new("Part")
	wave.Name = "NoodleWave"
	wave.Size = Vector3.new(24, 30, 320)
	wave.Position = Vector3.new(-220, 12, 0)
	wave.Color = Color3.fromRGB(40, 140, 255)
	wave.Material = Enum.Material.Neon
	wave.Transparency = 1
	wave.Anchored = true
	wave.CanCollide = false
	wave.Parent = Workspace
	world.WavePart = wave

	return world
end

-- Write a player's name on their plot's sign.
function WorldBuilder.setPlotOwner(world, plotIndex, ownerName)
	local plot = world.Plots[plotIndex]
	if plot == nil or plot.SignLabel == nil then
		return
	end
	if ownerName == nil or ownerName == "" then
		plot.SignLabel.Text = "Empty plot"
	else
		plot.SignLabel.Text = ownerName .. "'s base"
	end
end

-- Is this position inside this plot's safe ground?
function WorldBuilder.isInsidePlot(world, plotIndex, position)
	local plot = world.Plots[plotIndex]
	if plot == nil then
		return false
	end
	local half = GameConfig.PLOT_SIZE / 2 + 1
	return math.abs(position.X - plot.Center.X) < half
		and math.abs(position.Z - plot.Center.Z) < half
end

return WorldBuilder
