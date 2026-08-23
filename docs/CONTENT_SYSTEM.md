# Marchbound Content System

This pass moves combat/content identity out of one giant hardcoded combat script and into editable catalogs.

## Shipped catalogs

- `data/content/items.json`
- `data/content/monsters.json`
- `data/content/attacks.json`
- `data/content/projectiles.json`
- `data/content/tiles.json`

`ContentDB` loads these files and then applies optional browser/local overrides from `user://marchbound_content_overrides.json`.

## Content Lab

Open **CONTENT LAB** from the bottom navigation.

The editor is scene-driven (`scenes/ui/ContentEditor.tscn`) and supports:
- category browsing;
- raw structured JSON editing;
- preview for IDs that already exist in `VisualAtlas`;
- relationship summary;
- saving runtime overrides;
- resetting an entry to shipped data;
- validating item -> attack/projectile and monster -> attack references.

Runtime overrides deliberately do not mutate `res://` because the Web build cannot safely write back into the shipped project. Once an override is approved, copy the JSON entry into the shipped catalog.

## Weapon schema

A weapon entry can define:

```json
{
  "name": "Rimeglass Bow",
  "kind": "weapon",
  "slot": "weapon",
  "weapon_class": "bow",
  "tier": 4,
  "power": 33,
  "attack_id": "bow_shot",
  "projectile_id": "arrow_frost",
  "attack_speed": 1.08,
  "damage_mult": 1.1,
  "knockback": 0.68,
  "inventory_sprite": "item_bow_rime",
  "equipped_sheet": "weapon_bow_rime",
  "attack_sprite": "weapon_bow_rime",
  "biomes": ["Frostwild"]
}
```

### Visual contract

- `inventory_sprite`: icon/art shown in inventory and loot UI.
- `equipped_sheet`: world-character overlay/spritesheet while equipped.
- `attack_sprite`: temporary weapon sprite shown during the attack motion.
- `attack_id`: collision/motion behavior.
- `projectile_id`: payload for ranged attacks; can vary independently of the bow/staff itself.

The current visual pass has fallbacks when a named visual asset is not yet present. Gameplay data should not wait for final art.

## Attack modes

### `melee_arc`
Sword/axe style swing. Uses reach + angular arc collision.

### `melee_thrust`
Spear/dagger style attack. Uses a forward corridor collision volume with configurable reach/width.

### `melee_slam`
Hammer/heavy attack. Uses an impact point and radial collision.

### `ranged`
Bow/crossbow/staff/wand/spell. Releases the selected projectile at the attack's release point.

Attack definitions also carry motion, duration, damage multiplier, knockback multiplier and a provisional FX visual ID.

## Projectile schema

Projectiles can independently define:
- speed;
- lifetime;
- collision radius;
- pierce count;
- damage multiplier;
- knockback multiplier;
- splash radius;
- future slow/status metadata;
- provisional visual ID and color.

This means one bow can fire Wooden, Iron, Ember or Rime arrows without needing four different attack implementations.

## Monster schema

Monsters define:
- display name;
- biome membership;
- behavior (`melee`, `rush`, `tank`, `ranged`);
- attack ID;
- optional projectile ID;
- HP/speed/damage multipliers;
- sprite ID;
- authored drop candidates.

The first expanded catalog contains 36 normal monster identities across the six current biomes.

## Tile schema

Local ground variation is also data-driven. Each definition provides:
- biome;
- ground kind;
- relative weight metadata;
- base color;
- accent color;
- movement-cost hook;
- tags.

The current pass includes 24 local ground identities. It is intentionally lightweight and browser-minded; it does not instantiate 36,864 tile nodes.

## Current authored attack families

Player-facing foundations include:
- Quick Slash
- Heavy Cleave
- Axe Cleave
- Dagger Flurry
- Spear Thrust
- Hammer Slam
- Bow Shot
- Crossbow Bolt
- Staff Cast
- Wand Flick
- Ember Lance
- Frost Shard
- Void Orb
- Sun Spear
- Thorn Burst

Enemy foundations include Bite, Claw, Slam, Spit and Hex Bolt plus existing named-boss patterns.

## Design rule

New content should prefer **composing existing attack/projectile primitives** before adding one-off combat code. A new spear should usually be data. A genuinely new mechanic, such as a returning boomerang or chained beam, earns a new reusable attack mode.
