# MARCHBOUND

Browser-first persistent fantasy strategy/action RPG built with Godot 4.

> Status: Pre-Alpha / broad playable MVP foundation.

## First local test

1. Pull `main` in GitHub Desktop.
2. Open `project.godot` in **Godot 4.7.2 stable**.
3. Press **F6/F5** to run the main project.
4. Start in **Settlement**, inspect upgrades/research, then open **World Map**.
5. Pick a tile and press **ENTER EXPEDITION**.

### Expedition controls
- WASD: move
- Space: dash
- Q: Rally army
- E: shockwave
- Warden auto-attacks nearest enemies

The loop is already wired as:

`Settlement → Army → World Tile → Expedition → Boss/Loot → Return → Build/Research/Equip → Higher Threat`

Current systems include passive/offline economy, settlement upgrades, tech, Command-limited armies, four unit types, procedural world tiles, action combat, horde scaling, boss, run upgrades, XP/resources, procedural equipment, paper-doll preview, forge upgrades, marketplace prototype, local persistence and Frontier Seasons.

## Project memory

- `docs/MARCHBOUND_MASTER.md` — canonical living game bible. Update whenever design/architecture/features change.
- `docs/MILESTONES.md` — development milestones and current acceptance checklist.
- `docs/CHANGELOG.md` — chronological decisions and implementation changes.
- `docs/TECH_ARCHITECTURE.md` — browser/backend architecture.

## Validation

The current foundation has passed Godot **4.7.2** project parsing, a headless main-scene smoke run, and a Web export through GitHub Actions.

## Online architecture direction

MVP persistence is local for fast iteration. The repository already includes `backend/supabase_schema.sql` as the first database draft. Online economy-sensitive actions will eventually be server-authoritative rather than trusting the browser client.
