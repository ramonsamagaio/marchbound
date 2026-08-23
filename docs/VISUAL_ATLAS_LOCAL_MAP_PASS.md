# MARCHBOUND — Visual Atlas / Local Territory Pass

**Date:** 2026-08-22

## Goals

This pass addresses four concrete playtest failures / design requirements:

1. The game relied too heavily on programmer shapes/text instead of authored visual assets.
2. The 1280×720 design viewport was too cramped; result UI could extend beyond the screen and block mission completion.
3. A strategic World Map tile must open into a large Necesse-like local territory, not a one-screen arena.
4. Units need collectible quality identity beyond family Rank and evolution.

## Approved provisional atlas

The uploaded art sheet is now a real game dependency:

`assets/marchbound_assetsprov.png`

`VisualAtlas.gd` centralizes crop regions and semantic IDs. The same sheet currently supplies:
- resource icons;
- navigation/system icons;
- human troops;
- enemies;
- Wild Bond creatures;
- buildings;
- combat effects/pickups;
- strategic biome/hex art.

The atlas is provisional. It proves the visual pipeline and replaces raw geometry while final production assets are built.

## Resolution / responsive safety

Native design resolution moved from **1280×720 to 1920×1080**.

Minimum window target remains **1280×720**.

Canvas items use `expand` aspect behavior. Dynamic expedition result content now scrolls and its Continue action is kept outside the scroll body.

## Macro territory → local map scale

Each strategic World Map territory now advertises a target local map size of:

**192 × 192 local tiles**

At 64 px per local tile, the initial world-space is:

**12,288 × 12,288 px**

This equals **36,864 local tiles per macro territory**.

The map is intentionally much larger than one viewport. The arena uses a lightweight camera model by shifting the rendered world around the player's local position. Drawing is culled to the visible grid/nearby content rather than spawning 36k TileMap-style nodes in this first prototype.

The architecture marks a target capacity of **3 Wardens / players per macro territory** for the future shared-world slice. Current combat is still local/single-player and no realtime multiplayer authority is implied yet.

## Local territory content

The local combat map now contains a physical frontier outpost built from atlas art:
- Town Hall / keep;
- Barracks;
- Forge;
- Storage;
- Watchtower;
- House;
- Chapel;
- Stable;
- roads;
- surrounding environmental props;
- harvest nodes.

Enemies spawn around the player's current camera ring instead of at the 12k map boundary.

## First in-expedition building mechanic

The local territory is no longer only decorated with buildings.

During an expedition:
- harvest Wood from local resource nodes;
- press **B** near a free tile;
- spend **6 Wood collected in that same expedition**;
- place a **Field Watchtower** snapped to the 64 px local grid;
- placed towers automatically fire at nearby enemies;
- towers have a per-run placement limit;
- placement rejects blocked/overlapping positions.

This is the first prototype of the intended Necesse-like construction vocabulary inside local territories. Future local construction can expand into walls, traps, repair stations, camps, turrets, resource processors and temporary logistics.

## Individual unit quality

The existing army family model remains:
- family / species;
- Rank;
- permanent evolution where available;
- Command cost.

A new individual-record layer now adds:

### Prefixes
New recruits have a chance to roll one prefix:
- **Swift** — faster attacks / slightly longer reach;
- **Ironhide** — stronger frontline damage;
- **Blessed** — attacks restore Warden HP;
- **Vicious** — stronger execution damage against wounded targets;
- **Ancient** — stronger attacks and longer reach;
- **Stormtouched** — attacks can arc damage to another enemy.

### Elite
Elite is an independent rare classification, analogous to the emotional role of a shiny collectible:
- current provisional chance: approximately **1 / 96** on a newly generated individual;
- visually marked with an Elite presentation/aura;
- gains additional combat quality multipliers;
- can coexist with a prefix.

Existing saves migrate their already-owned aggregate troops into Standard individual records, avoiding destructive rerolls of old armies. New recruits can roll prefix/Elite quality.

## Scene-driven visual UI added

- `scenes/ui/ExpeditionLayout.tscn`
- `scenes/ui/ExpeditionResult.tscn`
- `scenes/ui/PaperDoll.tscn`

See `VISUAL_UI_AUDIT.md` for the remaining code-defined UI debt.

## Next scale tests

- parse/smoke/Web export under Godot 4.7.2;
- verify actual atlas cuts after Godot imports the PNG;
- interactive 1920×1080 Chrome playtest;
- 1280×720 minimum-size overflow test;
- local-map camera / enemy spawning / building feel pass;
- browser performance with giant coordinate space;
- eventual chunk streaming if local territory density increases substantially;
- multiplayer local-territory authority only after the single-player loop is fun.
