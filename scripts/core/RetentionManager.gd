extends Node

signal changed

const MEMORY_THRESHOLDS:Array[int] = [0,60,180,450]
const NEMESIS_TITLES:Array[String] = ["the Unbroken","Ash-Eyed","the Patient","Grave-Touched","Ironjaw","the Twice-Born","Red Banner","the Hollow","Bone-Crowned","Stormscar"]
const NEMESIS_TRAITS:Array[String] = ["swift","ironhide","vicious","stormtouched","hexed","relentless"]

var data:Dictionary = {}

func _ready() -> void:
	reset(false)

func reset(emit_signal:bool=true) -> void:
	data = {
		"march_chain":{"count":0,"unbanked_bounty":0,"max_chain":0},
		"nemesis":{"active":false,"species":"","name":"","biome":"","rank":0,"wins":0,"trait":"","defeated":0}
	}
	if emit_signal:
		changed.emit()

func ensure_schema() -> void:
	if not data.has("march_chain") or not data["march_chain"] is Dictionary:
		data["march_chain"] = {"count":0,"unbanked_bounty":0,"max_chain":0}
	if not data.has("nemesis") or not data["nemesis"] is Dictionary:
		data["nemesis"] = {"active":false,"species":"","name":"","biome":"","rank":0,"wins":0,"trait":"","defeated":0}
	var chain:Dictionary = Dictionary(data["march_chain"])
	for pair:Array in [["count",0],["unbanked_bounty",0],["max_chain",0]]:
		if not chain.has(pair[0]): chain[pair[0]] = pair[1]
	data["march_chain"] = chain
	var nemesis:Dictionary = Dictionary(data["nemesis"])
	for pair:Array in [["active",false],["species",""],["name",""],["biome",""],["rank",0],["wins",0],["trait",""],["defeated",0]]:
		if not nemesis.has(pair[0]): nemesis[pair[0]] = pair[1]
	data["nemesis"] = nemesis

func to_dict() -> Dictionary:
	ensure_schema()
	return data.duplicate(true)

func from_dict(value:Dictionary) -> void:
	data = value.duplicate(true)
	ensure_schema()
	changed.emit()

func chain_count() -> int:
	ensure_schema()
	return int(Dictionary(data["march_chain"]).get("count",0))

func chain_bounty() -> int:
	ensure_schema()
	return int(Dictionary(data["march_chain"]).get("unbanked_bounty",0))

func chain_reward_mult() -> float:
	return 1.0 + minf(0.60,float(chain_count())*0.10)

func bank_chain() -> void:
	ensure_schema()
	var chain:Dictionary = Dictionary(data["march_chain"])
	var count:int = int(chain.get("count",0))
	var bounty:int = int(chain.get("unbanked_bounty",0))
	if count <= 0 and bounty <= 0:
		return
	if bounty > 0:
		GameState.add_resources({"gold":bounty})
	var renown_bonus:int = count*3
	if renown_bonus > 0:
		GameState.player["renown"] = int(GameState.player.get("renown",0))+renown_bonus
	GameState.toast_requested.emit("MARCH CHAIN BANKED · %d wins · +%d Gold · +%d Renown"%[count,bounty,renown_bonus])
	chain["count"] = 0
	chain["unbanked_bounty"] = 0
	data["march_chain"] = chain
	changed.emit()

func prepare_expedition_result(result:Dictionary,tile:Dictionary) -> void:
	ensure_schema()
	var chain:Dictionary = Dictionary(data["march_chain"])
	var previous_count:int = int(chain.get("count",0))
	var threat:int = int(result.get("threat",tile.get("threat",1)))
	if bool(result.get("victory",false)):
		var multiplier:float = 1.0 + minf(0.60,float(previous_count)*0.10)
		var loot:Dictionary = Dictionary(result.get("loot",{})).duplicate(true)
		if multiplier > 1.0:
			for raw_key:Variant in loot.keys():
				var key:String = String(raw_key)
				loot[key] = round(float(loot[key])*multiplier)
			result["loot"] = loot
		chain["count"] = previous_count+1
		chain["max_chain"] = maxi(int(chain.get("max_chain",0)),int(chain["count"]))
		chain["unbanked_bounty"] = int(chain.get("unbanked_bounty",0)) + threat*(20+previous_count*8)
		result["march_chain"] = int(chain["count"])
		result["march_chain_mult"] = multiplier
		result["march_chain_bounty"] = int(chain["unbanked_bounty"])
	else:
		result["march_chain_lost"] = previous_count
		result["march_chain_bounty_lost"] = int(chain.get("unbanked_bounty",0))
		chain["count"] = 0
		chain["unbanked_bounty"] = 0
		if not nemesis_active():
			_create_nemesis(String(tile.get("biome","Greenlands")),tile)
	data["march_chain"] = chain
	_advance_equipped_weapon_memory(result,tile)
	changed.emit()

func _advance_equipped_weapon_memory(result:Dictionary,tile:Dictionary) -> void:
	var uid:String = String(GameState.equipped.get("weapon",""))
	if uid == "":
		return
	for i:int in range(GameState.inventory.size()):
		var item:Dictionary = GameState.inventory[i]
		if String(item.get("uid","")) != uid:
			continue
		var old_rank:int = int(item.get("memory_rank",0))
		var gain:int = int(result.get("kills",0)) + int(result.get("elite_kills",0))*4 + (20 if bool(result.get("boss_killed",false)) else 0)
		item["memory_xp"] = int(item.get("memory_xp",0))+gain
		var new_rank:int = _memory_rank_for_xp(int(item["memory_xp"]))
		item["memory_rank"] = new_rank
		if not item.has("memories") or not item["memories"] is Array:
			item["memories"] = []
		if bool(result.get("boss_killed",false)):
			var boss_name:String = String(result.get("boss_name",tile.get("boss_name","Frontier Guardian")))
			var memories:Array = Array(item["memories"])
			if boss_name != "" and boss_name not in memories:
				memories.append(boss_name)
				if memories.size() > 6: memories.pop_front()
			item["memories"] = memories
		GameState.inventory[i] = item
		if new_rank > old_rank:
			GameState.toast_requested.emit("WEAPON MEMORY AWAKENED · %s reached Memory %d"%[String(item.get("name","Weapon")),new_rank])
		break

func _memory_rank_for_xp(xp:int) -> int:
	var rank:int = 0
	for i:int in range(MEMORY_THRESHOLDS.size()):
		if xp >= MEMORY_THRESHOLDS[i]: rank = i
	return rank

func equipped_weapon_memory_rank() -> int:
	var item:Dictionary = GameState.get_item(String(GameState.equipped.get("weapon","")))
	return int(item.get("memory_rank",0)) if not item.is_empty() else 0

func equipped_weapon_memory_xp() -> int:
	var item:Dictionary = GameState.get_item(String(GameState.equipped.get("weapon","")))
	return int(item.get("memory_xp",0)) if not item.is_empty() else 0

func nemesis_active() -> bool:
	ensure_schema()
	return bool(Dictionary(data["nemesis"]).get("active",false))

func nemesis_data() -> Dictionary:
	ensure_schema()
	return Dictionary(data["nemesis"]).duplicate(true)

func nemesis_can_invade(biome:String) -> bool:
	if not nemesis_active():
		return false
	var n:Dictionary = Dictionary(data["nemesis"])
	return String(n.get("biome","")) == biome or int(n.get("rank",0)) >= 3

func _create_nemesis(biome:String,tile:Dictionary) -> void:
	var roster:Array[String] = ContentDB.monsters_for_biome(biome)
	if roster.is_empty():
		return
	var seed_value:int = abs(hash("nemesis:%s:%s:%s"%[biome,tile.get("x",0),tile.get("y",0)]))
	var species:String = roster[seed_value%roster.size()]
	var monster:Dictionary = ContentDB.monster(species)
	var title_index:int = int(seed_value/7)%NEMESIS_TITLES.size()
	var trait_index:int = int(seed_value/13)%NEMESIS_TRAITS.size()
	var title:String = NEMESIS_TITLES[title_index]
	var nemesis_trait:String = NEMESIS_TRAITS[trait_index]
	data["nemesis"] = {
		"active":true,
		"species":species,
		"name":"%s %s"%[String(monster.get("name",species.replace("_"," ").capitalize())),title],
		"biome":biome,
		"rank":1,
		"wins":1,
		"trait":nemesis_trait,
		"defeated":int(Dictionary(data["nemesis"]).get("defeated",0))
	}
	GameState.toast_requested.emit("A NEMESIS RISES · %s remembers this defeat."%String(Dictionary(data["nemesis"]).get("name","Unknown")))

func mark_nemesis_escape() -> void:
	if not nemesis_active():
		return
	var n:Dictionary = Dictionary(data["nemesis"])
	n["rank"] = mini(8,int(n.get("rank",1))+1)
	n["wins"] = int(n.get("wins",0))+1
	data["nemesis"] = n
	GameState.toast_requested.emit("NEMESIS ESCAPED · %s is now Rank %d"%[String(n.get("name","Nemesis")),int(n.get("rank",1))])
	changed.emit()

func defeat_nemesis() -> Dictionary:
	if not nemesis_active():
		return {}
	var n:Dictionary = Dictionary(data["nemesis"])
	var rank:int = int(n.get("rank",1))
	var reward_gold:int = 160 + rank*110
	var reward_renown:int = 8 + rank*5
	var mana_reward:int = maxi(1,int(rank/2))
	GameState.add_resources({"gold":reward_gold,"mana":mana_reward})
	GameState.player["renown"] = int(GameState.player.get("renown",0))+reward_renown
	n["active"] = false
	n["defeated"] = int(n.get("defeated",0))+1
	data["nemesis"] = n
	GameState.toast_requested.emit("NEMESIS BROKEN · %s · +%d Gold · +%d Renown"%[String(n.get("name","Nemesis")),reward_gold,reward_renown])
	changed.emit()
	return {"gold":reward_gold,"renown":reward_renown,"rank":rank,"name":String(n.get("name","Nemesis"))}
