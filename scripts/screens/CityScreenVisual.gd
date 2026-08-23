extends "res://scripts/screens/CityScreen.gd"

func _build()->void:
	var margin=MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",22)
	margin.add_theme_constant_override("margin_right",22)
	margin.add_theme_constant_override("margin_top",16)
	margin.add_theme_constant_override("margin_bottom",16)
	add_child(margin)
	var root=HBoxContainer.new()
	root.add_theme_constant_override("separation",16)
	margin.add_child(root)

	var left=VBoxContainer.new()
	left.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	root.add_child(left)
	var title_row=HBoxContainer.new()
	left.add_child(title_row)
	title_row.add_child(UIFactory.title("Dawnkeep",30))
	title_row.add_child(UIFactory.label("  Living Settlement",14,Color("#9daacb")))
	title_row.add_child(UIFactory.spacer())
	title_row.add_child(UIFactory.button("Ride to World Map",func():GameState.screen_requested.emit("world"),Color("#5b4b2d")))
	left.add_child(UIFactory.label("Drag buildings directly in the scene. The atlas art is provisional, but the settlement now uses the same visual language as the battle and world map.",13,Color("#9daacb")))
	settlement_summary=VBoxContainer.new()
	left.add_child(settlement_summary)

	var board_panel=PanelContainer.new()
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
	selected_panel.custom_minimum_size.y=118
	selected_panel.add_theme_stylebox_override("panel",UIFactory.panel(Color("#171e2d"),10,Color("#35415f")))
	left.add_child(selected_panel)
	selected_box=VBoxContainer.new()
	selected_panel.add_child(selected_box)

	var right=PanelContainer.new()
	right.custom_minimum_size.x=390
	right.add_theme_stylebox_override("panel",UIFactory.panel(Color("#141a29"),12,Color("#34405d")))
	root.add_child(right)
	var scroll=ScrollContainer.new()
	right.add_child(scroll)
	tech_box=VBoxContainer.new()
	tech_box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	tech_box.add_theme_constant_override("separation",9)
	scroll.add_child(tech_box)
