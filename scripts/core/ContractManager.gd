extends Node

signal changed

const SAVE_PATH := "user://marchbound_contracts.json"
const SAVE_VERSION := 1

var state := {"cycle":1,"offers":[]}
var baseline := {}
var initialized := false

func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	load_contracts()
	if state.get("offers",[]).is_empty():
		_generate_contracts()
	_sync_baseline()
	initialized = true
	if not GameState.changed.is_connected(_on_game_changed):
		GameState.changed.connect(_on_game_changed)
	changed.emit()

func _capture_stats() -> Dictionary:
	return {
		"kills":int(GameState.stats.get("kills",0)),
		"victories":int(GameState.stats.get("victories",0)),
		"bosses":int(GameState.stats.get("bosses",0)),
		"claims":int(GameState.stats.get("territories_claimed",GameState.claimed_count())),
		"expeditions":int(GameState.stats.get("expeditions",0))
	}

func _sync_baseline() -> void:
	baseline = _capture_stats()

func _on_game_changed() -> void:
	if not initialized:
		return
	var current = _capture_stats()
	var delta := {}
	var any_progress := false
	for key in current:
		var gain = max(0,int(current[key])-int(baseline.get(key,current[key])))
		delta[key] = gain
		if gain > 0:
			any_progress = true
	baseline = current
	if not any_progress:
		return
	if _apply_progress(delta):
		save_contracts()
		changed.emit()

func _apply_progress(delta:Dictionary) -> bool:
	var did_change := false
	var offers:Array = state.get("offers",[])
	for i in offers.size():
		var contract:Dictionary = offers[i]
		if bool(contract.get("claimed",false)) or bool(contract.get("completed",false)):
			continue
		var type = String(contract.get("type",""))
		var gain = int(delta.get(type,0))
		if gain <= 0:
			continue
		contract["progress"] = min(int(contract.get("target",1)),int(contract.get("progress",0))+gain)
		if int(contract.progress) >= int(contract.target):
			contract["completed"] = true
			GameState.toast_requested.emit("Contract complete: %s" % String(contract.title))
		offers[i] = contract
		did_change = true
	state["offers"] = offers
	return did_change

func _make_contract(type:String,title:String,description:String,target:int,reward:Dictionary) -> Dictionary:
	return {
		"id":"%s_%d_%d"%[type,int(GameState.world.get("season",1)),int(state.get("cycle",1))],
		"type":type,
		"title":title,
		"description":description,
		"target":max(1,target),
		"progress":0,
		"completed":false,
		"claimed":false,
		"reward":reward
	}

func _generate_contracts() -> void:
	var season = int(GameState.world.get("season",1))
	var cycle = int(state.get("cycle",1))
	var difficulty = max(1,season+int(GameState.world.get("highest_threat",1))/4)
	var rng = RandomNumberGenerator.new()
	rng.seed = int(GameState.world.get("seed",947213)) + season*7919 + cycle*104729

	var kill_target = 28 + difficulty*7
	var claim_target = 1 + int((cycle+season)%2)
	var offers:Array = []
	offers.append(_make_contract(
		"kills",
		"Frontier Cull",
		"Thin the hostile packs gathering beyond Dawnkeep. Every kill counts, no matter the biome.",
		kill_target,
		{"resources":{"gold":140.0+difficulty*35.0,"food":60.0+difficulty*12.0},"xp":80+difficulty*18,"renown":2+difficulty}
	))
	offers.append(_make_contract(
		"claims",
		"Expand the March",
		"Claim new territory and extend the supply line. Patrols do not count; the frontier must actually grow.",
		claim_target,
		{"resources":{"gold":180.0+difficulty*45.0,"wood":70.0+difficulty*15.0,"stone":55.0+difficulty*12.0},"xp":90+difficulty*20,"renown":5+difficulty*2}
	))

	var rotating := []
	rotating.append(_make_contract(
		"victories",
		"Unbroken Standard",
		"Return from victorious expeditions. Any objective counts, so choose the frontier that best serves your build.",
		2+int(difficulty/3),
		{"resources":{"gold":170.0+difficulty*40.0,"mana":8.0+difficulty*2.0},"xp":110+difficulty*22,"renown":4+difficulty}
	))
	rotating.append(_make_contract(
		"bosses",
		"Guardian Writ",
		"Break territorial guardians or named regional bosses and bring proof back to Dawnkeep.",
		2+int(difficulty/4),
		{"resources":{"gold":210.0+difficulty*50.0,"iron":18.0+difficulty*4.0,"mana":10.0+difficulty*2.0},"xp":125+difficulty*24,"renown":6+difficulty*2}
	))
	rotating.append(_make_contract(
		"expeditions",
		"Field Ledger",
		"Complete frontier deployments, win or lose. The Council pays for useful field data as well as glory.",
		3+int(difficulty/3),
		{"resources":{"wood":75.0+difficulty*14.0,"stone":75.0+difficulty*14.0,"food":90.0+difficulty*16.0},"xp":100+difficulty*20,"renown":3+difficulty}
	))
	offers.append(rotating[rng.randi_range(0,rotating.size()-1)])
	state["offers"] = offers

func offers() -> Array:
	return state.get("offers",[])

func reward_text(contract:Dictionary) -> String:
	var reward:Dictionary = contract.get("reward",{})
	var parts := []
	var bundle:Dictionary = reward.get("resources",{})
	for key in GameState.RESOURCE_ORDER:
		var value = int(round(float(bundle.get(key,0.0))))
		if value > 0:
			parts.append("%s +%d"%[key.capitalize(),value])
	var xp = int(reward.get("xp",0))
	var renown = int(reward.get("renown",0))
	if xp > 0:
		parts.append("XP +%d"%xp)
	if renown > 0:
		parts.append("Renown +%d"%renown)
	return " · ".join(parts)

func claim_contract(id:String) -> bool:
	var offers:Array = state.get("offers",[])
	for i in offers.size():
		var contract:Dictionary = offers[i]
		if String(contract.get("id","")) != id:
			continue
		if not bool(contract.get("completed",false)) or bool(contract.get("claimed",false)):
			return false
		contract["claimed"] = true
		offers[i] = contract
		state["offers"] = offers
		save_contracts()
		var reward:Dictionary = contract.get("reward",{})
		GameState.add_resources(reward.get("resources",{}))
		var renown = int(reward.get("renown",0))
		if renown > 0:
			GameState.player.renown += renown
		var xp = int(reward.get("xp",0))
		if xp > 0:
			GameState.add_xp(xp)
		else:
			GameState.changed.emit()
		GameState.toast_requested.emit("Contract paid: %s" % String(contract.title))
		changed.emit()
		return true
	return false

func all_claimed() -> bool:
	var offers:Array = state.get("offers",[])
	if offers.is_empty():
		return false
	for contract in offers:
		if not bool(contract.get("claimed",false)):
			return false
	return true

func post_new_contracts() -> bool:
	if not all_claimed():
		GameState.toast_requested.emit("Finish and claim the current board first.")
		return false
	state["cycle"] = int(state.get("cycle",1))+1
	state["offers"] = []
	_generate_contracts()
	save_contracts()
	GameState.toast_requested.emit("The Council posted a fresh contract board.")
	changed.emit()
	return true

func save_contracts() -> void:
	var payload = {"version":SAVE_VERSION,"state":state}
	var file = FileAccess.open(SAVE_PATH,FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(payload))
		file.close()

func load_contracts() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		state = {"cycle":1,"offers":[]}
		return
	var file = FileAccess.open(SAVE_PATH,FileAccess.READ)
	if not file:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed)==TYPE_DICTIONARY and parsed.has("state") and typeof(parsed.state)==TYPE_DICTIONARY:
		state = parsed.state
	if not state.has("cycle"):
		state["cycle"] = 1
	if not state.has("offers") or typeof(state.offers)!=TYPE_ARRAY:
		state["offers"] = []
