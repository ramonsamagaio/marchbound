class_name VisualCombatArena
extends MutatedCombatArena

const LOCAL_TILE_PX := 64
const LOCAL_MAP_TILES := 192
const LOCAL_MAP_PX := LOCAL_TILE_PX * LOCAL_MAP_TILES

var view_size := Vector2(1400, 840)
var local_structures:Array = []
var local_props:Array = []

func begin(data:Dictionary) -> void:
	bounds = Rect2(0, 0, LOCAL_MAP_PX, LOCAL_MAP_PX)
	player_pos = bounds.get_center()
	_generate_local_outpost()
	super.begin(data)
	_reposition_resource_nodes_near_player()
	_update_camera()

func set_view_size(value:Vector2) -> void:
	view_size = value
	_update_camera()

func _process(delta:float) -> void:
	super._process(delta)
	_update_camera()

func _update_camera() -> void:
	# The arena is a huge world-space canvas. Moving the Node2D under a clipped holder
	# gives us a lightweight camera without creating tens of thousands of nodes.
	position = view_size * 0.5 - player_pos

func _generate_local_outpost() -> void:
	local_structures.clear()
	local_props.clear()
	var c := bounds.get_center()
	local_structures = [
		{"id":"building_town_hall","pos":c+Vector2(-420,-250),"size":Vector2(190,165)},
		{"id":"building_barracks","pos":c+Vector2(-120,-300),"size":Vector2(165,150)},
		{"id":"building_forge","pos":c+Vector2(260,-250),"size":Vector2(150,145)},
		{"id":"building_storage","pos":c+Vector2(430,40),"size":Vector2(145,140)},
		{"id":"building_watchtower","pos":c+Vector2(-520,110),"size":Vector2(145,115)},
		{"id":"building_house","pos":c+Vector2(-260,250),"size":Vector2(145,120)},
		{"id":"building_chapel","pos":c+Vector2(130,260),"size":Vector2(150,120)},
		{"id":"building_stable","pos":c+Vector2(410,270),"size":Vector2(155,120)}
	]
	for i in 24:
		var angle := TAU * float(i) / 24.0
		var radius := 760.0 + float((i % 3) * 95)
		local_props.append({"kind":"tree" if i % 3 != 0 else "rock","pos":c+Vector2.RIGHT.rotated(angle)*radius})

func _reposition_resource_nodes_near_player() -> void:
	var count := max(resource_nodes.size(), 10 + int(tile.get("richness",1))*3)
	while resource_nodes.size() < count:
		resource_nodes.append({"pos":player_pos,"type":"wood","progress":0.0,"collected":false,"value":8,"pulse":rng.randf_range(0.0,TAU)})
	var choices := _resource_choices_for_biome(String(tile.get("biome","Greenlands")))
	for i in resource_nodes.size():
		var node = resource_nodes[i]
		var angle := rng.randf_range(0.0, TAU)
		var radius := rng.randf_range(280.0, 1700.0)
		node.pos = player_pos + Vector2.RIGHT.rotated(angle) * radius
		node.pos.x = clamp(node.pos.x, 80.0, bounds.size.x-80.0)
		node.pos.y = clamp(node.pos.y, 80.0, bounds.size.y-80.0)
		node.type = choices[i % choices.size()]
		resource_nodes[i] = node

func _spawn_enemy(boss:bool) -> void:
	var before := enemies.size()
	super._spawn_enemy(boss)
	if enemies.size() <= before:
		return
	var e = enemies[enemies.size()-1]
	# Spawn around the current camera instead of the 12k map border.
	var angle := rng.randf_range(0.0, TAU)
	var ring := max(view_size.x, view_size.y) * rng.randf_range(0.58,0.78)
	e.pos = player_pos + Vector2.RIGHT.rotated(angle) * ring
	e.pos.x = clamp(e.pos.x, 30.0, bounds.size.x-30.0)
	e.pos.y = clamp(e.pos.y, 30.0, bounds.size.y-30.0)
	enemies[enemies.size()-1] = e

func _visible_world_rect(extra:=180.0) -> Rect2:
	return Rect2(player_pos-view_size*0.5-Vector2(extra,extra), view_size+Vector2(extra*2.0,extra*2.0))

func _draw_ground() -> void:
	var colors={"Greenlands":Color("#243c2c"),"Ancient Forest":Color("#18372a"),"Iron Hills":Color("#35393d"),"Mistfen":Color("#233b3e"),"Ash Wastes":Color("#402c27"),"Frostwild":Color("#2b3c4d")}
	var base:Color=colors.get(String(tile.get("biome","Greenlands")),Color("#243c2c"))
	var visible := _visible_world_rect(220.0)
	draw_rect(visible,base)
	var x0 := int(floor(visible.position.x/LOCAL_TILE_PX))*LOCAL_TILE_PX
	var x1 := int(ceil(visible.end.x/LOCAL_TILE_PX))*LOCAL_TILE_PX
	var y0 := int(floor(visible.position.y/LOCAL_TILE_PX))*LOCAL_TILE_PX
	var y1 := int(ceil(visible.end.y/LOCAL_TILE_PX))*LOCAL_TILE_PX
	for x in range(x0,x1+1,LOCAL_TILE_PX):
		draw_line(Vector2(x,y0),Vector2(x,y1),Color(base.lightened(0.045),0.55),1.0)
	for y in range(y0,y1+1,LOCAL_TILE_PX):
		draw_line(Vector2(x0,y),Vector2(x1,y),Color(base.lightened(0.045),0.55),1.0)
	_draw_outpost_roads()
	for s in local_structures:
		if visible.grow(220).has_point(Vector2(s.pos)):
			_draw_atlas(String(s.id),Vector2(s.pos),Vector2(s.size),true)
	for prop in local_props:
		if not visible.grow(120).has_point(Vector2(prop.pos)):
			continue
		if String(prop.kind)=="tree":
			draw_circle(Vector2(prop.pos),22,Color("#315a3d"))
			draw_circle(Vector2(prop.pos)+Vector2(-8,-6),15,Color("#3c7049"))
		else:
			draw_colored_polygon(PackedVector2Array([Vector2(prop.pos)+Vector2(-18,12),Vector2(prop.pos)+Vector2(-10,-12),Vector2(prop.pos)+Vector2(10,-16),Vector2(prop.pos)+Vector2(20,8)]),Color("#777c80"))

func _draw_outpost_roads() -> void:
	var c := bounds.get_center()
	var road := Color("#746b58")
	draw_rect(Rect2(c+Vector2(-610,-38),Vector2(1220,76)),road)
	draw_rect(Rect2(c+Vector2(-38,-470),Vector2(76,940)),road)
	draw_circle(c,72,Color("#807761"))

func _draw_atlas(id:String,center:Vector2,size:Vector2,centered:=true) -> void:
	if not VisualAtlas.has(id):
		return
	var dst := Rect2(center,size)
	if centered:
		dst.position -= size*0.5
	draw_texture_rect_region(VisualAtlas.ATLAS,dst,VisualAtlas.region(id))

func _draw_player() -> void:
	# Compact game-world sprite. The high-detail paper doll remains an inventory/inspect asset.
	_draw_atlas("unit_knight",player_pos,Vector2(62,76),true)
	draw_circle(player_pos+Vector2(0,13),27,Color(0.58,0.76,1.0,0.08),false,2.0)
	if dash_time>0.0:
		draw_arc(player_pos,31,0,TAU,28,Color("#d9efff"),3.0)
	if combo>=10:
		draw_arc(player_pos,35,0,TAU,28,Color("#f0d77a"),2.0)

func _draw_ally(a:Dictionary) -> void:
	var id := VisualAtlas.unit_sprite_id(String(a.type))
	var size := Vector2(50,58)
	if String(a.type) in ["stone_golem"]:
		size=Vector2(66,68)
	_draw_atlas(id,Vector2(a.pos),size,true)
	if bool(a.get("elite",false)):
		draw_arc(Vector2(a.pos),32,0,TAU,24,Color("#d8b7ff"),2.5)

func _draw_enemy(e:Dictionary) -> void:
	var id := VisualAtlas.enemy_sprite_id(String(e.type))
	var size := Vector2(54,60)
	if bool(e.boss):
		id="enemy_boss"
		size=Vector2(110,116)
	elif bool(e.get("elite",false)):
		size*=1.16
	_draw_atlas(id,Vector2(e.pos),size,true)
	if bool(e.get("elite",false)):
		draw_arc(Vector2(e.pos),float(e.radius)+12,0,TAU,24,Color("#d9a3ff"),3.0)
	if bool(e.boss):
		draw_arc(Vector2(e.pos),float(e.radius)+17,0,TAU,32,Color("#e9bb63"),4.0)
	var hp_ratio := clamp(float(e.hp)/max(1.0,float(e.max_hp)),0.0,1.0)
	if bool(e.boss) or bool(e.get("elite",false)):
		draw_rect(Rect2(Vector2(e.pos)+Vector2(-32,-48),Vector2(64,5)),Color("#241d28"))
		draw_rect(Rect2(Vector2(e.pos)+Vector2(-32,-48),Vector2(64*hp_ratio,5)),Color("#d85c6c"))

func _draw_resource_node(node:Dictionary) -> void:
	var p:Vector2=node.pos
	var id := {"gold":"pickup_gold","mana":"pickup_mana","wood":"res_wood","stone":"res_stone","iron":"res_iron","food":"res_food"}.get(String(node.type),"pickup_gold")
	_draw_atlas(id,p,Vector2(34,34),true)
	if float(node.progress)>0.0:
		var ratio=clamp(float(node.progress)/1.15,0.0,1.0)
		draw_rect(Rect2(p+Vector2(-20,24),Vector2(40,5)),Color("#17202c"))
		draw_rect(Rect2(p+Vector2(-20,24),Vector2(40*ratio,5)),_resource_color(String(node.type)))
