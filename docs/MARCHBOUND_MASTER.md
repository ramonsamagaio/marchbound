# MARCHBOUND — Living Project Bible

> Canonical project memory. Update this file whenever a feature, rule, architecture choice, visual direction or milestone changes.

**Project initiated:** 2026-08-22  
**Engine:** Godot 4.x / GDScript / Compatibility renderer / browser-first  
**Repository:** `ramonsamagaio/marchbound`  
**Primary mandate:** fun immediately, strong repeatable loop, near-infinite progression horizon, and a scope that can actually ship.

## 1. Pitch

MARCHBOUND is a persistent fantasy strategy/action RPG where the player develops a settlement and technology, commands a limited-capacity army across a persistent strategic frontier, personally resolves expeditions in fast top-down action maps, collects modular gear, trades resources and keeps pushing into increasingly dangerous territory.

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
2. **Warden / Army:** spend permanent Talent Points and choose a Command-limited army composition.
3. **World frontier:** inspect biome, threat, richness, objective, boss/PvP metadata and strategic position.
4. **Supply line:** patrol owned land or enter an unclaimed orthogonally adjacent tile.
5. **Expedition:** personally enter the territory.
6. **Action:** move, evade, auto-attack, use abilities, direct the army indirectly, harvest resources and build Momentum.
7. **Objective pressure:** the tile objective determines what forces the guardian into the open.
8. **Guardian:** defeat the guardian while handling biome enemies, elites and projectiles.
9. **Extraction:** receive resources, XP, Renown and possible equipment.
10. **Claim:** first victory permanently claims that tile for the current Frontier Season and opens new adjacent territory.
11. **Power conversion:** spend the haul on buildings, research, units, talents and gear.
12. **Push farther:** higher threat and different biomes/objectives create the next temptation.
13. **Frontier Season:** prestige-like resets reshape pressure while preserving meaningful meta progression.

## 4. World layer

- Dawnkeep is fixed at world coordinate `[0,0]`.
- World UI is a pannable window over effectively unbounded deterministic coordinates rather than one finite board.
- Territories persist as claimed/unclaimed state in the save.
- New unclaimed tiles are reachable only when orthogonally adjacent to an already claimed tile, producing visible supply lines and frontier shapes.
- First victory in a reachable unclaimed tile claims it and pays a frontier bounty.
- Threat increases primarily with distance from Dawnkeep plus Frontier Season pressure and deterministic local variance.
- Each tile can expose biome, threat, richness, objective, boss state and future PvP/event/faction metadata.
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

Current set:

- **Frontier Claim:** baseline territorial run. Survive roughly 44 seconds, then defeat the guardian.
- **Monster Hunt:** aggressive kill target based on Threat. Extra enemy pressure, bonus Gold/XP, and a fail-safe timer.
- **Resource Sweep:** harvest a target number of biome-weighted resource sites while fighting. Bonus construction resources and fail-safe timer.
- **Ruin Siege:** guardian arrives early, is substantially stronger and has improved high-rarity reward odds plus Gold/Mana weighting.

Common final condition: force the guardian into the open and defeat it.

## 6. Combat direction

Target feel: **Necesse + Vampire Survivors**, faster and more active than traditional asynchronous browser strategy combat.

### Player

- Direct WASD movement.
- Auto attack nearest enemy.
- Space dash with short invulnerability window.
- Q Rally army.
- E Shockwave.
- Equipment and permanent talents influence combat identity.
- Temporary Field Doctrines create a build inside each run.
- Harvesting and objectives force movement instead of passive edge-circling.

### Momentum

Fast consecutive kills build a short-lived Momentum chain. Momentum boosts Warden/army damage and every 10-kill threshold pays a small Gold bonus. The design goal is controlled aggression.

### Resource sites

Each expedition spawns several biome-weighted resource sites. Standing beside a site channels a short harvest, granting resources, XP and a small heal. Richer territories spawn more/larger payouts. **Scavenger** talent increases these yields.

### Combat feel pass 1

Implemented before final visual assets:

- screen shake on impacts, guardian events and abilities
- floating crit/resource/elite/guardian callouts
- hostile projectiles
- guardian radial volleys
- dash invulnerability
- elite enemy variants
- browser-minded caps for active enemies and projectiles
- lightweight biome-specific procedural ground markings

Final game should replace procedural primitives with authored sprites/FX without throwing away the underlying behaviors.

## 7. Enemy identity

Enemy composition is biome-weighted instead of globally random.

Current archetypes:

- Raider — baseline melee
- Slime — basic soft body enemy
- Wolf — fast rush enemy
- Wisp — ranged attacker
- Bramble — Ancient Forest tank
- Golem — Iron Hills / Ash Wastes tank
- Leech — fast Mistfen rush enemy
- Imp — Ash Wastes ranged attacker
- Frostling — Frostwild rush enemy
- Guardian — objective boss archetype with radial projectile volleys

Behavior classes currently include **melee, rush, tank, ranged and boss**.

### Elites

Non-boss enemies can roll Elite status. Elites are visibly ringed in purple, have substantially higher health/damage, reward extra Gold/XP, and elite kills slightly improve the run's final rarity roll.

Long-term target: biome-specific families, named elite modifiers, several regional bosses and event-only enemies.

## 8. Field Doctrines / run builds

Temporary run upgrades are intentionally broader than linear +damage buttons. Current pool has 12 stackable doctrines:

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

Intended archetypes already include at least:

- Warden carry / crit / projectile build
- Commander / War Drums army build
- Sustain / Blood Oath / Ironblood build
- Mobility / Marchstep / Windstep build
- Arc/Shockwave area-control hybrid

The run layer should eventually become pleasantly overpowered without making permanent progression irrelevant.

## 9. Permanent Warden talents

Every Warden level grants one **Talent Point**. New games receive one point immediately so build identity begins before the first expedition.

Current branches, max rank 10 each:

- **Bladecraft:** +8% Warden damage per rank.
- **Ironheart:** +7% max HP per rank.
- **Pathfinder:** +4% movement speed per rank.
- **Commander:** +2 Command capacity per rank.
- **Scavenger:** +12% harvested resource yield per rank.
- **Fortune:** +3% expedition gear-drop chance per rank.

Talents persist in save data and are surfaced in the Warband & Warden screen. Old saves are schema-migrated and receive an initial point when first upgraded to the talent system.

## 10. Army / Command

Army size is constrained by **Command**, not flat headcount.

Initial costs:

- Militia: 1
- Archer: 2
- War Wolf: 3
- Mage: 4

Capacity grows through Warden level, Leadership research, Town Hall and Commander talents, with artifacts/doctrines possible later.

Current units:

- Militia
- Archer
- War Wolf
- Mage

Long-term:

- unit ranks and branching evolutions
- recruitable monsters
- rare boss/event units
- faction units
- composition synergies
- quick doctrines such as Aggressive, Defensive, Follow, Hold, Focus and Retreat
- no individual RTS micromanagement

## 11. Settlement

Physical-town direction is inspired by Necesse and simplified RimWorld. Current MVP is management UI first; future milestone replaces cards with spatial placement/building.

Current building families:

- Town Hall
- Lumberyard
- Quarry
- Farmstead
- Barracks
- Forge
- Arcane Lab
- Trade Hall

Settlement produces while offline with sensible caps. UI should always point economic decisions back toward the next frontier push.

Long-term: walls/towers, workshops, housing, temples, stable, warehouses, specialized production and workers/jobs without full RimWorld psychology simulation.

## 12. Resources and technology

Core resources:

- Gold
- Wood
- Stone
- Iron
- Food
- Mana

Later biomes add regional materials such as Ancient Wood, Resin, Herbs, Sulfur, Obsidian, Sunstone, Frost Crystal and Silver. Regional scarcity is intentional so trade has strategic value.

Initial research branches:

- Leadership
- Metallurgy
- Agriculture
- Arcana
- Exploration
- Commerce

Technology should increasingly unlock mechanics/buildings/item tiers/unit branches, not only percentages.

## 13. Equipment / visual identity

This remains a major perceived-value pillar.

Target:

- modular paper-doll character in Inventory and Inspect Player
- base body prepared for Spine animation
- armor attaches as separate RGBA layers
- premium visual quality concentrated in character, gear icons, profiles and Inspect
- cheaper/simpler realtime gameplay sprites in world/local maps

Slots:

- helm
- shoulders
- chest
- gloves
- belt
- legs
- boots
- cape/back
- main hand
- future off-hand/accessories

Art direction from supplied references:

- polished semi-stylized fantasy
- elegant readable silhouettes
- anime-influenced concept-art cleanliness without demanding equal realtime detail
- layered armor with clear material separation
- modular body/equipment structure

Rarities:

- common
- uncommon
- rare
- epic
- legendary

Other-player Inspect should create aspirational “where did they get that?” moments.

Current MVP has procedural gear drops, inventory/equip, forge upgrades and a functional procedural paper-doll preview. **Gear affixes are the next loot-system priority.**

## 14. Marketplace / PvP / social direction

### Marketplace

Long-term:

- player listings
- resources, gear, selected materials and blueprints
- tradable/bound flags
- listing fees and taxes
- price history
- anti-dupe ledger
- server-side escrow and authoritative purchases

MVP has deterministic NPC listings only to prove the economy/UI loop.

### PvP

PvP is optional by design.

Proposed region categories:

- Kingdom/Core — no PvP
- Frontier — optional/conditional PvP
- Wildlands — PvP enabled with higher rewards

PvP should create risk/reward without turning casual players into mandatory prey.

### Social future

- guild foundations
- caravans / regional trade
- map ownership and influence
- asynchronous conflict where appropriate
- world events
- cooperative world boss prototype

## 15. Near-infinite progression strategy

“Infinite” does not mean infinite handcrafted content. Systems create the horizon.

Current/future pillars:

- effectively unbounded deterministic world coordinates
- adjacency-based frontier conquest and visible supply lines
- escalating threat with distance from Dawnkeep
- deterministic objective variation
- biome-specific encounter composition
- seasonal frontier advancement/prestige
- Warden levels and talents
- widening Command
- unit ranks/evolutions
- gear rarities, upgrades and future affixes
- settlement levels and specialization
- technology branches
- Renown
- world bosses/events
- market economy
- guild/territory layer later

Frontier Seasons currently reset claims back to Dawnkeep, raise frontier pressure and preserve broader progression.

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
**Phase 3:** authoritative API/server functions for economy-sensitive mutations such as marketplace, crafting/upgrading, rewards, army/world movement and PvP results.

Never trust the browser client to award itself currency or authoritative competitive results.

### Realtime

Only add a dedicated realtime/game server when a feature truly requires it. Candidates later: Godot headless, Nakama or Colyseus-style services.

### Validation

GitHub Actions currently validates:

1. Godot 4.7.2 project parse
2. headless main-scene smoke run
3. Web export
4. Web build artifact upload

M1 Fun Pass 1 passed all three executable validation stages before merge.

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

Do not block the first production slice on:

- full guild wars
- 100-player realtime PvP
- elaborate siege simulation
- ships
- dozens of professions
- marriage/breeding
- full RimWorld colonist psychology
- huge currency zoo
- literally infinite world streaming
- final premium art for every gameplay entity

The game can feel enormous because systems interlock, not because every possible feature is implemented at once.

## 19. Current implementation snapshot — 2026-08-22

Implemented and validated foundations now include:

- Dawnkeep `[0,0]`
- persistent adjacency-based frontier conquest
- pannable effectively unbounded deterministic world coordinates
- six biomes
- threat/richness/objective metadata
- four expedition objectives
- biome-weighted enemy rosters
- melee/rush/tank/ranged enemy behavior
- Elite enemies
- hostile projectiles and guardian volleys
- dash invulnerability
- horde scaling
- Momentum kill chains
- biome resource harvesting
- 12 Field Doctrines / multiple run-build directions
- six persistent Warden talents
- four Command-limited army units
- settlement/passive/offline economy
- eight building families
- six technology branches
- equipment/inventory/forge/paper-doll preview
- NPC marketplace proof
- Renown and Frontier Season scaffold
- local save schema migration
- automated Godot parse/smoke/Web export

## 20. Immediate priorities after Fun Pass 1

1. **Gear affixes and equipment identity** so loot changes playstyle, not only Power.
2. **Regional bosses** with mechanics distinct from the generic guardian volley.
3. **Contracts/quests** that deliberately pull the player toward different biomes/objectives and create short-session goals.
4. **Unit evolution choices** so army progression gains collection/build identity.
5. **First browser URL** and interactive Chrome validation.
6. **Visual foundation**: approved body, Spine paper-doll, first armor set, resource icons, settlement/world/combat visual language.
7. User playtest and balance pass focused on the core question: **does the next expedition feel irresistible?**
