class_name ClaimMicroRTSCombatArena
extends MicroRTSCombatArena

func _try_build_selected() -> void:
	var id:String=_selected_building_id()
	var snapped:=Vector2(round(player_pos.x/float(LOCAL_TILE_PX))*LOCAL_TILE_PX,round(player_pos.y/float(LOCAL_TILE_PX))*LOCAL_TILE_PX)
	var tile_pos:=Vector2i(int(round(snapped.x/float(LOCAL_TILE_PX))),int(round(snapped.y/float(LOCAL_TILE_PX))))
	# Natural terrain must be physically cleared. No building through trees/ore/ruins.
	if claude_layout!=null:
		var natural:Dictionary=claude_layout.object_at(tile_pos.x,tile_pos.y)
		if not natural.is_empty():
			_float_text(player_pos+Vector2(0,-56),"CLEAR %s FIRST · E"%String(natural.get("name","OBJECT")).to_upper(),Color("#ddb07e"),1.0)
			return
		var ground:Dictionary=claude_layout.ground_at(tile_pos.x,tile_pos.y)
		if bool(ground.get("solid",false)):
			_float_text(player_pos+Vector2(0,-56),"CANNOT BUILD ON DEEP WATER",Color("#7fb2d0"),1.0)
			return
	if id=="town_hall":
		var check:Dictionary=AreaEcology.can_found(current_macro,tile,snapped,AreaEcology.CLAIM_SETTLEMENT)
		# Existing founding claim may already cover the home Town Hall.
		if not bool(check.get("ok",false)) and not AreaEcology.point_in_friendly_claim(current_macro,snapped):
			_float_text(player_pos+Vector2(0,-62),String(check.get("reason","AREA NOT SECURE")).to_upper(),Color("#e39a86"),1.25)
			return
	var before:int=WorldAreaManager.structures(current_macro).size()
	super._try_build_selected()
	var after:int=WorldAreaManager.structures(current_macro).size()
	if id=="town_hall" and after>before and not AreaEcology.point_in_friendly_claim(current_macro,snapped):
		var founded:Dictionary=AreaEcology.found(current_macro,tile,snapped,AreaEcology.CLAIM_SETTLEMENT)
		if bool(founded.get("ok",false)):
			_float_text(snapped+Vector2(0,-76),"SETTLEMENT CLAIM FOUNDED",Color("#a7d7a5"),1.4)

func _draw_ground() -> void:
	super._draw_ground()
	var visible:Rect2=_visible_world_rect(120.0)
	for raw:Variant in AreaEcology.claims(current_macro):
		if not (raw is Dictionary): continue
		var claim:Dictionary=Dictionary(raw)
		var center:=Vector2(float(claim.get("x",0.0)),float(claim.get("y",0.0)))
		var radius:float=float(claim.get("radius",0.0))
		if not visible.grow(radius).has_point(center): continue
		var color:=Color("#9fca92") if bool(claim.get("capital",false)) else Color("#8fb6d0")
		draw_circle(center,radius,Color(color,0.025))
		draw_arc(center,radius,0,TAU,96,Color(color,0.20),2.0)
		draw_string(ThemeDB.fallback_font,center+Vector2(-80,-radius+24),"CAPITAL CLAIM" if bool(claim.get("capital",false)) else "SETTLEMENT CLAIM",HORIZONTAL_ALIGNMENT_CENTER,160,12,Color(color,0.75))
