extends "res://scripts/screens/InventoryScreen.gd"

const PAPER_DOLL_SCENE:=preload("res://scenes/ui/PaperDoll.tscn")

func _build()->void:
	var margin=MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",22)
	margin.add_theme_constant_override("margin_right",22)
	margin.add_theme_constant_override("margin_top",16)
	margin.add_theme_constant_override("margin_bottom",16)
	add_child(margin)
	var root=HBoxContainer.new()
	root.size_flags_vertical=Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation",16)
	margin.add_child(root)

	var left=PanelContainer.new()
	left.custom_minimum_size.x=370
	left.size_flags_vertical=Control.SIZE_EXPAND_FILL
	left.add_theme_stylebox_override("panel",UIFactory.panel(Color("#151b2a"),12,Color("#35415d")))
	root.add_child(left)
	var left_margin=MarginContainer.new()
	left_margin.add_theme_constant_override("margin_left",12)
	left_margin.add_theme_constant_override("margin_right",12)
	left_margin.add_theme_constant_override("margin_top",10)
	left_margin.add_theme_constant_override("margin_bottom",10)
	left.add_child(left_margin)
	var left_v=VBoxContainer.new()
	left_margin.add_child(left_v)
	left_v.add_child(UIFactory.title("Inventory",24))
	var intro=UIFactory.label("Regional equipment families make where an item came from matter. Mix affixes, sets and raw power instead of chasing one number.",12,Color("#92a0bf"))
	intro.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	left_v.add_child(intro)
	left_v.add_child(UIFactory.hsep())
	var item_scroll=ScrollContainer.new()
	item_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	item_scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	item_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	left_v.add_child(item_scroll)
	item_list=VBoxContainer.new()
	item_list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	item_list.add_theme_constant_override("separation",6)
	item_scroll.add_child(item_list)

	var middle=PanelContainer.new()
	middle.custom_minimum_size.x=500
	middle.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	middle.size_flags_vertical=Control.SIZE_EXPAND_FILL
	middle.add_theme_stylebox_override("panel",UIFactory.panel(Color("#121827"),12,Color("#38445f")))
	root.add_child(middle)
	var mid_margin=MarginContainer.new()
	mid_margin.add_theme_constant_override("margin_left",10)
	mid_margin.add_theme_constant_override("margin_right",10)
	mid_margin.add_theme_constant_override("margin_top",8)
	mid_margin.add_theme_constant_override("margin_bottom",8)
	middle.add_child(mid_margin)
	var mid=VBoxContainer.new()
	mid_margin.add_child(mid)
	var title=UIFactory.title("Warden",26)
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	mid.add_child(title)
	var subtitle=UIFactory.label("Level %d · Renown %d · Power %d"%[GameState.player.level,GameState.player.renown,GameState.total_power()],13,Color("#99a7c7"))
	subtitle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	mid.add_child(subtitle)
	build_summary=UIFactory.label("",11,Color("#c5b98e"))
	build_summary.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	build_summary.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	mid.add_child(build_summary)
	doll=PAPER_DOLL_SCENE.instantiate()
	doll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	doll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	mid.add_child(doll)
	var hint=UIFactory.label("Paper-doll composition lives in scenes/ui/PaperDoll.tscn. Body, slots and future armor layers can be repositioned visually in Godot.",10,Color("#7f8ca9"))
	hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	mid.add_child(hint)

	var right=PanelContainer.new()
	right.custom_minimum_size.x=390
	right.size_flags_vertical=Control.SIZE_EXPAND_FILL
	right.add_theme_stylebox_override("panel",UIFactory.panel(Color("#151b2a"),12,Color("#35415d")))
	root.add_child(right)
	var right_margin=MarginContainer.new()
	right_margin.add_theme_constant_override("margin_left",12)
	right_margin.add_theme_constant_override("margin_right",12)
	right_margin.add_theme_constant_override("margin_top",10)
	right_margin.add_theme_constant_override("margin_bottom",10)
	right.add_child(right_margin)
	var detail_scroll=ScrollContainer.new()
	detail_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	detail_scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	detail_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	right_margin.add_child(detail_scroll)
	detail=VBoxContainer.new()
	detail.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation",7)
	detail_scroll.add_child(detail)

func _refresh_detail()->void:
	super._refresh_detail()
	_make_column_wrap(detail)

func _make_column_wrap(container:Node)->void:
	for child in container.get_children():
		if child is Label:
			child.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			child.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		elif child is Container:
			_make_column_wrap(child)
