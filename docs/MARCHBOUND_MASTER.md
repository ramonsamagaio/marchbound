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
3. World map: evaluate biome, threat, richness, objective, boss/PvP properties and strategic value.
4. Frontier choice: patrol owned land or claim an adjacent unowned territory connected to the supply line.
5. Expedition: enter the tile personally.
6. Action: WASD movement, dash, active abilities, Warden auto-attacks, army AI, enemy hordes, run upgrades, resource-site harvesting and Momentum kill chains.
7. Objective pressure: the tile's objective determines what forces the guardian into the open.
8. Extraction: kill the guardian, return with resources, XP, renown and equipment.
9. Claim: first victory permanently claims that territory for the current Frontier Season and opens adjacent territory.
10. Power conversion: upgrade settlement, research, units and gear.
11. Push farther: higher-threat territory yields better rewards.
12. Season/frontier advancement: reset/expand portions of world pressure while preserving meaningful meta-progression.
13. Repeat with more possibilities, not merely larger numbers.

The player should repeatedly think: **“one more expedition, then I can afford/unlock/try that.”**

## 4. World layer

- Large strategic world divided into tiles/territories.
- Dawnkeep, the player capital, is anchored at world coordinate `[0,0]`.
- The world-map UI is a pannable window over effectively unbounded deterministic coordinates rather than a single finite board.
- Territories persist as claimed/unclaimed state in the save game.
- New unclaimed tiles are reachable only when orthogonally adjacent to an already claimed territory. This creates a visible supply-line/frontier shape.
- First victory in a reachable unclaimed tile claims it and pays an extra frontier bounty.
- Threat increases primarily with distance from Dawnkeep plus Frontier Season pressure and deterministic local variance.
- Huge biomes and difficulty bands.
- Each tile may expose threat, resource richness, objective, rare resources, faction influence, PvP state and event/boss state.
- Safe/core lands, optional PvP frontier, and later high-risk Wildlands.
- Resource geography creates organic trade and diplomacy.
- World events and bosses create social convergence.
- Long-term direction is a shared persistent world, but MVP uses deterministic local simulation while network layer is built.

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
- Movement incentives from resource harvesting and objectives, so optimal play is not just orbiting the arena edge.

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

### Expedition objectives
Objectives are deterministic properties of world tiles. They alter player behavior, guardian timing/strength and reward weighting while retaining a common readable win condition: force the guardian into the open and defeat it.

Current MVP objective set:

- **Frontier Claim:** baseline territorial expedition. Survive approximately 44 seconds, then defeat the guardian. Balanced reward profile.
- **Monster Hunt:** aggressive combat objective. Reach a kill target based on Threat to spawn the alpha; higher enemy pressure, bonus Gold and XP. A time fail-safe prevents a stalled run.
- **Resource Sweep:** movement/extraction objective. Harvest a target number of biome-weighted resource sites to awaken the guardian; bonus construction materials. A time fail-safe prevents a soft lock.
- **Ruin Siege:** special boss territory. Guardian arrives early, has substantially higher health/damage and improved high-rarity gear odds plus bonus Gold/Mana.

Objective progress is visible live in the expedition HUD. The design goal is for adjacent world tiles to represent different play decisions, not merely different numerical difficulty.

### Momentum
Fast consecutive kills build a short-lived Momentum chain. Momentum temporarily increases Warden and army damage. Each 10-kill threshold also awards a small Gold bonus. The intended feel is controlled aggression: the player has a reason to keep moving toward the next pack rather than merely survive passively.

### Resource sites
Each expedition spawns several biome-weighted resource sites. Standing beside one for a short channel harvests it, adding resources/XP and a small heal. Richer territories spawn more sites and larger payouts. This turns resource geography into something the player physically experiences in the action layer.

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

Settlement UI should surface strategic frontier progress, including claimed-territory count, highest conquered threat and Renown, so economic upgrading always points back toward the next expedition.

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
- tile guardians
- special Ruin Siege guardians
- world events
- later cooperative world bosses
- reward tables that justify travel and danger

MVP guardian timing is objective-driven rather than always timer-driven.

## 15. Near-infinite progression strategy

“Infinite” does not mean infinite handcrafted content. It means systems create a horizon.

Pillars:
- effectively unbounded deterministic world coordinates
- adjacency-based frontier conquest and visible supply lines
- escalating threat with distance from Dawnkeep
- deterministic objective variation across the frontier
- seasonal frontier advancement that redraws territorial pressure
- player levels with widening Command
- unit ranks/evolutions
- gear rarities/upgrades/affixes later
- settlement levels and specialization
- tech branches
- renown
- world bosses/events
- market economy
- future guild/territory layer

A prestige-like **Frontier Season** system reshapes the frontier while preserving meaningful meta-progression. In the current MVP, advancing a season returns territorial claims to Dawnkeep and raises frontier pressure while preserving the broader progression loop.

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

The first playable slice should already demonstrate settlement, passive/offline economy, buildings, tech, army recruitment/ranks/Command, world map, biomes/threat, adjacency-based territory conquest, objective-driven action expeditions, player movement/combat, army followers, hordes, guardian encounters, run upgrades, active resource harvesting, Momentum kill chains, loot/resources/XP, equipment drops, inventory/paper-doll concept, gear upgrades, marketplace concept, Renown/Frontier Seasons and save persistence.

## 20. Current implementation snapshot — 2026-08-22

The repository currently contains the broad MVP foundation plus the first major loop-strengthening passes:

- Dawnkeep at `[0,0]`
- pannable deterministic frontier coordinates
- persistent territory claims
- adjacent-tile supply-line expansion
- first-claim bounties
- distance-scaled threat
- biome/resource richness metadata
- four deterministic expedition objectives
- objective-specific guardian triggers, pressure, rewards and Ruin Siege rarity boost
- live objective progress HUD
- action expeditions
- resource-site harvesting
- Momentum kill chains
- horde scaling and guardian phase
- temporary field doctrines/run upgrades
- Command-limited army followers
- settlement/passive economy/research/recruitment
- equipment/forge/inventory/paper-doll functional preview
- NPC marketplace proof
- local save/offline progress
- Frontier Season prestige scaffold
- automated Godot parse/smoke/Web-export workflow
- current objective-driven build validated successfully in Godot 4.7.2 CI: project parse, headless main-scene smoke test and Web export all passed

The next design priority is **feel**: the first hands-on user playtest should tell us where the loop drags. Then prioritize combat feedback, biome-specific enemy families, stronger tile identity and the visual foundation without sacrificing browser performance.
