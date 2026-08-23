# MARCHBOUND — Milestones

## M0 — The Loop Exists
**Goal:** one sitting proves why the player wants another sitting.

### M0.1 Broad MVP foundation — PLAYTEST READY
- [x] Repository initialized
- [x] Living project bible
- [x] Godot project shell
- [x] Settlement economy
- [x] Passive production
- [x] Offline-production save logic
- [x] Buildings and upgrade costs
- [x] Six technology branches
- [x] Command capacity
- [x] Four initial unit types
- [x] Recruitment and unit ranks
- [x] Strategic world-map generator
- [x] Biomes, threat, richness, bosses, PvP-preview tile metadata
- [x] Persistent territory claims and adjacency/supply-line expansion
- [x] Pannable world-map window over effectively unbounded coordinates
- [x] First-claim frontier bounties
- [x] Action expedition arena
- [x] Four deterministic expedition flows: Frontier Claim / Monster Hunt / Resource Sweep / Ruin Siege
- [x] Objective-specific boss timing, pressure and reward profiles
- [x] Player movement, dash and two abilities
- [x] Auto attack
- [x] Army followers with auto-combat
- [x] Horde scaling
- [x] Expedition guardian/boss
- [x] Run-level upgrade choices
- [x] Resource/XP rewards
- [x] Biome-weighted resource sites harvested during expeditions
- [x] Momentum kill-chain system with combat/economy payoff
- [x] Procedural gear drops
- [x] Inventory and equipment
- [x] Forge upgrades
- [x] Marketplace concept with NPC listings
- [x] Renown / Frontier Season long-game hook
- [ ] First full user balance/fun pass on the new large-map visual build

### M0.2 Browser build
- [x] Web export generated successfully in CI
- [x] Automatic GitHub Actions build workflow
- [x] CI rejects hidden Godot script/autoload errors even when Godot returns exit code 0
- [x] Native design target raised to 1920×1080
- [x] 1280×720 retained as minimum-window target
- [x] Expedition result redesigned to keep the Continue action reachable with scrollable variable content
- [ ] Web build validated interactively in Chrome after visual/local-map pass
- [ ] Public preview URL
- [ ] Browser save persistence verified
- [ ] Input/focus/fullscreen UX checked
- [ ] First performance budget for giant local territory

### M0.3 Visual foundation
- [ ] Final visual bible v1
- [x] Approved provisional Marchbound atlas uploaded to project
- [x] Centralized atlas-region mapper (`VisualAtlas.gd`)
- [x] Resource bar begins using real atlas icons
- [x] World Map territory cells begin using atlas biome/hex artwork
- [x] Combat begins using atlas units/enemies/resources/buildings
- [x] Dawnkeep begins using atlas building artwork
- [x] Expedition HUD moved into editable `.tscn`
- [x] Expedition result moved into editable `.tscn`
- [x] Paper-doll composition moved into editable `.tscn` foundation
- [x] Visual/UI audit documented with scene-first rules
- [ ] Final approved isolated body-base RGBA asset in project
- [ ] Final isolated modular armor layers / Spine paper-doll rig
- [ ] First complete production modular armor set
- [ ] Weapon set
- [ ] Final resource icon set
- [ ] Final settlement visual kit assets
- [ ] Final World Map tile language
- [ ] Final combat sprite language
- [ ] Full Inventory shell converted to `.tscn`
- [ ] Main global shell converted to `.tscn`
- [ ] Warband card components converted to reusable `.tscn`

## M1 — I Want One More Expedition
- [x] First combat-feel pass: shake, floating feedback, crit callouts, elite callouts and clearer impacts
- [ ] Sound / music / deeper camera feedback
- [x] First biome-specific enemy families across all six MVP biomes
- [x] Ranged enemy behavior and hostile projectiles
- [x] Elite enemy variants with extra risk/reward
- [x] Dash invulnerability timing / active evasion
- [x] 3 distinct regional boss archetypes with named biome variants
- [x] Beast charge boss pattern
- [x] Oracle fan/ring projectile-control boss pattern
- [x] Colossus radial eruption / heavy-shot boss pattern
- [x] 20+ equipment pieces / named loot families
- [x] Six biome-bound equipment families with 54 authored slot identities
- [x] 2pc / 4pc regional set bonuses that modify live expedition systems
- [x] Named boss provenance on high-rarity regional drops
- [x] Inventory shows family lore, active pieces and set-bonus state
- [x] First gear-affix system with rarity-scaled slot-specific rolls
- [x] Equipped affixes modify combat, Command, harvest and drop economy
- [x] Inventory affix display and same-slot comparison
- [x] First explicit expedition objective variants besides survival
- [x] First resource nodes / extraction interactions
- [x] 3+ meaningful run-build directions through 12 stackable Field Doctrines
- [x] Persistent Warden talent progression with six branches and Talent Points on level-up
- [x] Player-selected expedition risk stances: Standard / Prospector / Blood Oath
- [x] Risk stance integrates with effective Threat, resource richness and existing reward scaling
- [x] Six deterministic Frontier Mutations alter live combat and reward rules
- [x] Frontier Mutations are visible/targetable on the World Map and stack with risk stances
- [x] First unit evolution choices at Rank 3
- [x] Eight first-tier branches across Militia / Archer / War Wolf / Mage
- [x] Unit evolution branches change live expedition combat roles
- [x] Evolution choices persist in existing player save data and migrate old saves lazily
- [x] First Wild Bonds recruitment pass with six biome-specific creatures
- [x] Wild Bond discovery integrates Monster Hunt, Elite kills, mutations and regional-boss guarantees
- [x] Wild Bonds persist/migrate, consume Command, can be recruited/trained and deploy in expeditions
- [x] Individual unit roster layer added beneath aggregate army families
- [x] Six first unit prefixes: Swift / Ironhide / Blessed / Vicious / Ancient / Stormtouched
- [x] Prefixes alter live combat behavior rather than only names
- [x] Rare independent Elite quality added as shiny-like collectible classification
- [x] Existing saves migrate owned troops to safe Standard individual records
- [x] Warband UI surfaces prefix / Elite specimens with atlas art
- [x] Strategic macro territory now opens to a 192×192 local-tile prototype
- [x] Local map prototype covers 36,864 tiles / 12,288×12,288 world-space
- [x] Lightweight player-following camera/culling model for giant local territory
- [x] Physical frontier outpost/buildings exist inside expedition map
- [x] Enemy spawning follows current local camera/player area instead of giant-map borders
- [x] First actual in-expedition construction: Field Watchtower built from harvested Wood
- [x] Field Watchtowers snap to local grid and automatically fight enemies
- [x] Macro territory data exposes future target capacity of 3 Wardens / players
- [x] City placement/building scene instead of management cards only
- [x] Buildings selectable/upgradable directly from settlement scene
- [x] Draggable Dawnkeep building layout with local persistence
- [x] First quests/contracts layer: persistent Frontier Contract Board
- [x] Contract families for kills, claims, victories, bosses, gear, Gold and Threat progression
- [x] Optional contract rewards, Renown payout and Gold board-refresh sink
- [x] First March onboarding ribbon with four rewarded gameplay goals
- [x] First March persists in the main save and disappears after completion
- [x] First March final reward introduces regional set gear

### Historical validation gates
- [x] M1 Fun Pass 1 Godot 4.7.2 parse / smoke / Web export
- [x] Gear Affix Pass Godot 4.7.2 parse / smoke / Web export
- [x] Regional Boss Pass Godot 4.7.2 parse / smoke / Web export
- [x] Dawnkeep Scene Pass Godot 4.7.2 parse / smoke / Web export
- [x] Frontier Contracts Pass Godot 4.7.2 parse / smoke / Web export
- [x] Risk Stance Pass Godot 4.7.2 parse / smoke / Web export
- [x] Unit Evolution Pass Godot 4.7.2 parse / smoke / Web export
- [x] Regional Loot Families Pass Godot 4.7.2 parse / smoke / Web export
- [x] First March Pass Godot 4.7.2 parse / smoke / Web export
- [x] Frontier Mutations Pass strict Godot 4.7.2 parse / smoke / Web export
- [x] Wild Bonds Pass strict Godot 4.7.2 parse / smoke / Web export
- [x] Visual Atlas / Giant Local Map / Unit Quality Pass strict parse validation
- [x] Visual Atlas / Giant Local Map / Unit Quality Pass strict headless smoke validation
- [x] Visual Atlas / Giant Local Map / Unit Quality Pass strict Web export validation

## M2 — Persistent Online Kingdom
- Supabase Auth
- profile
- cloud save
- authoritative settlement mutations
- world state stored online
- marketplace server transactions
- inspect another profile
- anti-dupe transaction ledger
- leaderboards
- basic telemetry/economy balancing

## M3 — The World Has Other People
- map ownership / influence
- 2–3 player shared local-territory prototype
- local-territory authority / synchronization
- caravans and regional trade
- optional PvP frontier rules
- asynchronous conflict where appropriate
- social/guild foundations
- world events
- cooperative boss prototype

## M4 — Endless Frontier
- procedural frontier expansion
- seasons/prestige tuned
- specialization trees
- rare regions
- faction content
- rare/high-tier Wild Bonds and creature evolution paths
- world economy sinks
- long-term live content architecture
