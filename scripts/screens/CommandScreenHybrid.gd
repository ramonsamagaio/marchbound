extends Control

const LAYOUT_SCENE:=preload("res://scenes/ui/CommandCenterHybrid.tscn")

var layout:Control
var summary:VBoxContainer
var body:VBoxContainer
var actions:VBoxContainer
var location:Label

func _ready() -> void:
	WorldAreaManager.ensure_schema()
	UnitRoster.ensure_schema()
	RetentionManager.bank_chain()
	_build()
	GameState.changed.connect(refresh)
	WorldAreaManager.changed.connect(refresh)
	refresh()

func _exit_tree() -> void:
	if GameState.changed.is_connected(refresh): GameState.changed.disconnect(refresh)
	if WorldAreaManager.changed.is_connected(refresh): WorldAreaManager.changed.disconnect(refresh)

func _build() -> void:
	layout = LAYOUT_SCENE.instantiate()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layout)
	var summary_panel:PanelContainer = layout.get_node("Margin/Root/Left/SummaryPanel")
	summary_panel.add_theme_stylebox_override("panel",UIFactory.panel(Color("#17221b"),10,Color("#415342")))
	var side:PanelContainer = layout.get_node("Margin/Root/Side")
	side.add_theme_stylebox_override("panel",UIFactory.panel(Color("#141a29"),12,Color("#35415d")))
	var intro:Label = layout.get_node("Margin/Root/Left/Intro")
	intro.add_theme_color_override("font_color",Color("#9eaac0"))
	location = layout.get_node("Margin/Root/Left/Header/Location")
	location.add_theme_color_override("font_color",Color("#9eaac0"))
	summary = layout.get_node("Margin/Root/Left/SummaryPanel/Summary")
	body = layout.get_node("Margin/Root/Left/BodyScroll/Body")
	actions = layout.get_node("Margin/Root/Side/SideMargin/Actions")

func refresh() -> void:
	if not is_inside_tree(): return
	UnitRoster.ensure_schema()
	var current:Vector2i = WorldAreaManager.current_macro()
	location.text = "Warden [%d,%d] · %s"%[current.x,current.y,"HOME" if current==Vector2i.ZERO else "FRONTIER"]
	UIFactory.clear_children(summary)
	summary.add_child(UIFactory.label("HOME AREA · [0,0] · SAFE",15,Color("#a9d8b9")))
	summary.add_child(UIFactory.label("Field party %d · Garrison %d · Reserve %d · Field Command %d/%d"%[
		UnitRoster.field_units().size(),UnitRoster.garrison_units().size(),UnitRoster.reserve_units().size(),UnitRoster.field_command_used(),GameState.command_capacity()
	],12,Color("#c4cedd")))
	var income:Dictionary = GameState.resource_income_per_minute()
	summary.add_child(UIFactory.label("Income/min · Gold %d · Wood %d · Stone %d · Iron %d · Food %d · Mana %.1f"%[
		int(income.get("gold",0)),int(income.get("wood",0)),int(income.get("stone",0)),int(income.get("iron",0)),int(income.get("food",0)),float(income.get("mana",0.0))
	],11,Color("#9fd3a7")))

	UIFactory.clear_children(body)
	body.add_child(UIFactory.label("PHYSICAL HOME INFRASTRUCTURE",15,Color("#f0dfae")))
	var counts:Dictionary = {}
	for raw:Variant in WorldAreaManager.structures(Vector2i.ZERO):
		if not (raw is Dictionary): continue
		var entry:Dictionary = Dictionary(raw)
		var id:String = String(entry.get("id",""))
		counts[id] = int(counts.get(id,0))+1
	if counts.is_empty():
		body.add_child(UIFactory.label("Dawnkeep is empty. Enter the HOME AREA and start placing structures with B/C.",12,Color("#9ca8bc")))
	else:
		for raw_id:Variant in counts.keys():
			var id:String = String(raw_id)
			var definition:Dictionary = ContentDB.building(id)
			body.add_child(UIFactory.label("%dx  %s · %s"%[int(counts[id]),String(definition.get("name",id.replace("_"," ").capitalize())),String(definition.get("category","Structure"))],12,Color("#c4cedd")))
	body.add_child(UIFactory.hsep())
	body.add_child(UIFactory.label("RESEARCH",15,Color("#f0dfae")))
	for branch:String in ["leadership","metallurgy","agriculture","arcana","exploration","commerce"]:
		var level:int = int(GameState.tech.get(branch,0))
		var row:=HBoxContainer.new()
		body.add_child(row)
		var label:=UIFactory.label("%s · Tier %d · %s"%[GameState.pretty(branch),level,UIFactory.cost_text(GameState.research_cost(branch))],12,Color("#b9c4d8"))
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var research:=UIFactory.button("Research",func(id=branch):GameState.research(id),Color("#3a4059"))
		research.disabled = not GameState.can_afford(GameState.research_cost(branch))
		row.add_child(research)
	body.add_child(UIFactory.hsep())
	var rumor:Dictionary = FrontierManager.rumor()
	body.add_child(UIFactory.label("FRONTIER INTELLIGENCE",15,Color("#d8b9ef")))
	if bool(rumor.get("active",false)):
		body.add_child(UIFactory.label("Rumor: %s at [%d,%d] · +%d Renown"%[String(rumor.get("name","Anomaly")),int(rumor.get("x",0)),int(rumor.get("y",0)),int(rumor.get("reward_renown",0))],12,Color("#c8afe0")))
	var nemesis:Dictionary = RetentionManager.nemesis_data()
	if bool(nemesis.get("active",false)):
		body.add_child(UIFactory.label("Nemesis: %s · Rank %d · %s"%[String(nemesis.get("name","Unknown")),int(nemesis.get("rank",1)),String(nemesis.get("trait","relentless")).capitalize()],12,Color("#e5a0a8")))

	UIFactory.clear_children(actions)
	actions.add_child(UIFactory.title("COMMAND",21))
	var current_is_home:bool = current == Vector2i.ZERO
	if current_is_home:
		var enter:=UIFactory.button("ENTER HOME AREA · SAFE",_enter_home,Color("#4d603f")); enter.custom_minimum_size.y=48; actions.add_child(enter)
	else:
		var cost:int = WorldAreaManager.fast_travel_cost(Vector2i.ZERO)
		var fast:=UIFactory.button("FAST TRAVEL HOME · %d FOOD"%cost,_fast_home,Color("#3c4f5f")); fast.custom_minimum_size.y=48; fast.disabled=float(GameState.resources.get("food",0.0))<float(cost); actions.add_child(fast)
		actions.add_child(UIFactory.label("Or physically walk back through AREA borders for 0 Food.",11,Color("#8fae9a")))
	actions.add_child(UIFactory.hsep())
	actions.add_child(UIFactory.button("WAR-BAND DEPLOYMENT",func():GameState.screen_requested.emit("army"),Color("#36485a")))
	actions.add_child(UIFactory.button("EQUIPMENT / INVENTORY",func():GameState.screen_requested.emit("inventory"),Color("#3d4059")))
	actions.add_child(UIFactory.button("MARKET",func():GameState.screen_requested.emit("market"),Color("#55472f")))
	actions.add_child(UIFactory.button("WORLD MAP",func():GameState.screen_requested.emit("world"),Color("#313e51")))
	actions.add_child(UIFactory.spacer())
	actions.add_child(UIFactory.label("Building is done in-world. B places the selected structure, C cycles it, R dismantles, F interacts with stations.",11,Color("#8f9bb2")))

func _enter_home() -> void:
	WorldAreaManager.set_current_macro(Vector2i.ZERO,"center")
	var tile:Dictionary = WorldAreaManager.tile_data(0,0)
	GameState.world["selected_tile"] = tile
	GameState.screen_requested.emit("expedition")

func _fast_home() -> void:
	if not WorldAreaManager.fast_travel(Vector2i.ZERO): return
	SaveManager.save_game()
	_enter_home()
