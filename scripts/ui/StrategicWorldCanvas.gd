class_name StrategicWorldCanvas
extends Control

signal tile_selected(position:Vector2i)
signal focus_changed(position:Vector2i)

var tile_provider:Callable
var focus:Vector2i = Vector2i.ZERO
var selected:Vector2i = Vector2i.ZERO
var zoom:float = 1.0
var pan_offset:Vector2 = Vector2.ZERO

const BASE_CELL:float = 50.0
const COLS:int = 23
const ROWS:int = 13
const BIOME_COLORS:Dictionary = {
	"Greenlands":Color("#536f46"),"Ancient Forest":Color("#304f38"),"Iron Hills":Color("#62656a"),
	"Mistfen":Color("#405d5c"),"Ash Wastes":Color("#71483d"),"Frostwild":Color("#587087")
}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)
	focus = WorldAreaManager.current_macro()
	selected = focus

func set_provider(value:Callable) -> void:
	tile_provider = value
	queue_redraw()

func center_on(position:Vector2i) -> void:
	focus = position
	pan_offset = Vector2.ZERO
	queue_redraw()
	focus_changed.emit(focus)

func select(position:Vector2i) -> void:
	selected = position
	queue_redraw()

func _cell_size() -> float:
	return BASE_CELL*zoom

func _cell_center(dx:int,dy:int) -> Vector2:
	return size*0.5+pan_offset+Vector2(float(dx),float(dy))*_cell_size()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("#0d1219"))
	if not tile_provider.is_valid(): return
	var half_cols:int = int(COLS/2)
	var half_rows:int = int(ROWS/2)
	var cell:float = _cell_size()
	for dy:int in range(-half_rows,half_rows+1):
		for dx:int in range(-half_cols,half_cols+1):
			var world:=focus+Vector2i(dx,dy)
			var tile:Dictionary = Dictionary(tile_provider.call(world.x,world.y))
			var center:Vector2 = _cell_center(dx,dy)
			var rect:=Rect2(center-Vector2(cell,cell)*0.47,Vector2(cell,cell)*0.94)
			_draw_tile(tile,world,rect)
	_draw_legend()

func _draw_tile(tile:Dictionary,world:Vector2i,rect:Rect2) -> void:
	var discovered:bool = bool(tile.get("discovered",false)) or bool(tile.get("home",false))
	var current:bool = world == WorldAreaManager.current_macro()
	var is_selected:bool = world == selected
	if not discovered:
		draw_rect(rect,Color("#171b23"))
		draw_rect(rect,Color("#343a49"),false,1.0)
		if is_selected: draw_rect(rect.grow(2),Color("#a7a9ba"),false,2.0)
		return
	var biome:String = String(tile.get("biome","Greenlands"))
	var base:Color = Color(BIOME_COLORS.get(biome,Color("#536f46")))
	var threat:int = int(tile.get("threat",0))
	if bool(tile.get("conquered",false)): base = base.lightened(0.11)
	elif threat >= 7: base = base.lerp(Color("#8c3c43"),0.30)
	elif threat >= 4: base = base.lerp(Color("#8b6640"),0.18)
	draw_rect(rect,base.darkened(0.10))
	var icon_id:String = "world_city" if bool(tile.get("home",false)) else VisualAtlas.biome_tile_id(biome)
	if VisualAtlas.has(icon_id):
		var inset:Rect2 = rect.grow(-5.0)
		draw_texture_rect_region(VisualAtlas.ATLAS,inset,VisualAtlas.region(icon_id),Color(1,1,1,0.48))
	var border:Color = Color("#596375")
	if bool(tile.get("conquered",false)): border = Color("#89a67d")
	if bool(tile.get("boss",false)): border = Color("#d88a8f")
	if current: border = Color("#f4d780")
	draw_rect(rect,border,false,1.5 if not current else 3.0)
	if is_selected: draw_rect(rect.grow(3.0),Color("#f6ecce"),false,2.0)
	var font:Font = ThemeDB.fallback_font
	if bool(tile.get("home",false)):
		draw_string(font,rect.position+Vector2(5,14),"HOME",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("#f5dea2"))
	else:
		draw_string(font,rect.position+Vector2(5,14),"T%d"%threat,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("#f2ead7"))
	var markers:String = ""
	if bool(tile.get("boss",false)): markers += "★"
	if Array(tile.get("mutations",[])).size()>0: markers += "✦"
	if bool(tile.get("visited",false)): markers += "•"
	if FrontierManager.rumor_for(world.x,world.y): markers += "?"
	if markers != "": draw_string(font,rect.position+Vector2(5,rect.size.y-5),markers,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#f1c6ff"))
	if current:
		draw_circle(rect.get_center(),7.0,Color("#fff0af"))
		draw_circle(rect.get_center(),12.0,Color(1.0,0.88,0.45,0.35),false,2.0)

func _draw_legend() -> void:
	var font:Font = ThemeDB.fallback_font
	draw_string(font,Vector2(12,size.y-12),"Gold ring: Warden · • visited · ? rumor · ★ boss · wheel zoom · middle drag",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("#9da8b9"))

func _gui_input(event:InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb:InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			zoom = minf(1.55,zoom*1.10); queue_redraw(); accept_event(); return
		if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			zoom = maxf(0.62,zoom*0.91); queue_redraw(); accept_event(); return
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var world:Vector2i = _world_under_mouse(mb.position)
			selected = world
			tile_selected.emit(world)
			queue_redraw()
			accept_event()
	elif event is InputEventMouseMotion:
		var mm:InputEventMouseMotion = event
		if mm.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
			pan_offset += mm.relative
			var cell:float = _cell_size()
			var shift:=Vector2i.ZERO
			if absf(pan_offset.x) >= cell: shift.x = -int(round(pan_offset.x/cell))
			if absf(pan_offset.y) >= cell: shift.y = -int(round(pan_offset.y/cell))
			if shift != Vector2i.ZERO:
				focus += shift
				pan_offset -= Vector2(float(-shift.x)*cell,float(-shift.y)*cell)
				focus_changed.emit(focus)
			queue_redraw()
			accept_event()

func _world_under_mouse(mouse:Vector2) -> Vector2i:
	var delta:Vector2 = mouse-(size*0.5+pan_offset)
	return focus+Vector2i(int(round(delta.x/_cell_size())),int(round(delta.y/_cell_size())))
