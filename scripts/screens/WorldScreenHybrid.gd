extends Control

const LAYOUT_SCENE:=preload("res://scenes/ui/WorldMapHybrid.tscn")

var layout:Control
var map_canvas:StrategicWorldCanvas
var info:VBoxContainer
var status:Label
var selected:Vector2i = Vector2i.ZERO

func _ready() -> void:
	WorldAreaManager.ensure_schema()
	FrontierManager.ensure_rumor()
	_build()
	selected = WorldAreaManager.current_macro()
	map_canvas.center_on(selected)
	map_canvas.select(selected)
	_refresh_side()

func _build() -> void:
	layout = LAYOUT_SCENE.instantiate()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layout)
	var map_panel:PanelContainer = layout.get_node("Margin/Root/Left/MapPanel")
	map_panel.add_theme_stylebox_override("panel",UIFactory.panel(Color("#101720"),10,Color("#364452")))
	var side:PanelContainer = layout.get_node("Margin/Root/Side")
	side.add_theme_stylebox_override("panel",UIFactory.panel(Color("#141a24"),12,Color("#344253")))
	status = layout.get_node("Margin/Root/Left/Header/Status")
	status.add_theme_color_override("font_color",Color("#a7b3c6"))
	var hint:Label = layout.get_node("Margin/Root/Left/Hint")
	hint.add_theme_color_override("font_color",Color("#a4b0c0"))
	var holder:Control = layout.get_node("Margin/Root/Left/MapPanel/MapHolder")
	map_canvas = StrategicWorldCanvas.new()
	map_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(map_canvas)
	map_canvas.set_provider(Callable(WorldAreaManager,"tile_data"))
	map_canvas.tile_selected.connect(_select_position)
	map_canvas.focus_changed.connect(_focus_changed)
	info = layout.get_node("Margin/Root/Side/SideMargin/Scroll/Info")
	_update_status()

func _focus_changed(_position:Vector2i) -> void:
	_update_status()

func _update_status() -> void:
	var p:Vector2i = WorldAreaManager.current_macro()
	status.text = "Warden [%d,%d] · Claimed %d · Atlas %d · Food %d"%[p.x,p.y,GameState.claimed_count(),FrontierManager.atlas_level(),int(GameState.resources.get("food",0.0))]

func _select_position(position:Vector2i) -> void:
	selected = position
	_refresh_side()

func _refresh_side() -> void:
	if not info: return
	UIFactory.clear_children(info)
	var tile:Dictionary = WorldAreaManager.tile_data(selected.x,selected.y)
	var current:Vector2i = WorldAreaManager.current_macro()
	var discovered:bool = bool(tile.get("discovered",false)) or bool(tile.get("home",false))
	if not discovered:
		info.add_child(UIFactory.title("UNKNOWN TERRITORY",22))
		info.add_child(UIFactory.label("The Atlas has no reliable report for [%d,%d]. Physically approach it to reveal the terrain."%[selected.x,selected.y],12,Color("#929db0")))
		info.add_child(UIFactory.hsep())
		info.add_child(UIFactory.label("PHYSICAL TRAVEL",13,Color("#f0dfae")))
		info.add_child(UIFactory.label("Walking across AREA borders never costs Food. Fast Travel is a convenience, not a movement tax.",11,Color("#a8b5c7")))
		return

	info.add_child(UIFactory.title("DAWNKEEP HOME AREA" if bool(tile.get("home",false)) else String(tile.get("biome","Frontier")),23))
	info.add_child(UIFactory.label("Territory [%d,%d] · %s"%[selected.x,selected.y,"CURRENT POSITION" if selected==current else ("VISITED" if bool(tile.get("visited",false)) else "UNVISITED")],12,Color("#9eabc2")))
	info.add_child(UIFactory.hsep())
	if bool(tile.get("home",false)):
		info.add_child(UIFactory.label("SAFE AREA",18,Color("#9fd3a7")))
		info.add_child(UIFactory.label("This is not a decorative city screen. Dawnkeep physically exists inside this AREA and its buildings are the structures you placed there.",12,Color("#b7c5d7")))
	else:
		var threat:int = int(tile.get("threat",1))
		var threat_color:Color = Color("#e3c58f") if threat < 5 else Color("#ef8e7f")
		info.add_child(UIFactory.label("DANGER %d"%threat,21,threat_color))
		info.add_child(UIFactory.label("Objective pressure: %s"%String(tile.get("objective","Frontier Claim")),13,Color("#e4cf98")))
		info.add_child(UIFactory.label("Resource richness: %s"%["Poor","Fair","Rich","Abundant"][clampi(int(tile.get("richness",1))-1,0,3)],12))
		if bool(tile.get("conquered",false)): info.add_child(UIFactory.label("✓ SECURED SUPPLY TERRITORY",11,Color("#9fd3a7")))
		elif GameState.is_accessible(selected.x,selected.y): info.add_child(UIFactory.label("◆ CLAIM FRONTIER · guardian victory secures this macro territory",11,Color("#e7cb86")))
		if bool(tile.get("boss",false)):
			info.add_child(UIFactory.label("★ %s"%String(tile.get("boss_name","Regional Boss")),15,Color("#f0b7c0")))
			var tell:=UIFactory.label(String(tile.get("boss_tell","")),11,Color("#c7a8b8")); tell.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; info.add_child(tell)
		_add_risk_forecast(tile)

	var rumor:Dictionary = FrontierManager.rumor()
	if FrontierManager.rumor_for(selected.x,selected.y):
		info.add_child(UIFactory.hsep())
		info.add_child(UIFactory.label("? ACTIVE RUMOR · %s"%String(rumor.get("name","Unknown anomaly")),14,Color("#d7b4ef")))
		var clue:=UIFactory.label(String(rumor.get("clue","Something impossible was reported here.")),11,Color("#baa7c9")); clue.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; info.add_child(clue)

	info.add_child(UIFactory.hsep())
	info.add_child(UIFactory.label("WAR-BAND DEPLOYMENT",13,Color("#f0dfae")))
	info.add_child(UIFactory.label("FIELD %d units · %d/%d Command\nGARRISON %d · RESERVE %d"%[UnitRoster.field_units().size(),UnitRoster.field_command_used(),GameState.command_capacity(),UnitRoster.garrison_units().size(),UnitRoster.reserve_units().size()],12,Color("#b8c5d8")))

	info.add_child(UIFactory.hsep())
	_add_travel_actions(tile,current)
	_update_status()

func _add_risk_forecast(tile:Dictionary) -> void:
	info.add_child(UIFactory.hsep())
	info.add_child(UIFactory.label("WHAT TO EXPECT",13,Color("#f0dfae")))
	var monsters:Array[String] = WorldAreaManager.expected_monsters(tile)
	var names:Array[String] = []
	for id:String in monsters:
		var definition:Dictionary = ContentDB.monster(id)
		names.append(String(definition.get("name",id.replace("_"," ").capitalize())))
		if names.size() >= 7: break
	var monster_text:=UIFactory.label("Enemies: "+(", ".join(names) if not names.is_empty() else "Unknown local fauna"),11,Color("#d39b9d"))
	monster_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	info.add_child(monster_text)
	var drop_ids:Array[String] = WorldAreaManager.expected_drop_ids(tile)
	var drop_names:Array[String] = []
	for id:String in drop_ids:
		var item:Dictionary = ContentDB.get_entry("items",id)
		drop_names.append(String(item.get("name",id.replace("_"," ").capitalize())))
		if drop_names.size() >= 6: break
	if not drop_names.is_empty():
		var drop_text:=UIFactory.label("Known drops: "+", ".join(drop_names),11,Color("#cbb67e")); drop_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; info.add_child(drop_text)
	var rarity:Dictionary = WorldAreaManager.rarity_forecast(tile)
	info.add_child(UIFactory.label("Estimated gear odds · Rare ~%d%% · Epic ~%d%% · Legendary ~%d%%"%[int(rarity.get("rare",0)),int(rarity.get("epic",0)),int(rarity.get("legendary",0))],11,Color("#a99bd1")))
	var mutations:Array = Array(tile.get("mutations",[]))
	if not mutations.is_empty(): info.add_child(UIFactory.label("Mutations: "+FrontierMutations.names(mutations),11,Color("#c4b2ef")))

func _add_travel_actions(tile:Dictionary,current:Vector2i) -> void:
	info.add_child(UIFactory.label("TRAVEL",13,Color("#f0dfae")))
	if selected == current:
		var enter_text:String = "ENTER HOME AREA · SAFE" if bool(tile.get("home",false)) else "ENTER CURRENT AREA"
		var enter:=UIFactory.button(enter_text,func(t=tile):_enter_area(t,"STANDARD",0,0),Color("#4d5d43") if bool(tile.get("home",false)) else Color("#4a4934"))
		enter.custom_minimum_size.y=46
		info.add_child(enter)
		if not bool(tile.get("home",false)):
			info.add_child(UIFactory.label("Optional pressure on entry",11,Color("#8f9bb2")))
			var standard:=UIFactory.button("STANDARD · native danger",func(t=tile):_enter_area(t,"STANDARD",0,0),Color("#303a4e")); info.add_child(standard)
			var prospector:=UIFactory.button("PROSPECTOR · +1 Threat · +1 Richness",func(t=tile):_enter_area(t,"PROSPECTOR",1,1),Color("#4a4531")); info.add_child(prospector)
			var blood:=UIFactory.button("BLOOD OATH · +3 Threat · +2 Richness",func(t=tile):_enter_area(t,"BLOOD OATH",3,2),Color("#543238")); info.add_child(blood)
		info.add_child(UIFactory.label("To move to another macro tile without spending Food, enter this AREA and physically cross its north/south/east/west border.",11,Color("#9fc1b1")))
		return
	var delta:Vector2i = selected-current
	var adjacent:bool = abs(delta.x)+abs(delta.y) == 1
	if adjacent:
		var edge:String = "EAST" if delta.x>0 else ("WEST" if delta.x<0 else ("SOUTH" if delta.y>0 else "NORTH"))
		info.add_child(UIFactory.label("WALK FREE · cross the %s border of your current AREA. Cost: 0 Food."%edge,12,Color("#9fd3a7")))
	if WorldAreaManager.can_fast_travel(selected):
		var cost:int = WorldAreaManager.fast_travel_cost(selected)
		var fast:=UIFactory.button("FAST TRAVEL · %d FOOD"%cost,func(p=selected):_fast_travel(p),Color("#3b4a5d"))
		fast.disabled = float(GameState.resources.get("food",0.0)) < float(cost)
		fast.custom_minimum_size.y=42
		info.add_child(fast)
		info.add_child(UIFactory.label("Food buys convenience only. The same route can always be crossed physically for free.",10,Color("#8897ad")))
	else:
		info.add_child(UIFactory.label("Fast Travel locked until this AREA has been physically visited or secured.",10,Color("#8b91a1")))

func _fast_travel(position:Vector2i) -> void:
	if not WorldAreaManager.fast_travel(position): return
	selected = position
	map_canvas.center_on(position)
	map_canvas.select(position)
	_refresh_side()
	SaveManager.save_game()

func _enter_area(tile:Dictionary,stance:String,threat_bonus:int,richness_bonus:int) -> void:
	var current:Vector2i = WorldAreaManager.current_macro()
	if Vector2i(int(tile.get("x",0)),int(tile.get("y",0))) != current: return
	var launch:Dictionary = WorldAreaManager.tile_data(current.x,current.y)
	launch["base_threat"] = int(launch.get("threat",0))
	launch["risk_stance"] = stance
	if not bool(launch.get("home",false)):
		launch["threat"] = int(launch.get("threat",1))+threat_bonus
		launch["richness"] = clampi(int(launch.get("richness",1))+richness_bonus,1,4)
	GameState.world["selected_tile"] = launch
	GameState.screen_requested.emit("expedition")
