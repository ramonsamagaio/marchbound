extends "res://scripts/screens/WorldScreen.gd"

func _build()->void:
	var margin=MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",24)
	margin.add_theme_constant_override("margin_right",24)
	margin.add_theme_constant_override("margin_top",18)
	margin.add_theme_constant_override("margin_bottom",18)
	add_child(margin)
	var root=HBoxContainer.new()
	root.add_theme_constant_override("separation",18)
	margin.add_child(root)

	var left=VBoxContainer.new()
	left.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	left.size_flags_vertical=Control.SIZE_EXPAND_FILL
	root.add_child(left)
	var top=HBoxContainer.new()
	left.add_child(top)
	top.add_child(UIFactory.title("The March",30))
	top.add_child(UIFactory.spacer())
	map_status=UIFactory.label("",14,Color("#9ca9c9"))
	top.add_child(map_status)
	left.add_child(UIFactory.label("Each macro territory opens into a 192 × 192 local tile map. Atlas hexes mark biome, danger and strategic reasons to march.",13,Color("#9ca9c9")))
	var pan=HBoxContainer.new()
	pan.alignment=BoxContainer.ALIGNMENT_CENTER
	pan.add_theme_constant_override("separation",7)
	left.add_child(pan)
	pan.add_child(UIFactory.button("← WEST",func():_pan(-PAN_STEP,0),Color("#252e43")))
	pan.add_child(UIFactory.button("↑ NORTH",func():_pan(0,-PAN_STEP),Color("#252e43")))
	pan.add_child(UIFactory.button("DAWNKEEP",func():_set_focus(0,0),Color("#4b442d")))
	pan.add_child(UIFactory.button("↓ SOUTH",func():_pan(0,PAN_STEP),Color("#252e43")))
	pan.add_child(UIFactory.button("EAST →",func():_pan(PAN_STEP,0),Color("#252e43")))
	left.add_child(UIFactory.hsep())
	var grid_scroll=ScrollContainer.new()
	grid_scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	grid_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	grid_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
	grid_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
	left.add_child(grid_scroll)
	grid=GridContainer.new()
	grid.columns=GRID_W
	grid.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
	grid.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation",7)
	grid.add_theme_constant_override("v_separation",7)
	grid_scroll.add_child(grid)

	var side=PanelContainer.new()
	side.custom_minimum_size.x=440
	side.size_flags_vertical=Control.SIZE_EXPAND_FILL
	side.add_theme_stylebox_override("panel",UIFactory.panel(Color("#151b2a"),12,Color("#35415d")))
	root.add_child(side)
	var side_margin=MarginContainer.new()
	side_margin.add_theme_constant_override("margin_left",16)
	side_margin.add_theme_constant_override("margin_right",16)
	side_margin.add_theme_constant_override("margin_top",16)
	side_margin.add_theme_constant_override("margin_bottom",16)
	side.add_child(side_margin)
	var side_scroll=ScrollContainer.new()
	side_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	side_margin.add_child(side_scroll)
	info=VBoxContainer.new()
	info.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation",8)
	side_scroll.add_child(info)

func make_tile(x:int,y:int)->Dictionary:
	var tile:Dictionary=super.make_tile(x,y)
	tile["local_map_tiles"]=VisualCombatArena.LOCAL_MAP_TILES
	tile["local_player_capacity"]=3
	return tile

func _generate_map()->void:
	UIFactory.clear_children(grid)
	var focus=_focus()
	map_status.text="Season %d · Claimed %d · Bonds %d/%d · View [%d,%d]"%[GameState.world.season,GameState.claimed_count(),GameState.unlocked_monsters().size(),MonsterRoster.ORDER.size(),focus.x,focus.y]
	for gy in GRID_H:
		for gx in GRID_W:
			var wx=focus.x+gx-int(GRID_W/2)
			var wy=focus.y+gy-int(GRID_H/2)
			var tile=make_tile(wx,wy)
			var cell=Control.new()
			cell.custom_minimum_size=Vector2(108,92)
			cell.mouse_filter=Control.MOUSE_FILTER_PASS
			var art=TextureRect.new()
			art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			art.texture=VisualAtlas.texture("world_city" if bool(tile.home) else VisualAtlas.biome_tile_id(String(tile.biome)))
			art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
			art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			art.mouse_filter=Control.MOUSE_FILTER_IGNORE
			if not bool(tile.accessible):
				art.modulate=Color(0.38,0.40,0.45,0.72)
			elif bool(tile.conquered):
				art.modulate=Color(1.0,1.0,1.0,1.0)
			cell.add_child(art)
			var button=Button.new()
			button.flat=true
			button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			button.focus_mode=Control.FOCUS_NONE
			var mutation_tip=" · "+FrontierMutations.names(tile.mutations) if tile.mutations.size()>0 else ""
			var bond_tip=" · Wild Bond: "+MonsterRoster.display_name(String(tile.wild_bond)) if not tile.home and not bool(tile.wild_bond_unlocked) else ""
			button.tooltip_text="%s [%d,%d] · Threat %d · %s%s%s%s"%["Dawnkeep" if tile.home else tile.biome,tile.x,tile.y,tile.threat,tile.objective,(" · "+String(tile.boss_name)) if tile.boss else "",mutation_tip,bond_tip]
			button.pressed.connect(func(t=tile):select_tile(t))
			cell.add_child(button)
			var threat=Label.new()
			threat.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
			threat.position=Vector2(-34,-28)
			threat.size=Vector2(68,23)
			threat.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
			threat.add_theme_font_size_override("font_size",12)
			threat.add_theme_color_override("font_color",Color("#f2e8ca"))
			threat.add_theme_color_override("font_shadow_color",Color(0,0,0,0.95))
			threat.add_theme_constant_override("shadow_offset_x",1)
			threat.add_theme_constant_override("shadow_offset_y",1)
			threat.text="HOME" if tile.home else "T%d"%int(tile.threat)
			cell.add_child(threat)
			var badges=Label.new()
			badges.set_anchors_preset(Control.PRESET_RIGHT_TOP)
			badges.position=Vector2(-58,4)
			badges.size=Vector2(52,22)
			badges.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
			badges.add_theme_font_size_override("font_size",13)
			badges.add_theme_color_override("font_color",Color("#ffe1a0"))
			badges.text=("★" if tile.boss else "")+("✦" if tile.mutations.size()>0 else "")+("♢" if not bool(tile.wild_bond_unlocked) else "")+("✓" if tile.conquered else "")
			cell.add_child(badges)
			grid.add_child(cell)
	var remembered=GameState.world.get("selected_tile",{})
	if not remembered.is_empty() and abs(int(remembered.get("x",0))-focus.x)<=int(GRID_W/2) and abs(int(remembered.get("y",0))-focus.y)<=int(GRID_H/2):
		select_tile(make_tile(int(remembered.x),int(remembered.y)))
	else:
		select_tile(make_tile(focus.x,focus.y))

func select_tile(tile:Dictionary)->void:
	super.select_tile(tile)
	if bool(tile.get("home",false)):
		return
	info.add_child(UIFactory.hsep())
	info.add_child(UIFactory.label("LOCAL MAP SCALE",13,Color("#f0dfae")))
	var scale_text=UIFactory.label("%d × %d buildable local tiles · capacity target: %d players in this macro territory."%[int(tile.get("local_map_tiles",192)),int(tile.get("local_map_tiles",192)),int(tile.get("local_player_capacity",3))],11,Color("#9eb2c5"))
	scale_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	info.add_child(scale_text)
