# MARCHBOUND — Visual / UI Audit

**Date:** 2026-08-22  
**Pass:** Visual Atlas + Large Local Map + Scene-driven UI  
**Branch:** `nyra/visual-atlas-pass-v2`

## Why this audit exists

Marchbound must remain visually editable in Godot. Important composition cannot live only in procedural GDScript, because the art/layout owner needs to open the project, select nodes, move panels, resize them, swap textures and replace assets without rewriting gameplay code.

The approved provisional atlas currently lives at:

`res://assets/marchbound_assetsprov.png`

All provisional atlas cuts are centralized in:

`res://scripts/core/VisualAtlas.gd`

This is deliberately a temporary art-production bridge. Future final body, armor, creatures, buildings, UI icons and effects can replace atlas regions without rewriting gameplay systems.

---

## Audit result

### Expedition HUD — CONVERTED TO SCENE

Before this pass, the entire expedition layout was assembled from GDScript.

Now the main expedition composition lives in:

`res://scenes/ui/ExpeditionLayout.tscn`

Editable nodes include:
- arena viewport/holder;
- side HUD width;
- biome/territory/boss/mutation/Wild Bond labels;
- objective block;
- HP bar;
- status/cooldown block;
- local-map scale information;
- controls/building instructions;
- retreat button.

Gameplay code now fills those nodes rather than determining the whole composition.

### Expedition result — CONVERTED TO SCENE

The result overlay that previously overflowed the user's viewport now lives in:

`res://scenes/ui/ExpeditionResult.tscn`

It is centered and uses a ScrollContainer for variable-length results/loot. The Continue button sits outside the scrolling body so it remains reachable.

### Paper doll — CONVERTED TO SCENE FOUNDATION

Audit confirmed that the original `PaperDoll.gd` was almost entirely procedural `_draw()` geometry. Body, armor preview, limbs and equipment cues were code-drawn and therefore painful to art-direct inside the Godot editor.

The new scene is:

`res://scenes/ui/PaperDoll.tscn`

It contains visually editable nodes for:
- CharacterStage;
- character artwork;
- aura;
- Warden level/power/build labels;
- Helm;
- Shoulders;
- Chest;
- Gloves;
- Weapon;
- Cape;
- Belt;
- Legs;
- Boots.

Controller:

`res://scripts/ui/PaperDollScene.gd`

The new controller intentionally overrides the old `_draw()` with no procedural drawing. It only updates data, tooltips, rarity tint and light breathing motion.

**Important limitation:** the current approved atlas contains complete character/unit artwork but not the original isolated body + every modular armor piece as separate transparent production layers. The scene structure is ready for true modular armor, but the final paper-doll quality pass should use separately uploaded body/armor RGBA assets (or Spine layers), not crop a combined unit sprite forever.

### Inventory outer layout — PARTIALLY SCENE-DRIVEN

The important paper-doll composition is now a `.tscn`, but the Inventory screen's outer three-column shell is still assembled by `InventoryScreenVisual.gd`.

Future conversion target: `InventoryScreen.tscn` with left item list, center paper doll and right item detail as editor-positionable scene containers.

### World Map — VISUALIZED, OUTER LAYOUT STILL CODE

World territories now use actual atlas terrain art instead of primarily text/color buttons. The right information column is now scroll-safe.

Current visual screen:

`res://scripts/screens/WorldScreenVisual.gd`

Remaining debt: convert the complete World Map shell to a `.tscn` once the tile dimensions and information hierarchy survive playtesting.

### Dawnkeep / settlement — VISUAL ASSETS IN PLACE, OUTER LAYOUT STILL CODE

`VisualSettlementCanvas.gd` now renders approved atlas building sprites instead of only procedural polygon buildings. Buildings remain directly draggable/selectable.

Remaining debt: settlement screen shell and build/research management panels are still constructed in GDScript. The actual draggable city canvas remains a custom drawing surface because it is interactive world-space content rather than ordinary HUD.

### Warband — DATA/UI STILL MOSTLY CODE

The Warband now shows individual units, prefix qualities and rare Elite specimens using atlas art.

Remaining debt: convert the Warband's card composition and evolution/quality detail into reusable `.tscn` card scenes after the unit-quality system is playtested.

### Main shell/navigation — STILL CODE

Top bar now uses atlas resource icons, but the global top/navigation shell still comes from `Main.gd` / `MainVisual.gd`.

Future conversion target: `MainShell.tscn`.

### Contracts / Marketplace — STILL CODE

These remain lower priority for visual-scene conversion until the primary loop screens stabilize.

---

## Approved rules going forward

1. **Gameplay systems can be code-driven. Layout/art direction cannot be trapped in code.**
2. Major HUDs, modal/result screens, paper dolls, reusable cards and inspect panels should have `.tscn` scene representations.
3. World-space procedural content can remain code/data-driven when that is appropriate, but it should consume authored visual assets wherever possible.
4. New placeholder art should prefer the approved atlas or authored SVG/PNG over circles, triangles and raw colored rectangles.
5. All atlas coordinates stay centralized in `VisualAtlas.gd`.
6. Final paper-doll equipment must migrate toward independent RGBA/Spine layers matching the approved mannequin/armor references.
7. Any panel that can grow with dynamic text/content must either reflow safely or scroll. Important action buttons must never be pushed beyond the viewport.
8. Native design target is now 1920×1080 with canvas expansion, while retaining 1280×720 as the practical minimum window size.

---

## Current visual conversion priority

1. Validate new expedition scene/result at 1920×1080 and 1280×720 browser sizes.
2. Validate atlas crop coordinates against the actual imported PNG.
3. Upload/use isolated Warden body and modular armor production assets for true paper doll.
4. Convert Main shell to `.tscn`.
5. Convert full Inventory shell to `.tscn`.
6. Convert World shell to `.tscn` after tile dimensions are locked.
7. Convert Warband unit cards into reusable visual scenes.
