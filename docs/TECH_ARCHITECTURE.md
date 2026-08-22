# MARCHBOUND — Technical Architecture

## Current MVP
Godot client runs all gameplay locally for speed of iteration.

```text
Godot 4.7.x
├── GameState autoload
├── SaveManager autoload
├── Settlement screen
├── World screen
├── Army screen
├── Inventory / paper-doll
├── Marketplace simulation
└── Expedition combat arena
```

Persistence: `user://marchbound_save.json`.

## Target browser-online architecture

```text
Godot Web Client
      │
      ├── read-safe queries ──────────────┐
      │                                   ▼
      ├── Auth / profile             Supabase/Postgres
      │                                   ▲
      └── sensitive commands ──> Authoritative API
                                   │
                                   ├─ validate economy
                                   ├─ validate loot
                                   ├─ marketplace escrow
                                   ├─ crafting/upgrades
                                   ├─ army/world movement
                                   └─ PvP result validation
```

The public browser must never be the authority for scarce currency, traded items, PvP outcomes or valuable reward generation.

## Suggested database domains
- profiles
- settlements
- settlement_buildings
- player_resources
- armies
- army_units
- inventories
- items/item_instances
- equipped_items
- technologies
- world_seasons
- world_tiles
- expeditions / reward receipts
- market_listings
- market_transactions
- guilds (later)
- world_events (later)

## Networking principle
Do not introduce a realtime game server until a feature needs realtime authority. Asynchronous persistent systems can remain HTTP/database-driven. Realtime movement/combat with multiple players would justify a dedicated session server later.
