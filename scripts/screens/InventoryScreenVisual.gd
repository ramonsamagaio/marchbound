extends "res://scripts/screens/InventoryScreen.gd"

const PAPER_DOLL_SCENE:=preload("res://scenes/ui/PaperDoll.tscn")

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

	var left=PanelContainer.new()
	left.custom_minimum_size.x=390
	left.add_theme_stylebox_override("panel",UIFactory.panel(Color("#151b2a"),12,Color("#35415d")))
	root.add_child(left)
	var left_v=VBoxContainer.new()
	left.add_child(left_v)
	left_v.add_child(UIFactory.title("Inventory",24))
	left_v.add_child(UIFactory.label("Regional equipment families make where an item came from matter. Mix affixes, sets and raw power instead of chasing one number.",12,Color("#92a0bf")))
	left_v.add_child(UIFactory.hsep())
	var item_scroll=ScrollContainer.new()
	item_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	left_v.add_child(item_scroll)
	item_list=VBoxContainer.new()
	item_list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	item_list.add_theme_constant_override("separation",6)
	item_scroll.add_child(item_list)

	var middle=PanelContainer.new()
	middle.custom_minimum_size.x=520
	middle.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	middle.add_theme_stylebox_override("panel",UIFactory.panel(Color("#121827"),12,Color("#38445f")))
	root.add_child(middle)
	var mid=VBoxContainer.new()
	middle.add_child(mid)
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
	var hint=UIFactory.label("Paper-doll composition now lives in scenes/ui/PaperDoll.tscn. Replace body, slot art and future armor layers visually in Godot instead of editing drawing code.",11,Color("#7f8ca9"))
	hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	mid.add_child(hint)

	var right=PanelContainer.new()
	right.custom_minimum_size.x=420
	right.add_theme_stylebox_override("panel",UIFactory.panel(Color("#151b2a"),12,Color("#35415d")))
	root.add_child(right)
	var detail_scroll=ScrollContainer.new()
	right.add_child(detail_scroll)
	detail=VBoxContainer.new()
	detail.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation",7)
	detail_scroll.add_child(detail)
