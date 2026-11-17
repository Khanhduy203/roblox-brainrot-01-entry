-- Brainrot Isles: game state, the single source of truth.
-- One job: hold every player's profile — cash, brainrots, slots, lock,
-- rebirths, what they are carrying — and the small honest operations on it.
-- The economy, the spawner and the steal system all read and write here,
-- and no other module keeps a copy of a player's numbers.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage.Shared.BrainrotCatalog)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local GameState = {}

local profiles = {}
local usedPlots = {}
local nextUid = 0

function GameState.newUid()
	nextUid = nextUid + 1
	return "b" .. tostring(nextUid)
end

-- Claim the first free plot for a joining player, or 0 when the isles are full.
function GameState.claimPlot()
	for i = 1, GameConfig.PLOT_COUNT do
		if usedPlots[i] == nil then
			usedPlots[i] = true
			return i
		end
	end
	return 0
end

function GameState.releasePlot(plotIndex)
	usedPlots[plotIndex] = nil
end

function GameState.newProfile(player, plotIndex)
	local profile = {
		Player = player,
		PlotIndex = plotIndex,
		Cash = GameConfig.START_CASH,
		Rebirths = 0,
		Multiplier = 1,
		OwnedSlots = GameConfig.START_SLOTS,
		Brainrots = {},
		LockUntil = 0,
		LockCooldownUntil = 0,
		Carrying = nil,
	}
	profiles[player] = profile
	return profile
end

function GameState.getProfile(player)
	return profiles[player]
end

function GameState.removeProfile(player)
	profiles[player] = nil
end

function GameState.eachProfile(fn)
	for player, profile in pairs(profiles) do
		fn(player, profile)
	end
end

-- Money a second from everything standing on this player's base.
function GameState.incomePerSecond(profile)
	local total = 0
	for _, record in pairs(profile.Brainrots) do
		total = total + record.Income
	end
	return total * profile.Multiplier
end

function GameState.firstFreeSlot(profile)
	for i = 1, profile.OwnedSlots do
		if profile.Brainrots[i] == nil then
			return i
		end
	end
	return nil
end

function GameState.ownedCount(profile)
	local n = 0
	for _, _ in pairs(profile.Brainrots) do
		n = n + 1
	end
	return n
end

function GameState.addBrainrot(profile, slotIndex, record)
	profile.Brainrots[slotIndex] = record
	record.SlotIndex = slotIndex
end

function GameState.removeBrainrot(profile, slotIndex)
	local record = profile.Brainrots[slotIndex]
	profile.Brainrots[slotIndex] = nil
	return record
end

function GameState.findBrainrot(profile, uid)
	for slotIndex, record in pairs(profile.Brainrots) do
		if record.Uid == uid then
			return record, slotIndex
		end
	end
	return nil, nil
end

-- Base lock: true while the lock is live.
function GameState.isLocked(profile)
	return os.time() < profile.LockUntil
end

function GameState.lockLeft(profile)
	return math.max(0, profile.LockUntil - os.time())
end

function GameState.lockCooldownLeft(profile)
	return math.max(0, profile.LockCooldownUntil - os.time())
end

-- Lock the base now. Returns false with a reason when it cannot lock.
function GameState.tryLock(profile)
	local now = os.time()
	if profile.PlotIndex == 0 then
		return false, "You have no base to lock."
	end
	if now < profile.LockCooldownUntil then
		return false, "Lock is cooling down."
	end
	if now < profile.LockUntil then
		return false, "Your base is already locked."
	end
	profile.LockUntil = now + GameConfig.LOCK_SECONDS
	profile.LockCooldownUntil = profile.LockUntil + GameConfig.LOCK_COOLDOWN
	return true, "Base locked for " .. tostring(GameConfig.LOCK_SECONDS) .. "s."
end

-- Rebirth: pay the price, lose the cash and the brainrots, keep a multiplier.
-- Returns false with a reason when it cannot rebirth; the caller destroys
-- the models only after this returns true.
function GameState.tryRebirth(profile)
	if profile.Rebirths >= GameConfig.REBIRTH_MAX then
		return false, "You have reached the most rebirths."
	end
	local cost = GameConfig.REBIRTH_BASE * math.pow(2, profile.Rebirths)
	if profile.Cash < cost then
		return false, "Rebirth needs " .. GameConfig.formatCash(cost) .. "."
	end
	profile.Cash = 0
	profile.Rebirths = profile.Rebirths + 1
	profile.Multiplier = 1 + profile.Rebirths
	profile.Brainrots = {}
	profile.Carrying = nil
	return true, "Rebirth " .. tostring(profile.Rebirths) .. "! Income x" .. tostring(profile.Multiplier) .. "."
end

-- Buy one more slot. Returns false with a reason when it cannot.
function GameState.tryBuySlot(profile)
	if profile.OwnedSlots >= GameConfig.MAX_SLOTS then
		return false, "Your base already has every slot."
	end
	local priceIndex = profile.OwnedSlots - GameConfig.START_SLOTS + 1
	local price = GameConfig.SLOT_PRICES[priceIndex]
	if price == nil then
		return false, "No more slots to buy."
	end
	if profile.Cash < price then
		return false, "That slot costs " .. GameConfig.formatCash(price) .. "."
	end
	profile.Cash = profile.Cash - price
	profile.OwnedSlots = profile.OwnedSlots + 1
	return true, "Slot " .. tostring(profile.OwnedSlots) .. " unlocked."
end

-- A brainrot record: what the game knows about one owned brainrot.
function GameState.makeRecord(uid, def, mutationName)
	return {
		Uid = uid,
		CatalogId = def.Id,
		Mutation = mutationName,
		Income = Catalog.incomeOf(def, mutationName),
		Cost = Catalog.priceOf(def, mutationName),
		SlotIndex = nil,
		Model = nil,
	}
end

return GameState
