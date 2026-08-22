# MARCHBOUND — Unit Evolution Pass

## Purpose
Turn base unit ranks into long-term identity choices that materially change expedition combat.

## First evolution gate
A unit family unlocks its first permanent branch at **Rank 3**. The current pre-alpha does not offer respec; that constraint is intentional for the first balance/playtest pass.

## Branches

### Militia
- **Vanguard** — boss breaker: stronger normal attacks and a large bonus against guardians/regional bosses.
- **Shieldwall** — Warden guard: deployed Militia reduce incoming Warden damage and gain a smaller damage increase.

### Archer
- **Ranger** — mobile pressure: much faster attacks and longer range with a minor per-shot damage tradeoff.
- **Longbow** — heavy ranged damage: very long range and much stronger shots at a slower cadence.

### War Wolf
- **Dire Wolf** — executioner: higher/faster damage with a large bonus against wounded enemies.
- **Pack Alpha** — army amplifier: stronger wolf attacks and a global army-damage buff while wolves are deployed.

### Mage
- **Stormcaller** — chain damage: primary attacks chain into nearby targets.
- **Lifebinder** — sustain support: faster attacks with lower damage, healing the Warden on successful casts.

## Persistence
Evolution choices live inside the existing saved `player` dictionary under `unit_evolutions`, so old saves migrate lazily when the Warband or expedition layer first requests the schema.

## Validation target
This branch exists to run the standard Godot 4.7.2 gates:
- parse project;
- headless main-scene smoke;
- Web export.
