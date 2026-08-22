class_name FirstMarch
extends RefCounted

const STEP_COUNT := 4

const STEPS = [
	{
		"title":"Choose Your Oath",
		"description":"Spend the Warden's first Talent Point. This is your first permanent statement about how you want to play.",
		"cta":"OPEN WARBAND",
		"screen":"army",
		"reward":"100 Gold · 80 Food"
	},
	{
		"title":"Raise the Warband",
		"description":"Recruit one more unit or train any unit family to Rank 2. Command is a budget, so composition matters.",
		"cta":"OPEN WARBAND",
		"screen":"army",
		"reward":"120 Gold · 60 Iron"
	},
	{
		"title":"Take the First Step",
		"description":"Claim one territory beyond Dawnkeep. Pick an adjacent frontier, choose your risk stance and break its guardian.",
		"cta":"OPEN WORLD MAP",
		"screen":"world",
		"reward":"160 Gold · 100 Wood · 80 Stone"
	},
	{
		"title":"Turn Blood Into Growth",
		"description":"Invest the haul back into Dawnkeep: upgrade any building or complete one research tier.",
		"cta":"OPEN DAWNKEEP",
		"screen":"city",
		"reward":"Rare Dawnward Helm · 15 Renown"
	}
]

static func ensure_schema() -> void:
	if not GameState.player.has("first_march") or typeof(GameState.player.get("first_march",{})) != TYPE_DICTIONARY:
		GameState.player["first_march"] = {"step":0,"completed":false}
	var state:Dictionary = GameState.player["first_march"]
	if not state.has("step"):
		state["step"] = 0
	if not state.has("completed"):
		state["completed"] = false
	GameState.player["first_march"] = state

static func state() -> Dictionary:
	ensure_schema()
	return GameState.player["first_march"]

static func step() -> int:
	return clamp(int(state().get("step",0)),0,STEP_COUNT-1)

static func completed() -> bool:
	return bool(state().get("completed",false))

static func current() -> Dictionary:
	if completed():
		return {}
	return STEPS[step()]

static func total_units() -> int:
	var total := 0
	for unit in GameState.army:
		total += int(GameState.army[unit])
	return total

static func has_trained_unit() -> bool:
	for unit in GameState.unit_levels:
		if int(GameState.unit_levels[unit]) >= 2:
			return true
	return false

static func settlement_growth() -> bool:
	var building_total := 0
	for id in GameState.buildings:
		building_total += int(GameState.buildings[id])
	var tech_total := 0
	for id in GameState.tech:
		tech_total += int(GameState.tech[id])
	return building_total >= 6 or tech_total >= 1

static func condition_met() -> bool:
	if completed():
		return false
	match step():
		0:
			return GameState.talent_total_ranks() >= 1
		1:
			return total_units() >= 8 or has_trained_unit()
		2:
			return GameState.claimed_count() >= 2
		3:
			return settlement_growth()
	return false

static func progress_text() -> String:
	if completed():
		return "First March complete"
	match step():
		0:
			return "%d Talent rank chosen" % GameState.talent_total_ranks()
		1:
			return "%d units · highest Rank %d" % [total_units(),_highest_unit_rank()]
		2:
			return "%d / 2 territories claimed" % min(GameState.claimed_count(),2)
		3:
			return "Upgrade a building or research a technology"
	return ""

static func _highest_unit_rank() -> int:
	var highest := 1
	for unit in GameState.unit_levels:
		highest = max(highest,int(GameState.unit_levels[unit]))
	return highest

static func claim_reward() -> bool:
	ensure_schema()
	if completed() or not condition_met():
		return false
	var current_step = step()
	# Advance first so reward-triggered UI refreshes cannot double-pay.
	if current_step >= STEP_COUNT-1:
		GameState.player["first_march"]["completed"] = true
	else:
		GameState.player["first_march"]["step"] = current_step+1

	match current_step:
		0:
			_grant_resources({"gold":100,"food":80})
		1:
			_grant_resources({"gold":120,"iron":60})
		2:
			_grant_resources({"gold":160,"wood":100,"stone":80})
		3:
			_grant_final_reward()

	SaveManager.save_game()
	GameState.changed.emit()
	if current_step >= STEP_COUNT-1:
		GameState.toast_requested.emit("FIRST MARCH COMPLETE · Dawnkeep knows your name now.")
	else:
		GameState.toast_requested.emit("First March reward claimed. A new objective is ready.")
	return true

static func _grant_resources(bundle:Dictionary) -> void:
	for key in bundle:
		GameState.resources[key] = float(GameState.resources.get(key,0.0))+float(bundle[key])
		if key == "gold":
			GameState.stats["gold_earned"] = float(GameState.stats.get("gold_earned",0.0))+float(bundle[key])

static func _grant_final_reward() -> void:
	GameState.player["renown"] = int(GameState.player.get("renown",0))+15
	var item = GameState.make_item("Sunwatch Helm","helm","rare",17,{"command":1.0,"health":14.0})
	item["affixes"] = [
		{"key":"command","name":"Bannered","value":1.0,"text":"+1 Command"},
		{"key":"health","name":"Vigorous","value":14.0,"text":"+14 max HP"}
	]
	item = LootFamilies.decorate_item(item,"Greenlands")
	item["origin_biome"] = "Greenlands"
	item["first_march_reward"] = true
	GameState.inventory.append(item)
	GameState.stats["items_found"] = int(GameState.stats.get("items_found",0))+1
