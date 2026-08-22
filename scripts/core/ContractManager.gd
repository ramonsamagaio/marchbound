extends Node

signal changed

const SAVE_PATH := "user://marchbound_contracts.json"
const MAX_ACTIVE := 3

var board_seed := 0
var board_cycle := 1
var available:Array = []
var active:Array = []
var completed_count := 0
var rng := RandomNumberGenerator.new()
var suppress_check := false

func _ready() -> void:
	await get_tree().process_frame
	_load()
	if available.is_empty() and active.is_empty():
		_new_board()
	GameState.changed.connect(_on_game_state_changed)

func _exit_tree() -> void:
	if GameState.changed.is_connected(_on_game_state_changed):
		GameState.changed.disconnect(_on_game_state_changed)

func _on_game_state_changed() -> void:
	if suppress_check:
		return
	changed.emit()

func _stat_value(key:String) -> float:
	match key:
		"territories": return float(GameState.stats.get("territories_claimed",GameState.claimed_count()))
		"kills": return float(GameState.stats.get("kills",0))
		"victories": return float(GameState.stats.get("victories",0))
		"bosses": return float(GameState.stats.get("bosses",0))
		"items": return float(GameState.stats.get("items_found",0))
		"gold": return float(GameState.stats.get("gold_earned",0.0))
		"threat": return float(GameState.world.get("highest_threat",1))
	return 0.0

func progress(contract:Dictionary) -> float:
	var current := _stat_value(String(contract.get("stat","kills")))
	if bool(contract.get("absolute",false)):
		return current
	return max(0.0,current-float(contract.get("baseline",0.0)))

func is_complete(contract:Dictionary) -> bool:
	return progress(contract) >= float(contract.get("target",1.0))

func accept_contract(uid:String) -> bool:
	if active.size() >= MAX_ACTIVE:
		GameState.toast_requested.emit("Your contract log is full.")
		return false
	for i in available.size():
		if String(available[i].get("uid","")) == uid:
			var contract:Dictionary = available[i].duplicate(true)
			contract["baseline"] = _stat_value(String(contract.stat))
			if bool(contract.get("absolute",false)):
				contract["baseline"] = 0.0
			active.append(contract)
			available.remove_at(i)
			_save()
			GameState.toast_requested.emit("Contract accepted: %s" % contract.title)
			changed.emit()
			return true
	return false

func abandon_contract(uid:String) -> bool:
	for i in active.size():
		if String(active[i].get("uid","")) == uid:
			var title := String(active[i].get("title","Contract"))
			active.remove_at(i)
			_save()
			GameState.toast_requested.emit("Abandoned: %s" % title)
			changed.emit()
			return true
	return false

func claim_contract(uid:String) -> bool:
	for i in active.size():
		var contract:Dictionary = active[i]
		if String(contract.get("uid","")) != uid:
			continue
		if not is_complete(contract):
			GameState.toast_requested.emit("Contract objective is not complete yet.")
			return false
		suppress_check = true
		var rewards:Dictionary = contract.get("reward",{}).duplicate(true)
		var renown := int(contract.get("renown",0))
		GameState.add_resources(rewards)
		GameState.player.renown = int(GameState.player.renown)+renown
		GameState.changed.emit()
		suppress_check = false
		completed_count += 1
		active.remove_at(i)
		_ensure_board_size()
		_save()
		GameState.toast_requested.emit("Contract complete: %s · +%d Renown" % [contract.title,renown])
		changed.emit()
		return true
	return false

func reroll_board() -> bool:
	var cost := 75 + int(GameState.world.get("season",1))*25
	suppress_check = true
	var paid := GameState.spend({"gold":cost})
	suppress_check = false
	if not paid:
		GameState.toast_requested.emit("Need %d Gold to refresh contracts." % cost)
		return false
	board_cycle += 1
	_new_board()
	GameState.toast_requested.emit("The Contract Board has new work.")
	return true

func reroll_cost() -> int:
	return 75 + int(GameState.world.get("season",1))*25

func _new_board() -> void:
	board_seed = abs(hash("%s:%s:%s" % [GameState.world.get("seed",1),GameState.world.get("season",1),board_cycle]))
	rng.seed = board_seed
	available.clear()
	for i in 3:
		available.append(_generate_contract(i))
	_save()
	changed.emit()

func _ensure_board_size() -> void:
	if board_seed == 0:
		board_seed = int(Time.get_unix_time_from_system())
	rng.seed = board_seed + completed_count*7919 + available.size()*37
	while available.size() < 3:
		available.append(_generate_contract(available.size()+completed_count))

func _generate_contract(index:int) -> Dictionary:
	var season := int(GameState.world.get("season",1))
	var level := int(GameState.player.get("level",1))
	var threat := int(GameState.world.get("highest_threat",1))
	var types := ["kills","territories","victories","bosses","items","gold","threat"]
	var stat:String = types[rng.randi_range(0,types.size()-1)]
	var target := 1
	var title := "Frontier Work"
	var desc := ""
	var absolute := false
	match stat:
		"kills":
			target = 35 + level*5 + rng.randi_range(0,25)
			title = ["Cull the Frontier","Broken Fang Writ","Marcher's Toll"][rng.randi_range(0,2)]
			desc = "Defeat %d enemies during expeditions." % target
		"territories":
			target = 2 + min(season,3)
			title = ["Push the Border","Surveyor's Charter","Claim New Ground"][rng.randi_range(0,2)]
			desc = "Claim %d new frontier territories." % target
		"victories":
			target = 2 + rng.randi_range(0,2)
			title = ["Unbroken March","Win the Road","Three Banners"][rng.randi_range(0,2)]
			desc = "Win %d expeditions." % target
		"bosses":
			target = 1 + int(season>=3)
			title = ["Guardian Bounty","Cut Off the Head","Warden's Quarry"][rng.randi_range(0,2)]
			desc = "Defeat %d expedition guardian or regional boss%s." % [target,"es" if target>1 else ""]
		"items":
			target = 2 + rng.randi_range(0,2)
			title = ["Relic Recovery","Armorer's Request","Spoils of the March"][rng.randi_range(0,2)]
			desc = "Recover %d equipment drops." % target
		"gold":
			target = 350 + level*45 + season*80
			title = ["War Chest","Fund the March","Merchant Compact"][rng.randi_range(0,2)]
			desc = "Earn %d Gold from expedition activity." % target
		"threat":
			absolute = true
			target = max(threat+2,3+season*2)
			title = ["Into the Red","Beyond the Lanterns","Deeper March"][rng.randi_range(0,2)]
			desc = "Conquer a territory of Threat %d or higher." % target
	var difficulty := max(1,int(ceil(float(target)/10.0))) if stat in ["kills","gold"] else max(1,target)
	var reward_gold := 70 + season*35 + level*12 + difficulty*10
	var reward := {"gold":reward_gold}
	var resource_options := ["wood","stone","iron","food","mana"]
	var resource:String = resource_options[rng.randi_range(0,resource_options.size()-1)]
	reward[resource] = 8 + season*3 + difficulty*2
	var renown := 4 + min(15,difficulty*2+season)
	return {"uid":"contract_%d_%d_%d"%[board_cycle,index,rng.randi_range(1000,9999)],"stat":stat,"title":title,"description":desc,"target":target,"baseline":0.0,"absolute":absolute,"reward":reward,"renown":renown}

func _save() -> void:
	var payload={"board_seed":board_seed,"board_cycle":board_cycle,"available":available,"active":active,"completed_count":completed_count}
	var file=FileAccess.open(SAVE_PATH,FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(payload))
		file.close()

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file=FileAccess.open(SAVE_PATH,FileAccess.READ)
	if not file:
		return
	var data=JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(data) != TYPE_DICTIONARY:
		return
	board_seed=int(data.get("board_seed",0))
	board_cycle=int(data.get("board_cycle",1))
	available=data.get("available",[])
	active=data.get("active",[])
	completed_count=int(data.get("completed_count",0))
	_ensure_board_size()
