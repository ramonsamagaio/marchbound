# MARCHBOUND — Living Project Bible

> Canonical project memory. Update this file whenever a feature, rule, architecture choice, visual direction or milestone changes.

**Project initiated:** 2026-08-22  
**Engine:** Godot 4.x / GDScript / Compatibility renderer / browser-first  
**Repository:** `ramonsamagaio/marchbound`  
**Primary mandate:** fun immediately, strong repeatable loop, near-infinite progression horizon, and a scope that can actually ship.

## 1. Pitch

MARCHBOUND is a persistent fantasy strategy/action RPG where the player develops a settlement and technology, commands a limited-capacity army across a persistent strategic frontier, personally resolves expeditions in fast top-down action maps, collects modular build-defining gear, trades resources and keeps pushing into increasingly dangerous territory.

The player should repeatedly think: **“one more expedition, then I can afford/unlock/try that.”**

## 2. Reference DNA

MARCHBOUND is not five games glued together. Each reference owns a layer:

- **Heroes of Might & Magic:** world map, hero, army, cities, resource geography, exploration.
- **Necesse:** local-map feel, physical settlement construction direction, crafting/exploration, simple readable graphics.
- **Vampire Survivors:** immediate horde combat, auto-attacks, short-term build choices and escalating run power.
- **Tribal Wars:** persistent economy, territory, asynchronous progression and future player-to-player strategic pressure.
- **RimWorld:** simplified physical settlement layout, production chains and worker-role inspiration without full colonist psychology.
- **Pokémon:** limited party/army capacity, meaningful composition, unit growth/evolution and collection.

## 3. Core loop

1. **Dawnkeep:** collect passive/offline production, upgrade buildings, research, forge and recruit.
2. **Warden / Army:** spend permanent Talent Points, equip a persistent gear build and choose a Command-limited army composition.
3. **World frontier:** inspect biome, threat, richness, objective, regional boss/PvP metadata and strategic position.
4. **Supply line:** patrol owned land or enter an unclaimed orthogonally adjacent tile.
5. **Expedition:** personally enter the territory.
6. **Action:** move, evade, auto-attack, use abilities, direct the army indirectly, harvest resources and build Momentum.
7. **Objective pressure:** the tile objective determines what forces the guardian or regional boss into the open.
8. **Boss encounter:** ordinary tiles use a baseline guardian; Ruin Siege tiles can contain named regional bosses with distinct patterns.
9. **Extraction:** receive resources, XP, Renown and possible affixed equipment.
10. **Loot decision:** compare the drop against the currently equipped piece. A lower-Power item may still be desirable because its affixes support a different build.
11. **Claim:** first victory permanently claims that tile for the current Frontier Season and opens new adjacent territory.
12. **Power conversion:** spend the haul on buildings, research, units, talents and gear.
13. **Push farther:** higher threat, different biomes, objectives and named bosses create the next temptation.
14. **Frontier Season:** prestige-like resets reshape pressure while preserving meaningful meta progression.

## 4. World layer

- Dawnkeep is fixed at world coordinate `[0,0]`.
- World UI is a pannable window over effectively unbounded deterministic coordinates rather than one finite board.
- Territories persist as claimed/unclaimed state in the save.
- New unclaimed tiles are reachable only when orthogonally adjacent to an already claimed tile, producing visible supply lines and frontier shapes.
- First victory in a reachable unclaimed tile claims it and pays a frontier bounty.
- Threat increases primarily with distance from Dawnkeep plus Frontier Season pressure and deterministic local variance.
- Each tile can expose biome, threat, richness, objective, boss identity, future PvP/event/faction metadata and strategic value.
- Named regional boss identity is deterministic from biome, so the player can inspect the danger before committing.
- Long-term shared-world direction remains, but MVP uses deterministic local simulation while the network layer is built.

### Initial biomes
- Greenlands
- Ancient Forest
- Iron Hills
- Mistfen
- Ash Wastes
- Frostwild

## 5. Expedition objectives

Objectives are deterministic tile properties. They should change how the player moves/fights, not merely change enemy HP.

- **Frontier Claim:** baseline territorial run. Survive roughly 44 seconds, then defeat the guardian.
- **Monster Hunt:** aggressive kill target based on Threat. Extra enemy pressure, bonus Gold/XP, and a fail-safe timer.
- **Resource Sweep:** harvest a target number of biome-weighted resource sites while fighting. Bonus construction resources and fail-safe timer.
- **Ruin Siege:** a named regional boss arrives early, is substantially more dangerous and grants improved high-rarity reward odds plus Gold/Mana weighting.

Common final condition: force the territory's final threat into the open and defeat it.

## 6. Combat direction

Target feel: **Necesse + Vampire Survivors**, faster and more active than traditional asynchronous browser strategy combat.

### Player
- Direct WASD movement.
- Auto attack nearest enemy.
- Space dash with short invulnerability window.
- Q Rally army.
- E Shockwave.
- Equipment affixes and permanent talents influence combat identity before the run begins.
- Temporary Field Doctrines create a second build layer inside each run.
- Harvesting and objectives force movement instead of passive edge-circling.
- Bosses must have readable tells so dash timing becomes a deliberate defensive skill.

### Momentum
Fast consecutive kills build a short-lived Momentum chain. Momentum boosts Warden/army damage and every 10-kill threshold pays a small Gold bonus. The design goal is controlled aggression.

### Resource sites
Each expedition spawns several biome-weighted resource sites. Standing beside a site channels a short harvest, granting resources, XP and a small heal. Richer territories spawn more/larger payouts. **Scavenger** talents and **Prospector's** gear affixes increase these yields.

### Combat feel foundation
Implemented before final visual assets:
- screen shake on impacts, boss events and abilities
- floating crit/resource/elite/boss callouts
- hostile projectiles
- dash invulnerability
- elite enemy variants
- browser-minded caps for active enemies and projectiles
- lightweight biome-specific procedural ground markings
- boss-specific procedural silhouettes/projectile colors as temporary visual language

Final game should replace procedural primitives with authored sprites/FX without throwing away the underlying behaviors.

## 7. Enemy identity and regional bosses

### Current regular archetypes
- Raider — baseline melee
- Slime — basic soft-body enemy
- Wolf — fast rush enemy
- Wisp — ranged attacker
- Bramble — Ancient Forest tank
- Golem — Iron Hills / Ash Wastes tank
- Leech — fast Mistfen rush enemy
- Imp — Ash Wastes ranged attacker
- Frostling — Frostwild rush enemy
- Frontier Guardian — ordinary expedition final threat with baseline radial volleys

Behavior classes currently include **melee, rush, tank, ranged and boss**.

### Elites
Non-boss enemies can roll Elite status. Elites are visibly ringed in purple, have substantially higher health/damage, reward extra Gold/XP, and elite kills slightly improve the run's final rarity roll.

### Regional boss rule
Ruin Siege tiles can expose a named regional boss. Boss name and a concise behavior tell appear on the World Map and Expedition HUD before combat. Regional bosses grant a premium Gold/Mana bounty and keep the higher Ruin Siege loot profile.

Current biome names and archetypes:
- **Greenlands — Redfang Matriarch:** Beast archetype.
- **Frostwild — White Maw:** Beast archetype.
- **Ancient Forest — Thorn Regent:** Oracle archetype.
- **Mistfen — Mire Oracle:** Oracle archetype.
- **Iron Hills — Iron Colossus:** Colossus archetype.
- **Ash Wastes — Cinder Titan:** Colossus archetype.

Current mechanical boss archetypes:
- **Beast:** pursues aggressively, telegraphs high-speed charge windows, rewards precise dash timing and punishes lazy kiting.
- **Oracle:** maintains range, fires aimed fan volleys and periodically creates rotating projectile rings that reshape safe space.
- **Colossus:** slow and extremely durable, fires heavy aimed shots and periodically triggers large radial Ground Break eruptions.

The six names intentionally reuse three mechanical foundations for scope efficiency. Future bosses can mutate these foundations with phase changes, summons, terrain interactions and rare event-specific mechanics.

## 8. Field Doctrines / run builds

Current pool has 12 stackable doctrines:
- Edge of War — Warden damage
- Windstep — movement speed
- Quickened Sigil — attack speed
- Twin Oath — additional projectile
- Battle Doctrine — army damage
- Ironblood — max HP / heal
- Executioner's Eye — crit chance and crit strength
- Blood Oath — lifesteal
- Stormbound — attacks can arc into nearby enemies
- Siegebreaker — stronger/larger Shockwave
- War Drums — faster/stronger army attacks
- Marchstep — faster dash recovery and movement

Intended archetypes include Warden carry/crit, Commander army, sustain, mobility and area-control hybrids. The persistent gear layer seeds an archetype before an expedition, while doctrines let it mutate or hybridize during the run.

## 9. Permanent Warden talents

Every Warden level grants one **Talent Point**. New games receive one point immediately.

Current branches, max rank 10 each:
- **Bladecraft:** +8% Warden damage per rank.
- **Ironheart:** +7% max HP per rank.
- **Pathfinder:** +4% movement speed per rank.
- **Commander:** +2 Command capacity per rank.
- **Scavenger:** +12% harvested resource yield per rank.
- **Fortune:** +3% expedition gear-drop chance per rank.

Talents persist in save data and are surfaced in the Warband & Warden screen. Old saves are schema-migrated.

## 10. Army / Command

Army size is constrained by **Command**, not flat headcount.

Initial costs:
- Militia: 1
- Archer: 2
- War Wolf: 3
- Mage: 4

Capacity grows through Warden level, Leadership research, Town Hall, Commander talents and **Bannered** gear affixes.

Current units:
- Militia
- Archer
- War Wolf
- Mage

Long-term: unit ranks and branching evolutions, recruitable monsters, rare boss/event units, faction units, composition synergies and lightweight quick doctrines without individual RTS micromanagement.

## 11. Settlement

Physical-town direction is inspired by Necesse and simplified RimWorld. Current MVP is management UI first; future milestone replaces cards with spatial placement/building.

Current buildings:
- Town Hall
- Lumberyard
- Quarry
- Farmstead
- Barracks
- Forge
- Arcane Lab
- Trade Hall

Settlement produces while offline with sensible caps. UI should always point economic decisions back toward the next frontier push.

## 12. Resources and technology

Core resources: Gold, Wood, Stone, Iron, Food and Mana.

Later biomes add regional materials such as Ancient Wood, Resin, Herbs, Sulfur, Obsidian, Sunstone, Frost Crystal and Silver. Regional scarcity is intentional so trade has strategic value.

Initial research branches: Leadership, Metallurgy, Agriculture, Arcana, Exploration and Commerce. Technology should increasingly unlock mechanics/buildings/item tiers/unit branches, not only percentages.

## 13. Equipment / loot identity / visual identity

Equipment is both a retention pillar and a visual aspiration pillar.

### Visual target
- modular paper-doll character in Inventory and Inspect Player
- base body prepared for Spine animation
- armor attaches as separate RGBA layers
- premium visual quality concentrated in character, gear icons, profiles and Inspect
- cheaper/simpler realtime gameplay sprites in world/local maps

Slots: helm, shoulders, chest, gloves, belt, legs, boots, cape/back, main hand, future off-hand/accessories.

Art direction: polished semi-stylized fantasy, elegant readable silhouettes, anime-influenced concept-art cleanliness, layered armor and modular equipment structure.

### Rarity and affix counts
- Common — 0 affixes
- Uncommon — 1 affix
- Rare — 2 affixes
- Epic — 3 affixes
- Legendary — 4 affixes

Higher Threat improves Power and rarity opportunity. Ruin Siege and Elite kills improve rarity odds.

### Current affix families
- **Sharpened:** flat Warden damage
- **Vigorous:** max HP
- **Fleet:** movement speed
- **Keen:** critical chance
- **Vampiric:** lifesteal
- **Warlord's:** army damage
- **Prospector's:** harvest yield
- **Fortunate:** gear-drop chance
- **Bannered:** Command capacity
- **Blinking:** dash cooldown reduction

Affix pools are slot-specific. Item Power is not the only answer. Inventory compares candidates against equipped gear and exposes both Power delta and special-stat changes.

Current implementation includes procedural gear drops, slot-specific affixes, live equipped-bonus aggregation, inventory comparison, equip, forge upgrades and a functional paper-doll preview.

Other-player Inspect should eventually create aspirational “where did they get that?” moments.

## 14. Marketplace / PvP / social direction

Marketplace long-term: player listings, resources, gear, materials/blueprints, tradable/bound flags, listing fees, taxes, price history, anti-dupe ledger and server-side escrow. Affixes make player-to-player gear trading strategically interesting. MVP has deterministic NPC listings.

PvP is optional by design:
- Kingdom/Core — no PvP
- Frontier — optional/conditional PvP
- Wildlands — PvP enabled with higher rewards

Future social layer: guilds, caravans, regional trade, map influence, asynchronous conflict, world events and cooperative bosses.

## 15. Near-infinite progression strategy

“Infinite” does not mean infinite handcrafted content. Systems create the horizon.

Pillars:
- effectively unbounded deterministic world coordinates
- adjacency-based frontier conquest and supply lines
- escalating threat with distance from Dawnkeep
- deterministic objective variation
- biome-specific encounter composition
- named regional boss encounters
- seasonal frontier advancement/prestige
- Warden levels and talents
- widening Command
- unit ranks/evolutions
- gear rarity + multi-affix combinations + upgrades
- settlement levels and specialization
- technology branches
- Renown
- world bosses/events
- market economy
- guild/territory layer later

The combinatorics of frontier geography, bosses, slots, rarity, affixes, talents, doctrines and army composition provide the long progression horizon without requiring infinite handcrafted content.

## 16. Technical architecture

### Client
- Godot 4.x
- GDScript
- GL Compatibility renderer
- browser export first
- desktop export remains possible later

### Persistence phases
**Phase 1:** local Godot save for fast iteration/browser proof.  
**Phase 2:** Supabase/Postgres for auth/profile/queryable persistent state.  
**Phase 3:** authoritative API/server functions for marketplace, crafting/upgrading, rewards, army/world movement and PvP results.

Never trust the browser client to award itself currency or authoritative competitive results.

### Realtime
Only add a dedicated realtime/game server when a feature truly requires it. Candidates later: Godot headless, Nakama or Colyseus-style services.

### Validation
GitHub Actions validates Godot 4.7.2 project parse, headless main-scene smoke run, Web export and artifact upload. The Regional Boss Pass passed all executable stages before documentation-only follow-up commits.

## 17. Art production pipeline

Preferred flow:
1. visual bible / approved anchors
2. concept directions
3. select direction
4. break into modular slots
5. transparent PNG RGBA game-ready layers
6. consistent naming/pivots/slot conventions
7. Godot import and Spine/rig implementation

Avoid random isolated art generation. Build coherent sets, factions and equipment families.

## 18. Scope guardrails

Do not block the first production slice on full guild wars, 100-player realtime PvP, elaborate siege simulation, ships, dozens of professions, full RimWorld psychology, huge currency zoo, literally infinite streaming or final premium art for every gameplay entity.

The game can feel enormous because systems interlock, not because every possible feature is implemented at once.

## 19. Current implementation snapshot — 2026-08-22

Implemented and validated:
- Dawnkeep `[0,0]`
- persistent adjacency-based frontier conquest
- effectively unbounded deterministic world window
- six biomes
- threat/richness/objective metadata
- four expedition objectives
- biome-weighted enemy rosters
- melee/rush/tank/ranged behavior
- Elite enemies
- ordinary frontier guardians
- six named regional boss variants across three distinct mechanical boss archetypes
- hostile projectiles and multiple boss projectile patterns
- dash invulnerability
- horde scaling and Momentum
- biome resource harvesting
- 12 Field Doctrines
- six persistent Warden talents
- four Command-limited army units
- settlement/passive/offline economy
- eight building families and six tech branches
- rarity-scaled slot-specific gear affixes
- live equipped-build bonuses and inventory comparison
- forge/paper-doll preview
- NPC marketplace proof
- Renown / Frontier Season scaffold
- local save migration
- automated Godot parse/smoke/Web export

## 20. Immediate priorities after Regional Boss Pass

1. **Contracts/quests** that deliberately pull the player toward different biomes, objectives and named bosses, creating short-session goals.
2. **Unit evolution choices** so army progression gains collection/build identity.
3. **Named equipment families / 20+ authored item identities** layered over the procedural affix system.
4. **First browser URL** and interactive Chrome validation.
5. **Visual foundation**: approved body, Spine paper-doll, first armor set, resource icons, settlement/world/combat visual language.
6. **Sound and deeper combat feedback** after the mechanical patterns are stable.
7. User playtest and balance pass focused on the core question: **does the next expedition feel irresistible?**
