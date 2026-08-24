class_name VisualCombatArena
extends MutatedCombatArena

# Match the Claude AREA geometry exactly. The micro-RTS layer owns terrain rendering.
const LOCAL_TILE_PX:int = 32
const LOCAL_MAP_TILES:int = 1024
const LOCAL_MAP_PX:int = LOCAL_TILE_PX*LOCAL_MAP_TILES

var view_size:=Vector2(1400,840)
var local_structures:Array=[]
var local_props:Array=[]

func begin(data:Dictionary) -> void:
	bounds=Rect2(0,0,LOCAL_MAP_PX,LOCAL_MAP_PX)
	player_pos=bounds.get_center()
	local_structures.clear()
	local_props.clear()
	super.begin(data)
	_update_camera()

func set_view_size(value:Vector2) -> void:
	view_size=value
	_update_camera()

func _process(delta:float) -> void:
	super._process(delta)
	_update_camera()

func _update_camera() -> void:
	position=view_size*0.5-player_pos

func _visible_world_rect(extra:float=180.0) -> Rect2:
	return Rect2(player_pos-view_size*0.5-Vector2(extra,extra),view_size+Vector2(extra*2.0,extra*2.0))

func _generate_local_outpost() -> void:
	# Removed. Settlements are what players physically build in the AREA.
	local_structures.clear()
	local_props.clear()

func _reposition_resource_nodes_near_player() -> void:
	# Removed. Contextual ClaudeAreaLayout owns natural resource placement.
	pass

func _draw_ground() -> void:
	# Fallback only. MicroRTSCombatArena renders the deterministic Claude layout.
	var base:=Color("#4a6b3c")
	draw_rect(_visible_world_rect(220.0),base)

func _draw_outpost_roads() -> void:
	pass

func _draw_atlas(id:String,center:Vector2,size:Vector2,centered:bool=true) -> void:
	if not VisualAtlas.has(id): return
	var dst:=Rect2(center,size)
	if centered: dst.position-=size*0.5
	draw_texture_rect_region(VisualAtlas.ATLAS,dst,VisualAtlas.region(id))

func _draw_player() -> void:
	_draw_atlas("unit_knight",player_pos,Vector2(62,76),true)
	if dash_time>0.0: draw_arc(player_pos,31,0,TAU,28,Color("#d9efff"),3.0)

func _draw_ally(a:Dictionary) -> void:
	var id:String=VisualAtlas.unit_sprite_id(String(a.get("type","militia")))
	var size:=Vector2(50,58)
	if String(a.get("type",""))=="stone_golem": size=Vector2(66,68)
	_draw_atlas(id,Vector2(a.get("pos",Vector2.ZERO)),size,true)
	if bool(a.get("elite",false)):
		draw_arc(Vector2(a.get("pos",Vector2.ZERO)),32,0,TAU,24,Color("#d8b7ff"),2.5)

func _draw_enemy(e:Dictionary) -> void:
	var id:String=VisualAtlas.enemy_sprite_id(String(e.get("type","raider")))
	var size:=Vector2(54,60)
	if bool(e.get("boss",false)):
		id="enemy_boss"; size=Vector2(110,116)
	elif bool(e.get("elite",false)): size*=1.16
	_draw_atlas(id,Vector2(e.get("pos",Vector2.ZERO)),size,true)
	if bool(e.get("elite",false)):
		draw_arc(Vector2(e.get("pos",Vector2.ZERO)),float(e.get("radius",14.0))+12,0,TAU,24,Color("#d9a3ff"),3.0)
	var hp_ratio:float=clampf(float(e.get("hp",1.0))/maxf(1.0,float(e.get("max_hp",1.0))),0.0,1.0)
	if bool(e.get("boss",false)) or bool(e.get("elite",false)):
		var p:Vector2=Vector2(e.get("pos",Vector2.ZERO))
		draw_rect(Rect2(p+Vector2(-32,-48),Vector2(64,5)),Color("#241d28"))
		draw_rect(Rect2(p+Vector2(-32,-48),Vector2(64*hp_ratio,5)),Color("#d85c6c"))

func _draw_resource_node(node:Dictionary) -> void:
	var p:Vector2=Vector2(node.get("pos",Vector2.ZERO))
	var id:String=String({"gold":"pickup_gold","mana":"pickup_mana","wood":"res_wood","stone":"res_stone","iron":"res_iron","food":"res_food"}.get(String(node.get("type","wood")),"pickup_gold"))
	_draw_atlas(id,p,Vector2(34,34),true)
	if float(node.get("progress",0.0))>0.0:
		var ratio:float=clampf(float(node.get("progress",0.0))/1.15,0.0,1.0)
		draw_rect(Rect2(p+Vector2(-20,24),Vector2(40,5)),Color("#17202c"))
		draw_rect(Rect2(p+Vector2(-20,24),Vector2(40*ratio,5)),_resource_color(String(node.get("type","wood"))))
