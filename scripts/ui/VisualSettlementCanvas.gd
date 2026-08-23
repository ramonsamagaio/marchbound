class_name VisualSettlementCanvas
extends SettlementCanvas

func _ready() -> void:
	super._ready()
	custom_minimum_size=Vector2(1080,500)
	# Expand old compact layouts only once. New coordinates are designed to fit the fixed
	# bottom navigation at 1920x1080 and remain usable around 1280x720.
	var max_x:=0.0
	var max_y:=0.0
	for id in positions:
		max_x=max(max_x,float(Vector2(positions[id]).x))
		max_y=max(max_y,float(Vector2(positions[id]).y))
	if max_x<760.0 and max_y<430.0:
		positions=_default_visual_layout()
		_save_layout()
	queue_redraw()

func _default_visual_layout()->Dictionary:
	return {
		"town_hall":Vector2(535,245),
		"lumberyard":Vector2(245,175),
		"quarry":Vector2(850,155),
		"farm":Vector2(225,365),
		"barracks":Vector2(720,350),
		"forge":Vector2(900,335),
		"arcane_lab":Vector2(565,88),
		"market":Vector2(455,385)
	}

func reset_layout() -> void:
	positions=_default_visual_layout()
	_save_layout()
	queue_redraw()
	layout_changed.emit()

func _building_at(point:Vector2)->String:
	var best:=""
	var best_distance:=99999.0
	for id in BUILDING_IDS:
		var d:float=Vector2(positions[id]).distance_to(point)
		if d<68.0 and d<best_distance:
			best=id
			best_distance=d
	return best

func _clamp_position(p:Vector2)->Vector2:
	return Vector2(clamp(p.x,78.0,size.x-78.0),clamp(p.y,72.0,size.y-66.0))

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
	var draw_size:=Vector2(134,105)*scale_bonus
	if id=="town_hall":draw_size=Vector2(176,136)*scale_bonus
	elif id in ["quarry","market"]:draw_size=Vector2(124,100)*scale_bonus
	_draw_flat_ellipse(p+Vector2(0,32),Vector2(draw_size.x*0.72,26),Color(0,0,0,0.30))
	if is_hover or is_selected:
		draw_arc(p,68.0,0,TAU,38,Color("#f0d17e") if is_selected else Color("#b9caa8"),3.0)
	var dst:=Rect2(p-draw_size*0.5,draw_size)
	draw_texture_rect_region(VisualAtlas.ATLAS,dst,VisualAtlas.region(String(atlas_id)))
	if level<=0:
		draw_rect(Rect2(p+Vector2(-52,36),Vector2(104,8)),Color("#82735a"),false,3.0)
		draw_line(p+Vector2(-42,38),p+Vector2(40,-40),Color("#b39a71"),4.0)
	var label="%s  Lv.%d"%[_short_name(id),level]
	draw_string(ThemeDB.fallback_font,p+Vector2(-58,draw_size.y*0.5+16),label,HORIZONTAL_ALIGNMENT_CENTER,116,12,Color("#f0e5c5"))
