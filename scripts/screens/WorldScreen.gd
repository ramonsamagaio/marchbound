extends Control

const GRID_W:=11
const GRID_H:=7
const PAN_STEP:=5
var grid:GridContainer
var info:VBoxContainer
var selected:={}
var map_status:Label
var biome_names=["Greenlands","Ancient Forest","Iron Hills","Mistfen","Ash Wastes","Frostwild"]
var biome_colors=[Color("#496d48"),Color("#294d3c"),Color("#5b5a58"),Color("#3e5f65"),Color("#6b4439"),Color("#52677d")]
var objective_names=["Frontier Claim","Monster Hunt","Resource Sweep"]

func _ready()->void:
	GameState.ensure_schema(); _build(); _generate_map()

func _build()->void:
	var margin=MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); margin.add_theme_constant_override("margin_left",24); margin.add_theme_constant_override("margin_right",24); margin.add_theme_constant_override("margin_top",18); margin.add_theme_constant_override("margin_bottom",18); add_child(margin)
	var root=HBoxContainer.new(); root.add_theme_constant_override("separation",16); margin.add_child(root)
	var left=VBoxContainer.new(); left.size_flags_horizontal=Control.SIZE_EXPAND_FILL; root.add_child(left)
	var top=HBoxContainer.new(); left.add_child(top); top.add_child(UIFactory.title("The March",28)); top.add_child(UIFactory.spacer()); map_status=UIFactory.label("",14,Color("#9ca9c9")); top.add_child(map_status)
	left.add_child(UIFactory.label("Push outward one territory at a time. Claimed land opens adjacent frontiers; distance raises danger and rewards.",13,Color("#9ca9c9")))
	var pan=HBoxContainer.new(); pan.alignment=BoxContainer.ALIGNMENT_CENTER; pan.add_theme_constant_override("separation",6); left.add_child(pan)
	pan.add_child(UIFactory.button("← WEST",func():_pan(-PAN_STEP,0),Color("#252e43")))
	pan.add_child(UIFactory.button("↑ NORTH",func():_pan(0,-PAN_STEP),Color("#252e43")))
	pan.add_child(UIFactory.button("DAWNKEEP",func():_set_focus(0,0),Color("#4b442d")))
	pan.add_child(UIFactory.button("↓ SOUTH",func():_pan(0,PAN_STEP),Color("#252e43")))
	pan.add_child(UIFactory.button("EAST →",func():_pan(PAN_STEP,0),Color("#252e43")))
	left.add_child(UIFactory.hsep())
	grid=GridContainer.new(); grid.columns=GRID_W; grid.size_flags_vertical=Control.SIZE_EXPAND_FILL; grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL; grid.add_theme_constant_override("h_separation",5); grid.add_theme_constant_override("v_separation",5); left.add_child(grid)
	var side=PanelContainer.new(); side.custom_minimum_size.x=340; side.add_theme_stylebox_override("panel",UIFactory.panel(Color("#151b2a"),12,Color("#35415d"))); root.add_child(side); info=VBoxContainer.new(); info.add_theme_constant_override("separation",8); side.add_child(info)

func _focus()->Vector2i:
	return Vector2i(int(GameState.world.get("focus_x",0)),int(GameState.world.get("focus_y",0)))

func _pan(dx:int,dy:int)->void:
	_set_focus(_focus().x+dx,_focus().y+dy)

func _set_focus(x:int,y:int)->void:
	GameState.world["focus_x"]=x; GameState.world["focus_y"]=y; _generate_map()

func _generate_map()->void:
	UIFactory.clear_children(grid)
	var focus=_focus(); map_status.text="Season %d · Claimed %d · View [%d,%d]"%[GameState.world.season,GameState.claimed_count(),focus.x,focus.y]
	for gy in GRID_H:
		for gx in GRID_W:
			var wx=focus.x+gx-int(GRID_W/2); var wy=focus.y+gy-int(GRID_H/2); var tile=make_tile(wx,wy); var b=Button.new(); b.custom_minimum_size=Vector2(74,64)
			if tile.home:
				b.text="DAWN\nHOME"
			else:
				b.text="%s\nT%d"%[biome_short(tile.biome),tile.threat]
				if tile.boss:b.text+=" ★"
				if tile.conquered:b.text+=" ✓"
			var c=biome_colors[tile.biome_index]
			if tile.conquered:c=c.lightened(0.16)
			elif not tile.accessible:c=c.darkened(0.48)
			elif tile.boss:c=c.lightened(0.12)
			var border=Color("#d8bd78") if tile.accessible and not tile.conquered else c.lightened(0.16)
			if tile.home:border=Color("#eadc9d")
			b.add_theme_stylebox_override("normal",UIFactory.panel(c.darkened(0.16),7,border)); b.add_theme_stylebox_override("hover",UIFactory.panel(c,7,border.lightened(0.18))); b.tooltip_text="%s [%d,%d] · Threat %d · %s"%["Dawnkeep" if tile.home else tile.biome,tile.x,tile.y,tile.threat,tile.objective]; b.pressed.connect(func(t=tile):select_tile(t)); grid.add_child(b)
	var remembered=GameState.world.get("selected_tile",{})
	if not remembered.is_empty() and abs(int(remembered.get("x",0))-focus.x)<=int(GRID_W/2) and abs(int(remembered.get("y",0))-focus.y)<=int(GRID_H/2): select_tile(make_tile(int(remembered.x),int(remembered.y)))
	else: select_tile(make_tile(focus.x,focus.y))

func make_tile(x:int,y:int)->Dictionary:
	var hashv=abs(hash("%s:%s:%s:%s"%[GameState.world.seed,GameState.world.season,x,y])); var biome_index=hashv%biome_names.size(); var dist=Vector2(float(x),float(y)).length(); var home=x==0 and y==0
	var threat=0 if home else max(1,int(dist*0.72)+int(GameState.world.frontier_depth)+int((hashv/13)%3)); var boss=not home and threat>=3 and hashv%9==0; var pvp=not home and threat>=7 and hashv%5==0; var richness=1+(hashv%4); var objective="Home" if home else ("Ruin Siege" if boss else objective_names[int((hashv/29)%objective_names.size())])
	return {"x":x,"y":y,"biome":"Greenlands" if home else biome_names[biome_index],"biome_index":0 if home else biome_index,"threat":threat,"boss":boss,"pvp":pvp,"richness":richness,"seed":hashv,"home":home,"conquered":GameState.is_conquered(x,y),"accessible":GameState.is_accessible(x,y),"objective":objective}

func biome_short(name:String)->String:return {"Greenlands":"GRN","Ancient Forest":"FOR","Iron Hills":"IRON","Mistfen":"FEN","Ash Wastes":"ASH","Frostwild":"FROST"}.get(name,"???")

func objective_description(objective:String)->String:
	return {"Frontier Claim":"Survive the frontier until its guardian appears, then break it.","Monster Hunt":"Keep the kill chain alive until the local alpha is forced into the open.","Resource Sweep":"Harvest enough frontier sites to draw out the territory guardian.","Ruin Siege":"A stronger guardian already controls this ruin. It arrives early and hits harder."}.get(objective,"Secure the territory.")

func select_tile(tile:Dictionary)->void:
	selected=tile; GameState.world.selected_tile=tile; UIFactory.clear_children(info)
	if tile.home:
		info.add_child(UIFactory.title("Dawnkeep",23)); info.add_child(UIFactory.label("Your capital · Territory [0,0]",12,Color("#8f9cbc"))); info.add_child(UIFactory.hsep()); info.add_child(UIFactory.label("THE HEART OF THE MARCH",18,Color("#f0dfae"))); info.add_child(UIFactory.label("Every frontier begins here. Expand through adjacent territories and build a supply line into danger.",13,Color("#aeb9d4"))); info.add_child(UIFactory.hsep()); info.add_child(UIFactory.label("Claimed territories: %d"%GameState.claimed_count(),14)); info.add_child(UIFactory.label("Highest threat conquered: %d"%GameState.world.highest_threat,13)); info.add_child(UIFactory.spacer()); var home=UIFactory.button("RETURN TO SETTLEMENT",func():GameState.screen_requested.emit("city"),Color("#4d563d")); home.custom_minimum_size.y=48; info.add_child(home); return
	info.add_child(UIFactory.title(tile.biome,23)); info.add_child(UIFactory.label("Territory [%d,%d] · Distance %.1f"%[tile.x,tile.y,Vector2(float(tile.x),float(tile.y)).length()],12,Color("#8f9cbc"))); info.add_child(UIFactory.hsep())
	var threat_color=Color("#e3c58f") if tile.threat<5 else Color("#ef8e7f"); info.add_child(UIFactory.label("THREAT %d"%tile.threat,22,threat_color)); info.add_child(UIFactory.label("Objective: %s"%tile.objective,14,Color("#e4cf98"))); info.add_child(UIFactory.label(objective_description(tile.objective),12,Color("#aeb9d4"))); info.add_child(UIFactory.label("Expected power: ~%d"%(tile.threat*130),13)); info.add_child(UIFactory.label("Your current power: %d"%GameState.total_power(),13,Color("#9fd3a7"))); info.add_child(UIFactory.label("Resource richness: %s"%["Poor","Fair","Rich","Abundant"][tile.richness-1],13))
	if tile.conquered: info.add_child(UIFactory.label("✓ CLAIMED · safe supply route established",13,Color("#9fd3a7")))
	elif tile.accessible: info.add_child(UIFactory.label("◆ FRONTIER · victory will claim this territory",13,Color("#e7cb86")))
	else: info.add_child(UIFactory.label("LOCKED · claim an adjacent territory first",13,Color("#a47777")))
	if tile.boss:info.add_child(UIFactory.label("★ Regional boss presence detected",14,Color("#f0b7c0")))
	if tile.pvp:info.add_child(UIFactory.label("⚔ Frontier PvP territory (future online rules)",12,Color("#d9a2a2")))
	if tile.accessible and not tile.conquered: info.add_child(UIFactory.label("First-claim bounty: +%d Gold + frontier materials"%(tile.threat*35),12,Color("#cfb77e")))
	info.add_child(UIFactory.hsep()); info.add_child(UIFactory.label("Expedition party",15,Color("#f0dfae"))); info.add_child(UIFactory.label("%d / %d command · Army power %d"%[GameState.command_used(),GameState.command_capacity(),GameState.army_power()],13))
	for unit in GameState.army:
		if GameState.army[unit]>0:info.add_child(UIFactory.label("%s ×%d · rank %d"%[GameState.pretty(unit),GameState.army[unit],GameState.unit_levels[unit]],12,Color("#aeb9d4")))
	info.add_child(UIFactory.spacer()); var label="PATROL TERRITORY" if tile.conquered else "CLAIM TERRITORY"; var enter=UIFactory.button(label,func():GameState.screen_requested.emit("expedition"),Color("#6a4c35")); enter.custom_minimum_size.y=48; enter.disabled=not tile.accessible; info.add_child(enter); info.add_child(UIFactory.label("WASD move · Space dash · Q rally · E shockwave",11,Color("#7f8ba7")))
