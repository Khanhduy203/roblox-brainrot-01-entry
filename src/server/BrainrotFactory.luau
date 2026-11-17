-- Brainrot Isles: the brainrot factory.
-- One job: turn a catalog entry plus a mutation into a 3D model that stands
-- on the belt or on a base slot, with a readable name, rarity and $/s label.
-- The spawner calls buildBrainrotModel; nothing else builds brainrots.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage.Shared.BrainrotCatalog)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local BrainrotFactory = {}

local EYE_WHITE = Color3.fromRGB(255, 255, 255)
local EYE_BLACK = Color3.fromRGB(20, 20, 20)

local function newPart(name, size, color, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = true
	part.Parent = parent
	return part
end

-- The floating label every brainrot wears: name, rarity, money a second.
local function attachLabel(model, def, mutationName, income)
	local gui = Instance.new("BillboardGui")
	gui.Name = "BrainrotLabel"
	gui.Size = UDim2.new(0, 180, 0, 64)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3.4 * def.Scale, 0)
	gui.AlwaysOnTop = false
	gui.Parent = model

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0, 24)
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 18
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0.2
	nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	nameLabel.Text = Catalog.displayName(def, mutationName)
	nameLabel.Parent = gui

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "RarityLabel"
	rarityLabel.Size = UDim2.new(1, 0, 0, 18)
	rarityLabel.Position = UDim2.new(0, 0, 0, 24)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Font = Enum.Font.GothamBold
	rarityLabel.TextSize = 14
	rarityLabel.TextColor3 = Catalog.rarityColor(def.Rarity)
	rarityLabel.TextStrokeTransparency = 0.2
	rarityLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	if mutationName ~= "Normal" then
		rarityLabel.Text = mutationName .. " " .. def.Rarity
	else
		rarityLabel.Text = def.Rarity
	end
	rarityLabel.Parent = gui

	local incomeLabel = Instance.new("TextLabel")
	incomeLabel.Name = "IncomeLabel"
	incomeLabel.Size = UDim2.new(1, 0, 0, 20)
	incomeLabel.Position = UDim2.new(0, 0, 0, 42)
	incomeLabel.BackgroundTransparency = 1
	incomeLabel.Font = Enum.Font.GothamBold
	incomeLabel.TextSize = 16
	incomeLabel.TextColor3 = Color3.fromRGB(120, 255, 140)
	incomeLabel.TextStrokeTransparency = 0.2
	incomeLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	incomeLabel.Text = GameConfig.formatCash(income) .. "/s"
	incomeLabel.Parent = gui

	return gui
end

-- Build the model. The caller positions it; the factory only shapes it.
function BrainrotFactory.buildBrainrotModel(def, mutationName, uid)
	local scale = def.Scale
	local model = Instance.new("Model")
	model.Name = "Brainrot_" .. uid

	local body = newPart("Body", Vector3.new(2 * scale, 1.8 * scale, 1.6 * scale), def.Body, model)
	body.CanCollide = true
	local head = newPart("Head", Vector3.new(1.5 * scale, 1.3 * scale, 1.4 * scale), def.Head, model)
	head.CFrame = CFrame.new(0, 1.5 * scale, 0)
	local footL = newPart("FootL", Vector3.new(0.6 * scale, 0.4 * scale, 0.9 * scale), def.Head, model)
	footL.CFrame = CFrame.new(-0.5 * scale, -1 * scale, 0)
	local footR = newPart("FootR", Vector3.new(0.6 * scale, 0.4 * scale, 0.9 * scale), def.Head, model)
	footR.CFrame = CFrame.new(0.5 * scale, -1 * scale, 0)

	-- Eyes on the front of the head, so the face reads from the belt.
	local eyeL = newPart("EyeL", Vector3.new(0.35 * scale, 0.45 * scale, 0.1), EYE_WHITE, model)
	eyeL.CFrame = CFrame.new(-0.35 * scale, 1.6 * scale, 0.72 * scale)
	local eyeR = newPart("EyeR", Vector3.new(0.35 * scale, 0.45 * scale, 0.1), EYE_WHITE, model)
	eyeR.CFrame = CFrame.new(0.35 * scale, 1.6 * scale, 0.72 * scale)
	local pupilL = newPart("PupilL", Vector3.new(0.16 * scale, 0.2 * scale, 0.05), EYE_BLACK, model)
	pupilL.CFrame = CFrame.new(-0.35 * scale, 1.58 * scale, 0.78 * scale)
	local pupilR = newPart("PupilR", Vector3.new(0.16 * scale, 0.2 * scale, 0.05), EYE_BLACK, model)
	pupilR.CFrame = CFrame.new(0.35 * scale, 1.58 * scale, 0.78 * scale)

	-- A mutation tints the body, so a Golden brainrot reads as golden.
	local mutColor = Catalog.mutationColor(mutationName)
	if mutationName ~= "Normal" then
		body.Color = mutColor
		body.Material = Enum.Material.Neon
	end

	model.PrimaryPart = body
	attachLabel(model, def, mutationName, Catalog.incomeOf(def, mutationName))
	return model
end

-- Move every part of a model to a target frame, keeping its shape.
function BrainrotFactory.placeModel(model, cframe)
	local primary = model.PrimaryPart
	if primary == nil then
		return
	end
	local offset = primary.CFrame:Inverse()
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CFrame = cframe * offset * part.CFrame
		end
	end
end

return BrainrotFactory
