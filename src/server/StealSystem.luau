-- Brainrot Isles: the steal system.
-- One job: the threat that forces a dash home. A player takes a brainrot
-- off an unlocked base, carries it overhead at a slow walk, and must reach
-- their own base before the owner tags them or the wave catches them.
-- The base lock is the defence; the owner touching the carrier ends the run.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage.Shared.BrainrotCatalog)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Net = require(ReplicatedStorage.Shared.Net)
local Factory = require(script.Parent.BrainrotFactory)
local GameState = require(script.Parent.GameState)

local StealSystem = {}

local ctx = nil

local function sendToast(player, text)
	local event = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild(Net.EVENT_NAME)
	event:FireClient(player, Net.EV_TOAST, text)
end

local function sendCarry(player, displayName)
	local event = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild(Net.EVENT_NAME)
	event:FireClient(player, Net.EV_CARRY, displayName)
end

local function slotCFrame(world, plotIndex, slotIndex, def)
	local plot = world.Plots[plotIndex]
	local padTop = plot.Slots[slotIndex]
	local center = plot.Center
	local target = Vector3.new(padTop.X, padTop.Y + 0.9 * def.Scale, padTop.Z)
	local outward = Vector3.new(padTop.X - center.X, 0, padTop.Z - center.Z)
	if outward.Magnitude < 0.01 then
		outward = Vector3.new(0, 0, 1)
	end
	outward = outward.Unit
	return CFrame.lookAt(target, target - outward)
end

local function setModelAnchored(model, anchored)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = anchored
		end
	end
end

local function rootPartOf(player)
	local character = player.Character
	if character == nil then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

-- The prompt on a brainrot standing on a base: your own sells it, a
-- stranger's steals it. One prompt, one rule, explained on the HUD.
function StealSystem.attachBasePrompt(model, record)
	local def = Catalog.getById(record.CatalogId)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BasePrompt"
	prompt.ActionText = "Take"
	prompt.ObjectText = Catalog.displayName(def, record.Mutation) .. "  •  " .. GameConfig.formatCash(record.Income) .. "/s"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(player)
		StealSystem.handleInteract(player, record.Uid)
	end)
end

function StealSystem.handleInteract(player, uid)
	local carrierProfile = GameState.getProfile(player)
	if carrierProfile == nil then
		return
	end
	local ownerProfile = nil
	local record = nil
	local ownerSlot = nil
	GameState.eachProfile(function(_, profile)
		local found, slot = GameState.findBrainrot(profile, uid)
		if found ~= nil then
			ownerProfile = profile
			record = found
			ownerSlot = slot
		end
	end)
	if record == nil or ownerProfile == nil then
		return
	end
	if ownerProfile.Player == player then
		ctx.Economy.trySell(player, uid)
		return
	end
	if GameState.isLocked(ownerProfile) then
		sendToast(player, "That base is locked — come back later.")
		return
	end
	if carrierProfile.Carrying ~= nil then
		sendToast(player, "You are already carrying one — deliver it first.")
		return
	end
	if carrierProfile.PlotIndex == 0 then
		sendToast(player, "You have no base to carry it home to.")
		return
	end
	if GameState.firstFreeSlot(carrierProfile) == nil then
		sendToast(player, "No free slot on your base — buy one first.")
		return
	end
	StealSystem.startCarry(player, carrierProfile, ownerProfile, record, ownerSlot)
end

function StealSystem.startCarry(player, carrierProfile, ownerProfile, record, ownerSlot)
	local root = rootPartOf(player)
	if root == nil then
		return
	end
	GameState.removeBrainrot(ownerProfile, ownerSlot)
	record.OriginalOwner = ownerProfile.Player
	record.OriginalSlot = ownerSlot

	local model = record.Model
	local prompt = model.PrimaryPart:FindFirstChild("BasePrompt")
	if prompt ~= nil then
		prompt.Enabled = false
	end
	setModelAnchored(model, false)
	local body = model.PrimaryPart
	body.CanCollide = false
	local weld = Instance.new("Weld")
	weld.Name = "CarryWeld"
	weld.Part0 = root
	weld.Part1 = body
	weld.C0 = CFrame.new(0, 3, 0)
	weld.Parent = body

	carrierProfile.Carrying = record
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid ~= nil then
		humanoid.WalkSpeed = GameConfig.CARRY_SPEED
	end
	local def = Catalog.getById(record.CatalogId)
	sendCarry(player, Catalog.displayName(def, record.Mutation))
	sendToast(player, "You grabbed " .. Catalog.displayName(def, record.Mutation) .. " — run it home before the owner tags you!")
	sendToast(ownerProfile.Player, player.Name .. " is stealing your " .. Catalog.displayName(def, record.Mutation) .. "! Tag them to stop it.")
end

-- Put a carried brainrot back on its owner's base, wherever it was taken from.
function StealSystem.dropCarried(profile)
	local record = profile.Carrying
	if record == nil then
		return
	end
	profile.Carrying = nil
	local player = profile.Player
	local model = record.Model
	if model ~= nil then
		local body = model.PrimaryPart
		if body ~= nil then
			local weld = body:FindFirstChild("CarryWeld")
			if weld ~= nil then
				weld:Destroy()
			end
		end
		setModelAnchored(model, true)
	end
	local humanoid = nil
	if player.Character ~= nil then
		humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	end
	if humanoid ~= nil then
		humanoid.WalkSpeed = GameConfig.WALK_SPEED
	end
	sendCarry(player, "")

	local ownerProfile = GameState.getProfile(record.OriginalOwner)
	if ownerProfile == nil or model == nil then
		if model ~= nil then
			model:Destroy()
		end
		return
	end
	local slotIndex = nil
	if ownerProfile.Brainrots[record.OriginalSlot] == nil then
		slotIndex = record.OriginalSlot
	else
		slotIndex = GameState.firstFreeSlot(ownerProfile)
	end
	if slotIndex == nil then
		model:Destroy()
		return
	end
	local def = Catalog.getById(record.CatalogId)
	GameState.addBrainrot(ownerProfile, slotIndex, record)
	Factory.placeModel(model, slotCFrame(ctx.World, ownerProfile.PlotIndex, slotIndex, def))
	StealSystem.attachBasePrompt(model, record)
end

-- The carrier reached their own base: the brainrot changes hands for good.
local function deliver(profile)
	local record = profile.Carrying
	if record == nil then
		return
	end
	local slotIndex = GameState.firstFreeSlot(profile)
	if slotIndex == nil then
		StealSystem.dropCarried(profile)
		return
	end
	local player = profile.Player
	local model = record.Model
	local body = model.PrimaryPart
	local weld = body:FindFirstChild("CarryWeld")
	if weld ~= nil then
		weld:Destroy()
	end
	setModelAnchored(model, true)
	profile.Carrying = nil
	local humanoid = nil
	if player.Character ~= nil then
		humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	end
	if humanoid ~= nil then
		humanoid.WalkSpeed = GameConfig.WALK_SPEED
	end
	sendCarry(player, "")
	local def = Catalog.getById(record.CatalogId)
	GameState.addBrainrot(profile, slotIndex, record)
	Factory.placeModel(model, slotCFrame(ctx.World, profile.PlotIndex, slotIndex, def))
	StealSystem.attachBasePrompt(model, record)
	sendToast(player, "Stolen! " .. Catalog.displayName(def, record.Mutation) .. " now earns for you.")
	local ownerProfile = GameState.getProfile(record.OriginalOwner)
	if ownerProfile ~= nil then
		sendToast(ownerProfile.Player, player.Name .. " stole your " .. Catalog.displayName(def, record.Mutation) .. "!")
	end
end

-- Watch every carrier: tagged by the owner, or home safe.
local function carrierLoop()
	while true do
		task.wait(0.2)
		GameState.eachProfile(function(_, profile)
			local record = profile.Carrying
			if record == nil then
				return
			end
			local player = profile.Player
			local root = rootPartOf(player)
			if root == nil then
				StealSystem.dropCarried(profile)
				return
			end
			local humanoid = nil
			if player.Character ~= nil then
				humanoid = player.Character:FindFirstChildOfClass("Humanoid")
			end
			if humanoid == nil or humanoid.Health <= 0 then
				StealSystem.dropCarried(profile)
				return
			end
			-- Home safe: inside your own plot with the catch.
			if profile.PlotIndex ~= 0 and ctx.World ~= nil then
				local WorldBuilder = require(script.Parent.WorldBuilder)
				if WorldBuilder.isInsidePlot(ctx.World, profile.PlotIndex, root.Position) then
					deliver(profile)
					return
				end
			end
			-- Tagged: the owner is close enough to touch the thief.
			local ownerRoot = rootPartOf(record.OriginalOwner)
			if ownerRoot ~= nil and (ownerRoot.Position - root.Position).Magnitude < 5 then
				StealSystem.dropCarried(profile)
				sendToast(record.OriginalOwner, "You tagged the thief — your brainrot is home!")
				sendToast(player, "Tagged! The brainrot slipped away.")
			end
		end)
	end
end

function StealSystem.tryLockBase(player)
	local profile = GameState.getProfile(player)
	if profile == nil then
		return false, "No profile."
	end
	local ok, message = GameState.tryLock(profile)
	sendToast(player, message)
	return ok, message
end

function StealSystem.dropCarriedForAll()
	GameState.eachProfile(function(_, profile)
		StealSystem.dropCarried(profile)
	end)
end

function StealSystem.start(context)
	ctx = context
	task.spawn(carrierLoop)
end

return StealSystem
