extends Control

var settlement_summary:VBoxContainer
var tech_box:VBoxContainer
var selected_box:VBoxContainer
var canvas:SettlementCanvas
var selected_id := "town_hall"
var building_defs={
	"town_hall":["Town Hall","Raises Command and settlement tier."],
	"lumberyard":["Lumberyard","Steady Wood production."],
	"quarry":["Quarry","Stone extraction and construction supply."],
	"farm":["Farmstead","Food for citizens and armies."],
	"barracks":["Barracks","Recruit and train military units."],
	"forge":["Forge","Iron production and equipment upgrades."],
	"arcane_lab":["Arcane Lab","Mana production and magical research."],
	"market":["Trade Hall","Gold income and commerce infrastructure."]
}

func _ready()->void:
	RetentionManager.bank_chain()
	_build()
	GameState.changed.connect(refresh)
	RetentionManager.changed.connect(refresh)
	refresh()

func _exit_tree()->void:
	if GameState.changed.is_connected(refresh):
		GameState.changed.disconnect(refresh)
	if RetentionManager.changed.is_connected(refresh):
		RetentionManager.changed.disconnect(refresh)

func _build()->void:
	var margin=MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",18)
	margin.add_theme_constant_override("margin_right",18)
	margin.add_theme_constant_override("margin_top",14)
	margin.add_theme_constant_override("margin_bottom",14)
	add_child(margin)
	var root=HBoxContainer.new()
	root.add_theme_constant_override("separation",14)
	margin.add_child(root)

	var left=VBoxContainer.new()
	left.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	root.add_child(left)
	var title_row=HBoxContainer.new()
	left.add_child(title_row)
	title_row.add_child(UIFactory.title("Dawnkeep",28))
	title_row.add_child(UIFactory.label("  Living Settlement",13,Color("#9daacb")))
	title_row.add_child(UIFactory.spacer())
	title_row.add_child(UIFactory.button("Ride to World Map",func():GameState.screen_requested.emit("world"),Color("#5b4b2d")))
	left.add_child(UIFactory.label("Your city is now a place, not a spreadsheet. Drag buildings to reshape it; click one to upgrade it.",13,Color("#9daacb")))
	settlement_summary=VBoxContainer.new()
	left.add_child(settlement_summary)

	var board_panel=PanelContainer.new()
	board_panel.size_flags_vertical=Control.SIZE_EXPAND_FILL
	board_panel.add_theme_stylebox_override("panel",UIFactory.panel(Color("#17221b"),12,Color("#435342")))
	left.add_child(board_panel)
	canvas=SettlementCanvas.new()
	canvas.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	canvas.size_flags_vertical=Control.SIZE_EXPAND_FILL
	canvas.building_selected.connect(_select_building)
	canvas.layout_changed.connect(_layout_saved)
	board_panel.add_child(canvas)

	var selected_panel=PanelContainer.new()
	selected_panel.custom_minimum_size.y=105
	selected_panel.add_theme_stylebox_override("panel",UIFactory.panel(Color("#171e2d"),10,Color("#35415f")))
	left.add_child(selected_panel)
	selected_box=VBoxContainer.new()
	selected_panel.add_child(selected_box)

	var right=PanelContainer.new()
	right.custom_minimum_size.x=335
	right.add_theme_stylebox_override("panel",UIFactory.panel(Color("#141a29"),12,Color("#34405d")))
	root.add_child(right)
	var scroll=ScrollContainer.new()
	right.add_child(scroll)
	tech_box=VBoxContainer.new()
	tech_box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	tech_box.add_theme_constant_override("separation",9)
	scroll.add_child(tech_box)

func refresh()->void:
	if not is_inside_tree():
		return
	GameState.ensure_schema()
	RetentionManager.ensure_schema()
	UIFactory.clear_children(settlement_summary)
	var income=GameState.resource_income_per_minute()
	var row=HBoxContainer.new()
	settlement_summary.add_child(row)
	row.add_child(UIFactory.label("Settlement Tier %d"%GameState.buildings.town_hall,16,Color("#f0dfae")))
	row.add_child(UIFactory.spacer())
	row.add_child(UIFactory.label("Power %d · %d territories · Threat %d · Renown %d"%[GameState.total_power(),GameState.claimed_count(),GameState.world.highest_threat,GameState.player.renown],13,Color("#d5bf83")))
	settlement_summary.add_child(UIFactory.label("Income/min  Gold +%d · Wood +%d · Stone +%d · Iron +%d · Food +%d · Mana +%.1f"%[income.gold,income.wood,income.stone,income.iron,income.food,income.mana],12,Color("#9fd3a7")))
	var n:Dictionary=RetentionManager.nemesis_data()
	if bool(n.get("active",false)):
		settlement_summary.add_child(UIFactory.label("NEMESIS · %s · Rank %d · %s · last seen in %s"%[String(n.get("name","Unknown")),int(n.get("rank",1)),String(n.get("trait","relentless")).capitalize(),String(n.get("biome","the frontier"))],12,Color("#e5a0a8")))
	_refresh_selected()
	_refresh_research()
	if canvas:
		canvas.queue_redraw()

func _select_building(id:String)->void:
	selected_id=id
	_refresh_selected()

func _layout_saved()->void:
	GameState.toast_requested.emit("Dawnkeep layout saved locally.")

func _refresh_selected()->void:
	if not selected_box:
		return
	UIFactory.clear_children(selected_box)
	var level=int(GameState.buildings.get(selected_id,0))
	var h=HBoxContainer.new()
	selected_box.add_child(h)
	h.add_child(UIFactory.title("%s · Lv.%d"%[building_defs[selected_id][0],level],19))
	h.add_child(UIFactory.spacer())
	var upgrade=UIFactory.button("Upgrade",func():GameState.upgrade_building(selected_id),Color("#39445e"))
	upgrade.custom_minimum_size=Vector2(100,34)
	h.add_child(upgrade)
	selected_box.add_child(UIFactory.label(building_defs[selected_id][1],12,Color("#9ca8c5")))
	var foot=HBoxContainer.new()
	selected_box.add_child(foot)
	foot.add_child(UIFactory.label("Cost: %s"%UIFactory.cost_text(GameState.building_cost(selected_id)),11,Color("#c3a97b")))
	foot.add_child(UIFactory.spacer())
	var reset=UIFactory.button("Reset city layout",func():canvas.reset_layout(),Color("#30394c"))
	reset.custom_minimum_size.x=118
	foot.add_child(reset)

func _refresh_research()->void:
	UIFactory.clear_children(tech_box)
	tech_box.add_child(UIFactory.title("Research Council",22))
	tech_box.add_child(UIFactory.label("Technology should unlock new ways to play, not only larger numbers.",12,Color("#99a7ca")))
	tech_box.add_child(UIFactory.hsep())
	for branch in GameState.tech:
		var card=VBoxContainer.new()
		var h=HBoxContainer.new()
		card.add_child(h)
		h.add_child(UIFactory.label("%s  T%d"%[GameState.pretty(branch),GameState.tech[branch]],14))
		h.add_child(UIFactory.spacer())
		var b=UIFactory.button("Research",func(bn=branch):GameState.research(bn),Color("#34345c"))
		b.custom_minimum_size=Vector2(88,30)
		h.add_child(b)
		card.add_child(UIFactory.label(UIFactory.cost_text(GameState.research_cost(branch)),10,Color("#8995b4")))
		tech_box.add_child(card)
	tech_box.add_child(UIFactory.hsep())
	tech_box.add_child(UIFactory.label("Frontier Seasons",16,Color("#f0dfae")))
	tech_box.add_child(UIFactory.label("Renown %d / %d · Highest Threat %d"%[GameState.player.renown,GameState.prestige_requirement(),GameState.world.highest_threat],12))
	tech_box.add_child(UIFactory.label("A new season keeps meta-power but redraws the frontier around Dawnkeep.",10,Color("#8995b4")))
	var season=UIFactory.button("Advance Frontier Season",GameState.advance_season,Color("#5d3a48"))
	season.disabled=not GameState.can_advance_season()
	tech_box.add_child(season)
