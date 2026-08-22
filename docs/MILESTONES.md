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
- [x] Functional procedural paper-doll preview
- [x] Marketplace concept with NPC listings
- [x] Renown / Frontier Season long-game hook
- [x] Godot 4.7.2 parse validation after frontier/objective update
- [x] Main-scene headless smoke run after frontier/objective update
- [x] Web export after frontier/objective update
- [ ] First user playtest + balance pass

### M0.2 Browser build
- [x] Web export generated successfully in CI
- [x] Automatic GitHub Actions build workflow
- [ ] Web build validated interactively in Chrome
- [ ] Public preview URL
- [ ] Browser save persistence verified
- [ ] Input/focus/fullscreen UX checked
- [ ] First performance budget

### M0.3 Visual foundation
- [ ] Final visual bible v1
- [ ] Approved body base
- [ ] Spine paper-doll rig
- [ ] First complete modular armor set
- [ ] Weapon set
- [ ] Resource icons
- [x] First interactive settlement visual scene / procedural kit
- [ ] Final settlement visual kit assets
- [ ] World-map tile language
- [ ] Combat sprite language
- [ ] Inventory/Inspect UI pass

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
- [ ] 20+ equipment pieces / named loot families
- [x] First gear-affix system with rarity-scaled slot-specific rolls
- [x] Equipped affixes modify combat, Command, harvest and drop economy
- [x] Inventory affix display and same-slot comparison
- [x] First explicit expedition objective variants besides survival
- [x] First resource nodes / extraction interactions
- [x] 3+ meaningful run-build directions through 12 stackable Field Doctrines
- [x] Persistent Warden talent progression with six branches and Talent Points on level-up
- [x] Player-selected expedition risk stances: Standard / Prospector / Blood Oath
- [x] Risk stance integrates with effective Threat, resource richness and existing reward scaling
- [ ] First unit evolution choices
- [x] City placement/building scene instead of management cards only
- [x] Buildings selectable/upgradable directly from settlement scene
- [x] Draggable Dawnkeep building layout with local persistence
- [x] First quests/contracts layer: persistent Frontier Contract Board
- [x] Contract families for kills, claims, victories, bosses, gear, Gold and Threat progression
- [x] Optional contract rewards, Renown payout and Gold board-refresh sink
- [ ] Onboarding
- [x] M1 Fun Pass 1 Godot 4.7.2 parse validation
- [x] M1 Fun Pass 1 headless main-scene smoke validation
- [x] M1 Fun Pass 1 Web export validation
- [x] Gear Affix Pass Godot 4.7.2 parse validation
- [x] Gear Affix Pass headless main-scene smoke validation
- [x] Gear Affix Pass Web export validation
- [x] Regional Boss Pass Godot 4.7.2 parse validation
- [x] Regional Boss Pass headless main-scene smoke validation
- [x] Regional Boss Pass Web export validation
- [x] Dawnkeep Scene Pass Godot 4.7.2 parse validation
- [x] Dawnkeep Scene Pass headless main-scene smoke validation
- [x] Dawnkeep Scene Pass Web export validation
- [x] Frontier Contracts Pass Godot 4.7.2 parse validation
- [x] Frontier Contracts Pass headless main-scene smoke validation
- [x] Frontier Contracts Pass Web export validation
- [x] Risk Stance Pass Godot 4.7.2 parse validation
- [x] Risk Stance Pass headless main-scene smoke validation
- [x] Risk Stance Pass Web export validation

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
- high-tier monster recruitment
- world economy sinks
- long-term live content architecture
