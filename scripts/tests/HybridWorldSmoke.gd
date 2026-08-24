extends Node

func _ready() -> void:
	await get_tree().process_frame
	GameState.reset_new_game(false)
	RetentionManager.reset(false)
	FrontierManager.reset(false)
	WorldAreaManager.ensure_schema()
	UnitRoster.ensure_schema()

	# Looking around the infinite world map must not allocate persistent AREA saves.
	var areas_before:int = Dictionary(GameState.world.get("areas",{})).size()
	for y:int in range(-5,6):
		for x:int in range(-8,9):
			WorldAreaManager.tile_data(x,y)
	var areas_after:int = Dictionary(GameState.world.get("areas",{})).size()
	if areas_after != areas_before:
		_fail("World-map preview allocated %d unwanted AREA records"%(areas_after-areas_before))
		return

	# Physical border traversal is deliberately free.
	var food_before:float = float(GameState.resources.get("food",0.0))
	var next:Vector2i = WorldAreaManager.walk_transition(Vector2i.RIGHT)
	if next != Vector2i(1,0) or WorldAreaManager.current_macro() != Vector2i(1,0):
		_fail("Physical border transition did not move the Warden to [1,0]")
		return
	if absf(float(GameState.resources.get("food",0.0))-food_before) > 0.001:
		_fail("Physical walking spent Food")
		return

	# Food is a convenience cost only when choosing Fast Travel.
	var expected_cost:int = WorldAreaManager.fast_travel_cost(Vector2i.ZERO)
	if expected_cost <= 0:
		_fail("Fast-travel cost was not positive")
		return
	if not WorldAreaManager.fast_travel(Vector2i.ZERO):
		_fail("Fast travel back to visited HOME failed")
		return
	var spent:float = food_before-float(GameState.resources.get("food",0.0))
	if absf(spent-float(expected_cost)) > 0.001:
		_fail("Fast travel spent %.1f Food instead of %d"%[spent,expected_cost])
		return

	# Persistent physical building survives a fresh AREA read.
	var build_pos:=Vector2i(112,112)
	if not WorldAreaManager.place_structure("palisade",build_pos,1):
		_fail("Could not place persistent structure")
		return
	var stored:Dictionary = WorldAreaManager.structure_at(build_pos)
	if String(stored.get("id","")) != "palisade":
		_fail("Persistent structure was not recoverable")
		return

	# Individual deployments must change who physically travels.
	var all:Array = UnitRoster.roster()
	if all.is_empty():
		_fail("Unit roster migration produced no individuals")
		return
	var first:Dictionary = Dictionary(all[0])
	var uid:String = String(first.get("uid",""))
	var field_before:int = UnitRoster.field_units().size()
	if not UnitRoster.set_assignment(uid,UnitRoster.ASSIGN_GARRISON):
		_fail("Could not assign individual to garrison")
		return
	if UnitRoster.field_units().size() >= field_before:
		_fail("Garrison assignment did not remove individual from traveling FIELD party")
		return
	if UnitRoster.garrison_units().is_empty():
		_fail("Garrison did not contain reassigned individual")
		return

	# HOME is a real safe AREA, not an arena with hidden enemies.
	var home:Dictionary = WorldAreaManager.tile_data(0,0)
	var arena:=HybridRuntimeArena.new()
	add_child(arena)
	arena.set_view_size(Vector2(1400,840))
	arena.begin(home)
	if not arena.safe_area:
		_fail("HOME AREA did not initialize as safe")
		return
	arena._spawn_logic()
	arena._spawn_enemy(false)
	if not arena.enemies.is_empty():
		_fail("HOME AREA spawned hostile enemies")
		return
	if not arena.local_structures.is_empty():
		_fail("Fake decorative outpost still exists in HOME AREA")
		return
	if arena.field_towers.is_empty():
		_fail("Physical HOME structures were not loaded into AREA runtime")
		return

	# One profile owns inventory/equipped/attack identity for each item.
	var weapon:Dictionary = GameState.get_item(String(GameState.equipped.get("weapon","")))
	var visual:Dictionary = EquipmentVisualResolver.profile(weapon)
	if String(visual.get("slot","")) != "weapon" or String(visual.get("weapon_class","")) == "":
		_fail("Unified equipment visual profile failed for equipped weapon")
		return

	print("HYBRID_WORLD_SMOKE_OK")
	get_tree().quit(0)

func _fail(message:String) -> void:
	push_error("HYBRID_WORLD_SMOKE_FAIL · %s"%message)
	get_tree().quit(1)
