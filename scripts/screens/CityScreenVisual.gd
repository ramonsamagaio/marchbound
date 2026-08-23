extends "res://scripts/screens/CityScreen.gd"

func _build()->void:
	var margin=MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",20)
	margin.add_theme_constant_override("margin_right",20)
	margin.add_theme_constant_override("margin_top",14)
	margin.add_theme_constant_override("margin_bottom",14)
	add_child(margin)
	var root=HBoxContainer.new()
	root.size_flags_vertical=Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation",16)
	margin.add_child(root)

	var left=VBoxContainer.new()
	left.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	left.size_flags_vertical=Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation",5)
	root.add_child(left)
	var title_row=HBoxContainer.new()
	left.add_child(title_row)
	title_row.add_child(UIFactory.title("Dawnkeep",29))
	title_row.add_child(UIFactory.label("  Living Settlement",13,Color("#9daacb")))
	title_row.add_child(UIFactory.spacer())
	var world_button=UIFactory.button("Ride to World Map",func():GameState.screen_requested.emit("world"),Color("#5b4b2d"))
	world_button.custom_minimum_size=Vector2(150,38)
	title_row.add_child(world_button)
	var intro=UIFactory.label("Drag buildings directly in the scene. The atlas is provisional, but Dawnkeep now shares the same visual language as battle and the World Map.",12,Color("#9daacb"))
	intro.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	left.add_child(intro)
	settlement_summary=VBoxContainer.new()
	left.add_child(settlement_summary)

	var board_panel=PanelContainer.new()
	board_panel.custom_minimum_size.y=430
	board_panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	board_panel.size_flags_vertical=Control.SIZE_EXPAND_FILL
	board_panel.add_theme_stylebox_override("panel",UIFactory.panel(Color("#17221b"),12,Color("#435342")))
	left.add_child(board_panel)
	canvas=VisualSettlementCanvas.new()
	canvas.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	canvas.size_flags_vertical=Control.SIZE_EXPAND_FILL
	canvas.building_selected.connect(_select_building)
	canvas.layout_changed.connect(_layout_saved)
	board_panel.add_child(canvas)

	var selected_panel=PanelContainer.new()
	selected_panel.custom_minimum_size.y=100
	selected_panel.add_theme_stylebox_override("panel",UIFactory.panel(Color("#171e2d"),10,Color("#35415f")))
	left.add_child(selected_panel)
	var selected_margin=MarginContainer.new()
	selected_margin.add_theme_constant_override("margin_left",12)
	selected_margin.add_theme_constant_override("margin_right",12)
	selected_margin.add_theme_constant_override("margin_top",8)
	selected_margin.add_theme_constant_override("margin_bottom",8)
	selected_panel.add_child(selected_margin)
	selected_box=VBoxContainer.new()
	selected_margin.add_child(selected_box)

	var right=PanelContainer.new()
	right.custom_minimum_size.x=390
	right.size_flags_vertical=Control.SIZE_EXPAND_FILL
	right.add_theme_stylebox_override("panel",UIFactory.panel(Color("#141a29"),12,Color("#34405d")))
	root.add_child(right)
	var right_margin=MarginContainer.new()
	right_margin.add_theme_constant_override("margin_left",14)
	right_margin.add_theme_constant_override("margin_right",14)
	right_margin.add_theme_constant_override("margin_top",12)
	right_margin.add_theme_constant_override("margin_bottom",12)
	right.add_child(right_margin)
	var scroll=ScrollContainer.new()
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	right_margin.add_child(scroll)
	tech_box=VBoxContainer.new()
	tech_box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	tech_box.add_theme_constant_override("separation",9)
	scroll.add_child(tech_box)
