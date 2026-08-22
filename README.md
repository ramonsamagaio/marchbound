# MARCHBOUND

Browser-first persistent fantasy strategy/action RPG built with Godot 4.

> Status: Pre-Alpha / broad playable MVP foundation.

## First local test

1. Pull `main` in GitHub Desktop.
2. Open `project.godot` in **Godot 4.7.2 stable**.
3. Press **F5** to run the project.
4. Start in **Settlement**, inspect upgrades/research, then open **World Map**.
5. Dawnkeep is `[0,0]`. Pick one of the highlighted adjacent frontier tiles.
6. Read the tile objective before entering. The current MVP generates four expedition flows: **Frontier Claim**, **Monster Hunt**, **Resource Sweep** and **Ruin Siege**.
7. Win to claim an unowned tile. Its orthogonal neighbors become reachable, letting your supply line grow outward indefinitely.
8. During combat, move onto glowing resource sites and remain nearby briefly to harvest them.
9. Chain kills quickly to build **Momentum**, increasing Warden/army damage and earning bonus Gold at each 10-kill chain.
10. Return to Dawnkeep, convert the haul into buildings, research, unit ranks and gear, then push toward a harder tile.

### Expedition controls
- WASD: move
- Space: dash
- Q: Rally army
- E: Shockwave
- Warden auto-attacks nearest enemies

## Current core loop

`Dawnkeep → Army → Reachable Frontier → Objective Expedition → Harvest/Momentum → Guardian → Loot/Claim → Build/Research/Equip → Push farther`

### Objective behaviors

- **Frontier Claim:** survive long enough to force the guardian into the open.
- **Monster Hunt:** kill aggressively until the local alpha appears; this mode has extra enemy pressure and a Gold/XP bounty.
- **Resource Sweep:** harvest enough frontier sites to awaken the guardian; pays extra construction materials.
- **Ruin Siege:** guardian arrives much earlier, is stronger and has improved high-rarity loot odds.

Current systems also include passive/offline economy, settlement upgrades, six research branches, Command-limited armies, four unit types, an effectively unbounded deterministic world-map window, persistent adjacency-based territory claims, biome/threat/resource metadata, action combat, run doctrines, horde scaling, procedural equipment, inventory/paper-doll preview, forge upgrades, marketplace prototype, local persistence and Frontier Seasons.

## What to judge in this build

The most important question is whether the game creates the thought: **“one more territory, then I can afford/unlock/try that.”**

Pay attention to:
- whether the visible supply line makes the world feel like a campaign rather than a menu;
- whether different objectives meaningfully change how you move and fight;
- whether harvesting tempts you into dangerous positions;
- whether Momentum makes aggression more fun than passive survival;
- whether expedition rewards immediately create a tempting decision back in Dawnkeep;
- whether the next higher-threat tile feels exciting rather than merely numerical.

## Project memory

- `docs/MARCHBOUND_MASTER.md` — canonical living game bible.
- `docs/MILESTONES.md` — development milestones and acceptance checklist.
- `docs/CHANGELOG.md` — chronological design/implementation history.
- `docs/TECH_ARCHITECTURE.md` — browser/backend architecture.

These files are intentionally maintained as project memory whenever the design or implementation changes.

## Validation

The current objective-driven frontier build passed Godot **4.7.2** project parsing, a headless main-scene smoke run and Web export through GitHub Actions.

## Online architecture direction

MVP persistence is local for rapid iteration. `backend/supabase_schema.sql` contains the first database draft. Online economy-sensitive actions will eventually be server-authoritative rather than trusting the browser client.
