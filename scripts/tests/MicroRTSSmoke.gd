extends Node

func _ready() -> void:
	await get_tree().process_frame
	GameState.reset_new_game(false)
	WorldAreaManager.ensure_schema()
	UnitRoster.ensure_schema()

	if ClaudeAreaLayout.W != 1024 or ClaudeAreaLayout.H != 1024 or ClaudeAreaLayout.TILE != 32:
		_fail("Claude AREA geometry changed")
		return

	var tile:Dictionary = WorldAreaManager.tile_data(1,0)
	var layout:=ClaudeAreaLayout.new()
	layout.generate(Vector2i(1,0),String(tile.get("biome","Greenlands")),int(tile.get("threat",1)),false)
	if layout.ground.size() != ClaudeAreaLayout.W*ClaudeAreaLayout.H:
		_fail("Claude ground field was not generated")
		return
	if layout.objects.size() != ClaudeAreaLayout.W*ClaudeAreaLayout.H:
		_fail("Claude object field was not generated")
		return
	# The exact Claude spawn clearing must stay object-free.
	for y:int in range(layout.spawn_tile.y-5,layout.spawn_tile.y+6):
		for x:int in range(layout.spawn_tile.x-5,layout.spawn_tile.x+6):
			if Vector2(Vector2i(x,y)-layout.spawn_tile).length() <= 5.0 and layout.object_type_at(x,y) != "":
				_fail("Spawn clearing contains a natural object")
				return

	var bow:Dictionary = ContentDB.weapon("hunter_bow")
	if bow.is_empty() or String(bow.get("weapon_class","")) != "bow":
		_fail("Hunter Bow is missing from player weapon content")
		return
	if String(bow.get("projectile_id","")) == "":
		_fail("Hunter Bow has no projectile")
		return
	var arrow:Dictionary = ContentDB.projectile(String(bow.get("projectile_id","")))
	if arrow.is_empty():
		_fail("Hunter Bow projectile does not resolve")
		return

	# Persistent ecology: wounds/deaths must survive leaving the local scene.
	var members:Array = AreaEcology.live_members(Vector2i(1,0),tile)
	if members.is_empty():
		_fail("Persistent AREA ecology generated no hostile units")
		return
	var first:Dictionary = Dictionary(members[0])
	var first_uid:String = String(first.get("uid",""))
	var first_pos:=Vector2(float(first.get("x",0.0)),float(first.get("y",0.0)))
	AreaEcology.update_member(Vector2i(1,0),first_uid,0.37,first_pos,false)
	var wounded_found:bool = false
	for raw:Variant in AreaEcology.live_members(Vector2i(1,0),tile):
		if raw is Dictionary and String(Dictionary(raw).get("uid","")) == first_uid:
			wounded_found = absf(float(Dictionary(raw).get("hp_pct",1.0))-0.37) < 0.001
			break
	if not wounded_found:
		_fail("AREA ecology did not persist enemy wounds")
		return
	AreaEcology.update_member(Vector2i(1,0),first_uid,0.0,first_pos,true)
	for raw:Variant in AreaEcology.live_members(Vector2i(1,0),tile):
		if raw is Dictionary and String(Dictionary(raw).get("uid","")) == first_uid:
			_fail("Dead ecology member respawned when AREA was re-read")
			return

	# On-foot macro travel is free. Fast travel is the Food convenience sink.
	WorldAreaManager.set_current_macro(Vector2i.ZERO,"center")
	var food_before:float = float(GameState.resources.get("food",0.0))
	var walked_to:Vector2i = WorldAreaManager.walk_transition(Vector2i.RIGHT)
	if walked_to != Vector2i(1,0):
		_fail("On-foot macro transition reached wrong AREA")
		return
	if absf(float(GameState.resources.get("food",0.0))-food_before) > 0.001:
		_fail("On-foot macro travel spent Food")
		return
	var expected_cost:int = WorldAreaManager.fast_travel_cost(Vector2i.ZERO)
	if expected_cost <= 0:
		_fail("Fast travel cost is not positive")
		return
	if not WorldAreaManager.fast_travel(Vector2i.ZERO):
		_fail("Fast travel to visited origin failed")
		return
	if absf(float(GameState.resources.get("food",0.0))-(food_before-float(expected_cost))) > 0.001:
		_fail("Fast travel did not spend its Food cost")
		return

	# A settlement claim is local. It must not sterilize or reserve the macro AREA.
	var claim_tile:Dictionary = WorldAreaManager.tile_data(2,0)
	var living:Array = AreaEcology.live_members(Vector2i(2,0),claim_tile)
	for raw:Variant in living:
		if not (raw is Dictionary): continue
		var m:Dictionary = Dictionary(raw)
		AreaEcology.update_member(Vector2i(2,0),String(m.get("uid","")),0.0,Vector2(float(m.get("x",0.0)),float(m.get("y",0.0))),true)
	var claim_center:=Vector2(ClaudeAreaLayout.WORLD_PX*0.5,ClaudeAreaLayout.WORLD_PX*0.5)
	var founded:Dictionary = AreaEcology.found(Vector2i(2,0),claim_tile,claim_center,AreaEcology.CLAIM_SETTLEMENT)
	if not bool(founded.get("ok",false)):
		_fail("Cleared local territory could not found a settlement")
		return
	if not AreaEcology.point_in_friendly_claim(Vector2i(2,0),claim_center):
		_fail("Settlement center is not inside its claim")
		return
	if AreaEcology.point_in_friendly_claim(Vector2i(2,0),claim_center+Vector2(2200,0)):
		_fail("Settlement claim incorrectly owns the whole macro AREA")
		return
	if not AreaEcology.designate_capital(Vector2i(2,0),String(founded.get("id",""))):
		_fail("New settlement could not become capital")
		return
	var capital:Dictionary = AreaEcology.capital()
	if int(capital.get("x",0)) != 2 or int(capital.get("y",0)) != 0:
		_fail("Capital relocation did not persist")
		return

	print("MICRORTS_SMOKE_OK")
	get_tree().quit(0)

func _fail(message:String) -> void:
	push_error("MICRORTS_SMOKE_FAIL · %s"%message)
	get_tree().quit(1)
