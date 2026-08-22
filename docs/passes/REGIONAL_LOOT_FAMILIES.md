# MARCHBOUND — Regional Loot Families Pass

## Goal
Make loot recognizable by **where it came from**, not only by rarity/affix math.

## Families
Each MVP biome now owns a named 9-slot equipment family, for **54 authored item identities** before affix combinations:

- Greenlands — **Dawnward**
- Ancient Forest — **Briarbound**
- Iron Hills — **Deepforge**
- Mistfen — **Mireglass**
- Ash Wastes — **Cinderborn**
- Frostwild — **Rimebound**

Epic/Legendary gear recovered from named regional bosses can also carry the boss name as provenance in the item name.

## Set bonuses
Each family currently has a 2-piece and 4-piece expedition bonus:

- Dawnward: army damage / army attack speed
- Briarbound: harvest yield / movement speed
- Deepforge: max HP / incoming-damage reduction
- Mireglass: lifesteal / additional lifesteal
- Cinderborn: critical chance / Warden damage
- Rimebound: dash cooldown / movement speed

## Inventory UX
Inventory now exposes family name, lore, equipped piece count, locked/active 2pc and 4pc bonuses, active set summary and boss provenance.

## Validation
This branch exists to run the standard Godot 4.7.2 gates:
- parse project;
- headless main-scene smoke;
- Web export.
