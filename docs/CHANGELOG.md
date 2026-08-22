# MARCHBOUND — Changelog

## 2026-08-22 — Project Start / MVP Foundation
- Name locked as **MARCHBOUND**.
- Project officially initiated.
- Established living documentation requirement so project decisions are not lost.
- Defined game as browser-first persistent fantasy strategy/action RPG.
- Locked core reference layering: Heroes of Might & Magic + Necesse + Vampire Survivors + Tribal Wars + simplified RimWorld + Pokémon-like army capacity/progression.
- Locked strong-loop mandate: Settlement → Army → World Tile → Expedition → Loot → Progress → Harder Frontier.
- Locked near-infinite progression mandate.
- Chosen technical direction: Godot/GDScript/Compatibility, GitHub, later Supabase authoritative backend.
- Implemented initial broad MVP code foundation covering settlement, economy, research, army, world, action expedition, boss, run upgrades, equipment, inventory, marketplace concept, save and Frontier Seasons.
- Visual paper-doll placeholder is intentionally a functional layered rig preview, not final art.

## 2026-08-22 — Frontier Conquest / Combat Loop Pass
- Replaced the finite-feeling world grid with a pannable window over global world coordinates.
- Dawnkeep is fixed at world coordinate `[0,0]`.
- Territories now persist as claimed state in the save game.
- Unclaimed territory can only be entered when connected to the player's current supply line through an adjacent claimed tile.
- First victory in a frontier tile claims it, opens neighboring territory and pays a first-claim bounty.
- Frontier danger now scales primarily with distance from Dawnkeep, preserving an effectively endless outward progression horizon.
- Frontier Season reset now rebuilds territorial claims around Dawnkeep while preserving the season/meta loop.
- Expeditions now contain biome-weighted resource sites that reward movement and risk-taking instead of pure arena circling.
- Standing near a resource site harvests it, awards materials/XP and a small heal.
- Added Momentum kill chains: fast consecutive kills raise temporary Warden/army damage and every 10-kill chain pays an extra Gold reward.
- Expedition result screen now reports harvested sites, best Momentum and whether the territory was newly claimed.
- Settlement summary now surfaces claimed-territory count, highest conquered threat and Renown.

## 2026-08-22 — Objective-Driven Frontier Pass
- World tiles now deterministically advertise an expedition objective before the player commits.
- Added four initial objective flows: **Frontier Claim**, **Monster Hunt**, **Resource Sweep** and **Ruin Siege**.
- Frontier Claim uses survival pressure before the guardian appears.
- Monster Hunt requires aggressive kill progression, adds extra enemy pressure and rewards bonus Gold/XP.
- Resource Sweep requires active harvesting/movement and rewards extra construction materials.
- Ruin Siege spawns an early guardian with increased health/damage and improved high-rarity equipment odds plus Gold/Mana rewards.
- Objective-specific fail-safe timers prevent stalled or unwinnable runs.
- Expedition HUD now exposes live objective progress and clearly signals when the guardian becomes active.
- Result screens identify the objective alongside kills, XP, harvesting, Momentum and loot.
- Refreshed the first-playtest guide around the new loop: Dawnkeep → reachable frontier → objective → guardian → claim → spend → push farther.
- Revalidated the current build in GitHub Actions using Godot 4.7.2: project parse passed, headless main-scene smoke test passed and Web export passed.
- Validation PR #4 was merged; obsolete validation PR #3 was closed.

## 2026-08-22 — M1 Fun Pass 1: Builds, Talents and Enemy Identity
- Added a persistent **Warden Talent** system. Every Warden level awards a Talent Point; new games begin with one point so build identity starts immediately.
- Added six permanent talent branches: **Bladecraft** (damage), **Ironheart** (max HP), **Pathfinder** (movement), **Commander** (Command capacity), **Scavenger** (resource-site yield) and **Fortune** (gear-drop chance).
- Added a dedicated Warden Growth / talent panel to the Warband screen so permanent progression and army construction live together.
- Expanded temporary Field Doctrines from six simple stat boosts to twelve stackable run-build choices including crit, lifesteal, arc damage, improved Shockwave, War Drums and faster dash recovery.
- Added distinct enemy rosters for all six MVP biomes instead of drawing from one global enemy pool.
- Added new enemy identities: Bramble, Golem, Leech, Imp and Frostling alongside the existing Raider, Slime, Wolf and Wisp archetypes.
- Added behavior classes for melee, rush, tank and ranged enemies.
- Added hostile ranged projectiles and guardian radial volleys, giving positioning and dodging more importance.
- Dash now grants a brief invulnerability window, turning movement into active defense instead of pure relocation.
- Added Elite enemy variants. Elites have stronger stats, a visible purple ring and enhanced Gold/XP rewards; elite kills slightly improve end-of-run rarity rolls.
- Added impact feedback through screen shake, floating damage/crit/resource text, Momentum callouts, Elite Down and Guardian Broken callouts.
- Added browser-minded hard caps for active enemies, friendly projectiles and hostile projectiles so density can rise without intentionally allowing runaway entity counts.
- Biomes now also have lightweight procedural ground markings to improve battlefield identity before final art assets arrive.
- Scavenger and Fortune talents are already connected to expedition calculations; Commander directly modifies Command capacity; Bladecraft, Ironheart and Pathfinder modify live combat stats.
- M1 Fun Pass 1 passed Godot 4.7.2 project parsing, the headless main-scene smoke test and Web export in CI before merge.

## 2026-08-22 — M1 Loot Identity / Gear Affix Pass
- Equipment drops now roll **rarity-scaled affixes** instead of functioning mainly as larger Item Power numbers.
- Affix count scales by rarity: Common 0, Uncommon 1, Rare 2, Epic 3, Legendary 4.
- Slots use different weighted affix pools so boots naturally favor mobility, weapons favor offense, shoulders/chest favor army/Command durability, and utility pieces can support harvest or Fortune builds.
- Added the first affix families: **Sharpened**, **Vigorous**, **Fleet**, **Keen**, **Vampiric**, **Warlord's**, **Prospector's**, **Fortunate**, **Bannered** and **Blinking**.
- Equipped affixes now alter actual systems: Warden damage/HP/speed/crit/lifesteal, army damage, Command capacity, harvest yield, gear-drop chance and dash cooldown.
- Epic and Legendary drops can incorporate a rolled affix into their display name, making high-value loot feel less interchangeable.
- Inventory now exposes affixes, combined equipped-build bonuses, same-slot Power comparison and the statistical gains/losses caused by a swap.
- Expedition result screens now expose affix count and individual rolled effects immediately when gear drops.
- Old saves are migrated so existing inventory entries receive safe empty affix arrays without invalidating the save.
- Starter gear bonus keys were normalized to the same live-stat system used by generated affixes.
- Gear Affix Pass passed Godot 4.7.2 project parsing, headless main-scene smoke test and Web export before documentation-only follow-up commits.

## 2026-08-22 — M1 Regional Boss Pass
- Ruin Siege tiles now expose a deterministic **named boss identity** before the expedition begins.
- Added six named biome variants mapped to three mechanical archetypes: **Redfang Matriarch**, **Thorn Regent**, **Iron Colossus**, **Mire Oracle**, **Cinder Titan** and **White Maw**.
- **Beast** bosses use telegraphed high-speed charge windows that reward dash timing and punish passive kiting.
- **Oracle** bosses maintain range, fire aimed projectile fans and periodically create rotating projectile rings that reshape safe space.
- **Colossus** bosses are slower and much tougher, fire heavy aimed shots and trigger large radial Ground Break eruptions.
- Boss archetypes now have visibly different procedural silhouettes and projectile colors even before final authored sprites arrive.
- World Map exposes boss name and a concise behavior tell before the player commits to a Ruin Siege.
- Expedition HUD continues that telegraphing and names the active boss during combat and on the result screen.
- Named regional bosses grant a premium Gold/Mana bounty on top of Ruin Siege rewards.
- Ordinary non-boss expedition guardians preserve the baseline radial-volley behavior, so regional bosses remain special rather than replacing every guardian.
- Regional Boss Pass passed Godot 4.7.2 project parsing, headless main-scene smoke test and Web export before documentation-only follow-up commits.

## 2026-08-22 — M1 Interactive Dawnkeep Pass
- Replaced the settlement's card-grid-first presentation with a visual top-down **Dawnkeep settlement canvas**.
- Added eight procedural building silhouettes with distinct visual identities for Town Hall, Lumberyard, Quarry, Farmstead, Barracks, Forge, Arcane Lab and Trade Hall.
- Roads connect the settlement back toward Town Hall so the city reads as a place rather than a menu.
- Buildings can be selected and upgraded directly from the settlement scene while the Research Council remains accessible alongside it.
- Buildings can be dragged to reshape Dawnkeep; cosmetic layout persists locally in `user://dawnkeep_layout.cfg`.
- Zero-level structures appear as construction states, preserving readability before authored environment assets exist.
- The procedural settlement kit is explicitly temporary scaffolding for future authored visual assets, not the final art target.
- Dawnkeep Scene Pass passed Godot 4.7.2 parsing, headless main-scene smoke and Web export.

## 2026-08-22 — M1 Frontier Contracts Pass
- Added a persistent **Frontier Contract Board** as a parallel retention loop.
- Players can carry up to three optional contracts at once.
- Initial contract families track kills, new territory claims, expedition victories, guardian/boss kills, gear recovery, expedition Gold and reaching higher Threat.
- Completed contracts pay resources plus Renown, giving the player another reason to choose a specific next expedition.
- The available board can be refreshed for Gold, creating a small repeatable economy sink.
- Contract state persists locally while the online backend is not yet authoritative.
- Frontier Contracts Pass passed Godot 4.7.2 parsing, headless main-scene smoke and Web export.

## 2026-08-22 — M1 Expedition Risk Stances Pass
- Added a player-selected risk layer before entering reachable territories.
- **Standard March** keeps the territory at its normal profile.
- **Prospector's Route** raises effective Threat by 1 and resource richness by one tier, creating a deliberate farming-risk choice.
- **Blood Oath** raises effective Threat by 3 so the same territory can become a much harsher test without requiring the player to travel farther first.
- Existing Threat-scaled XP, Renown, loot and enemy/boss systems see the increased risk instead of the stance being only UI flavor.
- Risk Stance Pass passed Godot 4.7.2 parsing, headless main-scene smoke and Web export.

## 2026-08-22 — M1 Unit Evolution Pass
- Added the first permanent unit-evolution tier, unlocked when a base unit family reaches **Rank 3**.
- Added eight branches with two meaningful choices for each initial unit family.
- Militia can become **Vanguard** (boss breaker) or **Shieldwall** (Warden protection).
- Archer can become **Ranger** (fast mobile pressure) or **Longbow** (slow heavy ranged damage).
- War Wolf can become **Dire Wolf** (wounded-target executioner) or **Pack Alpha** (army amplifier).
- Mage can become **Stormcaller** (chain damage) or **Lifebinder** (Warden sustain support).
- Branches change live combat behavior, range, cadence, damage and support effects rather than only renaming units.
- Evolution state is stored inside the existing player save dictionary and old saves receive the schema lazily.
- Warband UI exposes evolution requirements, costs, branch descriptions and the permanent choice.
- The current pre-alpha deliberately has no evolution respec yet so the first balance pass can expose whether choices feel distinct enough.
- Unit Evolution Pass passed Godot 4.7.2 parsing, headless main-scene smoke and Web export.

## 2026-08-22 — M1 Regional Loot Families Pass
- Added six biome-bound equipment families so loot identity reflects **where the player fought**, not only rarity and affix rolls.
- Families are **Dawnward** (Greenlands), **Briarbound** (Ancient Forest), **Deepforge** (Iron Hills), **Mireglass** (Mistfen), **Cinderborn** (Ash Wastes) and **Rimebound** (Frostwild).
- Each family has authored names across all nine current equipment slots, producing **54 named regional item identities** before procedural affix combinations.
- Generated regional gear preserves the existing Power/rarity/affix system while receiving family name, lore and biome provenance.
- Epic/Legendary equipment dropped from named regional bosses can carry boss provenance directly in the displayed item name.
- Added functional 2-piece and 4-piece set bonuses: army damage/cadence, harvest/movement, durability, lifesteal, crit/damage and dash/movement depending on family.
- Inventory now exposes family lore, equipped piece count, active/inactive set bonuses, active set summary and boss provenance.
- Biome selection therefore begins to participate in build planning and targeted loot pursuit, strengthening the reason to revisit regions.
- Regional Loot Families Pass passed Godot 4.7.2 parsing, headless main-scene smoke and Web export.