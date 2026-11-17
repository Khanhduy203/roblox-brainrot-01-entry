-- Brainrot Isles: the noodle wave.
-- One job: the hazard that forces a dash home. Every two minutes a warning
-- goes out, then a wave sweeps the whole map. Anyone caught outside their
-- own base is knocked over, drops what they carry, and is shoved along.
-- A base is the only safe ground.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Net = require(ReplicatedStorage.Shared.Net)
local WorldBuilder = require(script.Parent.WorldBuilder)
local GameState = require(script.Parent.GameState)

local EventSystem = {}

local ctx = nil

local function broadcast(kind, ...)
	local event = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild(Net.EVENT_NAME)
	event:FireAllClients(kind, ...)
end

local function rootPartOf(player)
	local character = player.Character
	if character == nil then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

local function hitPlayer(profile, root)
	local player = profile.Player
	if profile.Carrying ~= nil and ctx.Steal ~= nil then
		ctx.Steal.dropCarried(profile)
	end
	local humanoid = nil
	if player.Character ~= nil then
		humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	end
	if humanoid ~= nil then
		humanoid.WalkSpeed = 0
		task.delay(2, function()
			if humanoid.Parent ~= nil then
				humanoid.WalkSpeed = GameConfig.WALK_SPEED
			end
		end)
	end
	root.AssemblyLinearVelocity = Vector3.new(40, 12, 0)
	local event = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild(Net.EVENT_NAME)
	event:FireClient(player, Net.EV_TOAST, "The noodle wave swept you off your feet!")
end

local function sweepWave()
	local wave = ctx.World.WavePart
	wave.Transparency = 0.45
	local startX = -220
	local endX = 220
	local hit = {}
	local started = os.clock()
	while os.clock() - started < GameConfig.WAVE_SWEEP_SECONDS do
		local p = (os.clock() - started) / GameConfig.WAVE_SWEEP_SECONDS
		wave.Position = Vector3.new(startX + (endX - startX) * p, 12, 0)
		GameState.eachProfile(function(player, profile)
			if hit[player] then
				return
			end
			local root = rootPartOf(player)
			if root == nil then
				return
			end
			if profile.PlotIndex ~= 0 and WorldBuilder.isInsidePlot(ctx.World, profile.PlotIndex, root.Position) then
				return
			end
			if math.abs(root.Position.X - wave.Position.X) < 16 then
				hit[player] = true
				hitPlayer(profile, root)
			end
		end)
		task.wait(0.1)
	end
	wave.Transparency = 1
	wave.Position = Vector3.new(-220, 12, 0)
end

local function waveLoop()
	while true do
		task.wait(GameConfig.WAVE_EVERY)
		broadcast(Net.EV_WAVE_WARN, GameConfig.WAVE_WARN)
		task.wait(GameConfig.WAVE_WARN)
		broadcast(Net.EV_WAVE_START)
		sweepWave()
		broadcast(Net.EV_TOAST, "The noodle wave passed — bases kept their owners safe.")
	end
end

function EventSystem.start(context)
	ctx = context
	task.spawn(waveLoop)
end

return EventSystem
