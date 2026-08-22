# Wild Bonds Pass

## Goal
Turn biome identity into army collection and long-term route planning without exploding the roster into hundreds of species.

## First regional roster
The first pass adds one recruitable creature identity per MVP biome:

- **Greenlands — Ridgeback:** wounded-target hunter. Bonus damage against enemies below 45% HP.
- **Ancient Forest — Thornkin:** living bulwark. Having Thornkin deployed slightly reduces Warden damage taken.
- **Iron Hills — Stone Golem:** heavy breaker. High Command cost, slow cadence, very heavy hits and bonus boss damage.
- **Mistfen — Mire Leech:** sustain predator. Successful attacks restore a small amount of Warden HP.
- **Ash Wastes — Ember Imp:** ranged splash pressure. Attacks splash part of their damage into a nearby enemy.
- **Frostwild — Frost Wisp:** fast ranged pressure. Long reach and high attack cadence.

Each creature has its own Command cost, army Power value, recruitment cost, damage, cadence and attack range.

## Discovery rules
A biome with an undiscovered creature is marked with `♢` on the World Map.

A victorious expedition can form the local Wild Bond when it is not already unlocked.

Base discovery chance is influenced by:
- effective Threat;
- Elite kills;
- **Monster Hunt** objective bonus;
- **Marked by Elites** Frontier Mutation bonus.

Defeating a **named regional boss guarantees** the local Wild Bond if it is still undiscovered. This gives every biome a deterministic pursuit path and prevents collection from becoming pure RNG.

## Persistence and migration
Wild Bond IDs persist under `player.monster_unlocks` inside the normal Marchbound save.

Old saves lazily receive the new schema. Unlocking a species creates safe entries in the existing `army` and `unit_levels` dictionaries, so recruitment, training, Command, Power, autosave and expedition deployment reuse the established systems rather than creating a parallel inventory.

## Warband UX
Unlocked creatures appear in a dedicated **Wild Bonds** section in Warband & Warden.

The UI exposes:
- discovered count out of six;
- biome;
- battlefield role;
- mechanical description;
- current quantity and Rank;
- Command cost;
- recruitment cost;
- Recruit and Train Rank actions.

The founding Militia / Archer / War Wolf / Mage evolution tree remains separate in this pass. Creature evolutions are intentionally deferred until the first six identities have been playtested.

## Strategic effect
Wild Bonds turn biome choice into more than resource and equipment targeting. The player can now route expansion around desired army identities, while boss territories provide a guaranteed collection objective.

## Validation target
The pass must satisfy the hardened Godot 4.7.2 CI gates:
- clean project parse with no hidden `SCRIPT ERROR`;
- clean headless main-scene smoke run;
- successful Web export with a non-empty `index.html`.
