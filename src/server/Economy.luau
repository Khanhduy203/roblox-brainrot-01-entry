-- Brainrot Isles: the economy.
-- One job: move money — the $/s tick, buying off the belt, selling back,
-- rebirthing, and buying base slots. Buying validates cash and a free slot
-- before it takes anything; the steal system owns the base prompt this
-- module attaches after a purchase.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage.Shared.BrainrotCatalog)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Net = require(ReplicatedStorage.Shared.Net)
local Factory = require(script.Parent.BrainrotFactory)
local GameState = require(script.Parent.GameState)
local BrainrotSpawner = require(script.Parent.BrainrotSpawner)

local Economy = {}

local ctx = nil

local function sendToast(player, text)
	local event = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild(Net.EVENT_NAME)
	event:FireClient(player, Net.EV_TOAST, text)
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

-- Buy the brainrot off the belt into the player's first free slot.
function Economy.tryBuy(player, uid)
	local profile = GameState.getProfile(player)
	if profile == nil then
		return false
	end
	local entry = BrainrotSpawner.getBeltEntry(uid)
	if entry == nil then
		sendToast(player, "That brainrot is already gone.")
		return false
	end
	if profile.PlotIndex == 0 then
		sendToast(player, "No free base on the isles — wait for a plot.")
		return false
	end
	local slotIndex = GameState.firstFreeSlot(profile)
	if slotIndex == nil then
		sendToast(player, "No free slot — buy one with the HUD button.")
		return false
	end
	if profile.Cash < entry.Price then
		sendToast(player, "You need " .. GameConfig.formatCash(entry.Price - profile.Cash) .. " more.")
		return false
	end

	BrainrotSpawner.takeFromBelt(uid)
	profile.Cash = profile.Cash - entry.Price
	local record = GameState.makeRecord(uid, entry.Def, entry.Mutation)
	record.Model = entry.Model
	GameState.addBrainrot(profile, slotIndex, record)

	local buyPrompt = entry.Model.PrimaryPart:FindFirstChild("BuyPrompt")
	if buyPrompt ~= nil then
		buyPrompt:Destroy()
	end
	Factory.placeModel(entry.Model, slotCFrame(ctx.World, profile.PlotIndex, slotIndex, entry.Def))
	ctx.Steal.attachBasePrompt(entry.Model, record)
	sendToast(player, "Bought " .. Catalog.displayName(entry.Def, entry.Mutation) .. " — earning " .. GameConfig.formatCash(record.Income) .. "/s!")
	return true
end

-- Sell one of your own brainrots back for half what it cost.
function Economy.trySell(player, uid)
	local profile = GameState.getProfile(player)
	if profile == nil then
		return false
	end
	local record, slotIndex = GameState.findBrainrot(profile, uid)
	if record == nil then
		return false
	end
	local refund = math.floor(record.Cost * GameConfig.SELL_REFUND + 0.5)
	GameState.removeBrainrot(profile, slotIndex)
	if record.Model ~= nil then
		record.Model:Destroy()
	end
	profile.Cash = profile.Cash + refund
	local def = Catalog.getById(record.CatalogId)
	local name = def and Catalog.displayName(def, record.Mutation) or "brainrot"
	sendToast(player, "Sold " .. name .. " for " .. GameConfig.formatCash(refund) .. ".")
	return true
end

function Economy.tryRebirth(player)
	local profile = GameState.getProfile(player)
	if profile == nil then
		return false, "No profile."
	end
	-- A carried brainrot goes home first: rebirth must not orphan it.
	if profile.Carrying ~= nil and ctx.Steal ~= nil then
		ctx.Steal.dropCarried(profile)
	end
	-- Snapshot the models first: the state call below clears the records.
	local doomed = {}
	for _, record in pairs(profile.Brainrots) do
		table.insert(doomed, record)
	end
	local ok, message = GameState.tryRebirth(profile)
	if not ok then
		sendToast(player, message)
		return false, message
	end
	for _, record in ipairs(doomed) do
		if record.Model ~= nil then
			record.Model:Destroy()
		end
	end
	sendToast(player, message)
	return true, message
end

function Economy.tryBuySlot(player)
	local profile = GameState.getProfile(player)
	if profile == nil then
		return false, "No profile."
	end
	local ok, message = GameState.tryBuySlot(profile)
	sendToast(player, message)
	return ok, message
end

-- The $/s tick, and a fresh HUD state for every player, once a second.
local function incomeLoop()
	while true do
		task.wait(1)
		local event = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild(Net.EVENT_NAME)
		GameState.eachProfile(function(player, profile)
			profile.Cash = profile.Cash + GameState.incomePerSecond(profile)
			event:FireClient(player, Net.EV_STATE, {
				Cash = profile.Cash,
				IncomePerSec = GameState.incomePerSecond(profile),
				Rebirths = profile.Rebirths,
				Multiplier = profile.Multiplier,
				LockLeft = GameState.lockLeft(profile),
				LockCooldownLeft = GameState.lockCooldownLeft(profile),
				OwnedSlots = profile.OwnedSlots,
				OwnedCount = GameState.ownedCount(profile),
			})
		end)
	end
end

function Economy.start(context)
	ctx = context
	task.spawn(incomeLoop)
end

return Economy
