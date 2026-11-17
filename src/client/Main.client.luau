-- Brainrot Isles: the client bootstrap.
-- One job: build the HUD and the effects, listen to the server's event,
-- and bind the lock and rebirth keys. It asks; the server decides.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local Hud = require(script.Parent.Hud)
local Effects = require(script.Parent.Effects)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local brainrotEvent = remotes:WaitForChild(Net.EVENT_NAME)
local brainrotRequest = remotes:WaitForChild(Net.FUNCTION_NAME)

local function request(action)
	local ok, message = pcall(function()
		return brainrotRequest:InvokeServer(action)
	end)
	if not ok then
		Hud.showBanner("The server did not answer. Try again.", 3)
	end
	return ok, message
end

Hud.build(player, request)
Effects.build(player)

brainrotEvent.OnClientEvent:Connect(function(kind, payload, extra)
	if kind == Net.EV_STATE then
		Hud.setState(payload)
	elseif kind == Net.EV_TOAST then
		Hud.showBanner(payload, 3)
	elseif kind == Net.EV_WAVE_WARN then
		Hud.showBanner("🌊 NOODLE WAVE in " .. tostring(payload) .. "s — run home to your base!", 10)
		Effects.flash(Color3.fromRGB(255, 170, 0), 1.5)
	elseif kind == Net.EV_WAVE_START then
		Hud.showBanner("🌊 THE WAVE IS HERE — get inside your base!", 6)
		Effects.flash(Color3.fromRGB(255, 0, 0), 2)
	elseif kind == Net.EV_CARRY then
		Hud.setCarry(payload)
	end
end)

-- L locks the base, R rebirths. ContextActionService, not a raw key
-- handler, so the camera's own keys never swallow them.
ContextActionService:BindAction("BrainrotLock", function(_, state)
	if state == Enum.UserInputState.Begin then
		request(Net.REQUEST_LOCK)
	end
end, false, Enum.KeyCode.L)

ContextActionService:BindAction("BrainrotRebirth", function(_, state)
	if state == Enum.UserInputState.Begin then
		request(Net.REQUEST_REBIRTH)
	end
end, false, Enum.KeyCode.R)
