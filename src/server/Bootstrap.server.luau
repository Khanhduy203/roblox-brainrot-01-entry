-- Brainrot Isles: the server bootstrap.
-- One job: build the remotes and the world, start every system, hand out
-- plots as players join, and route the HUD's three requests (lock, rebirth,
-- buy slot) to the module that owns them.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Net = require(ReplicatedStorage.Shared.Net)
local WorldBuilder = require(script.Parent.WorldBuilder)
local GameState = require(script.Parent.GameState)
local BrainrotSpawner = require(script.Parent.BrainrotSpawner)
local Economy = require(script.Parent.Economy)
local StealSystem = require(script.Parent.StealSystem)
local EventSystem = require(script.Parent.EventSystem)

-- The wire: one event for server-to-client news, one function for requests.
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local brainrotEvent = Instance.new("RemoteEvent")
brainrotEvent.Name = Net.EVENT_NAME
brainrotEvent.Parent = remotes

local brainrotRequest = Instance.new("RemoteFunction")
brainrotRequest.Name = Net.FUNCTION_NAME
brainrotRequest.Parent = remotes

local world = WorldBuilder.buildWorld()

local ctx = {
	World = world,
	Event = brainrotEvent,
	Spawner = BrainrotSpawner,
	Economy = Economy,
	Steal = StealSystem,
}
ctx.OnBuy = function(player, uid)
	return Economy.tryBuy(player, uid)
end

BrainrotSpawner.start(ctx)
Economy.start(ctx)
StealSystem.start(ctx)
EventSystem.start(ctx)

local function onCharacterAdded(player, character)
	local profile = GameState.getProfile(player)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.WalkSpeed = GameConfig.WALK_SPEED
	humanoid.Died:Connect(function()
		if profile ~= nil and profile.Carrying ~= nil then
			StealSystem.dropCarried(profile)
		end
	end)
end

local function onPlayerAdded(player)
	local plotIndex = GameState.claimPlot()
	GameState.newProfile(player, plotIndex)
	if plotIndex ~= 0 then
		WorldBuilder.setPlotOwner(world, plotIndex, player.Name)
	end
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character ~= nil then
		onCharacterAdded(player, player.Character)
	end
end

local function onPlayerRemoving(player)
	local profile = GameState.getProfile(player)
	if profile == nil then
		return
	end
	if profile.Carrying ~= nil then
		StealSystem.dropCarried(profile)
	end
	for _, record in pairs(profile.Brainrots) do
		if record.Model ~= nil then
			record.Model:Destroy()
		end
	end
	if profile.PlotIndex ~= 0 then
		WorldBuilder.setPlotOwner(world, profile.PlotIndex, "")
		GameState.releasePlot(profile.PlotIndex)
	end
	GameState.removeProfile(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

brainrotRequest.OnServerInvoke = function(player, action)
	if action == Net.REQUEST_LOCK then
		return StealSystem.tryLockBase(player)
	elseif action == Net.REQUEST_REBIRTH then
		return Economy.tryRebirth(player)
	elseif action == Net.REQUEST_BUY_SLOT then
		return Economy.tryBuySlot(player)
	end
	return false, "Unknown request."
end
