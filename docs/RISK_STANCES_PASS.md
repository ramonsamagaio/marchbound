# Expedition Risk Stances

Before entering an accessible territory, the player now chooses how aggressively to approach it.

- **Standard March**: uses the tile's normal Threat and richness.
- **Prospector's Route**: +1 effective Threat and +1 resource-richness tier (capped at Abundant), increasing resource-site count/yield while also strengthening combat.
- **Blood Oath**: +3 effective Threat. This sharply increases enemy/boss scaling while feeding the existing Threat-based XP, Renown, first-claim payout and gear-rarity systems.

The stance is copied into the selected expedition tile as `risk_stance`, alongside `base_threat`. The world tile itself is not permanently rewritten. This means the same territory can become a different risk/reward decision on repeat patrols without corrupting deterministic world generation.

Design goal: let strong builds manufacture their own danger instead of waiting to walk many tiles farther from Dawnkeep, and let players use a familiar territory as a controlled test bench for new gear/army builds.
