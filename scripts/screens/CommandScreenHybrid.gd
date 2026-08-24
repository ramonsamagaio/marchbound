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
	layout=LAYOUT_SCENE.instantiate(); layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(layout)
	var summary_panel:PanelContainer=layout.get_node("Margin/Root/Left/SummaryPanel")
	summary_panel.add_theme_stylebox_override("panel",UIFactory.panel(Color("#17221b"),10,Color("#415342")))
	var side:PanelContainer=layout.get_node("Margin/Root/Side")
	side.add_theme_stylebox_override("panel",UIFactory.panel(Color("#141a29"),12,Color("#35415d")))
	var intro:Label=layout.get_node("Margin/Root/Left/Intro")
	intro.text="A strategic interface over physical settlements. Buildings, armies and claims live in the world; this screen only commands them."
	intro.add_theme_color_override("font_color",Color("#9eaac0"))
	location=layout.get_node("Margin/Root/Left/Header/Location"); location.add_theme_color_override("font_color",Color("#9eaac0"))
	summary=layout.get_node("Margin/Root/Left/SummaryPanel/Summary")
	body=layout.get_node("Margin/Root/Left/BodyScroll/Body")
	actions=layout.get_node("Margin/Root/Side/SideMargin/Actions")

func refresh() -> void:
	if not is_inside_tree(): return
	UnitRoster.ensure_schema()
	var current:Vector2i=WorldAreaManager.current_macro()
	var capital:Dictionary=AreaEcology.capital()
	var capital_pos:=Vector2i(int(capital.get("x",0)),int(capital.get("y",0)))
	location.text="Warden [%d,%d] · Capital [%d,%d]"%[current.x,current.y,capital_pos.x,capital_pos.y]

	UIFactory.clear_children(summary)
	summary.add_child(UIFactory.label("PHYSICAL SETTLEMENT NETWORK",15,Color("#a9d8b9")))
	summary.add_child(UIFactory.label("Capital [%d,%d] · %d settlement claim%s"%[capital_pos.x,capital_pos.y,_all_claims().size(),"s" if _all_claims().size()!=1 else ""],12,Color("#c4cedd")))
	summary.add_child(UIFactory.label("Field %d · Garrison %d · Reserve %d · Command %d/%d"%[
		UnitRoster.field_units().size(),UnitRoster.garrison_units().size(),UnitRoster.reserve_units().size(),UnitRoster.field_command_used(),GameState.command_capacity()
	],12,Color("#c4cedd")))
	var income:Dictionary=GameState.resource_income_per_minute()
	summary.add_child(UIFactory.label("Legacy income/min · Gold %d · Wood %d · Stone %d · Iron %d · Food %d · Mana %.1f"%[
		int(income.get("gold",0)),int(income.get("wood",0)),int(income.get("stone",0)),int(income.get("iron",0)),int(income.get("food",0)),float(income.get("mana",0.0))
	],11,Color("#9fd3a7")))

	UIFactory.clear_children(body)
	body.add_child(UIFactory.label("SETTLEMENTS",15,Color("#f0dfae")))
	var settlements:Array=_all_claims()
	if settlements.is_empty():
		body.add_child(UIFactory.label("No settlement claims. Clear a local radius and build a Town Hall to found one.",12,Color("#9ca8bc")))
	else:
		for entry:Dictionary in settlements:
			var macro:Vector2i=Vector2i(int(entry.get("mx",0)),int(entry.get("my",0)))
			var claim:Dictionary=Dictionary(entry.get("claim",{}))
			var row:=HBoxContainer.new(); body.add_child(row)
			var tag:String="CAPITAL" if bool(claim.get("capital",false)) else String(claim.get("kind","settlement")).to_upper()
			var structures:int=WorldAreaManager.structures(macro).size()
			var label:=UIFactory.label("[%d,%d] · %s · %d structures · radius %d"%[macro.x,macro.y,tag,structures,int(claim.get("radius",0))],12,Color("#c4cedd"))
			label.size_flags_horizontal=Control.SIZE_EXPAND_FILL; row.add_child(label)
			if not bool(claim.get("capital",false)):
				var cid:String=String(claim.get("id",""))
				row.add_child(UIFactory.button("MAKE CAPITAL",func(p=macro,id=cid):_make_capital(p,id),Color("#4b573d")))

	body.add_child(UIFactory.hsep())
	body.add_child(UIFactory.label("CURRENT AREA INFRASTRUCTURE",15,Color("#f0dfae")))
	var counts:Dictionary={}
	for raw:Variant in WorldAreaManager.structures(current):
		if not (raw is Dictionary): continue
		var id:String=String(Dictionary(raw).get("id","")); counts[id]=int(counts.get(id,0))+1
	if counts.is_empty(): body.add_child(UIFactory.label("No player structures in this AREA.",12,Color("#9ca8bc")))
	else:
		for raw_id:Variant in counts.keys():
			var id:String=String(raw_id); var definition:Dictionary=ContentDB.building(id)
			body.add_child(UIFactory.label("%dx  %s"%[int(counts[id]),String(definition.get("name",id.replace("_"," ").capitalize()))],12,Color("#c4cedd")))

	body.add_child(UIFactory.hsep())
	body.add_child(UIFactory.label("RESEARCH",15,Color("#f0dfae")))
	for branch:String in ["leadership","metallurgy","agriculture","arcana","exploration","commerce"]:
		var level:int=int(GameState.tech.get(branch,0)); var row:=HBoxContainer.new(); body.add_child(row)
		var label:=UIFactory.label("%s · Tier %d · %s"%[GameState.pretty(branch),level,UIFactory.cost_text(GameState.research_cost(branch))],12,Color("#b9c4d8")); label.size_flags_horizontal=Control.SIZE_EXPAND_FILL; row.add_child(label)
		var research:=UIFactory.button("Research",func(id=branch):GameState.research(id),Color("#3a4059")); research.disabled=not GameState.can_afford(GameState.research_cost(branch)); row.add_child(research)

	body.add_child(UIFactory.hsep())
	body.add_child(UIFactory.label("FRONTIER INTELLIGENCE",15,Color("#d8b9ef")))
	var rumor:Dictionary=FrontierManager.rumor()
	if bool(rumor.get("active",false)):
		body.add_child(UIFactory.label("Rumor: %s at [%d,%d]"%[String(rumor.get("name","Anomaly")),int(rumor.get("x",0)),int(rumor.get("y",0))],12,Color("#c8afe0")))
	var nemesis:Dictionary=RetentionManager.nemesis_data()
	if bool(nemesis.get("active",false)):
		body.add_child(UIFactory.label("Nemesis intelligence: %s · Rank %d"%[String(nemesis.get("name","Unknown")),int(nemesis.get("rank",1))],12,Color("#e5a0a8")))

	UIFactory.clear_children(actions)
	actions.add_child(UIFactory.title("COMMAND",21))
	var enter:=UIFactory.button("ENTER CURRENT AREA",_enter_current,Color("#4d603f")); enter.custom_minimum_size.y=48; actions.add_child(enter)
	if current!=capital_pos:
		var cost:int=WorldAreaManager.fast_travel_cost(capital_pos)
		var fast:=UIFactory.button("FAST TRAVEL CAPITAL · %d FOOD"%cost,func():_fast_to(capital_pos),Color("#3c4f5f")); fast.custom_minimum_size.y=48; fast.disabled=float(GameState.resources.get("food",0.0))<float(cost); actions.add_child(fast)
		actions.add_child(UIFactory.label("Walking through macro borders is always free. Fast travel spends Food for convenience.",11,Color("#8fae9a")))
	actions.add_child(UIFactory.hsep())
	actions.add_child(UIFactory.button("WAR-BAND DEPLOYMENT",func():GameState.screen_requested.emit("army"),Color("#36485a")))
	actions.add_child(UIFactory.button("EQUIPMENT / INVENTORY",func():GameState.screen_requested.emit("inventory"),Color("#3d4059")))
	actions.add_child(UIFactory.button("MARKET",func():GameState.screen_requested.emit("market"),Color("#55472f")))
	actions.add_child(UIFactory.button("WORLD MAP",func():GameState.screen_requested.emit("world"),Color("#313e51")))
	actions.add_child(UIFactory.spacer())
	actions.add_child(UIFactory.label("Town Hall founds a claim only after its local radius is clear. A settlement suppresses hostile spawning only inside that local claim, never across the whole macro AREA.",11,Color("#8f9bb2")))

func _all_claims() -> Array:
	var out:Array=[]
	var areas:Dictionary=Dictionary(GameState.world.get("areas",{}))
	for raw_key:Variant in areas.keys():
		if not (areas[raw_key] is Dictionary): continue
		var area:Dictionary=Dictionary(areas[raw_key])
		for raw_claim:Variant in Array(area.get("claims",[])):
			if not (raw_claim is Dictionary): continue
			var claim:Dictionary=Dictionary(raw_claim)
			if String(claim.get("owner","local"))!="local": continue
			out.append({"mx":int(area.get("x",0)),"my":int(area.get("y",0)),"claim":claim.duplicate(true)})
	return out

func _make_capital(position:Vector2i,claim_id:String) -> void:
	if AreaEcology.designate_capital(position,claim_id):
		GameState.toast_requested.emit("CAPITAL RELOCATED · [%d,%d] · old capital remains a settlement"%[position.x,position.y])
		SaveManager.save_game(); refresh()

func _enter_current() -> void:
	var p:Vector2i=WorldAreaManager.current_macro(); var tile:Dictionary=WorldAreaManager.tile_data(p.x,p.y)
	GameState.world["selected_tile"]=tile; GameState.screen_requested.emit("expedition")

func _fast_to(position:Vector2i) -> void:
	if not WorldAreaManager.fast_travel(position): return
	SaveManager.save_game(); _enter_current()
