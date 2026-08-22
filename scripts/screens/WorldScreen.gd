extends Control

const GRID_W:=12
const GRID_H:=7
var grid:GridContainer
var info:VBoxContainer
var selected:={}
var biome_names=["Greenlands","Ancient Forest","Iron Hills","Mistfen","Ash Wastes","Frostwild"]
var biome_colors=[Color("#496d48"),Color("#294d3c"),Color("#5b5a58"),Color("#3e5f65"),Color("#6b4439"),Color("#52677d")]

func _ready()->void:_build();_generate_map()
func _build()->void:
	var margin=MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); margin.add_theme_constant_override("margin_left",24); margin.add_theme_constant_override("margin_right",24); margin.add_theme_constant_override("margin_top",18); margin.add_theme_constant_override("margin_bottom",18); add_child(margin)
	var root=HBoxContainer.new(); root.add_theme_constant_override("separation",16); margin.add_child(root); var left=VBoxContainer.new(); left.size_flags_horizontal=Control.SIZE_EXPAND_FILL; root.add_child(left); var top=HBoxContainer.new(); left.add_child(top); top.add_child(UIFactory.title("The March",28)); top.add_child(UIFactory.spacer()); top.add_child(UIFactory.label("Season %d · Frontier %d"%[GameState.world.season,GameState.world.frontier_depth],14,Color("#9ca9c9"))); left.add_child(UIFactory.label("Choose a territory. Threat controls enemy density, boss power, loot tier and resource yield.",13,Color("#9ca9c9"))); left.add_child(UIFactory.hsep()); grid=GridContainer.new(); grid.columns=GRID_W; grid.size_flags_vertical=Control.SIZE_EXPAND_FILL; grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL; grid.add_theme_constant_override("h_separation",5); grid.add_theme_constant_override("v_separation",5); left.add_child(grid)
	var side=PanelContainer.new(); side.custom_minimum_size.x=330; side.add_theme_stylebox_override("panel",UIFactory.panel(Color("#151b2a"),12,Color("#35415d"))); root.add_child(side); info=VBoxContainer.new(); info.add_theme_constant_override("separation",8); side.add_child(info)
func _generate_map()->void:
	UIFactory.clear_children(grid)
	for y in GRID_H:
		for x in GRID_W:
			var tile=make_tile(x,y); var b=Button.new(); b.custom_minimum_size=Vector2(70,64); b.text="%s\nT%d"%[biome_short(tile.biome),tile.threat]; var c=biome_colors[tile.biome_index]
			if tile.boss:c=c.lightened(0.17);b.text+=" ★"
			b.add_theme_stylebox_override("normal",UIFactory.panel(c.darkened(0.18),7,c.lightened(0.08))); b.add_theme_stylebox_override("hover",UIFactory.panel(c,7,c.lightened(0.25))); b.tooltip_text="%s · Threat %d"%[tile.biome,tile.threat]; b.pressed.connect(func(t=tile):select_tile(t)); grid.add_child(b)
	select_tile(make_tile(int(GRID_W/2),int(GRID_H/2)))
func make_tile(x:int,y:int)->Dictionary:
	var center=Vector2(GRID_W/2.0,GRID_H/2.0); var dist=Vector2(x,y).distance_to(center); var hashv=abs(hash("%s:%s:%s:%s"%[GameState.world.seed,GameState.world.season,x,y])); var biome_index=hashv%biome_names.size(); var threat=max(1,int(dist*1.15)+int(GameState.world.frontier_depth)+int((hashv/13)%3)); var boss=threat>=4 and hashv%11==0; var pvp=threat>=7 and hashv%5==0; var richness=1+(hashv%4); return {"x":x,"y":y,"biome":biome_names[biome_index],"biome_index":biome_index,"threat":threat,"boss":boss,"pvp":pvp,"richness":richness,"seed":hashv}
func biome_short(name:String)->String:return {"Greenlands":"GRN","Ancient Forest":"FOR","Iron Hills":"IRON","Mistfen":"FEN","Ash Wastes":"ASH","Frostwild":"FROST"}.get(name,"???")
func select_tile(tile:Dictionary)->void:
	selected=tile; GameState.world.selected_tile=tile; UIFactory.clear_children(info); info.add_child(UIFactory.title(tile.biome,23)); info.add_child(UIFactory.label("Territory [%d,%d]"%[tile.x,tile.y],12,Color("#8f9cbc"))); info.add_child(UIFactory.hsep()); var threat_color=Color("#e3c58f") if tile.threat<5 else Color("#ef8e7f"); info.add_child(UIFactory.label("THREAT %d"%tile.threat,22,threat_color)); info.add_child(UIFactory.label("Expected power: ~%d"%(tile.threat*130),13)); info.add_child(UIFactory.label("Your current power: %d"%GameState.total_power(),13,Color("#9fd3a7"))); info.add_child(UIFactory.label("Resource richness: %s"%["Poor","Fair","Rich","Abundant"][tile.richness-1],13))
	if tile.boss:info.add_child(UIFactory.label("★ Regional boss presence detected",14,Color("#f0b7c0")))
	if tile.pvp:info.add_child(UIFactory.label("⚔ Frontier PvP territory (future online rules)",12,Color("#d9a2a2")))
	info.add_child(UIFactory.hsep()); info.add_child(UIFactory.label("Expedition party",15,Color("#f0dfae"))); info.add_child(UIFactory.label("%d / %d command · Army power %d"%[GameState.command_used(),GameState.command_capacity(),GameState.army_power()],13))
	for unit in GameState.army:
		if GameState.army[unit]>0:info.add_child(UIFactory.label("%s ×%d · rank %d"%[GameState.pretty(unit),GameState.army[unit],GameState.unit_levels[unit]],12,Color("#aeb9d4")))
	info.add_child(UIFactory.spacer()); var enter=UIFactory.button("ENTER EXPEDITION",func():GameState.screen_requested.emit("expedition"),Color("#6a4c35")); enter.custom_minimum_size.y=48; info.add_child(enter); info.add_child(UIFactory.label("WASD move · Space dash · Q rally · E shockwave",11,Color("#7f8ba7")))
