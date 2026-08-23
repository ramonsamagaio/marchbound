extends Node

func _ready() -> void:
	await get_tree().process_frame
	GameState.reset_new_game(false)
	RetentionManager.reset(false)
	FrontierManager.reload_discoveries()
	FrontierManager.reset(false)
	GameState.resources["gold"] = 1000.0
	var validation:Array[String] = FrontierManager.validate_discoveries()
	if not validation.is_empty():
		_fail("Discovery catalog invalid: %s"%" | ".join(validation))
		return
	var rumor:Dictionary = FrontierManager.ensure_rumor(true)
	if rumor.is_empty() or not bool(rumor.get("active",false)):
		_fail("Rumor generation failed")
		return
	var tile:Dictionary = {
		"x":int(rumor.get("x",1)),
		"y":int(rumor.get("y",0)),
		"seed":77119,
		"biome":"Greenlands",
		"threat":4,
		"richness":2,
		"objective":"Frontier Claim",
		"boss":false,
		"boss_name":"Frontier Guardian",
		"boss_archetype":"guardian"
	}
	var arena:=DiscoveryCombatArena.new()
	add_child(arena)
	arena.set_view_size(Vector2(1400,840))
	arena.begin(tile)
	var wanted:String = String(rumor.get("discovery_id",""))
	var found_index:int = -1
	for i:int in range(arena.discoveries.size()):
		if String(Dictionary(arena.discoveries[i]).get("id","")) == wanted:
			found_index = i
			break
	if found_index < 0:
		_fail("Rumored discovery did not spawn")
		return
	var definition:Dictionary = FrontierManager.discovery(wanted)
	var choices:Array = Array(definition.get("choices",[]))
	if choices.is_empty():
		_fail("Rumored discovery has no choices")
		return
	arena.active_discovery_index = found_index
	arena.paused_for_upgrade = true
	var first_choice:Dictionary = Dictionary(choices[0])
	if not arena.choose_discovery(String(first_choice.get("id",""))):
		_fail("Discovery choice failed")
		return
	if FrontierManager.last_run_discoveries().is_empty():
		_fail("Discovery was not recorded")
		return
	if FrontierManager.rumor_for(int(tile["x"]),int(tile["y"])):
		_fail("Rumor did not resolve")
		return
	FrontierManager.add_mark("moon_mark")
	FrontierManager.grant_warband_legacy("oathkeeper")
	FrontierManager.awaken_weapon_echo("storm_echo")
	var bonuses:Dictionary = FrontierManager.combat_bonuses()
	if float(bonuses.get("crit_add",0.0)) <= 0.0:
		_fail("Campaign Mark did not affect combat bonuses")
		return
	if float(bonuses.get("army_damage_mult",1.0)) <= 1.0:
		_fail("Warband Legacy did not affect combat bonuses")
		return
	var weapon:Dictionary = GameState.get_item(String(GameState.equipped.get("weapon","")))
	if "storm_echo" not in Array(weapon.get("echo_traits",[])):
		_fail("Weapon Echo did not persist on equipped weapon")
		return
	print("FRONTIER_SMOKE_OK")
	get_tree().quit(0)

func _fail(message:String) -> void:
	push_error("FRONTIER_SMOKE_FAIL · %s"%message)
	get_tree().quit(1)
