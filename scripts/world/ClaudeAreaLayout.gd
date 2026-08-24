class_name ClaudeAreaLayout
extends RefCounted

# Direct port of the local-world generation rules from the user-owned Claude build.
# Same dimensions, tile size, coordinate seed, FastNoiseLite frequencies and thresholds.

const W:int = 1024
const H:int = 1024
const TILE:int = 32
const WORLD_PX:int = W*TILE

const GROUND_IDS:Array[String] = ["deep_water","water","sand","grass","dirt","stone","moss","ash","crystal"]
const OBJECT_IDS:Array[String] = ["","tree","rock","iron_vein","gold_vein","mana_crystal","bush","ruin","lair","dead_tree"]
const GROUND:Dictionary = {
	"deep_water":{"color":"#1d3350","solid":true,"speed":1.0},
	"water":{"color":"#2f5675","solid":false,"speed":0.55},
	"sand":{"color":"#a8935e","solid":false,"speed":0.92},
	"grass":{"color":"#4a6b3c","solid":false,"speed":1.0},
	"dirt":{"color":"#6b543a","solid":false,"speed":1.0},
	"stone":{"color":"#5c6068","solid":false,"speed":1.0},
	"moss":{"color":"#3f5f45","solid":false,"speed":1.0},
	"ash":{"color":"#4a4048","solid":false,"speed":0.95},
	"crystal":{"color":"#4a3f63","solid":false,"speed":1.0}
}
const OBJECTS:Dictionary = {
	"tree":{"name":"Tree","hits":4,"drops":{"wood":12},"solid":true,"color":"#2c4a2c","xp":1},
	"dead_tree":{"name":"Dead Tree","hits":3,"drops":{"wood":7},"solid":true,"color":"#4a3f33","xp":1},
	"rock":{"name":"Rock","hits":5,"drops":{"stone":10},"solid":true,"color":"#6a6f77","xp":1},
	"iron_vein":{"name":"Iron Vein","hits":7,"drops":{"iron":8},"solid":true,"color":"#8b97a8","xp":3},
	"gold_vein":{"name":"Gold Vein","hits":8,"drops":{"gold":14},"solid":true,"color":"#d9a441","xp":4},
	"mana_crystal":{"name":"Mana Crystal","hits":6,"drops":{"mana":6},"solid":true,"color":"#7b5fc4","xp":4},
	"bush":{"name":"Bush","hits":2,"drops":{"food":9},"solid":false,"color":"#5d7a3a","xp":1},
	"ruin":{"name":"Ruin","hits":6,"drops":{"stone":8,"gold":5},"solid":true,"color":"#8b8578","xp":2},
	"lair":{"name":"Lair","hits":0,"drops":{},"solid":true,"color":"#6b2028","xp":0}
}

var ground:PackedByteArray
var objects:PackedByteArray
var seed_value:int = 0
var macro:=Vector2i.ZERO
var biome:String = "plains"
var danger:int = 0
var spawn_tile:=Vector2i(W/2,H/2)
var lair_tile:=Vector2i(-1,-1)

func idx(x:int,y:int) -> int:
	return y*W+x

func in_bounds(x:int,y:int) -> bool:
	return x>=0 and y>=0 and x<W and y<H

func ground_index(id:String) -> int:
	return GROUND_IDS.find(id)

func object_index(id:String) -> int:
	return OBJECT_IDS.find(id)

func ground_name(index:int) -> String:
	return GROUND_IDS[clampi(index,0,GROUND_IDS.size()-1)]

func object_name(index:int) -> String:
	return OBJECT_IDS[clampi(index,0,OBJECT_IDS.size()-1)]

func generate(position:Vector2i,biome_id:String,danger_level:int,home:bool=false) -> void:
	macro = position
	biome = _claude_biome_id(biome_id)
	danger = danger_level
	seed_value = int(abs(position.x*73856093 ^ position.y*19349663))%2147483647
	ground = PackedByteArray(); ground.resize(W*H)
	objects = PackedByteArray(); objects.resize(W*H)

	var n_land:=FastNoiseLite.new()
	n_land.seed=seed_value
	n_land.frequency=0.014
	n_land.fractal_octaves=4
	var n_detail:=FastNoiseLite.new()
	n_detail.seed=seed_value+7
	n_detail.frequency=0.055
	var n_ore:=FastNoiseLite.new()
	n_ore.seed=seed_value+13
	n_ore.frequency=0.09
	var rng:=RandomNumberGenerator.new()
	rng.seed=seed_value
	var pal:Dictionary=_biome_palette(biome)
	var gi_deep:=ground_index("deep_water")
	var gi_water:=ground_index("water")
	var gi_sand:=ground_index("sand")
	var gi_base:=ground_index(String(pal["base"]))
	var gi_rough:=ground_index(String(pal["rough"]))
	var gi_alt:=ground_index(String(pal["alt"]))
	var oi_ore:=object_index(String(pal["ore"]))
	var oi_rock:=object_index("rock")
	var oi_tree:=object_index(String(pal["tree"]))
	var oi_bush:=object_index("bush")
	var oi_ruin:=object_index("ruin")
	var tree_density:float=float(pal["tree_density"])

	for y:int in range(H):
		for x:int in range(W):
			var i:int=idx(x,y)
			var land:float=n_land.get_noise_2d(x,y)
			var det:float=n_detail.get_noise_2d(x,y)
			var gi:int=gi_base
			var wet:bool=false
			if land < -0.52:
				gi=gi_deep; wet=true
			elif land < -0.42:
				gi=gi_water; wet=true
			elif land < -0.34:
				gi=gi_sand
			elif det > 0.34:
				gi=gi_rough
			elif det < -0.36:
				gi=gi_alt
			ground[i]=gi
			if wet: continue
			var r:float=rng.randf()
			var ore:float=n_ore.get_noise_2d(x,y)
			if ore > 0.55 and r < 0.55:
				objects[i]=oi_ore
			elif ore > 0.44 and r < 0.30:
				objects[i]=oi_rock
			elif det > 0.22 and r < tree_density:
				objects[i]=oi_tree
			elif r < 0.028:
				objects[i]=oi_bush
			elif r < 0.036 and danger >= 2:
				objects[i]=oi_ruin

	spawn_tile=Vector2i(W/2,H/2)
	_clear_disc(spawn_tile,7)
	if not home and (biome in ["boss","bandit"] or danger>=3):
		var guard:int=0
		while guard<400:
			guard+=1
			var lp:=Vector2i(rng.randi_range(20,W-20),rng.randi_range(20,H-20))
			if Vector2(lp-spawn_tile).length()<60.0: continue
			if bool(GROUND[ground_name(ground[idx(lp.x,lp.y)])]["solid"]): continue
			lair_tile=lp
			_clear_disc(lp,5)
			objects[idx(lp.x,lp.y)]=object_index("lair")
			break

func _claude_biome_id(value:String) -> String:
	return {
		"Greenlands":"plains","Ancient Forest":"forest","Iron Hills":"mountains",
		"Mistfen":"swamp","Ash Wastes":"corrupted","Frostwild":"mountains",
		"Rolling Hills":"hills","Old Ruins":"ruins","Bandit Camp":"bandit","Titan's Rest":"boss"
	}.get(value,value.to_lower().replace(" ","_"))

func _biome_palette(value:String) -> Dictionary:
	match value:
		"forest": return {"base":"grass","alt":"moss","rough":"dirt","tree":"tree","ore":"iron_vein","tree_density":0.55}
		"mountains": return {"base":"stone","alt":"dirt","rough":"stone","tree":"dead_tree","ore":"iron_vein","tree_density":0.10}
		"hills": return {"base":"grass","alt":"dirt","rough":"stone","tree":"tree","ore":"iron_vein","tree_density":0.22}
		"swamp": return {"base":"moss","alt":"water","rough":"dirt","tree":"dead_tree","ore":"mana_crystal","tree_density":0.32}
		"corrupted": return {"base":"ash","alt":"crystal","rough":"stone","tree":"dead_tree","ore":"mana_crystal","tree_density":0.26}
		"ruins": return {"base":"dirt","alt":"stone","rough":"sand","tree":"dead_tree","ore":"gold_vein","tree_density":0.14}
		"bandit": return {"base":"dirt","alt":"grass","rough":"sand","tree":"tree","ore":"gold_vein","tree_density":0.20}
		"boss": return {"base":"ash","alt":"stone","rough":"crystal","tree":"dead_tree","ore":"gold_vein","tree_density":0.16}
		_: return {"base":"grass","alt":"dirt","rough":"sand","tree":"tree","ore":"iron_vein","tree_density":0.26}

func _clear_disc(center:Vector2i,radius:int) -> void:
	for y:int in range(center.y-radius,center.y+radius+1):
		for x:int in range(center.x-radius,center.x+radius+1):
			if not in_bounds(x,y): continue
			if Vector2(Vector2i(x,y)-center).length()>float(radius): continue
			var i:int=idx(x,y)
			objects[i]=0
			if bool(GROUND[ground_name(ground[i])]["solid"]): ground[i]=ground_index("sand")

func ground_at(x:int,y:int) -> Dictionary:
	if not in_bounds(x,y): return GROUND["deep_water"]
	return Dictionary(GROUND[ground_name(ground[idx(x,y)])])

func object_at(x:int,y:int) -> Dictionary:
	if not in_bounds(x,y): return {}
	var id:String=object_name(objects[idx(x,y)])
	return Dictionary(OBJECTS.get(id,{}))

func object_type_at(x:int,y:int) -> String:
	if not in_bounds(x,y): return ""
	return object_name(objects[idx(x,y)])

func world_to_tile(world_pos:Vector2) -> Vector2i:
	return Vector2i(floori(world_pos.x/TILE),floori(world_pos.y/TILE))

func tile_to_world(tile_pos:Vector2i) -> Vector2:
	return Vector2(tile_pos)*TILE+Vector2(TILE,TILE)*0.5

func remove_object(tile_pos:Vector2i) -> void:
	if in_bounds(tile_pos.x,tile_pos.y): objects[idx(tile_pos.x,tile_pos.y)]=0

func apply_removed(encoded:Array) -> void:
	for raw:Variant in encoded:
		if raw is Array and Array(raw).size()>=2:
			var p:Array=Array(raw)
			remove_object(Vector2i(int(p[0]),int(p[1])))

func visible_tiles(world_rect:Rect2,pad:int=2) -> Rect2i:
	var x0:int=clampi(int(floor(world_rect.position.x/TILE))-pad,0,W-1)
	var y0:int=clampi(int(floor(world_rect.position.y/TILE))-pad,0,H-1)
	var x1:int=clampi(int(ceil(world_rect.end.x/TILE))+pad,0,W-1)
	var y1:int=clampi(int(ceil(world_rect.end.y/TILE))+pad,0,H-1)
	return Rect2i(x0,y0,x1-x0+1,y1-y0+1)
