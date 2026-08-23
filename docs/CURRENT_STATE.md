# MARCHBOUND - Current State

> Canonical short status ledger. The full design canon remains in `MARCHBOUND_MASTER.md`; focused implementation notes and audits live beside this file.

**Last updated:** 2026-08-22  
**Stage:** Pre-Alpha / M1 loop, scale and visual-production expansion  
**Engine:** Godot 4.7.2, GDScript, Compatibility renderer, browser-first  
**Repository:** `ramonsamagaio/marchbound`  
**Active visual pass:** `nyra/visual-atlas-pass-v2` pending strict CI/merge

## Playable loop

`First March -> Dawnkeep -> Warden / equipment / Warband -> Contracts -> visual World Map -> choose reachable territory + risk -> enter giant local territory -> explore / harvest / fight / build temporary defenses -> guardian / regional boss -> loot / claim / Wild Bond chance -> equip / forge / research / recruit / train -> push farther`

The long-term rule is unchanged: **the player should keep inventing a reason to play one more expedition.**

## Current visual production pipeline

The approved provisional atlas uploaded by the user is now a real project asset:

`res://assets/marchbound_assetsprov.png`

All atlas coordinates/semantic IDs are centralized in:

`res://scripts/core/VisualAtlas.gd`

The atlas currently supplies provisional:
- resource and system icons;
- human troops;
- enemies;
- Wild Bond creatures;
- buildings;
- battle effects / pickups;
- World Map territory art.

The atlas is a production bridge, not final art. Final character/equipment work should follow the approved mannequin + modular armor + assembled Warden references.

## Resolution / layout safety

Native design resolution is now **1920×1080**, increased from 1280×720 after the first playtest exposed crowded HUD/result panels.

Minimum practical window remains **1280×720** and canvas stretch uses `expand`.

The expedition result is now a centered, scroll-safe scene whose Continue button remains outside the variable-length loot body, fixing the case where a completed mission could become impossible to exit because the button fell outside the viewport.

## Scene-driven UI status

Important art-direction surfaces are being moved out of procedural GDScript.

### Converted to `.tscn`
- `scenes/ui/ExpeditionLayout.tscn`
- `scenes/ui/ExpeditionResult.tscn`
- `scenes/ui/PaperDoll.tscn`

The Paper Doll no longer depends on its old procedural `_draw()` body composition. Its visible stage, character art, aura, equipment slots and labels are editor-positionable nodes.

### Partially converted / still code-driven
- Main shell/navigation: resource icons are visual, shell still code-built.
- Inventory: Paper Doll is scene-driven, outer 3-column layout still code-built.
- World Map: territory art is atlas-driven and information panel is scroll-safe, shell still code-built.
- Dawnkeep: building art is atlas-driven, draggable world canvas remains custom/code-driven.
- Warband: atlas unit cards + qualities are visible, outer card/layout system still code-built.
- Contracts / Marketplace: still code-built and lower visual priority.

Full audit: `docs/VISUAL_UI_AUDIT.md`.

## Strategic World Map

- effectively unbounded deterministic macro coordinates;
- Dawnkeep anchored at `[0,0]`;
- adjacency/supply-line conquest;
- pannable map window;
- six MVP biomes;
- Threat increases with distance / Frontier Season;
- resource richness;
- boss territories;
- future optional-PvP metadata;
- four objectives: Frontier Claim, Monster Hunt, Resource Sweep, Ruin Siege;
- three risk stances: Standard, Prospector, Blood Oath;
- deterministic Frontier Mutations;
- regional equipment targeting;
- regional Wild Bond targeting;
- macro tiles now use clear atlas territory art rather than primarily text/color buttons.

Every macro World Map territory now advertises a **192×192 local-map target** and a future target capacity of **3 players/Wardens** in that territory.

## Giant local territories

The local expedition prototype is no longer a 900×560 one-screen arena.

Current local map target:
- **192 × 192 local tiles**;
- **64 px tile scale**;
- **36,864 tiles**;
- **12,288 × 12,288 px world-space**.

The current prototype renders only the visible grid/content around the Warden and uses a lightweight camera model, rather than creating 36,864 scene nodes.

The local territory already contains a physical atlas-driven frontier outpost with buildings, roads, resource nodes and environmental props.

This is the base for the intended Necesse + Vampire Survivors local layer.

## Local building during expeditions

Building is now gameplay, not only scenery.

First field-building prototype:
- harvest Wood during the expedition;
- press **B** on a free local grid position;
- spend **6 Wood harvested in that run**;
- build a Field Watchtower;
- watchtowers automatically attack enemies in range;
- placement snaps to the 64 px local grid;
- blocked/overlapping placement is rejected;
- current per-expedition limit is 12 towers.

This is the first step toward local walls, traps, camps, turrets, repair/logistics and resource structures.

## Action combat

- WASD movement;
- auto attack;
- dash with invulnerability;
- Rally and Shockwave;
- Field Watchtower building on B;
- Command-limited army followers;
- biome-specific enemy rosters;
- melee / rush / tank / ranged enemy behaviors;
- hostile projectiles;
- enemy Elites;
- Momentum kill chains;
- harvest nodes;
- 12 stackable Field Doctrines;
- Warden talent hooks;
- unit evolution behavior;
- Wild Bond behavior;
- regional equipment set bonuses;
- Frontier Mutation rules;
- impact feedback / floating text / shake;
- browser-minded entity caps;
- player/allies/enemies/resources/buildings now begin using real atlas sprites instead of only programmer primitives.

## Warband progression

### Founding families
- Militia
- Archer
- War Wolf
- Mage

Each has Rank progression and Rank-3 permanent evolution choices:
- Vanguard / Shieldwall
- Ranger / Longbow
- Dire Wolf / Pack Alpha
- Stormcaller / Lifebinder

### Wild Bonds
- Ridgeback
- Thornkin
- Stone Golem
- Mire Leech
- Ember Imp
- Frost Wisp

Wild Bonds are regional discoveries. Named regional bosses guarantee an undiscovered local bond. Monster Hunt / Elite-heavy territory improves ordinary discovery odds.

## Individual unit quality

Army families now have a persistent individual-unit layer in `player.unit_roster`.

Old saves migrate existing troops into Standard individual records. New recruits can roll a prefix and/or rare Elite classification.

Current prefix chance: **42%**.

Prefixes:
- **Swift** - faster cadence / slightly more reach;
- **Ironhide** - stronger frontline damage;
- **Blessed** - attacks restore some Warden HP;
- **Vicious** - stronger execution against wounded enemies;
- **Ancient** - stronger attacks + extended reach;
- **Stormtouched** - attacks can chain damage.

### Elite
Elite is independent of prefix and fills the emotional/collection role of a shiny-quality unit.

Current provisional roll: approximately **1 / 96** for a newly generated individual.

Elite units currently gain combat multipliers and a distinct visual aura/card treatment. A unit may be both prefixed and Elite.

The Warband screen surfaces individual quality cards using atlas art.

## Warden / equipment progression

- Warden XP and levels;
- six permanent Talent branches;
- Command progression;
- procedural equipment power/rarity;
- slot-specific affixes;
- six biome-bound equipment families;
- 54 authored regional item identities;
- 2pc / 4pc set bonuses;
- named boss provenance on qualifying drops;
- equipment comparison;
- Forge upgrades;
- scene-driven Paper Doll foundation.

The Paper Doll scene is structurally ready for true modular body/armor layers, but final production quality still requires the isolated approved body and modular armor pieces as RGBA/Spine-ready assets rather than relying forever on a cropped combined atlas unit.

## Dawnkeep / economy

- draggable visual settlement;
- atlas-driven building art in the current visual pass;
- Town Hall, Lumberyard, Quarry, Farm, Barracks, Forge, Arcane Lab, Market;
- building upgrades;
- six research branches;
- passive production;
- offline production;
- local layout persistence;
- Renown / Frontier Season scaffold;
- NPC Marketplace proof;
- Frontier Contracts;
- First March onboarding.

## Frontier Mutations

- Swarming Brood
- Frenzied Hunt
- Ironhide Territory
- Marked by Elites
- Rich Veins
- Arcane Storm

Mutations stack with risk stances and change live combat/reward rules.

## Validation status

The repository uses a hardened Godot 4.7.2 CI because Godot can sometimes print script errors while returning exit code 0.

A valid green pass requires:
- clean project parse;
- clean headless main-scene smoke;
- clean Web export;
- generated Web artifact;
- no hidden SCRIPT ERROR/autoload failure in captured logs.

The **Visual Atlas / Giant Local Map / Unit Quality pass is not yet declared validated**. It is currently on `nyra/visual-atlas-pass-v2` and must pass the strict CI before merge.

## Architecture direction

Current phase:
- Godot client;
- GitHub source + strict CI / Web export;
- local/browser persistence.

Planned online phase:
- Supabase Auth/profile/Postgres/cloud state;
- authoritative server-side economy mutations;
- shared world/profile inspection;
- marketplace ledger/escrow;
- realtime authority only where genuinely needed.

The 3-player-per-macro-territory target is a **local-map scale/architecture target**, not a claim that multiplayer networking is implemented today.

## Immediate priorities after this pass

1. Strict CI validation and fix every parse/runtime/Web error.
2. Interactive 1920×1080 and 1280×720 playtest.
3. Verify/correct atlas crop coordinates visually inside Godot.
4. Continue replacing programmer primitives with atlas/SVG assets.
5. Upload isolated Warden body + modular armor layers for the true paper doll.
6. Expand local construction beyond the first watchtower.
7. Add local-map chunk/content generation so the 192×192 territory becomes worth exploring, not merely large empty coordinates.
8. Public browser preview and Chrome persistence/performance testing.

## Documentation rule

Every material gameplay/design/architecture change updates this ledger and, when relevant, `MILESTONES.md`, `CHANGELOG.md` or a focused implementation/audit note.
