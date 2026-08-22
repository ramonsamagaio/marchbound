# MARCHBOUND — Current State

> Short canonical status ledger. Update this file whenever a development pass materially changes what is playable. The full design canon remains in `MARCHBOUND_MASTER.md`; historical changes remain in `CHANGELOG.md` and focused pass notes.

**Last updated:** 2026-08-22  
**Stage:** Pre-Alpha / M1 loop-and-fun expansion  
**Engine:** Godot 4.7.2, GDScript, Compatibility renderer, browser-first  
**Repository:** `ramonsamagaio/marchbound`

## Playable loop now

`Dawnkeep → choose/upgrade army + Warden build → inspect Contracts → choose reachable frontier tile → choose risk stance → objective expedition → harvest + Momentum + boss → loot/claim → equip/forge/build/research → collect Contracts → push farther`

The design target remains: **the player should keep inventing a reason to play one more expedition.**

## Current strategic/world systems

- effectively unbounded deterministic world coordinates;
- Dawnkeep anchored at `[0,0]`;
- pannable world-map window;
- persistent adjacency-based territory conquest / supply lines;
- six MVP biomes;
- Threat scaling with distance and Frontier Season pressure;
- resource richness, boss identity and future-PvP metadata;
- four expedition objectives: Frontier Claim, Monster Hunt, Resource Sweep, Ruin Siege;
- named regional bosses with Beast, Oracle and Colossus mechanical archetypes;
- three player-selected risk stances:
  - Standard March;
  - Prospector's Route (+1 Threat, +1 richness tier);
  - Blood Oath (+3 effective Threat and corresponding Threat-scaled reward potential).

## Current action-combat systems

- direct WASD movement;
- auto attack;
- dash with invulnerability timing;
- Rally and Shockwave active abilities;
- Command-limited army followers;
- biome-specific enemy rosters;
- melee/rush/tank/ranged enemy behaviors;
- hostile projectiles;
- elite enemies;
- Momentum kill chains;
- biome-weighted harvest nodes inside combat;
- 12 stackable Field Doctrines creating multiple run-build directions;
- crit/lifesteal/arc/army/dash/etc build hooks;
- impact feedback, floating text and screen shake;
- browser-minded active-entity caps.

## Current persistent progression

- Warden XP and levels;
- six Warden Talent branches;
- Command capacity progression;
- four base unit types and unit ranks;
- settlement buildings and upgrades;
- six research branches;
- passive and offline economy;
- local save persistence;
- procedural gear drops;
- rarity-scaled slot-specific affixes;
- equipment comparison and Forge upgrades;
- Renown and Frontier Season prestige scaffold;
- NPC Marketplace proof;
- persistent optional Frontier Contract Board.

## Frontier Contracts

Up to three active contracts can be carried simultaneously. Current families track:
- kills;
- new territory claims;
- expedition victories;
- guardian/boss kills;
- equipment recovery;
- expedition Gold earnings;
- reaching higher Threat.

Contracts reward resources + Renown. The available board can be refreshed for Gold, creating a small economy sink. Contract state currently persists in browser/local storage separately from the main save while the online backend is not yet authoritative.

## Dawnkeep now

Dawnkeep is no longer only management cards.

- visual settlement canvas;
- eight distinct procedural building silhouettes;
- roads connect structures back to Town Hall;
- buildings can be clicked and upgraded directly;
- buildings can be dragged to reshape the city;
- cosmetic layout saves locally to `user://dawnkeep_layout.cfg`;
- zero-level structures appear as construction states;
- Research Council / Frontier Season controls remain integrated;
- procedural visuals are explicitly a bridge toward authored RGBA/Spine/scene assets, not final art.

## Visual direction still locked

High perceived-value art is concentrated in:
- Inventory / Inspect Player;
- modular paper-doll character;
- equipment and weapon presentation;
- portraits/icons/UI;
- aspirational other-player inspection.

World/combat art can stay graphically simpler and highly readable to preserve browser performance and scope.

## Validation status

The following major passes have each completed all three CI gates with Godot 4.7.2:
- project parse;
- headless main-scene smoke run;
- Web export.

Validated passes include the objective frontier loop, M1 combat/talent/enemy pass, gear-affix pass, regional-boss pass, interactive Dawnkeep pass, Frontier Contracts pass and expedition risk-stance pass.

## Architecture direction

Current fast-iteration phase:
- Godot client;
- GitHub source control + automated Web build;
- local/browser persistence.

Planned online phase:
- Supabase Auth + Postgres/profile/cloud state;
- authoritative server-side mutations for economy-sensitive actions;
- online marketplace/escrow/ledger;
- shared world/profile inspection;
- realtime server only for features that genuinely require it.

## Highest-priority next passes

1. **First unit evolution branches** so army composition gains Pokémon/Heroes-like long-term identity beyond rank numbers.
2. **Named equipment families / 20+ authored loot identities** on top of the affix generator.
3. **Onboarding** that teaches the loop without turning the first session into a tutorial prison.
4. **Public browser preview URL + Chrome persistence/performance validation.**
5. **Visual Bible v1 + approved body base + first modular armor set**, then replace procedural/placeholder visuals strategically.
6. First Supabase-backed account/profile/cloud-save slice after the local loop is judged fun.

## Rule for future updates

Every material gameplay/design/architecture change should update at least:
- this file (`CURRENT_STATE.md`);
- `MILESTONES.md` when milestone status changes;
- a focused pass note or `CHANGELOG.md` when historical detail matters.
