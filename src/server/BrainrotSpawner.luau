-- Brainrot Isles: the brainrot spawner.
-- One job: roll new brainrots, walk them down the conveyor belt, and let a
-- player buy one off the belt. The economy takes a brainrot off the belt
-- when it is bought; this module never touches a player's cash or base.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Catalog = require(ReplicatedStorage.Shared.BrainrotCatalog)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Factory = require(script.Parent.BrainrotFactory)
local GameState = require(script.Parent.GameState)

local BrainrotSpawner = {}

local belt = {}
local beltCount = 0
local ctx = nil

local function beltPosition(progress)
	local startPos = GameConfig.BELT_START
	local endPos = GameConfig.BELT_END
	return startPos:Lerp(endPos, progress)
end

local function rollBrainrot()
	local rarity = Catalog.rollRarity()
	local def = Catalog.pickForRarity(rarity)
	local mutation = Catalog.rollMutation()
	return def, mutation
end

local function spawnOne()
	if beltCount >= GameConfig.BELT_MAX then
		return
	end
	local def, mutation = rollBrainrot()
	local uid = GameState.newUid()
	local model = Factory.buildBrainrotModel(def, mutation, uid)
	local price = Catalog.priceOf(def, mutation)
	local income = Catalog.incomeOf(def, mutation)

	-- The buy prompt rides on the body, so any nearby player can grab it.
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = "Buy"
	prompt.ObjectText = Catalog.displayName(def, mutation) .. "  •  " .. GameConfig.formatCash(price)
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart

	prompt.Triggered:Connect(function(player)
		if ctx ~= nil and ctx.OnBuy ~= nil then
			ctx.OnBuy(player, uid)
		end
	end)

	model.Parent = game:GetService("Workspace")
	local entry = {
		Uid = uid,
		Def = def,
		Mutation = mutation,
		Price = price,
		Income = income,
		Model = model,
		Progress = 0,
		Phase = math.random() * math.pi * 2,
	}
	belt[uid] = entry
	beltCount = beltCount + 1
end

-- Walk every brainrot down the belt; unbought ones fall off the end.
local function onHeartbeat(dt)
	local length = (GameConfig.BELT_END - GameConfig.BELT_START).Magnitude
	local step = GameConfig.BELT_SPEED * dt / length
	local now = os.clock()
	for uid, entry in pairs(belt) do
		entry.Progress = entry.Progress + step
		if entry.Progress >= 1 then
			entry.Model:Destroy()
			belt[uid] = nil
			beltCount = beltCount - 1
		else
			local pos = beltPosition(entry.Progress)
			local bob = math.sin(now * 3 + entry.Phase) * 0.25
			local target = Vector3.new(pos.X, pos.Y + bob, pos.Z)
			local facing = CFrame.lookAt(target, target + Vector3.new(-1, 0, 0))
			Factory.placeModel(entry.Model, facing)
		end
	end
end

function BrainrotSpawner.getBeltEntry(uid)
	return belt[uid]
end

-- Take a brainrot off the belt for good (bought). Returns the entry or nil.
function BrainrotSpawner.takeFromBelt(uid)
	local entry = belt[uid]
	if entry == nil then
		return nil
	end
	belt[uid] = nil
	beltCount = beltCount - 1
	return entry
end

function BrainrotSpawner.start(context)
	ctx = context
	task.spawn(function()
		while true do
			task.wait(GameConfig.SPAWN_EVERY)
			spawnOne()
		end
	end)
	RunService.Heartbeat:Connect(onHeartbeat)
end

return BrainrotSpawner
