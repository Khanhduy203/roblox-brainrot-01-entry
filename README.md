# Brainrot Isles

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/Khanhduy203/roblox-brainrot-01-entry/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/Khanhduy203/roblox-brainrot-01-entry/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

https://make.fun/bounty/roblox-brainrot-01

A 3D brainrot game in the Steal a Brainrot genre, built for make.fun's
roblox-brainrot-01 bounty. Absurd meme-born characters walk down a conveyor
belt, you buy them onto your base, and each one earns money every second.

## The game

- **The cast:** 13 original characters — Toaster Toad, Sock Goblin, Pickle
  Wizard, Chairman Meow, DJ Spaghetti, Grandma Rocket, Sir Bananasworth,
  Tax Manatee, Captain Noodlebeard, Quantum Quokka, El Grande Burrito,
  Infinite Mime, and the Secret Glorbo Prime — across 7 rarities
  (Common to Secret) and 4 mutations (Normal, Golden, Diamond, Rainbow).
- **The loop:** buy brainrots off the belt, place them on your base's slots,
  watch the cash tick up, buy rarer ones, buy more slots, rebirth for a
  permanent income multiplier.
- **The threat:** steal from unlocked bases — carry the catch home over your
  head at a slow walk while its owner chases you to tag you. Lock your base
  for 45 seconds when the coast is not clear. And every two minutes the
  Noodle Wave sweeps the whole map: anyone caught outside their base is
  knocked over and drops what they carry.
- **The world:** a real 3D isle — a conveyor belt, six colored base plots
  in a ring, a spawn plaza with an arch, trees and rocks — under Roblox's
  3D camera, with a ScreenGui HUD (cash, income, rebirths, lock, banner).

## Structure

- `src/shared/` — `BrainrotCatalog.luau` (cast, rarities, mutations),
  `GameConfig.luau` (every tuning number), `Net.luau` (remote names).
- `src/server/` — `Bootstrap.server.luau` (wiring), `WorldBuilder.luau`
  (slot pads, signs, the wave), `GameState.luau` (the single source of
  truth for players), `BrainrotSpawner.luau` (the belt),
  `BrainrotFactory.luau` (the 3D models and their labels),
  `Economy.luau` (income tick, buy, sell, rebirth, slots),
  `StealSystem.luau` (carry, tag, deliver, lock),
  `EventSystem.luau` (the noodle wave).
- `src/client/` — `Main.client.luau` (bootstrap + keys),
  `Hud.luau` (the ScreenGui), `Effects.luau` (wave flashes).
- `default.project.json` — the Rojo project; `rojo build
  default.project.json --output game.rbxl` writes the place.

## Build

```sh
rojo build default.project.json --output game.rbxl
```

Screenshots are taken in Roblox Studio by the account owner (this repo
ships with an empty `screenshots/` until then), and `PLAY.json` is filled
in once the experience is published.
