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
	left.add_child(UIFactory.label("Build the army, then decide what kind of Warden leads it. Every level awards a permanent Talent Point.",13,Color("#9ca8c5")))
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
	UIFactory.clear_children(list)
	for unit in defs:
		var p=PanelContainer.new()
		p.add_theme_stylebox_override("panel",UIFactory.panel(Color("#181f31"),10,Color("#35415f")))
		var v=VBoxContainer.new()
		p.add_child(v)
		var h=HBoxContainer.new()
		v.add_child(h)
		h.add_child(UIFactory.label("%s · Rank %d"%[defs[unit][0],GameState.unit_levels[unit]],18,Color("#eadfbf")))
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
		list.add_child(p)

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
	summary.add_child(UIFactory.label("WARDEN TALENTS",16,Color("#f0dfae")))
	summary.add_child(UIFactory.label("Permanent ranks. Your first point is available immediately so the build starts before the first expedition.",11,Color("#9ca8c5")))
	for id in GameState.TALENT_ORDER:
		summary.add_child(_talent_card(id))

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
