# MARCHBOUND — Frontier Mutations Pass

## Goal
Multiply strategic and combat variety without requiring handcrafted maps for every territory.

Threat 2+ territories can roll one deterministic Frontier Mutation. Deep territories at Threat 7+ can roll two. Mutations stack with expedition Risk Stances, so the same biome/objective can still demand different builds and movement decisions.

## Initial mutation pool
- **Swarming Brood** — extra bodies per wave, slightly softer enemies, +15% combat Gold.
- **Frenzied Hunt** — faster/harder-hitting enemies, +20% expedition XP.
- **Ironhide Territory** — +30% enemy HP, +10% gear-drop chance.
- **Marked by Elites** — greatly increased Elite incidence, +15% combat Gold and +6% gear-drop chance.
- **Rich Veins** — +2 harvest sites and +25% site yield.
- **Arcane Storm** — faster hostile projectiles and increased enemy damage, bonus Mana on victory and +4% gear-drop chance.

## Presentation
World tiles carrying mutations display `✦`, show the mutation names, tells and reward hooks before commitment, and keep the modifiers when the player layers Standard / Prospector / Blood Oath on top. Expedition HUD/result screens repeat the active mutation names.

## Technical approach
`FrontierMutations.gd` owns deterministic rolls and composable effects. `MutatedCombatArena.gd` extends the existing evolved/set-aware combat layer instead of duplicating the core combat architecture.

## Validation
This branch runs the standard Godot 4.7.2 gates:
- project parse;
- headless main-scene smoke;
- Web export.
