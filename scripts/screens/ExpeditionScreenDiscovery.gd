extends "res://scripts/screens/ExpeditionScreenVisual.gd"

var discovery_overlay:PanelContainer

func _build() -> void:
	super._build()
	var old_arena:CombatArena = arena
	var holder:Node = old_arena.get_parent()
	holder.remove_child(old_arena)
	old_arena.free()
	arena = DiscoveryCombatArena.new()
	holder.add_child(arena)
	arena.set_view_size(Vector2(1400,840))
	arena.hud_changed.connect(_hud)
	arena.upgrade_requested.connect(_show_upgrade)
	arena.finished.connect(_finished)
	arena.gambit_requested.connect(_show_gambit)
	arena.discovery_requested.connect(_show_discovery)
	var map_scale:Label = layout_scene.get_node("Margin/MainRow/SidePanel/SideMargin/Scroll/HUD/MapScale")
	map_scale.text += "\nApproach glowing anomalies to trigger persistent Frontier Discoveries."

func _show_discovery(discovery_id:String,choices:Array) -> void:
	if discovery_overlay:
		return
	var definition:Dictionary = FrontierManager.discovery(discovery_id)
	discovery_overlay = PanelContainer.new()
	discovery_overlay.set_anchors_preset(Control.PRESET_CENTER)
	discovery_overlay.position = Vector2(-430,-300)
	discovery_overlay.size = Vector2(860,600)
	discovery_overlay.add_theme_stylebox_override("panel",UIFactory.panel(Color("#121822"),16,Color(String(definition.get("color","#7da4c2")))))
	add_child(discovery_overlay)
	var margin:=MarginContainer.new()
	margin.add_theme_constant_override("margin_left",28)
	margin.add_theme_constant_override("margin_right",28)
	margin.add_theme_constant_override("margin_top",24)
	margin.add_theme_constant_override("margin_bottom",24)
	discovery_overlay.add_child(margin)
	var column:=VBoxContainer.new()
	column.add_theme_constant_override("separation",12)
	margin.add_child(column)
	var rarity:String = String(definition.get("rarity","common")).to_upper()
	var heading:=UIFactory.title("%s · %s"%[String(definition.get("name",discovery_id)),rarity],28)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(heading)
	var intro:=UIFactory.label(String(definition.get("intro","The frontier is offering a choice.")),13,Color("#b8c3d6"))
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(intro)
	column.add_child(UIFactory.hsep())
	for raw_choice:Variant in choices:
		if not (raw_choice is Dictionary):
			continue
		var choice:Dictionary = Dictionary(raw_choice)
		var cost:int = int(choice.get("cost_gold",0))
		var cost_text:String = "\nCost: %d Gold"%cost if cost > 0 else ""
		var button:=Button.new()
		button.text = "%s\n%s%s"%[String(choice.get("name","Choose")),String(choice.get("description","")),cost_text]
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size.y = 112
		button.disabled = cost > int(GameState.resources.get("gold",0.0))
		var choice_id:String = String(choice.get("id",""))
		button.pressed.connect(func(id=choice_id):_choose_discovery(id))
		column.add_child(button)
	var footer:=UIFactory.label("These decisions can alter the current run, your weapon, your Warband or the campaign itself.",11,Color("#8390a8"))
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(footer)

func _choose_discovery(choice_id:String) -> void:
	if arena is DiscoveryCombatArena and arena.choose_discovery(choice_id):
		if discovery_overlay:
			discovery_overlay.queue_free()
			discovery_overlay = null

func _finished(result:Dictionary) -> void:
	super._finished(result)
	var discoveries:Array = FrontierManager.last_run_discoveries()
	if discoveries.is_empty() or not result_overlay:
		return
	var summary:Label = result_overlay.get_node("Margin/Column/Scroll/Body/Summary")
	var lines:Array[String] = [summary.text,"","FRONTIER DISCOVERIES"]
	for entry:Variant in discoveries:
		var data:Dictionary = Dictionary(entry)
		lines.append("◆ %s · %s"%[String(data.get("name","Anomaly")),String(data.get("choice","choice")).replace("_"," ").capitalize()])
	lines.append("Atlas Insight %d · Wonder %d · Codex %d/%d"%[FrontierManager.insight(),FrontierManager.wonder(),FrontierManager.codex_count(),FrontierManager.discovery_ids().size()])
	summary.text = "\n".join(lines)
