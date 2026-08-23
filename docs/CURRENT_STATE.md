# MARCHBOUND — Current State

> Canonical short status ledger. Full design canon lives in `MARCHBOUND_MASTER.md`; implementation-specific schemas live beside this file.

**Last updated:** 2026-08-23  
**Stage:** Pre-Alpha / M1 depth + content expansion  
**Engine:** Godot 4.7.2 · GDScript · Compatibility renderer · browser-first  
**Repository:** `ramonsamagaio/marchbound`

## Current playable loop

`First March → Dawnkeep → equipment / Warband / Contracts → World Map → choose reachable territory + risk → giant local territory → explore / harvest / fight / build field defenses → guardian / regional boss → loot / claim / Wild Bond → equip / forge / research / recruit / train → push farther`

Core long-game rule: **the player should keep inventing a reason to play one more expedition.**

## Strategic World Map

- effectively unbounded deterministic macro coordinates;
- Dawnkeep at `[0,0]`;
- adjacency / supply-line conquest;
- six MVP biomes;
- Threat, resource richness, boss territories and future PvP metadata;
- Frontier Claim / Monster Hunt / Resource Sweep / Ruin Siege objectives;
- Standard / Prospector / Blood Oath risk stances;
- deterministic Frontier Mutations;
- regional loot families and Wild Bond targeting;
- atlas-driven territory art.

Every macro territory currently opens to a **192×192 local-tile target**: 36,864 local tiles / 12,288×12,288 world-space. The architecture reserves a future target capacity of 3 Wardens/players per macro territory.

## Local territory / Necesse layer

Current prototype:
- lightweight player-following camera rather than 36,864 scene nodes;
- physical outpost with buildings and roads;
- biome-weighted resource harvesting;
- local props;
- field construction;
- camera-relative enemy spawning;
- deterministic local ground variation.

First field structure is the **Field Watchtower**, built from Wood harvested in the current run. It snaps to the local grid and automatically attacks enemies.

The new content pass adds **24 local ground identities** across the six current biomes. They are data-driven rather than individual hardcoded arena cases.

## Data-driven Content Spine

A new `ContentDB` autoload moves content identity out of giant combat scripts.

Shipped catalogs:
- `data/content/items.json`
- `data/content/monsters.json`
- `data/content/attacks.json`
- `data/content/projectiles.json`
- `data/content/tiles.json`

Current first catalog size:
- **20 reusable attack definitions**;
- **13 projectile definitions**;
- **26 authored weapon/armor definitions**;
- **36 normal monster identities**;
- **24 local ground variants**.

Runtime editor overrides save to `user://marchbound_content_overrides.json`, which is browser-safe and does not mutate the shipped project.

Schema / authoring guide: `docs/CONTENT_SYSTEM.md`.

## Content Lab

`CONTENT LAB` is now a routable scene-driven tool inside the game shell.

It supports:
- Items / Monsters / Attacks / Projectiles / Tiles categories;
- browse/select entries;
- editable structured JSON;
- atlas preview when an existing visual ID is available;
- relationship summary;
- persistent local/runtime overrides;
- reset-to-shipped-entry;
- attack/projectile reference validation.

Its UI lives in `scenes/ui/ContentEditor.tscn`, so the editor itself is visually adjustable in Godot.

## Weapon / attack architecture

Weapons now separate **content logic from art**.

A weapon can independently define:
- `inventory_sprite` — inventory / loot visual;
- `equipped_sheet` — world-character equipped overlay / sheet;
- `attack_sprite` — temporary visible weapon used during the attack motion;
- `attack_id` — collision + timing behavior;
- `projectile_id` — ranged payload;
- attack speed;
- damage multiplier;
- knockback;
- biome / drop identity.

Current reusable attack modes:
- **melee arc** — sword / axe style sweep;
- **melee thrust** — spear / dagger forward collision corridor;
- **melee slam** — hammer impact radius;
- **ranged** — bow / crossbow / staff / wand / spell projectile release.

All player weapons now have a knockback value, even when small.

When final weapon art is absent, the combat layer can draw deterministic class-shaped placeholders so attack behavior remains readable: sword, axe, spear, dagger, hammer, bow, crossbow, staff and wand.

## Ranged payloads / spells

Ranged weapon behavior is not welded to one projectile.

Current projectile foundations include:
- Wooden / Iron / Ember / Rime arrows;
- Iron bolt;
- Arcane Bolt;
- Ember Orb;
- Frost Shard;
- Void Orb;
- Holy Spark;
- Thorn Spine;
- Acid Glob;
- hostile Hex Bolt.

Projectile data can independently control speed, life, collision radius, pierce, damage multiplier, knockback multiplier, splash radius and future status hooks.

Current spell-flavored attacks include Ember Lance, Frost Shard, Void Orb, Sun Spear and Thorn Burst, alongside Staff Cast and Wand Flick.

## Monster depth

The normal monster catalog now targets six identities per current biome instead of a tiny shared roster.

Examples:
- Greenlands: Raider, Wolf, Slime, Tusk Boar, Bandit Archer, Meadow Shaman;
- Ancient Forest: Bramble Guard, Thorn Hound, Forest Wisp, Bark Guard, Vine Spitter, Lost Dryad;
- Iron Hills: Stone Golem, Cave Bat, Ironclad Deserter, Quarry Rat, Crystal Shardling, Miner Wraith;
- Mistfen: Mire Leech, Bog Slime, Fen Crawler, Mire Spitter, Swamp Witch, Lantern Wisp;
- Ash Wastes: Ember Imp, Cinder Hound, Ash Raider, Magma Beetle, Ember Cultist, Charred Golem;
- Frostwild: Frostling, Ice Wolf, Snow Wisp, Rime Archer, Crystal Yeti, Frost Seer.

Monsters can define behavior, attack, optional projectile, HP/speed/damage multipliers, sprite ID, biome membership and authored drop candidates.

Existing named regional boss patterns remain in place.

## Equipment / loot

Existing systems remain:
- procedural rarity / power;
- affixes;
- Forge upgrades;
- six regional equipment families;
- 54 regional set identities;
- 2pc / 4pc bonuses;
- boss provenance;
- equipment comparison.

The new authored item catalog adds explicit weapon identities and gives new content drops a stable `content_id`. A generated weapon can carry its class, attack, projectile, attack speed, knockback and art links through the normal inventory/save flow.

Inventory detail now exposes weapon behavior and its sprite links for debugging/content production.

## Warband

Founding families:
- Militia;
- Archer;
- War Wolf;
- Mage.

Rank-3 evolution branches:
- Vanguard / Shieldwall;
- Ranger / Longbow;
- Dire Wolf / Pack Alpha;
- Stormcaller / Lifebinder.

Wild Bonds:
- Ridgeback;
- Thornkin;
- Stone Golem;
- Mire Leech;
- Ember Imp;
- Frost Wisp.

Individual units can carry prefixes Swift / Ironhide / Blessed / Vicious / Ancient / Stormtouched plus an independent rare **Elite** classification.

## Visual direction

Two visual scales intentionally coexist:

1. **In-world player / army / enemies:** direction has shifted toward very compact, manually editable pixel sprites. Current production target under exploration is roughly a 24×32 logical character inside a 32×40 cell, with minimal side-view movement cycles and left/right mirroring where useful.
2. **Inventory / inspect / prestige surfaces:** the scene-driven paper-doll foundation remains available for richer equipment presentation.

The provisional atlas and SVG placeholder kit remain implementation bridges, not a requirement that final world sprites share their detail level.

## Scene-driven UI status

Converted to `.tscn` foundations:
- `scenes/ui/MainShell.tscn`;
- `scenes/ui/ExpeditionLayout.tscn`;
- `scenes/ui/ExpeditionResult.tscn`;
- `scenes/ui/PaperDoll.tscn`;
- `scenes/ui/ContentEditor.tscn`.

Still significantly code-driven:
- outer Inventory layout;
- World Map shell;
- Dawnkeep custom canvas;
- Warband cards/layout;
- Contracts / Marketplace.

Full visual audit: `docs/VISUAL_UI_AUDIT.md`.

## Browser / validation

Native design target: **1920×1080**. Minimum practical target: **1280×720**.

CI is intentionally strict because Godot may report script errors while returning exit code 0. A green pass requires:
- project parse;
- headless Main smoke;
- Web export;
- Web artifact;
- no hidden script/autoload failure in captured logs.

The first Depth Content CI correctly rejected loose Variant inference. The strongly typed rewrite then passed **parse + smoke + Web export**.

## Important remaining near-term work

- first hands-on balance/fun pass of the current large-map build;
- public browser preview URL / Chrome persistence and focus test;
- replace provisional in-world art with the newly chosen compact pixel-character language;
- expand in-expedition building beyond the first Watchtower;
- add more reusable spell/attack mechanics after the current primitives are proven fun;
- complete final inventory/item/world sprite asset mapping;
- sound/music/deeper feedback;
- Supabase/auth/cloud/authoritative economy phase;
- shared 2–3 player local-territory prototype later, after the solo loop is strong.
