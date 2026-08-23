extends Node

func _ready() -> void:
	await get_tree().process_frame
	ContentDB.reload_all()
	var reference_errors:Array[String] = ContentDB.validate_references()
	if not reference_errors.is_empty():
		_fail("Content references invalid: %s"%" | ".join(reference_errors))
		return

	RetentionManager.reset(false)
	var chain:Dictionary = Dictionary(RetentionManager.data.get("march_chain",{}))
	chain["count"] = 3
	chain["unbanked_bounty"] = 180
	RetentionManager.data["march_chain"] = chain
	RetentionManager.data["nemesis"] = {
		"active":true,
		"species":"ridgeback",
		"name":"Ridgeback the Unbroken",
		"biome":"Greenlands",
		"rank":2,
		"wins":2,
		"trait":"swift",
		"defeated":0
	}

	var arena:PursuitCombatArena = PursuitCombatArena.new()
	add_child(arena)
	arena.set_view_size(Vector2(1400,840))
	var tile:Dictionary = {
		"x":1,"y":0,"seed":44119,"biome":"Greenlands","threat":3,"richness":2,
		"objective":"Monster Hunt","boss":false,"boss_name":"Frontier Guardian","boss_archetype":"guardian"
	}
	arena.begin(tile)

	arena.gambit_active = true
	arena.choose_gambit("blood_price")
	if arena.chosen_gambits.is_empty():
		_fail("Gambit did not activate")
		return

	arena._spawn_enemy(false)
	if arena.enemies.is_empty():
		_fail("Enemy spawn failed")
		return
	var enemy:Dictionary = arena.enemies[0]
	arena._apply_status(enemy,"burn",20.0)
	arena._apply_status(enemy,"chill",20.0)
	if arena.reaction_count <= 0:
		_fail("Status reaction did not trigger")
		return

	arena._spawn_hunter_pack()
	if not arena.hunter_pack_spawned:
		_fail("Pursuit hunter pack did not spawn")
		return

	arena._spawn_nemesis()
	if not arena.nemesis_spawned:
		_fail("Nemesis did not invade")
		return

	print("RETENTION_SMOKE_OK")
	get_tree().quit(0)

func _fail(message:String) -> void:
	push_error("RETENTION_SMOKE_FAIL · %s"%message)
	get_tree().quit(1)
