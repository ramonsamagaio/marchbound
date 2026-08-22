extends Control

var building_box:GridContainer
var tech_box:VBoxContainer
var settlement_summary:VBoxContainer
var building_defs={"town_hall":["Town Hall","Raises command, unlocks settlement tiers."],"lumberyard":["Lumberyard","Steady Wood production."],"quarry":["Quarry","Stone extraction and construction supply."],"farm":["Farmstead","Food for citizens and armies."],"barracks":["Barracks","Recruit and train military units."],"forge":["Forge","Iron production and equipment upgrades."],"arcane_lab":["Arcane Lab","Mana production and magical research."],"market":["Trade Hall","Gold income and commerce infrastructure."]}

func _ready()->void:
	_build(); GameState.changed.connect(refresh); refresh()
func _exit_tree()->void:
	if GameState.changed.is_connected(refresh): GameState.changed.disconnect(refresh)
func _build()->void:
	var margin=MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); margin.add_theme_constant_override("margin_left",24); margin.add_theme_constant_override("margin_right",24); margin.add_theme_constant_override("margin_top",18); margin.add_theme_constant_override("margin_bottom",18); add_child(margin)
	var root=HBoxContainer.new(); root.add_theme_constant_override("separation",16); margin.add_child(root)
	var left=VBoxContainer.new(); left.size_flags_horizontal=Control.SIZE_EXPAND_FILL; root.add_child(left)
	var title_row=HBoxContainer.new(); left.add_child(title_row); title_row.add_child(UIFactory.title("Settlement · Dawnkeep",28)); title_row.add_child(UIFactory.spacer()); title_row.add_child(UIFactory.button("Ride to World Map",func():GameState.screen_requested.emit("world"),Color("#5b4b2d")))
	left.add_child(UIFactory.label("Build a machine that feeds the next expedition. Every upgrade should make the frontier tempt you farther.",14,Color("#9daacb"))); left.add_child(UIFactory.hsep())
	settlement_summary=VBoxContainer.new(); left.add_child(settlement_summary)
	var scroll=ScrollContainer.new(); scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL; left.add_child(scroll)
	building_box=GridContainer.new(); building_box.columns=2; building_box.size_flags_horizontal=Control.SIZE_EXPAND_FILL; building_box.add_theme_constant_override("h_separation",10); building_box.add_theme_constant_override("v_separation",10); scroll.add_child(building_box)
	var right=PanelContainer.new(); right.custom_minimum_size.x=350; right.add_theme_stylebox_override("panel",UIFactory.panel(Color("#141a29"),12,Color("#34405d"))); root.add_child(right)
	tech_box=VBoxContainer.new(); tech_box.add_theme_constant_override("separation",9); right.add_child(tech_box)
func refresh()->void:
	if not is_inside_tree():return
	UIFactory.clear_children(settlement_summary); var income=GameState.resource_income_per_minute(); var row=HBoxContainer.new(); settlement_summary.add_child(row); row.add_child(UIFactory.label("Settlement Tier %d"%GameState.buildings.town_hall,17,Color("#f0dfae"))); row.add_child(UIFactory.spacer()); row.add_child(UIFactory.label("Power %d"%GameState.total_power(),15)); settlement_summary.add_child(UIFactory.label("Income/min  Gold +%d · Wood +%d · Stone +%d · Iron +%d · Food +%d · Mana +%.1f"%[income.gold,income.wood,income.stone,income.iron,income.food,income.mana],13,Color("#9fd3a7")))
	UIFactory.clear_children(building_box)
	for id in building_defs: building_box.add_child(_building_card(id))
	UIFactory.clear_children(tech_box); tech_box.add_child(UIFactory.title("Research Council",23)); tech_box.add_child(UIFactory.label("Technologies permanently widen your strategic options.",13,Color("#99a7ca"))); tech_box.add_child(UIFactory.hsep())
	for branch in GameState.tech:
		var row2=VBoxContainer.new(); var h=HBoxContainer.new(); row2.add_child(h); h.add_child(UIFactory.label("%s  T%d"%[GameState.pretty(branch),GameState.tech[branch]],15)); h.add_child(UIFactory.spacer()); var cost=GameState.research_cost(branch); var b=UIFactory.button("Research",func(bn=branch):GameState.research(bn),Color("#34345c")); b.custom_minimum_size=Vector2(92,32); h.add_child(b); row2.add_child(UIFactory.label(UIFactory.cost_text(cost),11,Color("#8995b4"))); tech_box.add_child(row2)
	tech_box.add_child(UIFactory.hsep()); tech_box.add_child(UIFactory.label("Long Game: Frontier Seasons",16,Color("#f0dfae"))); tech_box.add_child(UIFactory.label("Renown %d / %d · Highest Threat %d"%[GameState.player.renown,GameState.prestige_requirement(),GameState.world.highest_threat],13)); var season=UIFactory.button("Advance Frontier Season",GameState.advance_season,Color("#5d3a48")); season.disabled=not GameState.can_advance_season(); tech_box.add_child(season)
func _building_card(id:String)->PanelContainer:
	var p=PanelContainer.new(); p.custom_minimum_size=Vector2(360,124); p.add_theme_stylebox_override("panel",UIFactory.panel(Color("#181f31"),10,Color("#35415f"))); var v=VBoxContainer.new(); p.add_child(v); var h=HBoxContainer.new(); v.add_child(h); h.add_child(UIFactory.label("%s  Lv.%d"%[building_defs[id][0],GameState.buildings[id]],17,Color("#e8dcbb"))); h.add_child(UIFactory.spacer()); var b=UIFactory.button("Upgrade",func():GameState.upgrade_building(id),Color("#39445e")); b.custom_minimum_size=Vector2(88,32); h.add_child(b); v.add_child(UIFactory.label(building_defs[id][1],12,Color("#9ca8c5"))); v.add_child(UIFactory.label(UIFactory.cost_text(GameState.building_cost(id)),11,Color("#c3a97b"))); return p
