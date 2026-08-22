extends Control

var list:VBoxContainer
var summary:VBoxContainer
var defs={
	"militia":["Militia","Cheap line infantry. Reliable bodies for 1 Command."],
	"archer":["Archer","Ranged support. Excellent behind a moving frontline."],
	"wolf":["War Wolf","Fast skirmisher that tears into isolated enemies."],
	"mage":["Mage","Expensive area damage. Requires Arcane Lab."]
}
var talent_defs={
	"bladecraft":["Bladecraft","+8% Warden damage per rank."],
	"ironheart":["Ironheart","+7% max HP per rank."],
	"pathfinder":["Pathfinder","+4% movement speed per rank."],
	"commander":["Commander","+2 Command capacity per rank."],
	"scavenger":["Scavenger","+12% harvested resource yield per rank."],
	"fortune":["Fortune","+3% expedition gear-drop chance per rank."]
}

func _ready()->void:
	UnitProgression.ensure_schema()
	_build()
	GameState.changed.connect(refresh)
	refresh()

func _exit_tree()->void:
	if GameState.changed.is_connected(refresh):
		GameState.changed.disconnect(refresh)

func _build()->void:
	var margin=MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",24)
	margin.add_theme_constant_override("margin_right",24)
	margin.add_theme_constant_override("margin_top",18)
	margin.add_theme_constant_override("margin_bottom",18)
	add_child(margin)
	var root=HBoxContainer.new()
	root.add_theme_constant_override("separation",16)
	margin.add_child(root)
	var left=VBoxContainer.new()
	left.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	root.add_child(left)
	left.add_child(UIFactory.title("Warband & Warden",28))
	left.add_child(UIFactory.label("Train a unit family to Rank 3, then lock in one permanent evolution path. The branch changes how that unit actually fights in expeditions.",13,Color("#9ca8c5")))
	left.add_child(UIFactory.hsep())
	var army_scroll=ScrollContainer.new()
	army_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	left.add_child(army_scroll)
	list=VBoxContainer.new()
	list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation",10)
	army_scroll.add_child(list)
	var side=PanelContainer.new()
	side.custom_minimum_size.x=375
	side.add_theme_stylebox_override("panel",UIFactory.panel(Color("#151b2a"),12,Color("#35415d")))
	root.add_child(side)
	var side_scroll=ScrollContainer.new()
	side.add_child(side_scroll)
	summary=VBoxContainer.new()
	summary.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	summary.add_theme_constant_override("separation",8)
	side_scroll.add_child(summary)

func refresh()->void:
	if not is_inside_tree():
		return
	UnitProgression.ensure_schema()
	UIFactory.clear_children(list)
	for unit in defs:
		list.add_child(_unit_card(unit))

	UIFactory.clear_children(summary)
	summary.add_child(UIFactory.title("Warden Growth",23))
	summary.add_child(UIFactory.label("Level %d · %d / %d XP"%[GameState.player.level,GameState.player.xp,GameState.player.xp_next],14,Color("#a8d2aa")))
	summary.add_child(UIFactory.label("Talent Points  %d"%GameState.player.skill_points,20,Color("#f0dfae")))
	summary.add_child(UIFactory.label("Power %d · Renown %d"%[GameState.total_power(),GameState.player.renown],13,Color("#9ca8c5")))
	summary.add_child(UIFactory.hsep())
	summary.add_child(UIFactory.label("COMMAND",14,Color("#f0dfae")))
	summary.add_child(UIFactory.label("%d / %d used · Army Power %d"%[GameState.command_used(),GameState.command_capacity(),GameState.army_power()],15))
	summary.add_child(UIFactory.label("Level, Leadership, Town Hall and Commander talents widen the army you can bring into each expedition.",11,Color("#8f9bb8")))
	summary.add_child(UIFactory.hsep())
	summary.add_child(UIFactory.label("EVOLUTION DOCTRINE",16,Color("#f0dfae")))
	var evolved_names := []
	for unit in UnitProgression.UNIT_ORDER:
		if UnitProgression.is_evolved(unit):
			evolved_names.append(UnitProgression.display_name(unit))
	if evolved_names.is_empty():
		summary.add_child(UIFactory.label("No unit family has evolved yet. Reach Rank 3 and choose carefully: paths are permanent in the current pre-alpha.",11,Color("#9ca8c5")))
	else:
		summary.add_child(UIFactory.label("Active: %s"%" · ".join(evolved_names),11,Color("#a7d9c5")))
	summary.add_child(UIFactory.hsep())
	summary.add_child(UIFactory.label("WARDEN TALENTS",16,Color("#f0dfae")))
	summary.add_child(UIFactory.label("Permanent ranks. Your first point is available immediately so the build starts before the first expedition.",11,Color("#9ca8c5")))
	for id in GameState.TALENT_ORDER:
		summary.add_child(_talent_card(id))

func _unit_card(unit:String)->PanelContainer:
	var p=PanelContainer.new()
	p.add_theme_stylebox_override("panel",UIFactory.panel(Color("#181f31"),10,Color("#35415f")))
	var v=VBoxContainer.new()
	p.add_child(v)
	var h=HBoxContainer.new()
	v.add_child(h)
	var title = UnitProgression.display_name(unit) if UnitProgression.is_evolved(unit) else defs[unit][0]
	h.add_child(UIFactory.label("%s · Rank %d"%[title,GameState.unit_levels[unit]],18,Color("#eadfbf")))
	h.add_child(UIFactory.spacer())
	h.add_child(UIFactory.label("×%d   Command %d ea."%[GameState.army[unit],GameState.unit_command_cost(unit)],13))
	v.add_child(UIFactory.label(defs[unit][1],12,Color("#9ca8c5")))
	var actions=HBoxContainer.new()
	v.add_child(actions)
	actions.add_child(UIFactory.button("Recruit",func(u=unit):GameState.recruit(u),Color("#33465b")))
	actions.add_child(UIFactory.label(UIFactory.cost_text(GameState.recruitment_cost(unit)),11,Color("#a8b4ce")))
	actions.add_child(UIFactory.spacer())
	var train=UIFactory.button("Train Rank",func(u=unit):GameState.upgrade_unit(u),Color("#4b3d57"))
	train.custom_minimum_size.x=105
	actions.add_child(train)
	v.add_child(UIFactory.hsep())
	if UnitProgression.is_evolved(unit):
		var branch = UnitProgression.evolution(unit)
		var data = UnitProgression.branch_data(unit,branch)
		v.add_child(UIFactory.label("EVOLVED · %s · %s"%[String(data.get("name",branch)).to_upper(),String(data.get("role",""))],13,Color("#a7d9c5")))
		v.add_child(UIFactory.label(String(data.get("description","")),11,Color("#aab7d0")))
	else:
		var rank = int(GameState.unit_levels.get(unit,1))
		if rank < UnitProgression.REQUIRED_RANK:
			v.add_child(UIFactory.label("Evolution locked · train to Rank %d (%d more)."%[UnitProgression.REQUIRED_RANK,UnitProgression.REQUIRED_RANK-rank],12,Color("#8f9bb8")))
		else:
			v.add_child(UIFactory.label("CHOOSE EVOLUTION · permanent path",12,Color("#e6c782")))
			var branches = UnitProgression.branches_for(unit)
			for branch in branches:
				v.add_child(_evolution_choice(unit,String(branch),branches[branch]))
	return p

func _evolution_choice(unit:String,branch:String,data:Dictionary)->PanelContainer:
	var p=PanelContainer.new()
	p.add_theme_stylebox_override("panel",UIFactory.panel(Color("#20283b"),7,Color("#43516f")))
	var row=HBoxContainer.new()
	p.add_child(row)
	var text=VBoxContainer.new()
	text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.add_child(text)
	text.add_child(UIFactory.label("%s · %s"%[data.get("name",branch),data.get("role","")],13,Color("#e7d8b0")))
	text.add_child(UIFactory.label(String(data.get("description","")),10,Color("#9eabc6")))
	text.add_child(UIFactory.label(UIFactory.cost_text(UnitProgression.evolution_cost(unit,branch)),10,Color("#c8aa76")))
	var choose=UIFactory.button("EVOLVE",func(u=unit,b=branch):UnitProgression.evolve(u,b),Color("#49604f"))
	choose.custom_minimum_size=Vector2(82,48)
	choose.disabled=not GameState.can_afford(UnitProgression.evolution_cost(unit,branch))
	row.add_child(choose)
	return p

func _talent_card(id:String)->PanelContainer:
	var rank=GameState.talent_rank(id)
	var p=PanelContainer.new()
	p.add_theme_stylebox_override("panel",UIFactory.panel(Color("#1a2234"),8,Color("#35415f")))
	var v=VBoxContainer.new()
	p.add_child(v)
	var row=HBoxContainer.new()
	v.add_child(row)
	row.add_child(UIFactory.label("%s  %d/%d"%[talent_defs[id][0],rank,GameState.TALENT_MAX_RANK],14,Color("#e5d9b7")))
	row.add_child(UIFactory.spacer())
	var spend=UIFactory.button("Spend 1",func(t=id):GameState.spend_talent(t),Color("#3e4567"))
	spend.custom_minimum_size.x=82
	spend.disabled=int(GameState.player.skill_points)<=0 or rank>=GameState.TALENT_MAX_RANK
	row.add_child(spend)
	v.add_child(UIFactory.label(talent_defs[id][1],11,Color("#98a5c2")))
	return p
