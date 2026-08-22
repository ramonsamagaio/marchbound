# MARCHBOUND — Changelog

## 2026-08-22 — Project Start / MVP Foundation
- Name locked as **MARCHBOUND**.
- Project officially initiated.
- Established living documentation requirement so project decisions are not lost.
- Defined game as browser-first persistent fantasy strategy/action RPG.
- Locked core reference layering: Heroes of Might & Magic + Necesse + Vampire Survivors + Tribal Wars + simplified RimWorld + Pokémon-like army capacity/progression.
- Locked strong-loop mandate: Settlement → Army → World Tile → Expedition → Loot → Progress → Harder Frontier.
- Locked near-infinite progression mandate.
- Chosen technical direction: Godot/GDScript/Compatibility, GitHub, later Supabase authoritative backend.
- Implemented initial broad MVP code foundation covering settlement, economy, research, army, world, action expedition, boss, run upgrades, equipment, inventory, marketplace concept, save and Frontier Seasons.
- Visual paper-doll placeholder is intentionally a functional layered rig preview, not final art.

## 2026-08-22 — Frontier Conquest / Combat Loop Pass
- Replaced the finite-feeling world grid with a pannable window over global world coordinates.
- Dawnkeep is fixed at world coordinate `[0,0]`.
- Territories now persist as claimed state in the save game.
- Unclaimed territory can only be entered when connected to the player's current supply line through an adjacent claimed tile.
- First victory in a frontier tile claims it, opens neighboring territory and pays a first-claim bounty.
- Frontier danger now scales primarily with distance from Dawnkeep, preserving an effectively endless outward progression horizon.
- Frontier Season reset now rebuilds territorial claims around Dawnkeep while preserving the season/meta loop.
- Expeditions now contain biome-weighted resource sites that reward movement and risk-taking instead of pure arena circling.
- Standing near a resource site harvests it, awards materials/XP and a small heal.
- Added Momentum kill chains: fast consecutive kills raise temporary Warden/army damage and every 10-kill chain pays an extra Gold reward.
- Expedition result screen now reports harvested sites, best Momentum and whether the territory was newly claimed.
- Settlement summary now surfaces claimed-territory count, highest conquered threat and Renown.

## 2026-08-22 — Objective-Driven Frontier Pass
- World tiles now deterministically advertise an expedition objective before the player commits.
- Added four initial objective flows: **Frontier Claim**, **Monster Hunt**, **Resource Sweep** and **Ruin Siege**.
- Frontier Claim uses survival pressure before the guardian appears.
- Monster Hunt requires aggressive kill progression, adds extra enemy pressure and rewards bonus Gold/XP.
- Resource Sweep requires active harvesting/movement and rewards extra construction materials.
- Ruin Siege spawns an early guardian with increased health/damage and improved high-rarity equipment odds plus Gold/Mana rewards.
- Objective-specific fail-safe timers prevent stalled or unwinnable runs.
- Expedition HUD now exposes live objective progress and clearly signals when the guardian becomes active.
- Result screens identify the objective alongside kills, XP, harvesting, Momentum and loot.
- Refreshed the first-playtest guide around the new loop: Dawnkeep → reachable frontier → objective → guardian → claim → spend → push farther.
- Revalidated the current build in GitHub Actions using Godot 4.7.2: project parse passed, headless main-scene smoke test passed and Web export passed.
- Validation PR #4 was merged; obsolete validation PR #3 was closed.
