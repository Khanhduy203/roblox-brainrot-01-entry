-- Brainrot Isles: tuning in one place.
-- One job: hold every number the game balances on, so a balance pass edits
-- this file and nothing else. Server modules read it; the client never does.

local GameConfig = {}

-- Starting cash for a fresh player.
GameConfig.START_CASH = 100

-- Base slots: every base starts with this many, the rest are bought.
GameConfig.START_SLOTS = 4
GameConfig.MAX_SLOTS = 8
-- Price of slot 5, 6, 7, 8, in order.
GameConfig.SLOT_PRICES = { 500, 2500, 10000, 40000 }

-- Base lock: seconds a lock lasts, and the cooldown before it can lock again.
GameConfig.LOCK_SECONDS = 45
GameConfig.LOCK_COOLDOWN = 90

-- The noodle wave: every this many seconds, after a warning of this length.
GameConfig.WAVE_EVERY = 120
GameConfig.WAVE_WARN = 10
GameConfig.WAVE_SWEEP_SECONDS = 8

-- Rebirth: costs this times two to the power of rebirths already taken.
GameConfig.REBIRTH_BASE = 25000
GameConfig.REBIRTH_MAX = 10
-- Income multiplier is 1 + rebirths.

-- The conveyor belt the brainrots walk down.
GameConfig.BELT_START = Vector3.new(-88, 3, -40)
GameConfig.BELT_END = Vector3.new(88, 3, -40)
GameConfig.BELT_SPEED = 4
GameConfig.SPAWN_EVERY = 6
GameConfig.BELT_MAX = 8

-- Selling a brainrot refunds this share of what it cost.
GameConfig.SELL_REFUND = 0.5

-- Walking: normal speed, and the speed while carrying a stolen brainrot.
GameConfig.WALK_SPEED = 16
GameConfig.CARRY_SPEED = 10

-- Six base plots in a ring around the plaza, 30 studs wide each.
GameConfig.PLOT_COUNT = 6
GameConfig.PLOT_SIZE = 30
GameConfig.PLOT_POSITIONS = {
	Vector3.new(70, 0, 0),
	Vector3.new(35, 0, 60.6),
	Vector3.new(-35, 0, 60.6),
	Vector3.new(-70, 0, 0),
	Vector3.new(-35, 0, -60.6),
	Vector3.new(35, 0, -60.6),
}

-- Where players appear when they join.
GameConfig.SPAWN_POSITION = Vector3.new(0, 3, 40)

-- "$12,345" style cash, shared by server toasts and client labels.
function GameConfig.formatCash(amount)
	local n = math.floor(amount + 0.5)
	local text = tostring(n)
	local out = ""
	while #text > 3 do
		out = "," .. string.sub(text, -3) .. out
		text = string.sub(text, 1, -4)
	end
	return "$" .. text .. out
end

return GameConfig
