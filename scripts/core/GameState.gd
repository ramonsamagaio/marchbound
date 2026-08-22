extends Node

signal changed
signal toast_requested(message: String)
signal screen_requested(screen_name: String)

const RESOURCE_ORDER = ["gold", "wood", "stone", "iron", "food", "mana"]
const TALENT_ORDER = ["bladecraft", "ironheart", "pathfinder", "commander", "scavenger", "fortune"]
const TALENT_MAX_RANK := 10

var resources = {}
var player = {}
var army = {}
var unit_levels = {}
var buildings = {}
var tech = {}
var talents = {}
var inventory = []
var equipped = {}
var world = {}
var stats = {}
var market_seed := 7781

func _ready() -> void:
	reset_new_game(false)

func reset_new_game(emit_signal := true) -> void:
	resources = {"gold":620.0,"wood":260.0,"stone":180.0,"iron":95.0,"food":330.0,"mana":22.0}
	player = {"name":"Warden","level":1,"xp":0,"xp_next":120,"hp_bonus":0.0,"damage_bonus":0.0,"command_base":12,"skill_points":1,"renown":0,"monster_unlocks":[]}
	army = {"militia":4,"archer":2,"wolf":1,"mage":0}
	unit_levels = {"militia":1,"archer":1,"wolf":1,"mage":1}
	buildings = {"town_hall":1,"lumberyard":1,"quarry":1,"farm":1,"barracks":1,"forge":0,"arcane_lab":0,"market":0}
	tech = {"leadership":0,"metallurgy":0,"agriculture":0,"arcana":0,"exploration":0,"commerce":0}
	talents = {"bladecraft":0,"ironheart":0,"pathfinder":0,"commander":0,"scavenger":0,"fortune":0}
	inventory = [make_item("Warden Blade","weapon","common",7,{"damage":5.0}),make_item("Frontier Cuirass","chest","common",6,{"health":12.0}),make_item("Scout Boots","boots","uncommon",8,{"speed":0.05})]
	equipped = {"weapon":"","helm":"","shoulders":"","chest":"","gloves":"","belt":"","legs":"","boots":"","cape":""}
	for item in inventory:
		if item.slot in ["weapon","chest","boots"]:
			equipped[item.slot] = item.uid
	world = {"seed":947213,"day":1,"frontier_depth":1,"highest_threat":1,"selected_tile":{},"season":1,"focus_x":0,"focus_y":0,"conquered":{"0:0":true}}
	stats = {"expeditions":0,"victories":0,"defeats":0,"kills":0,"bosses":0,"gold_earned":0.0,"items_found":0,"territories_claimed":1,"wild_bonds":0}
	if emit_signal:
		changed.emit()

func ensure_schema() -> void:
	if not world.has("focus_x"): world["focus_x"] = 0
	if not world.has("focus_y"): world["focus_y"] = 0
	if not world.has("conquered") or typeof(world["conquered"]) != TYPE_DICTIONARY:
		world["conquered"] = {"0:0":true}
	if not world["conquered"].has("0:0"): world["conquered"]["0:0"] = true
	if not stats.has("territories_claimed"): stats["territories_claimed"] = world["conquered"].size()
	if not stats.has("wild_bonds"): stats["wild_bonds"] = 0
	if not player.has("skill_points"): player["skill_points"] = 0
	if not player.has("monster_unlocks") or typeof(player.get("monster_unlocks",[])) != TYPE_ARRAY:
		player["monster_unlocks"] = []
	var clean_unlocks:Array[String] = []
	for raw_id in player["monster_unlocks"]:
		var monster_id:String = String(raw_id)
		if MonsterRoster.has(monster_id) and monster_id not in clean_unlocks:
			clean_unlocks.append(monster_id)
			if not army.has(monster_id): army[monster_id] = 0
			if not unit_levels.has(monster_id): unit_levels[monster_id] = 1
	player["monster_unlocks"] = clean_unlocks
	if typeof(talents) != TYPE_DICTIONARY:
		talents = {}
	for id in TALENT_ORDER:
		if not talents.has(id): talents[id] = 0
	for i in inventory.size():
		var item = inventory[i]
		if not item.has("bonuses") or typeof(item["bonuses"]) != TYPE_DICTIONARY:
			item["bonuses"] = {}
		if not item.has("affixes") or typeof(item["affixes"]) != TYPE_ARRAY:
			item["affixes"] = []
		inventory[i] = item

func monster_unlocked(id:String) -> bool:
	ensure_schema()
	return id in player["monster_unlocks"]

func unlocked_monsters() -> Array[String]:
	ensure_schema()
	var result:Array[String] = []
	for id in player["monster_unlocks"]:
		result.append(String(id))
	return result

func unlock_monster(id:String) -> bool:
	ensure_schema()
	if not MonsterRoster.has(id) or monster_unlocked(id):
		return false
	var unlocks:Array = player["monster_unlocks"]
	unlocks.append(id)
	player["monster_unlocks"] = unlocks
	army[id] = int(army.get(id,0))
	unit_levels[id] = max(1,int(unit_levels.get(id,1)))
	stats["wild_bonds"] = int(stats.get("wild_bonds",0))+1
	toast_requested.emit("WILD BOND FORMED · %s can now join your Warband." % MonsterRoster.display_name(id))
	changed.emit()
	return true

func talent_rank(id:String) -> int:
	ensure_schema()
	return int(talents.get(id,0))

func spend_talent(id:String) -> bool:
	ensure_schema()
	if id not in TALENT_ORDER:
		return false
	if int(player.skill_points) <= 0:
		toast_requested.emit("Earn Warden levels to gain Talent Points.")
		return false
	if talent_rank(id) >= TALENT_MAX_RANK:
		toast_requested.emit("That talent is already mastered.")
		return false
	player.skill_points -= 1
	talents[id] = talent_rank(id) + 1
	toast_requested.emit("%s advanced to rank %d." % [pretty(id),talents[id]])
	changed.emit()
	return true

func talent_total_ranks() -> int:
	ensure_schema()
	var total := 0
	for id in TALENT_ORDER:
		total += talent_rank(id)
	return total

func tile_key(x:int, y:int) -> String:
	return "%d:%d" % [x,y]

func is_conquered(x:int, y:int) -> bool:
	ensure_schema()
	return bool(world["conquered"].get(tile_key(x,y), false))

func is_accessible(x:int, y:int) -> bool:
	if is_conquered(x,y): return true
	for dir in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if is_conquered(x+dir.x,y+dir.y): return true
	return false

func claim_tile(tile:Dictionary) -> bool:
	if tile.is_empty(): return false
	ensure_schema()
	var key = tile_key(int(tile.get("x",0)),int(tile.get("y",0)))
	if world["conquered"].has(key): return false
	world["conquered"][key] = true
	stats["territories_claimed"] = int(stats.get("territories_claimed",1)) + 1
	changed.emit()
	return true

func claimed_count() -> int:
	ensure_schema()
	return world["conquered"].size()

func make_item(name:String, slot:String, rarity:String, power:int, bonuses:={}) -> Dictionary:
	var uid = "%s_%s_%s" % [slot, Time.get_ticks_msec(), randi_range(100,999)]
	return {"uid":uid,"name":name,"slot":slot,"rarity":rarity,"power":power,"bonuses":bonuses.duplicate(true),"affixes":[],"level":1,"upgrade":0}

func equipped_bonuses() -> Dictionary:
	ensure_schema()
	var total := {}
	for slot in equipped:
		var item = get_item(String(equipped.get(slot,"")))
		if item.is_empty():
			continue
		var bonuses = item.get("bonuses",{})
		if typeof(bonuses) != TYPE_DICTIONARY:
			continue
		for key in bonuses:
			var value = bonuses[key]
			if typeof(value) in [TYPE_INT,TYPE_FLOAT]:
				total[key] = float(total.get(key,0.0)) + float(value)
	return total

func equipped_bonus(key:String) -> float:
	return float(equipped_bonuses().get(key,0.0))

func resource_income_per_minute() -> Dictionary:
	var town = buildings.town_hall
	return {"gold":10.0+town*4.0+buildings.market*8.0+tech.commerce*5.0,"wood":14.0+buildings.lumberyard*18.0,"stone":10.0+buildings.quarry*14.0,"iron":3.0+buildings.forge*7.0+tech.metallurgy*2.0,"food":18.0+buildings.farm*24.0+tech.agriculture*7.0,"mana":0.8+buildings.arcane_lab*2.0+tech.arcana*0.8}

func tick_economy(seconds:float) -> void:
	var income = resource_income_per_minute()
	for key in income:
		resources[key] += income[key] * seconds / 60.0
	changed.emit()

func command_capacity() -> int:
	return int(player.command_base)+int(player.level)*2+int(tech.leadership)*4+int(buildings.town_hall)*2+talent_rank("commander")*2+int(round(equipped_bonus("command")))

func unit_command_cost(unit:String) -> int:
	if MonsterRoster.has(unit):
		return MonsterRoster.command_cost(unit)
	return int({"militia":1,"archer":2,"wolf":3,"mage":4}.get(unit,1))

func command_used() -> int:
	var used := 0
	for unit in army:
		used += int(army[unit]) * unit_command_cost(unit)
	return used

func army_power() -> int:
	var base = {"militia":12,"archer":22,"wolf":31,"mage":48}
	var total := 0
	for unit in army:
		var unit_power:int = MonsterRoster.power(String(unit)) if MonsterRoster.has(String(unit)) else int(base.get(unit,10))
		total += int(army[unit]) * unit_power * int(unit_levels.get(unit,1))
	return total

func gear_power() -> int:
	var total := 0
	for slot in equipped:
		var item = get_item(String(equipped.get(slot,"")))
		if not item.is_empty():
			total += int(item.power)+int(item.upgrade)*3
	return total

func total_power() -> int:
	var affix_weight = int(equipped_bonus("damage")*3.0 + equipped_bonus("health") + equipped_bonus("command")*15.0 + equipped_bonus("crit")*180.0 + equipped_bonus("army_damage")*120.0)
	return army_power()+gear_power()*5+int(player.level)*25+int(player.renown)*3+talent_total_ranks()*18+affix_weight

func get_item(uid:String) -> Dictionary:
	if uid == "": return {}
	for item in inventory:
		if item.uid == uid: return item
	return {}

func add_item(item:Dictionary) -> void:
	if not item.has("bonuses"): item["bonuses"] = {}
	if not item.has("affixes"): item["affixes"] = []
	inventory.append(item)
	stats.items_found += 1
	toast_requested.emit("New loot: %s" % item.name)
	changed.emit()

func equip_item(uid:String) -> void:
	var item = get_item(uid)
	if item.is_empty(): return
	equipped[item.slot] = uid
	toast_requested.emit("Equipped %s." % item.name)
	changed.emit()

func upgrade_item(uid:String) -> bool:
	for i in inventory.size():
		if inventory[i].uid == uid:
			var item = inventory[i]
			var cost = 60+int(item.upgrade)*90+int(item.power)*4
			if resources.gold < cost or resources.iron < 8+item.upgrade*4:
				toast_requested.emit("Not enough Gold / Iron.")
				return false
			resources.gold -= cost
			resources.iron -= 8+item.upgrade*4
			item.upgrade += 1
			item.power += 2
			inventory[i]=item
			toast_requested.emit("%s upgraded to +%d" % [item.name,item.upgrade])
			changed.emit()
			return true
	return false

func can_afford(cost:Dictionary) -> bool:
	for key in cost:
		if float(resources.get(key,0.0)) < float(cost[key]): return false
	return true

func spend(cost:Dictionary) -> bool:
	if not can_afford(cost): return false
	for key in cost:
		resources[key] -= float(cost[key])
	changed.emit()
	return true

func add_resources(bundle:Dictionary) -> void:
	for key in bundle:
		resources[key] = float(resources.get(key,0.0))+float(bundle[key])
		if key == "gold": stats.gold_earned += float(bundle[key])
	changed.emit()

func building_cost(id:String) -> Dictionary:
	var level = int(buildings.get(id,0))
	var base = {"town_hall":{"wood":120,"stone":100,"gold":140},"lumberyard":{"wood":70,"stone":25,"gold":60},"quarry":{"wood":50,"stone":70,"gold":65},"farm":{"wood":55,"stone":20,"gold":50},"barracks":{"wood":90,"stone":70,"gold":90,"food":80},"forge":{"wood":80,"stone":110,"iron":25,"gold":110},"arcane_lab":{"wood":80,"stone":100,"mana":15,"gold":130},"market":{"wood":90,"stone":70,"gold":170}}.get(id,{"wood":50,"gold":50})
	var mult = pow(1.55,level)
	var result={}
	for key in base:
		result[key]=int(base[key]*mult)
	return result

func upgrade_building(id:String) -> bool:
	var cost=building_cost(id)
	if not spend(cost):
		toast_requested.emit("Your settlement lacks resources.")
		return false
	buildings[id]=int(buildings.get(id,0))+1
	toast_requested.emit("%s reached level %d" % [pretty(id),buildings[id]])
	changed.emit()
	return true

func research_cost(branch:String) -> Dictionary:
	var level=int(tech.get(branch,0))
	return {"gold":120+level*160,"mana":8+level*9,"iron":8+level*5}

func research(branch:String) -> bool:
	var cost=research_cost(branch)
	if not spend(cost):
		toast_requested.emit("Research requires more resources.")
		return false
	tech[branch]+=1
	toast_requested.emit("%s advanced to tier %d" % [pretty(branch),tech[branch]])
	changed.emit()
	return true

func recruitment_cost(unit:String, amount:=1) -> Dictionary:
	if MonsterRoster.has(unit):
		return MonsterRoster.recruitment_cost(unit,int(amount))
	var base={"militia":{"gold":24,"food":18},"archer":{"gold":45,"food":28,"wood":12},"wolf":{"gold":52,"food":45},"mage":{"gold":90,"food":25,"mana":8}}.get(unit,{"gold":20,"food":20})
	var result={}
	for key in base:
		result[key]=base[key]*amount
	return result

func recruit(unit:String) -> bool:
	if MonsterRoster.has(unit) and not monster_unlocked(unit):
		toast_requested.emit("That Wild Bond has not been discovered yet.")
		return false
	if command_used()+unit_command_cost(unit)>command_capacity():
		toast_requested.emit("Command capacity reached.")
		return false
	var required_barracks:int = int({"militia":1,"archer":1,"wolf":1,"mage":2}.get(unit,1))
	if int(buildings.barracks)<required_barracks:
		toast_requested.emit("Barracks level %d required." % required_barracks)
		return false
	if unit=="mage" and buildings.arcane_lab<1:
		toast_requested.emit("Build an Arcane Lab first.")
		return false
	if not spend(recruitment_cost(unit)):
		toast_requested.emit("Not enough resources to recruit.")
		return false
	army[unit]=int(army.get(unit,0))+1
	toast_requested.emit("%s joined the Warband." % pretty(unit))
	changed.emit()
	return true

func upgrade_unit(unit:String) -> bool:
	if not unit_levels.has(unit):
		return false
	var level=int(unit_levels[unit])
	var cost={"gold":100*level,"food":50*level,"iron":12*level}
	if not spend(cost):
		toast_requested.emit("Unit training needs more resources.")
		return false
	unit_levels[unit]=level+1
	toast_requested.emit("%s trained to rank %d" % [pretty(unit),level+1])
	changed.emit()
	return true

func add_xp(amount:int) -> void:
	player.xp += amount
	while player.xp >= player.xp_next:
		player.xp -= player.xp_next
		player.level += 1
		player.skill_points += 1
		player.command_base += 1
		player.xp_next=int(player.xp_next*1.22+30)
		toast_requested.emit("LEVEL UP! Warden level %d · +1 Talent Point" % player.level)
	changed.emit()

func expedition_completed(result:Dictionary) -> void:
	stats.expeditions += 1
	stats.kills += int(result.get("kills",0))
	var threat = int(result.get("threat",1))
	if result.get("victory",false):
		stats.victories += 1
		world.highest_threat=max(int(world.highest_threat),threat)
		player.renown += threat*2
		if result.get("boss_killed",false):
			stats.bosses += 1
			player.renown += 5
		var first_claim = claim_tile(world.get("selected_tile",{}))
		result["territory_claimed"] = first_claim
		if first_claim:
			var tile = world.get("selected_tile",{})
			var richness = int(tile.get("richness",1))
			var claim_loot = result.get("loot",{}).duplicate(true)
			claim_loot["gold"] = float(claim_loot.get("gold",0.0)) + 35.0*threat
			claim_loot["wood"] = float(claim_loot.get("wood",0.0)) + 4.0*richness
			claim_loot["stone"] = float(claim_loot.get("stone",0.0)) + 3.0*richness
			result["loot"] = claim_loot
			toast_requested.emit("Frontier claimed! New adjacent territories are now reachable.")
		var wild_bond:String = String(result.get("wild_bond",""))
		result["wild_bond_unlocked"] = unlock_monster(wild_bond) if wild_bond != "" else false
	else:
		stats.defeats += 1
		result["territory_claimed"] = false
		result["wild_bond_unlocked"] = false
	add_resources(result.get("loot",{}))
	add_xp(int(result.get("xp",0)))
	if result.has("item") and not result.item.is_empty():
		add_item(result.item)
	changed.emit()

func prestige_requirement() -> int:
	return 3000+int(world.season)*1800

func can_advance_season() -> bool:
	return int(player.renown)>=prestige_requirement() and int(world.highest_threat)>=8+int(world.season)*2

func advance_season() -> void:
	if not can_advance_season():
		toast_requested.emit("Conquer deeper threats and earn more Renown first.")
		return
	world.season += 1
	world.frontier_depth += 1
	world.seed=randi()
	world.focus_x=0
	world.focus_y=0
	world.conquered={"0:0":true}
	player.renown=int(player.renown*0.35)
	resources.gold += 500*world.season
	stats.territories_claimed=1
	toast_requested.emit("A new Frontier Season begins. The frontier is reborn and harsher.")
	changed.emit()

func pretty(value:String) -> String:
	if MonsterRoster.has(value):
		return MonsterRoster.display_name(value)
	return value.replace("_"," ").capitalize()

func to_dict() -> Dictionary:
	return {"resources":resources,"player":player,"army":army,"unit_levels":unit_levels,"buildings":buildings,"tech":tech,"talents":talents,"inventory":inventory,"equipped":equipped,"world":world,"stats":stats,"market_seed":market_seed}

func from_dict(data:Dictionary) -> void:
	var had_talents = data.has("talents")
	for key in ["resources","player","army","unit_levels","buildings","tech","talents","inventory","equipped","world","stats"]:
		if data.has(key):
			set(key,data[key])
	if data.has("market_seed"):
		market_seed=int(data.market_seed)
	if not had_talents and int(player.get("skill_points",0)) <= 0:
		player["skill_points"] = 1
	ensure_schema()
	changed.emit()
