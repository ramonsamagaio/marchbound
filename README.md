# MARCHBOUND

Browser-first persistent fantasy strategy/action RPG built with Godot 4.

> Status: Pre-Alpha / broad playable MVP foundation.

## First local test

1. Pull `main` in GitHub Desktop.
2. Open `project.godot` in **Godot 4.7.2 stable**.
3. Press **F6/F5** to run the main project.
4. Start in **Settlement**, inspect upgrades/research, then open **World Map**.
5. Dawnkeep is `[0,0]`. Pick one of the highlighted adjacent frontier tiles and enter an expedition.
6. Win the expedition to claim that tile. Its neighbors become reachable, so you can visibly push a supply line outward.
7. During combat, move over glowing resource sites and remain nearby briefly to harvest them.
8. Chain kills quickly to build **Momentum**, temporarily increasing Warden/army damage and paying bonus Gold every 10 chained kills.

### Expedition controls
- WASD: move
- Space: dash
- Q: Rally army
- E: shockwave
- Warden auto-attacks nearest enemies

The loop is now wired as:

`Settlement → Army → Choose reachable Frontier → Expedition/Harvest/Momentum → Boss/Loot → Claim Territory → Build/Research/Equip → Push farther`

Current systems include passive/offline economy, settlement upgrades, tech, Command-limited armies, four unit types, an effectively unbounded deterministic world-map window, adjacency-based persistent territory claims, biome/threat/resource metadata, action combat, harvestable resource sites, Momentum kill chains, horde scaling, boss, run upgrades, XP/resources, procedural equipment, paper-doll preview, forge upgrades, marketplace prototype, local persistence and Frontier Seasons.

## What to judge in this build

The most important question is not polish yet. It is whether the game creates the thought: **“one more territory, then I can afford/unlock/try that.”**

Please pay attention to:
- whether claiming adjacent tiles makes the world map feel like a real campaign rather than a menu;
- whether harvesting pulls you into risky movement during combat;
- whether Momentum makes aggression more fun than passive survival;
- whether rewards feel strong enough to make you immediately spend them in Dawnkeep;
- whether the next visible threat feels tempting rather than merely numerical.

## Project memory

- `docs/MARCHBOUND_MASTER.md` — canonical living game bible. Update whenever design/architecture/features change.
- `docs/MILESTONES.md` — development milestones and current acceptance checklist.
- `docs/CHANGELOG.md` — chronological decisions and implementation changes.
- `docs/TECH_ARCHITECTURE.md` — browser/backend architecture.

## Validation

The foundation build passed Godot **4.7.2** project parsing, a headless main-scene smoke run, and Web export through GitHub Actions. The frontier-conquest update is being revalidated through the same workflow before its milestone checkbox is closed.

## Online architecture direction

MVP persistence is local for fast iteration. The repository already includes `backend/supabase_schema.sql` as the first database draft. Online economy-sensitive actions will eventually be server-authoritative rather than trusting the browser client.
