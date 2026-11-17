-- Brainrot Isles: the wire between client and server.
-- One job: name the remotes and the messages that travel on them, so the
-- client and the server can never disagree about a spelling.

local Net = {}

-- ReplicatedStorage.Remotes holds these two instances, made by the bootstrap.
Net.EVENT_NAME = "BrainrotEvent"
Net.FUNCTION_NAME = "BrainrotRequest"

-- Client -> server requests (RemoteFunction action strings).
Net.REQUEST_LOCK = "LockBase"
Net.REQUEST_REBIRTH = "Rebirth"
Net.REQUEST_BUY_SLOT = "BuySlot"

-- Server -> client events (RemoteEvent payload: kind, then fields).
Net.EV_STATE = "State" -- cash, incomePerSec, rebirths, multiplier, lockLeft, lockCooldownLeft, ownedSlots, ownedCount
Net.EV_TOAST = "Toast" -- short message line
Net.EV_WAVE_WARN = "WaveWarning" -- seconds until the wave arrives
Net.EV_WAVE_START = "WaveStart" -- the wave is sweeping now
Net.EV_CARRY = "Carry" -- display name of the carried brainrot, or "" when none

return Net
