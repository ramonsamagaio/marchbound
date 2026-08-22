# MARCHBOUND — First March Onboarding Pass

## Goal
Teach the real retention loop without freezing the player inside a modal tutorial.

The First March appears as a compact persistent ribbon outside expeditions. Each step can be completed naturally, exposes one relevant navigation shortcut, and only asks the player to claim a reward after the condition is actually met.

## Sequence
1. **Choose Your Oath** — spend the first Warden Talent Point.
2. **Raise the Warband** — recruit one more unit or train any unit family to Rank 2.
3. **Take the First Step** — claim one territory beyond Dawnkeep.
4. **Turn Blood Into Growth** — upgrade a building or complete one research tier.

## Rewards
- Step 1: 100 Gold + 80 Food.
- Step 2: 120 Gold + 60 Iron.
- Step 3: 160 Gold + 100 Wood + 80 Stone.
- Final: 15 Renown + a Rare **Sunwatch Helm** from the Dawnward regional family, with Bannered (+1 Command) and Vigorous (+14 HP) affixes.

The final reward deliberately introduces the regional-set system as part of the onboarding rather than through explanatory text.

## Persistence
Progress is stored inside `player.first_march` in the existing main save. Old saves receive the schema lazily. Completed onboarding disappears from the shell permanently for that save.

## Validation
This branch runs the standard Godot 4.7.2 gates:
- project parse;
- headless main-scene smoke;
- Web export.
