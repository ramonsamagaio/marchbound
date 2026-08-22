# MARCHBOUND — Living Project Bible

> Canonical project memory. Update this file whenever a feature, rule, architecture choice, visual direction or milestone changes.

**Project initiated:** 2026-08-22  
**Engine direction:** Godot 4.x, GDScript, Compatibility renderer, browser-first  
**Primary design mandate:** fun immediately, a strong repeatable loop, and a near-infinite long-term progression horizon.

## 1. One-sentence pitch

MARCHBOUND is a persistent fantasy strategy/action RPG where the player develops a settlement and technology, commands a limited-capacity army across a shared strategic world map, and personally resolves expeditions in fast top-down action maps while building an economy, collecting modular gear, trading and pushing into increasingly dangerous frontiers.

## 2. Reference DNA

MARCHBOUND is not five games glued together. Each reference owns a layer:

- **Heroes of Might & Magic:** world map, hero, army, cities, resource geography, exploration.
- **Necesse:** local-map feel, physical settlement construction, crafting/exploration, simple readable graphics.
- **Vampire Survivors:** immediate action, hordes, auto-attacks/build choices, short-term power curves during runs.
- **Tribal Wars:** persistent economy, territory, asynchronous progression, player-to-player strategic layer.
- **RimWorld:** simplified physical settlement layout, production chains and worker-role inspiration without full colonist psychology.
- **Pokémon:** limited party/army capacity, meaningful composition, unit growth/evolution and collection.

## 3. Core loop

1. Settlement: collect passive production, build, research, forge, recruit.
2. Army preparation: spend Command capacity on a chosen composition.
3. World map: evaluate biome, threat, richness, boss/PvP properties and strategic value.
4. Expedition: enter the tile personally.
5. Action: WASD movement, dash, active abilities, Warden auto-attacks, army AI, enemy hordes, run upgrades.
6. Extraction: survive/kill boss, return with resources, XP, renown and equipment.
7. Power conversion: upgrade settlement, research, units and gear.
8. Push farther: higher-threat territory yields better rewards.
9. Season/frontier advancement: reset/expand portions of world pressure while preserving meaningful meta-progression.
10. Repeat with more possibilities, not merely larger numbers.

The player should repeatedly think: **“one more expedition, then I can afford/unlock/try that.”**

## 4. World layer

- Large strategic world divided into tiles/territories.
- Huge biomes and difficulty bands.
- Each tile may expose threat, resource richness, rare resources, faction influence, PvP state, event/boss state.
- Safe/core lands, optional PvP frontier, and later high-risk Wildlands.
- Resource geography creates organic trade and diplomacy.
- World events and bosses create social convergence.
- Long-term direction is a shared persistent world, but MVP may use deterministic local simulation while network layer is built.

### Initial biomes
- Greenlands
- Ancient Forest
- Iron Hills
- Mistfen
- Ash Wastes
- Frostwild

## 5. Combat / expedition layer

Target feel: **Necesse + Vampire Survivors**, faster and more direct than asynchronous browser strategy combat.

Player:
- Direct movement.
- Auto/basic attacks for accessibility and horde readability.
- Dash.
- Active abilities.
- Equipment stats and build identity.
- Temporary run upgrades.

Army:
- Follows hero with lightweight AI.
- Unit types have simple tactical identity.
- Player can later issue quick doctrines such as Aggressive, Defensive, Follow, Hold, Focus and Retreat.
- No individual RTS micromanagement.

MVP controls:
- WASD movement
- Space dash
- Q Rally
- E Shockwave
- Auto attack nearest enemy

## 6. Command capacity

Army size is constrained by **Command**, not a flat headcount.

Initial costs:
- Militia: 1
- Archer: 2
- War Wolf: 3
- Mage: 4

Capacity grows through player level, Leadership research, Town Hall, passive skills, equipment/artifacts and future doctrines. This makes quantity and quality compete for the same strategic budget.

## 7. Units

Initial MVP:
- Militia
- Archer
- War Wolf
- Mage

Long-term:
- branching upgrades/evolutions
- recruitable monsters
- rare boss/event units
- faction units
- unit ranks/levels
- composition synergies
- doctrines

## 8. Settlement

Physical town/local-map direction inspired by Necesse and simplified RimWorld.

Initial building families:
- Town Hall
- Lumberyard
- Quarry
- Farmstead
- Barracks
- Forge
- Arcane Lab
- Trade Hall

Long-term: walls/towers, workshops, housing, temples, stable, warehouses, specialized production and workers/jobs without full RimWorld psychological simulation.

The town continues producing while the user is offline, with sensible caps.

## 9. Resources

Core resources:
- Gold
- Wood
- Stone
- Iron
- Food
- Mana

Later biomes add regional materials such as Ancient Wood, Resin, Herbs, Sulfur, Obsidian, Sunstone, Frost Crystal, Silver, etc. Regional scarcity is intentional so trade is strategically valuable.

## 10. Technology

Initial branches:
- Leadership
- Metallurgy
- Agriculture
- Arcana
- Exploration
- Commerce

Long-term tech should visibly unlock buildings, item tiers, unit branches and mechanics, not only percentage bonuses.

## 11. Equipment / visual identity

This is a major perceived-value pillar.

Target:
- modular paper-doll character in Inventory and Inspect Player
- base body prepared for Spine animation
- armor attaches as separate RGBA visual layers
- premium visual quality in paper-doll, gear icons, inventory, profiles and inspect
- cheaper/simpler gameplay sprites in local/world maps

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

Desired art direction from references supplied by the user:
- polished semi-stylized fantasy
- elegant readable silhouettes
- anime-influenced concept-art cleanliness without requiring equivalent realtime world detail
- layered armor with clear material separation
- modular body/equipment structure

Rarities:
- common
- uncommon
- rare
- epic
- legendary

Other players' Inspect profile should show the paper-doll and create aspirational “where did they get that?” moments.

## 12. Marketplace

Long-term:
- player listings
- resources
- gear
- selected materials / blueprints
- tradable/bound flags
- listing fees
- price history
- taxes
- anti-dupe ledger
- server-side escrow / authoritative purchasing

MVP currently contains deterministic NPC listings only to prove economy/UI loop.

## 13. PvP

Optional by design.

Proposed region categories:
- Kingdom/Core: no PvP
- Frontier: optional/conditional PvP
- Wildlands: PvP enabled, with higher rewards

PvP should create risk/reward without forcing casual players to become prey.

## 14. Bosses / events

- regional bosses
- tile bosses
- world events
- later cooperative world bosses
- reward tables that justify travel and danger

MVP expedition spawns a boss after a short survival phase.

## 15. Near-infinite progression strategy

“Infinite” does not mean infinite handcrafted content. It means systems create a horizon.

Pillars:
- escalating frontier threat
- procedural/deterministic world seeds
- seasonal frontier advancement
- player levels with widening Command
- unit ranks/evolutions
- gear rarities/upgrades/affixes later
- settlement levels and specialization
- tech branches
- renown
- world bosses/events
- market economy
- future guild/territory layer

A later prestige-like **Frontier Season** system can reshape/expand world pressure while preserving key accomplishments.

## 16. Technical architecture

### Client
- Godot 4.x
- GDScript
- Compatibility renderer
- browser export first
- same project should remain desktop-exportable later

### Version control
- GitHub repository: `ramonsamagaio/marchbound`

### Persistence
Phase 1: local Godot save for fast iteration and browser proof.

Phase 2: Supabase/Postgres for auth/profile/storage/queryable persistent state.

Phase 3: authoritative API/server functions for economy-sensitive mutations: buy/sell, crafting, upgrading, collect rewards, army/world movement, marketplace and PvP/results. Never trust the browser client to award itself currency.

### Realtime
Only add a dedicated realtime/game server when a feature truly requires it. Options to evaluate later include Godot headless, Nakama or Colyseus-style services.

## 17. Art production pipeline

Preferred flow:
1. visual bible / approved anchor references
2. concept directions
3. select direction
4. break into modular slots
5. transparent PNG RGBA game-ready layers
6. name/pivot/slot conventions
7. Godot import and Spine/rig implementation

Avoid random isolated art generation. Build coherent sets and factions.

## 18. Non-goals for first production slice

Do not block MVP on full guild wars, 100-player realtime PvP, elaborate siege simulation, ships, dozens of professions, marriage/breeding, full RimWorld colonist psychology, a huge currency zoo, fully infinite world streaming or final premium art for every gameplay entity.

## 19. MVP mandate

The first playable slice should already demonstrate settlement, passive/offline economy, buildings, tech, army recruitment/ranks/Command, world map, biomes/threat, real action expedition, player movement/combat, army followers, hordes, boss, run upgrades, loot/resources/XP, equipment drops, inventory/paper-doll concept, gear upgrades, marketplace concept, Renown/Frontier Seasons and save persistence.
