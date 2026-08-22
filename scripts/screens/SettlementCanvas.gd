class_name SettlementCanvas
extends Control

signal building_selected(id: String)
signal layout_changed

const LAYOUT_PATH := "user://dawnkeep_layout.cfg"
const BUILDING_IDS := ["town_hall","lumberyard","quarry","farm","barracks","forge","arcane_lab","market"]

var positions := {
	"town_hall": Vector2(390,205),
	"lumberyard": Vector2(175,155),
	"quarry": Vector2(660,120),
	"farm": Vector2(155,335),
	"barracks": Vector2(565,315),
	"forge": Vector2(680,300),
	"arcane_lab": Vector2(445,85),
	"market": Vector2(335,350)
}
var selected_id := "town_hall"
var hover_id := ""
var dragging_id := ""
var drag_offset := Vector2.ZERO

func _ready() -> void:
	custom_minimum_size = Vector2(800,440)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_load_layout()
	GameState.changed.connect(_on_game_state_changed)
	queue_redraw()

func _exit_tree() -> void:
	if GameState.changed.is_connected(_on_game_state_changed):
		GameState.changed.disconnect(_on_game_state_changed)

func _on_game_state_changed() -> void:
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var mouse:Vector2 = event.position
		if dragging_id != "":
			positions[dragging_id] = _clamp_position(mouse - drag_offset)
			queue_redraw()
			accept_event()
			return
		var next_hover:String = _building_at(mouse)
		if next_hover != hover_id:
			hover_id = next_hover
			queue_redraw()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var id:String = _building_at(event.position)
			if id != "":
				selected_id = id
				dragging_id = id
				drag_offset = event.position - Vector2(positions[id])
				building_selected.emit(id)
				queue_redraw()
				accept_event()
		else:
			if dragging_id != "":
				dragging_id = ""
				_save_layout()
				layout_changed.emit()
				accept_event()

func _building_at(point: Vector2) -> String:
	var best := ""
	var best_distance := 99999.0
	for id in BUILDING_IDS:
		var p:Vector2 = Vector2(positions[id])
		var d:float = p.distance_to(point)
		if d < 48.0 and d < best_distance:
			best = id
			best_distance = d
	return best

func _clamp_position(p: Vector2) -> Vector2:
	return Vector2(clamp(p.x,58.0,size.x-58.0),clamp(p.y,62.0,size.y-48.0))

func _load_layout() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(LAYOUT_PATH) != OK:
		return
	for id in BUILDING_IDS:
		var value:Variant = cfg.get_value("buildings",id,null)
		if value is Vector2:
			positions[id] = value

func _save_layout() -> void:
	var cfg := ConfigFile.new()
	for id in BUILDING_IDS:
		cfg.set_value("buildings",id,positions[id])
	cfg.save(LAYOUT_PATH)

func reset_layout() -> void:
	positions = {
		"town_hall": Vector2(390,205),"lumberyard": Vector2(175,155),"quarry": Vector2(660,120),"farm": Vector2(155,335),
		"barracks": Vector2(565,315),"forge": Vector2(680,300),"arcane_lab": Vector2(445,85),"market": Vector2(335,350)
	}
	_save_layout()
	queue_redraw()
	layout_changed.emit()

func _draw() -> void:
	_draw_land()
	_draw_paths()
	for id in BUILDING_IDS:
		_draw_building(id,Vector2(positions[id]),int(GameState.buildings.get(id,0)),id == selected_id,id == hover_id)
	_draw_legend()

func _draw_land() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("#26382c"))
	for y in range(26,int(size.y),52):
		for x in range(26,int(size.x),52):
			var wobble:float = float(abs(hash("%d:%d"%[x,y]))%9)-4.0
			draw_circle(Vector2(x+wobble,y),2.0,Color("#3d5140"))
	var river := PackedVector2Array([Vector2(0,50),Vector2(95,63),Vector2(175,48),Vector2(245,68),Vector2(318,55),Vector2(390,68),Vector2(470,54),Vector2(555,70),Vector2(640,53),Vector2(size.x,70)])
	for i in range(river.size()-1):
		draw_line(river[i],river[i+1],Color("#334d56"),16.0)
		draw_line(river[i],river[i+1],Color("#496873"),3.0)
	draw_arc(Vector2(size.x*0.5,size.y*0.55),min(size.x,size.y)*0.43,PI*0.12,PI*0.88,42,Color("#6d5a3b"),3.0)

func _draw_paths() -> void:
	var center:Vector2 = Vector2(positions["town_hall"])
	for id in BUILDING_IDS:
		if id == "town_hall":
			continue
		var p:Vector2 = Vector2(positions[id])
		var mid := Vector2((center.x+p.x)*0.5,center.y)
		draw_polyline(PackedVector2Array([center,mid,p]),Color("#776d55"),9.0,true)
		draw_polyline(PackedVector2Array([center,mid,p]),Color("#a0916d"),2.0,true)

func _draw_building(id:String,p:Vector2,level:int,is_selected:bool,is_hover:bool) -> void:
	var built:bool = level > 0
	var scale_bonus:float = 1.0 + float(min(level,8))*0.025
	var wall:Color = Color("#b7a27c") if built else Color("#5c615c")
	var roof:Color = Color("#76514a") if built else Color("#4a4e4c")
	var accent:Color = _accent(id)
	var shadow_size:Vector2 = Vector2(70,34)*scale_bonus
	_draw_flat_ellipse(p+Vector2(2,22),shadow_size,Color(0,0,0,0.28))
	if is_hover or is_selected:
		draw_arc(p,49.0,0,TAU,34,Color("#e7ce86") if is_selected else Color("#b8c8a5"),3.0)
	match id:
		"town_hall": _draw_town_hall(p,wall,roof,accent,scale_bonus)
		"lumberyard": _draw_lumberyard(p,wall,roof,accent)
		"quarry": _draw_quarry(p,accent)
		"farm": _draw_farm(p,wall,roof)
		"barracks": _draw_barracks(p,wall,roof,accent)
		"forge": _draw_forge(p,wall,roof,accent)
		"arcane_lab": _draw_arcane(p,wall,roof,accent)
		"market": _draw_market(p,accent)
	if not built:
		draw_rect(Rect2(p+Vector2(-28,22),Vector2(56,7)),Color("#80755f"),false,2.0)
		draw_line(p+Vector2(-26,26),p+Vector2(24,-24),Color("#a79676"),3.0)
	var label:String = "%s  Lv.%d" % [_short_name(id),level]
	draw_string(ThemeDB.fallback_font,p+Vector2(-38,48),label,HORIZONTAL_ALIGNMENT_CENTER,76,12,Color("#e9dfc3"))

func _draw_flat_ellipse(center:Vector2,radii:Vector2,color:Color) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var a:float = TAU*float(i)/24.0
		pts.append(center+Vector2(cos(a)*radii.x*0.5,sin(a)*radii.y*0.5))
	draw_colored_polygon(pts,color)

func _draw_house(p:Vector2,wall:Color,roof:Color,w:float=52.0,h:float=34.0) -> void:
	draw_rect(Rect2(p+Vector2(-w*0.5,-h*0.15),Vector2(w,h*0.72)),wall)
	draw_colored_polygon(PackedVector2Array([p+Vector2(-w*0.62,-h*0.12),p+Vector2(0,-h*0.72),p+Vector2(w*0.62,-h*0.12),p+Vector2(w*0.46,h*0.05),p+Vector2(-w*0.46,h*0.05)]),roof)
	draw_rect(Rect2(p+Vector2(-5,6),Vector2(10,13)),roof.darkened(0.35))

func _draw_town_hall(p:Vector2,wall:Color,roof:Color,accent:Color,s:float) -> void:
	_draw_house(p,wall,roof,68*s,48*s)
	draw_rect(Rect2(p+Vector2(-10,-48)*s,Vector2(20,35)*s),wall.lightened(0.08))
	draw_colored_polygon(PackedVector2Array([p+Vector2(-15,-47)*s,p+Vector2(0,-67)*s,p+Vector2(15,-47)*s]),roof)
	draw_line(p+Vector2(0,-66)*s,p+Vector2(0,-80)*s,accent,2.0)
	draw_colored_polygon(PackedVector2Array([p+Vector2(1,-79)*s,p+Vector2(18,-73)*s,p+Vector2(1,-68)*s]),accent)

func _draw_lumberyard(p:Vector2,wall:Color,roof:Color,accent:Color) -> void:
	_draw_house(p+Vector2(12,-4),wall,roof,48,30)
	for i in 3:
		var y:float = 8.0+i*7.0
		draw_line(p+Vector2(-34,y),p+Vector2(-5,y-3),accent,6.0)
		draw_circle(p+Vector2(-34,y),3.0,accent.lightened(0.18))

func _draw_quarry(p:Vector2,accent:Color) -> void:
	for off in [Vector2(-20,8),Vector2(4,-9),Vector2(24,11),Vector2(-2,16)]:
		var q:Vector2 = p+Vector2(off)
		draw_colored_polygon(PackedVector2Array([q+Vector2(-12,8),q+Vector2(-8,-7),q+Vector2(2,-13),q+Vector2(12,-3),q+Vector2(10,10)]),accent.darkened(0.15+Vector2(off).y*0.002))
	draw_line(p+Vector2(22,-20),p+Vector2(35,-38),Color("#9c865f"),4.0)
	draw_line(p+Vector2(35,-38),p+Vector2(44,-29),Color("#9c865f"),4.0)

func _draw_farm(p:Vector2,wall:Color,roof:Color) -> void:
	for i in 5:
		draw_line(p+Vector2(-38,-4+i*7),p+Vector2(10,-4+i*7),Color("#9a8d4d"),2.0)
	_draw_house(p+Vector2(24,-10),wall,roof,36,26)

func _draw_barracks(p:Vector2,wall:Color,roof:Color,accent:Color) -> void:
	_draw_house(p,wall,roof,64,34)
	draw_line(p+Vector2(30,-17),p+Vector2(30,-48),Color("#a99b75"),3.0)
	draw_colored_polygon(PackedVector2Array([p+Vector2(31,-47),p+Vector2(49,-40),p+Vector2(31,-33)]),accent)
	draw_line(p+Vector2(-18,18),p+Vector2(-18,-13),Color("#c8c4b1"),2.0)
	draw_line(p+Vector2(-24,-7),p+Vector2(-12,-7),Color("#c8c4b1"),2.0)

func _draw_forge(p:Vector2,wall:Color,roof:Color,accent:Color) -> void:
	_draw_house(p,wall.darkened(0.12),roof,50,32)
	draw_rect(Rect2(p+Vector2(14,-36),Vector2(12,27)),Color("#4e4b48"))
	draw_circle(p+Vector2(20,-43),7,Color(0.35,0.35,0.35,0.18))
	draw_circle(p+Vector2(-18,12),7,accent)
	draw_circle(p+Vector2(-18,12),3,Color("#ffd07a"))

func _draw_arcane(p:Vector2,wall:Color,roof:Color,accent:Color) -> void:
	draw_circle(p,25,Color(accent,0.10))
	_draw_house(p+Vector2(0,5),wall.darkened(0.08),roof.darkened(0.15),42,34)
	for off in [Vector2(-24,-16),Vector2(0,-40),Vector2(24,-16)]:
		var q:Vector2 = p+Vector2(off)
		draw_colored_polygon(PackedVector2Array([q+Vector2(0,-11),q+Vector2(7,2),q+Vector2(2,13),q+Vector2(-6,4)]),accent)

func _draw_market(p:Vector2,accent:Color) -> void:
	for off in [Vector2(-23,0),Vector2(20,3),Vector2(0,-18)]:
		var q:Vector2 = p+Vector2(off)
		draw_rect(Rect2(q+Vector2(-14,0),Vector2(28,18)),Color("#bca77d"))
		draw_colored_polygon(PackedVector2Array([q+Vector2(-17,0),q+Vector2(-10,-12),q+Vector2(10,-12),q+Vector2(17,0)]),accent if Vector2(off).x<=0 else accent.lightened(0.12))
		draw_line(q+Vector2(-12,18),q+Vector2(-12,25),Color("#6b5b41"),2.0)
		draw_line(q+Vector2(12,18),q+Vector2(12,25),Color("#6b5b41"),2.0)

func _accent(id:String) -> Color:
	return {"town_hall":Color("#d5b462"),"lumberyard":Color("#946b3f"),"quarry":Color("#8c979d"),"farm":Color("#c4a94f"),"barracks":Color("#a7534f"),"forge":Color("#d27745"),"arcane_lab":Color("#8474cf"),"market":Color("#4f91a3")}.get(id,Color.WHITE)

func _short_name(id:String) -> String:
	return {"town_hall":"Hall","lumberyard":"Lumber","quarry":"Quarry","farm":"Farm","barracks":"Barracks","forge":"Forge","arcane_lab":"Arcane","market":"Market"}.get(id,id)

func _draw_legend() -> void:
	draw_string(ThemeDB.fallback_font,Vector2(16,size.y-14),"Drag buildings to reshape Dawnkeep · layout saves locally",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("#9cab94"))