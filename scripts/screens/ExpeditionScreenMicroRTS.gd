extends "res://scripts/screens/ExpeditionScreenDiscovery.gd"

func _build() -> void:
	super._build()
	var old_arena:CombatArena=arena
	var holder:Node=old_arena.get_parent()
	holder.remove_child(old_arena)
	old_arena.free()
	arena=MicroRTSCombatArena.new()
	holder.add_child(arena)
	arena.set_view_size(Vector2(1400,840))
	arena.hud_changed.connect(_hud)
	arena.finished.connect(_finished)
	arena.area_transition_requested.connect(_leave_area_to_world)
	arena.station_requested.connect(_open_station)
	# Upgrade/Gambit/Discovery popups remain implemented elsewhere but this mode does not emit them.
	var map_scale:Label=layout_scene.get_node("Margin/MainRow/SidePanel/SideMargin/Scroll/HUD/MapScale")
	map_scale.text="1024 × 1024 Claude-layout AREA · 32 px tiles\nLMB attack toward cursor · E gather · F interact/leave\nB build · C next building · R remove\n1 Aggressive · 2 Defensive · 3 Follow · 4 Hold\nLeaving through an edge returns to World Map and costs 0 Food."
	var boss_label:Label=layout_scene.get_node("Margin/MainRow/SidePanel/SideMargin/Scroll/HUD/BossLabel")
	boss_label.text="MICRO RTS · persistent enemy packs · no timed horde spawner"

func _objective_progress_text(_data:Dictionary) -> String:
	var alive:int=AreaEcology.alive_count(Vector2i(int(tile.get("x",0)),int(tile.get("y",0))),tile)
	var claims:int=AreaEcology.claims(Vector2i(int(tile.get("x",0)),int(tile.get("y",0)))).size()
	return "AREA ECOLOGY · %d hostiles remain · %d local claim%s"%[alive,claims,"s" if claims!=1 else ""]

func _hud(data:Dictionary) -> void:
	super._hud(data)
	if arena is MicroRTSCombatArena:
		status.text="HP %d / %d\nField units %d · Garrison %d\nWarband %s · AREA [%d,%d]\nLMB attack · E gather · F interact"%[
			int(data.get("hp",0)),int(data.get("hp_max",0)),UnitRoster.field_units().size(),UnitRoster.garrison_units().size(),
			String(arena.party_stance).capitalize(),int(tile.get("x",0)),int(tile.get("y",0))
		]

func _leave_area_to_world(next_tile:Dictionary) -> void:
	SaveManager.save_game()
	GameState.world["selected_tile"]=next_tile.duplicate(true)
	GameState.screen_requested.emit("world")

func _open_station(station:String) -> void:
	SaveManager.save_game()
	var target:String={
		"command":"city","army":"army","forge":"inventory","research":"city",
		"market":"market","storage":"inventory"
	}.get(station,"city")
	GameState.screen_requested.emit(target)
