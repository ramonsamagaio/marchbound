# MARCHBOUND — Current State

> Short canonical status ledger. Update this file whenever a development pass materially changes what is playable. The full design canon remains in `MARCHBOUND_MASTER.md`; historical changes remain in `CHANGELOG.md` and focused pass notes.

**Last updated:** 2026-08-22  
**Stage:** Pre-Alpha / M1 loop-and-fun expansion  
**Engine:** Godot 4.7.2, GDScript, Compatibility renderer, browser-first  
**Repository:** `ramonsamagaio/marchbound`

## Playable loop now

`First March guidance → Dawnkeep → choose/upgrade army + Warden build → train/evolve unit families → inspect Contracts → choose reachable frontier tile → choose risk stance → objective expedition → harvest + Momentum + boss → regional loot/claim → equip/set-build/forge/build/research → collect Contracts → push farther`

The design target remains: **the player should keep inventing a reason to play one more expedition.**

## First March onboarding

New/unfinished saves see a compact non-blocking ribbon in the main shell. It disappears during expeditions and permanently hides once completed. It never prevents free navigation.

The four rewarded goals teach the real loop:
1. **Choose Your Oath** — spend the first Warden Talent Point. Reward: 100 Gold + 80 Food.
2. **Raise the Warband** — recruit one more unit or train any unit family to Rank 2. Reward: 120 Gold + 60 Iron.
3. **Take the First Step** — claim one territory beyond Dawnkeep. Reward: 160 Gold + 100 Wood + 80 Stone.
4. **Turn Blood Into Growth** — upgrade a building or complete one research tier. Reward: 15 Renown + a Rare Dawnward **Sunwatch Helm** with Bannered (+1 Command) and Vigorous (+14 HP).

The final reward deliberately introduces regional set gear through play rather than a text tutorial. Progress lives inside `player.first_march` in the normal save and old saves receive the schema lazily.

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
- first unit-evolution combat layer with branch-specific range, cadence, damage, sustain and army-support behavior;
- regional equipment set bonuses feed back into combat, harvesting, movement and army performance;
- impact feedback, floating text and screen shake;
- browser-minded active-entity caps.

## Current persistent progression

- Warden XP and levels;
- six Warden Talent branches;
- Command capacity progression;
- four base unit families and unit ranks;
- permanent first-tier unit evolutions unlocked at Rank 3;
- eight evolution branches with two choices per unit family;
- settlement buildings and upgrades;
- six research branches;
- passive and offline economy;
- local save persistence;
- procedural gear power/rarity and slot-specific affixes;
- six biome-bound equipment families with 54 authored item identities;
- 2pc / 4pc set bonuses;
- boss provenance on qualifying high-rarity drops;
- equipment comparison and Forge upgrades;
- Renown and Frontier Season prestige scaffold;
- NPC Marketplace proof;
- persistent optional Frontier Contract Board;
- persistent First March onboarding state.

## Regional equipment families

Every MVP biome now owns a recognizable equipment family. A generated drop keeps procedural Power/rarity/affixes, but receives an authored regional identity and can contribute to set bonuses.

- **Greenlands — Dawnward:** command/army identity. 2pc gives army damage; 4pc improves army attack cadence.
- **Ancient Forest — Briarbound:** gathering/mobility identity. 2pc improves harvest yield; 4pc improves movement.
- **Iron Hills — Deepforge:** durability identity. 2pc increases max HP; 4pc reduces incoming damage.
- **Mistfen — Mireglass:** sustain identity. 2pc grants lifesteal; 4pc adds more lifesteal.
- **Ash Wastes — Cinderborn:** aggression identity. 2pc adds critical chance; 4pc increases Warden damage.
- **Frostwild — Rimebound:** evasive mobility identity. 2pc shortens dash cooldown; 4pc improves movement.

Each family currently has authored names for weapon, helm, shoulders, chest, gloves, belt, legs, boots and cape, producing **54 named regional item identities** before procedural affix combinations. Epic/Legendary equipment from named regional bosses may also carry boss provenance in the displayed name.

Inventory exposes family lore, current equipped-piece count, 2pc/4pc bonus state and active set summary. This makes biome choice part of build planning instead of only resource geography.

## Unit evolution — current first tier

The first permanent branch unlocks when a base unit family reaches **Rank 3**. Current pre-alpha choices do not have respec yet.

### Militia
- **Vanguard** — boss breaker. Stronger attacks with a large bonus against guardians/regional bosses.
- **Shieldwall** — Warden guard. Deployed Militia reduce incoming Warden damage and gain a smaller damage increase.

### Archer
- **Ranger** — mobile pressure. Much faster attacks and longer range with a minor per-shot damage tradeoff.
- **Longbow** — heavy ranged damage. Very long range and much stronger individual shots at a slower cadence.

### War Wolf
- **Dire Wolf** — executioner. Higher/faster damage with a large bonus against wounded targets.
- **Pack Alpha** — army amplifier. Stronger wolves and a global army-damage buff while wolves are deployed.

### Mage
- **Stormcaller** — chain damage. Primary attacks arc into nearby targets.
- **Lifebinder** — sustain support. Faster casts with reduced damage; successful attacks heal the Warden.

Evolution choices are stored inside the existing player save dictionary under `unit_evolutions`, allowing old saves to receive the schema lazily instead of requiring a destructive reset.

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

Validated passes include the objective frontier loop, M1 combat/talent/enemy pass, gear-affix pass, regional-boss pass, interactive Dawnkeep pass, Frontier Contracts pass, expedition risk-stance pass, first unit-evolution pass, regional-loot-families pass and First March onboarding pass.

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

1. **Public browser preview URL + Chrome persistence/performance validation.**
2. **Visual Bible v1 + approved body base + first modular armor set**, then replace procedural/placeholder visuals strategically.
3. **Second-tier unit evolution / monster recruitment design**, once the first evolution choices have been playtested.
4. First Supabase-backed account/profile/cloud-save slice after the local loop is judged fun.
5. Deeper itemization later: unique boss relics, regional crafting and set-targeting systems.

## Rule for future updates

Every material gameplay/design/architecture change should update at least:
- this file (`CURRENT_STATE.md`);
- `MILESTONES.md` when milestone status changes;
- a focused pass note or `CHANGELOG.md` when historical detail matters.