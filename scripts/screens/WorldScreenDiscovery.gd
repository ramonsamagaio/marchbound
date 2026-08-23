extends "res://scripts/screens/WorldScreenVisual.gd"

func _generate_map() -> void:
	FrontierManager.ensure_rumor()
	super._generate_map()
	var rumor:Dictionary = FrontierManager.rumor()
	if not bool(rumor.get("active",false)):
		return
	var rx:int = int(rumor.get("x",0))
	var ry:int = int(rumor.get("y",0))
	map_status.text += " · RUMOR [%d,%d]"%[rx,ry]
	var needle:String = "[%d,%d]"%[rx,ry]
	for cell:Node in grid.get_children():
		var target_button:Button
		for child:Node in cell.get_children():
			if child is Button:
				target_button = child
				break
		if not target_button or target_button.tooltip_text.find(needle) < 0:
			continue
		target_button.tooltip_text += " · RUMOR: %s"%String(rumor.get("name","Unknown anomaly"))
		var badge:=Label.new()
		badge.set_anchors_preset(Control.PRESET_TOP_LEFT)
		badge.position = Vector2(6,4)
		badge.size = Vector2(30,24)
		badge.text = "?"
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.add_theme_font_size_override("font_size",18)
		badge.add_theme_color_override("font_color",Color("#e8b5ff"))
		cell.add_child(badge)
		break

func select_tile(tile:Dictionary) -> void:
	super.select_tile(tile)
	if bool(tile.get("home",false)):
		return
	if not FrontierManager.rumor_for(int(tile.get("x",0)),int(tile.get("y",0))):
		return
	var rumor:Dictionary = FrontierManager.rumor()
	info.add_child(UIFactory.hsep())
	info.add_child(UIFactory.label("? ACTIVE RUMOR · %s"%String(rumor.get("name","Unknown anomaly")),14,Color("#d7b4ef")))
	var clue:=UIFactory.label(String(rumor.get("clue","Something unusual was reported here.")),11,Color("#b7a6c7"))
	clue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(clue)
	info.add_child(UIFactory.label("Prove the rumor by finding this anomaly inside the local map. Reward: +%d Renown."%int(rumor.get("reward_renown",0)),11,Color("#d6c185")))
	_wrap_info(info)
