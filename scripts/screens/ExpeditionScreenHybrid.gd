extends "res://scripts/screens/ExpeditionScreenDiscovery.gd"

func _build() -> void:
	super._build()
	var old_arena:CombatArena = arena
	var holder:Node = old_arena.get_parent()
	holder.remove_child(old_arena)
	old_arena.free()
	arena = HybridAreaCombatArena.new()
	holder.add_child(arena)
	arena.set_view_size(Vector2(1400,840))
	arena.hud_changed.connect(_hud)
	arena.upgrade_requested.connect(_show_upgrade)
	arena.finished.connect(_finished)
	arena.gambit_requested.connect(_show_gambit)
	arena.discovery_requested.connect(_show_discovery)
	arena.area_transition_requested.connect(_transition_area)
	arena.station_requested.connect(_open_station)
	var map_scale:Label = layout_scene.get_node("Margin/MainRow/SidePanel/SideMargin/Scroll/HUD/MapScale")
	map_scale.text = "%d × %d persistent local tiles · physical macro [%d,%d]\nB build · C next building · R remove · F station\n1 Aggressive · 2 Defensive · 3 Follow · 4 Hold\nCross any AREA border to walk to the next macro tile for 0 Food."%[
		WorldAreaManager.LOCAL_MAP_TILES,WorldAreaManager.LOCAL_MAP_TILES,int(tile.get("x",0)),int(tile.get("y",0))
	]
	if bool(tile.get("home",false)):
		RetentionManager.bank_chain()
		var boss_label:Label = layout_scene.get_node("Margin/MainRow/SidePanel/SideMargin/Scroll/HUD/BossLabel")
		boss_label.text = "SAFE HOME AREA · hostile spawning disabled"

func _objective_progress_text(data:Dictionary) -> String:
	if bool(tile.get("home",false)):
		return "DAWNKEEP HOME · build the real settlement, manage stations, or walk through a border"
	return super._objective_progress_text(data)

func _hud(data:Dictionary) -> void:
	super._hud(data)
	if arena is HybridAreaCombatArena:
		status.text += "\nWar-band stance: %s · Field %d · Garrison %d"%[
			String(arena.party_stance).capitalize(),UnitRoster.field_units().size(),UnitRoster.garrison_units().size()
		]

func _transition_area(next_tile:Dictionary) -> void:
	if gambit_overlay:
		gambit_overlay.queue_free(); gambit_overlay = null
	if discovery_overlay:
		discovery_overlay.queue_free(); discovery_overlay = null
	SaveManager.save_game()
	GameState.world["selected_tile"] = next_tile.duplicate(true)
	GameState.screen_requested.emit("expedition")

func _open_station(station:String) -> void:
	SaveManager.save_game()
	var target:String = {
		"command":"city","army":"army","forge":"inventory","research":"city",
		"market":"market","storage":"inventory"
	}.get(station,"city")
	GameState.screen_requested.emit(target)
