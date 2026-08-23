class_name VisualSettlementCanvas
extends SettlementCanvas

func _ready() -> void:
	super._ready()
	custom_minimum_size=Vector2(1180,690)
	# Expand the original compact layout when no user layout has been spread out yet.
	var max_x:=0.0
	var max_y:=0.0
	for id in positions:
		max_x=max(max_x,float(Vector2(positions[id]).x))
		max_y=max(max_y,float(Vector2(positions[id]).y))
	if max_x<760.0 and max_y<430.0:
		positions={
			"town_hall":Vector2(575,315),
			"lumberyard":Vector2(265,235),
			"quarry":Vector2(915,205),
			"farm":Vector2(240,500),
			"barracks":Vector2(785,475),
			"forge":Vector2(980,455),
			"arcane_lab":Vector2(610,125),
			"market":Vector2(500,535)
		}
		_save_layout()
	queue_redraw()

func reset_layout() -> void:
	positions={
		"town_hall":Vector2(575,315),"lumberyard":Vector2(265,235),"quarry":Vector2(915,205),"farm":Vector2(240,500),
		"barracks":Vector2(785,475),"forge":Vector2(980,455),"arcane_lab":Vector2(610,125),"market":Vector2(500,535)
	}
	_save_layout()
	queue_redraw()
	layout_changed.emit()

func _building_at(point:Vector2)->String:
	var best:=""
	var best_distance:=99999.0
	for id in BUILDING_IDS:
		var d:float=Vector2(positions[id]).distance_to(point)
		if d<74.0 and d<best_distance:
			best=id
			best_distance=d
	return best

func _draw_building(id:String,p:Vector2,level:int,is_selected:bool,is_hover:bool)->void:
	var atlas_id={
		"town_hall":"building_town_hall",
		"lumberyard":"building_lumber",
		"quarry":"building_quarry",
		"farm":"building_farm",
		"barracks":"building_barracks",
		"forge":"building_forge",
		"arcane_lab":"building_research",
		"market":"building_market"
	}.get(id,"building_house")
	var scale_bonus:=1.0+float(min(level,8))*0.025
	var size:=Vector2(142,116)*scale_bonus
	if id=="town_hall":size=Vector2(188,150)*scale_bonus
	elif id in ["quarry","market"]:size=Vector2(132,110)*scale_bonus
	_draw_flat_ellipse(p+Vector2(0,36),Vector2(size.x*0.72,28),Color(0,0,0,0.30))
	if is_hover or is_selected:
		draw_arc(p,72.0,0,TAU,38,Color("#f0d17e") if is_selected else Color("#b9caa8"),4.0)
	var dst:=Rect2(p-size*0.5,size)
	draw_texture_rect_region(VisualAtlas.ATLAS,dst,VisualAtlas.region(String(atlas_id)))
	if level<=0:
		draw_rect(Rect2(p+Vector2(-56,40),Vector2(112,9)),Color("#82735a"),false,3.0)
		draw_line(p+Vector2(-44,42),p+Vector2(42,-44),Color("#b39a71"),4.0)
	var label="%s  Lv.%d"%[_short_name(id),level]
	draw_string(ThemeDB.fallback_font,p+Vector2(-62,size.y*0.5+18),label,HORIZONTAL_ALIGNMENT_CENTER,124,13,Color("#f0e5c5"))
