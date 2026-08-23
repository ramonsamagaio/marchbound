# MARCHBOUND — Retention Gameplay Systems

These systems exist to create meaningful **one-more-expedition** pressure through decisions, buildcraft, attachment and emergent stories. They should not become passive check-in timers, monetization tricks or fake scarcity.

## March Chain

Consecutive victories away from Dawnkeep create a push-your-luck chain.

- Every win increases the chain.
- Previous chain depth multiplies expedition resource loot by +10% per win, capped at +60%.
- Every win adds an unbanked Gold bounty based on Threat and chain depth.
- Returning to Dawnkeep banks the bounty and also grants Renown.
- Losing breaks the chain and destroys the unbanked bounty.

The intended decision is: **bank now, or push one territory deeper?**

## Pursuit

March Chain is not free reward scaling. The frontier reacts to repeated victories.

- Pursuit level equals the current March Chain at expedition start.
- Pursuit scales enemy health, damage and speed moderately.
- Pursuit increases the chance that ordinary spawns become Elites.
- Pursuit 3+ triggers an early Hunter Pack composed of multiple Elites.
- Pursuit is visible when the expedition begins.

Future Pursuit content should add hunter archetypes, ambushes, bounty carriers and anti-build enemies rather than only larger stats.

## Nemesis

A defeat can create a persistent enemy that remembers the Warden.

- If no Nemesis exists when the player loses, one monster from that biome is promoted.
- It receives a generated title, biome identity and combat trait.
- Current traits: Swift, Ironhide, Vicious, Stormtouched, Hexed, Relentless.
- A Nemesis can invade later expeditions in its home biome; Rank 3+ Nemeses can hunt outside it.
- If it survives another player defeat, it gains Rank and becomes stronger.
- Defeating it permanently closes that rivalry and pays Gold, Mana and Renown.

Nemesis should remain a story generator. New traits should change behavior, not only stats.

## Weapon Memories

Weapons remember what they have done.

The equipped weapon gains Memory XP from:
- kills;
- bonus credit for Elites;
- large bonus credit for boss kills.

Memory thresholds: 0 / 60 / 180 / 450 XP.

Memory Rank increases damage, cadence, knockback and crit. Melee weapons also gain reach; fully awakened ranged weapons gain an extra projectile.

Bosses killed with a weapon are stored in that item's `memories` list and surfaced in Inventory.

The goal is to create attachment to a veteran weapon so loot decisions are not always a trivial replacement by the highest Item Power.

Future extension: a Forge inheritance mechanic may allow one Memory to be passed from a sacrificed veteran weapon into a new item.

## Frontier Gambits

Once per expedition, the frontier can interrupt the run with three intentionally dangerous choices.

Each Gambit contains:
- a dramatic immediate boon;
- a mechanical price;
- a victory-only Gold bounty.

Current Gambits include Blood Price, Glass March, Gold Fever, Arcane Overflow, Iron Funeral, Wolf Debt, Grave Invitation, Hungry Forge, Builder Kings and Black Banner.

Gambits stack with gear, Field Doctrines, Frontier Mutations, March Chain and Pursuit. They are designed to produce unusual runs rather than optimal fixed builds.

## Status Reactions

Status effects now form combinations instead of independent debuff icons.

Current reactions:
- **Thermal Shock** — Burning + Chilled; detonates and applies Sundered.
- **Plague Bloom** — Poisoned + Hexed; creates an infectious poison burst.
- **Fracture** — Sundered + Stunned; high burst damage and consumes both setup effects.
- **Witchfire** — Burning + Hexed; violet explosion that spreads Burning.
- **Brittle Venom** — Poisoned + Chilled; burst plus Sundered.

Reaction definitions are data-driven in `data/content/reactions.json`.

## Content validation

`ContentDB.validate_references()` checks cross-catalog links including projectile → status and reaction → status.

CI now contains a dedicated `RetentionSmoke` scene that executes:
1. Content reference validation.
2. Pursuit arena creation.
3. Gambit activation.
4. Enemy spawning.
5. Status application and a live Reaction.
6. Hunter Pack spawning.
7. Nemesis invasion.

The normal strict gates remain: Godot 4.7.2 parse, main-scene smoke and Web export.
