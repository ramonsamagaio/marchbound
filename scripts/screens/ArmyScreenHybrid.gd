extends Control

const LAYOUT_SCENE:=preload("res://scenes/ui/ArmyHybrid.tscn")
const FOUNDING:Array[String] = ["militia","archer","wolf","mage"]

var layout:Control
var roster_box:VBoxContainer
var management:VBoxContainer
var summary_label:Label

func _ready() -> void:
	UnitRoster.ensure_schema()
	UnitProgression.ensure_schema()
	_build()
	GameState.changed.connect(refresh)
	refresh()

func _exit_tree() -> void:
	if GameState.changed.is_connected(refresh): GameState.changed.disconnect(refresh)

func _build() -> void:
	layout = LAYOUT_SCENE.instantiate()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layout)
	var side:PanelContainer = layout.get_node("Margin/Root/Right")
	side.add_theme_stylebox_override("panel",UIFactory.panel(Color("#141a29"),12,Color("#35415d")))
	var hint:Label = layout.get_node("Margin/Root/Left/Hint")
	hint.add_theme_color_override("font_color",Color("#9ba8bd"))
	roster_box = layout.get_node("Margin/Root/Left/RosterScroll/Roster")
	management = layout.get_node("Margin/Root/Right/RightMargin/Scroll/Management")
	summary_label = layout.get_node("Margin/Root/Left/Header/Summary")
	summary_label.add_theme_color_override("font_color",Color("#a9b5c9"))

func refresh() -> void:
	if not is_inside_tree(): return
	UnitRoster.ensure_schema()
	UnitProgression.ensure_schema()
	var field:Array = UnitRoster.field_units()
	var garrison:Array = UnitRoster.garrison_units()
	var reserve:Array = UnitRoster.reserve_units()
	summary_label.text = "FIELD %d · %d/%d CMD  |  GARRISON %d · DEF %d  |  RESERVE %d"%[
		field.size(),UnitRoster.field_command_used(),GameState.command_capacity(),garrison.size(),_garrison_defense(garrison),reserve.size()
	]
	UIFactory.clear_children(roster_box)
	_add_roster_section("FIELD PARTY · PHYSICALLY FOLLOWS THE WARDEN",field,Color("#a9d8b9"))
	_add_roster_section("GARRISON · STAYS BEHIND TO PROTECT SETTLEMENTS",garrison,Color("#d5bf83"))
	_add_roster_section("RESERVE",reserve,Color("#9ba8bd"))
	UIFactory.clear_children(management)
	management.add_child(UIFactory.title("Deployment",22))
	management.add_child(UIFactory.label("Field Command %d / %d"%[UnitRoster.field_command_used(),GameState.command_capacity()],15,Color("#f0dfae")))
	management.add_child(UIFactory.label("Only FIELD units spawn around your Warden in local AREAs. Garrison strength is reserved for settlement defense, raids and future PvP sieges.",11,Color("#98a6bd")))
	management.add_child(UIFactory.hsep())
	management.add_child(UIFactory.label("RECRUIT INDIVIDUALS",15,Color("#f0dfae")))
	for family:String in _recruitable_families():
		management.add_child(_recruit_card(family))
	management.add_child(UIFactory.hsep())
	management.add_child(UIFactory.label("FOUNDING COMPANY TRAINING",15,Color("#f0dfae")))
	for family:String in FOUNDING:
		management.add_child(_training_card(family))
	management.add_child(UIFactory.hsep())
	management.add_child(UIFactory.label("WARDEN",15,Color("#f0dfae")))
	management.add_child(UIFactory.label("Level %d · Renown %d · Talent Points %d"%[GameState.player.level,GameState.player.renown,GameState.player.skill_points],12,Color("#bdc8da")))

func _add_roster_section(title:String,source:Array,color:Color) -> void:
	roster_box.add_child(UIFactory.label(title,13,color))
	if source.is_empty():
		roster_box.add_child(UIFactory.label("Nobody assigned.",11,Color("#778398")))
		return
	for raw:Variant in source:
		if raw is Dictionary: roster_box.add_child(_individual_card(Dictionary(raw)))
	roster_box.add_child(UIFactory.hsep())

func _individual_card(record:Dictionary) -> PanelContainer:
	var panel:=PanelContainer.new()
	var elite:bool = bool(record.get("elite",false))
	var border:Color = Color("#c89beb") if elite else Color("#3a4861")
	panel.add_theme_stylebox_override("panel",UIFactory.panel(Color("#151c2a"),9,border))
	var row:=HBoxContainer.new(); row.add_theme_constant_override("separation",10); panel.add_child(row)
	var art:=TextureRect.new(); art.custom_minimum_size=Vector2(68,78)
	art.texture=VisualAtlas.texture(VisualAtlas.unit_sprite_id(String(record.get("family","militia"))))
	art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; row.add_child(art)
	var text:=VBoxContainer.new(); text.size_flags_horizontal=Control.SIZE_EXPAND_FILL; row.add_child(text)
	text.add_child(UIFactory.label(UnitRoster.display_name(record),15,Color("#eadfbf") if not elite else Color("#e1c0ff")))
	text.add_child(UIFactory.label(UnitRoster.quality_line(record),11,Color("#9eabc1")))
	var xp:int = int(record.get("xp",0)); var level:int = int(record.get("level",1))
	text.add_child(UIFactory.label("XP %d/%d · HP %d%% · Kills %d"%[xp,UnitRoster.xp_to_next(level),int(round(float(record.get("hp_pct",1.0))*100.0)),int(record.get("kills",0))],10,Color("#8897ad")))
	var deeds:Array = Array(record.get("deeds",[]))
	if not deeds.is_empty(): text.add_child(UIFactory.label("Deeds · "+", ".join(deeds),10,Color("#c8ae78")))
	var prefix:String = String(record.get("prefix",""))
	if prefix != "":
		var desc:=UIFactory.label(String(UnitRoster.prefix_data(prefix).get("description","")),10,Color("#8795ad")); desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; text.add_child(desc)
	var buttons:=VBoxContainer.new(); buttons.custom_minimum_size.x=114; row.add_child(buttons)
	var uid:String = String(record.get("uid","")); var assignment:String = String(record.get("assignment",UnitRoster.ASSIGN_FIELD))
	for option:String in [UnitRoster.ASSIGN_FIELD,UnitRoster.ASSIGN_GARRISON,UnitRoster.ASSIGN_RESERVE]:
		var button:=UIFactory.button(option.to_upper(),func(value=option,id=uid):UnitRoster.set_assignment(id,value),Color("#3a5544") if option==UnitRoster.ASSIGN_FIELD else (Color("#554b34") if option==UnitRoster.ASSIGN_GARRISON else Color("#353d4d")))
		button.disabled = assignment == option
		buttons.add_child(button)
	return panel

func _recruit_card(family:String) -> PanelContainer:
	var panel:=PanelContainer.new(); panel.add_theme_stylebox_override("panel",UIFactory.panel(Color("#192231"),7,Color("#36465d")))
	var row:=HBoxContainer.new(); panel.add_child(row)
	var text:=VBoxContainer.new(); text.size_flags_horizontal=Control.SIZE_EXPAND_FILL; row.add_child(text)
	text.add_child(UIFactory.label(_family_name(family),13,Color("#dfe3d3")))
	text.add_child(UIFactory.label("Command %d · %s"%[GameState.unit_command_cost(family),UIFactory.cost_text(GameState.recruitment_cost(family))],10,Color("#9da9bc")))
	var button:=UIFactory.button("Recruit",func(id=family):UnitRoster.recruit_individual(id),Color("#385044"))
	button.disabled = not GameState.can_afford(GameState.recruitment_cost(family))
	row.add_child(button)
	return panel

func _training_card(family:String) -> PanelContainer:
	var panel:=PanelContainer.new(); panel.add_theme_stylebox_override("panel",UIFactory.panel(Color("#1b2131"),7,Color("#3a465d")))
	var box:=VBoxContainer.new(); panel.add_child(box)
	var row:=HBoxContainer.new(); box.add_child(row)
	row.add_child(UIFactory.label("%s · Company Rank %d"%[_family_name(family),int(GameState.unit_levels.get(family,1))],13,Color("#e0d6b8")))
	row.add_child(UIFactory.spacer())
	var train:=UIFactory.button("Train Rank",func(id=family):GameState.upgrade_unit(id),Color("#4b3d57")); row.add_child(train)
	if family in UnitProgression.UNIT_ORDER and not UnitProgression.is_evolved(family) and int(GameState.unit_levels.get(family,1)) >= UnitProgression.REQUIRED_RANK:
		box.add_child(UIFactory.label("EVOLUTION READY · permanent company doctrine",10,Color("#d8bd7d")))
		var branches:Dictionary = UnitProgression.branches_for(family)
		for raw_branch:Variant in branches.keys():
			var branch:String = String(raw_branch); var data:Dictionary = Dictionary(branches[raw_branch])
			var evolve:=UIFactory.button("%s · %s"%[String(data.get("name",branch)),String(data.get("role",""))],func(u=family,b=branch):UnitProgression.evolve(u,b),Color("#46584b"))
			evolve.disabled = not GameState.can_afford(UnitProgression.evolution_cost(family,branch))
			box.add_child(evolve)
	elif family in UnitProgression.UNIT_ORDER and UnitProgression.is_evolved(family):
		var branch:String = UnitProgression.evolution(family); var data:Dictionary = UnitProgression.branch_data(family,branch)
		box.add_child(UIFactory.label("EVOLVED · %s · %s"%[String(data.get("name",branch)),String(data.get("role",""))],10,Color("#9fcfb4")))
	return panel

func _recruitable_families() -> Array[String]:
	var result:Array[String] = FOUNDING.duplicate()
	for id:String in GameState.unlocked_monsters():
		if id not in result: result.append(id)
	return result

func _family_name(family:String) -> String:
	return MonsterRoster.display_name(family) if MonsterRoster.has(family) else UnitProgression.display_name(family)

func _garrison_defense(source:Array) -> int:
	var total:float = 0.0
	for raw:Variant in source:
		if not (raw is Dictionary): continue
		var record:Dictionary = Dictionary(raw); var family:String = String(record.get("family","militia"))
		var base:float = float(MonsterRoster.power(family)) if MonsterRoster.has(family) else float({"militia":12,"archer":22,"wolf":31,"mage":48}.get(family,10))
		total += base*float(record.get("level",1))*UnitRoster.damage_mult(record)
	return int(round(total))
