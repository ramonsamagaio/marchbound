# Dawnkeep Visual Settlement Pass

This pass replaces the old building-card-only settlement presentation with a visual interactive city canvas.

Current behavior:
- eight building families are represented directly inside Dawnkeep;
- clicking a building selects it and exposes its live upgrade action/cost;
- buildings can be dragged to reshape the settlement layout;
- cosmetic layout persists locally in `user://dawnkeep_layout.cfg`;
- roads redraw automatically between the Town Hall and moved buildings;
- each building family has a distinct procedural silhouette and accent language;
- zero-level buildings appear as construction/foundation states instead of disappearing;
- Research Council and Frontier Season controls remain available beside the city;
- settlement summary keeps economy, frontier and power state visible.

This is intentionally a bridge toward final art. The next visual step is replacing procedural silhouettes with approved reusable RGBA/Spine/scene assets while keeping this interaction layer and saved layout behavior.
