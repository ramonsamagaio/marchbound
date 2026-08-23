# Marchbound SVG Placeholder Pipeline

This pass intentionally does **not** use generated PNG sheets as if they were vectors.

## Rule

Gameplay placeholders that benefit from visual editing should be authored as real SVG files whenever practical.

- SVG is source art, not a screenshot of source art.
- Files have deterministic dimensions and coordinates.
- Godot imports each SVG directly as a Texture2D.
- Paper-doll layers share one `256x512` viewBox so body/equipment overlays align without atlas cropping.
- Local construction pieces use fixed `64x64` canvases so they can snap to the local building grid.
- Final art can replace an SVG file later without changing gameplay code or scene layout.

## Current proof set

### Paper doll, 256x512
- `assets/svg/paperdoll/body_base.svg`
- `assets/svg/paperdoll/armor_chest_vanguard.svg`
- `assets/svg/paperdoll/armor_helm_vanguard.svg`
- `assets/svg/paperdoll/armor_boots_vanguard.svg`
- `assets/svg/paperdoll/weapon_sword_vanguard.svg`

`scenes/ui/PaperDoll.tscn` stacks these files as separate visually editable TextureRect layers. Equipped slots control whether the matching overlay is visible.

### Local construction, 64x64
- `assets/svg/build/floor_stone.svg`
- `assets/svg/build/wall_wood.svg`
- `assets/svg/build/door_wood.svg`
- `assets/svg/build/chest_storage.svg`

These are deliberately simple placeholder vectors. Their purpose is readability, deterministic alignment and easy replacement, not final art polish.

## Next expansion after validation

1. Complete all paper-doll slots using the same 256x512 layer convention.
2. Create two or three coherent armor sets as SVG overlays for systems testing.
3. Expand the 64x64 construction kit: wall corners, gate, floor variants, torch, bed, workbench, tower, farm, traps.
4. Create SVG HUD icons and item icons as individual files rather than cutting them from generated sheets.
5. Keep generated raster art only as concept/reference unless it is intentionally approved as raster production art.
