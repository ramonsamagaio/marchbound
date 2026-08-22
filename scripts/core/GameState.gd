extends Node

signal changed
signal toast_requested(message: String)
signal screen_requested(screen_name: String)

const RESOURCE_ORDER = ["gold", "wood", "stone", "iron", "food", "mana"]

var resources = {}
var player = {}
var army = {}
var unit_levels = {}
var buildings = {}
var tech = {}
var inventory = []
var equipped = {}
var world = {}
var stats = {}
var market_seed := 7781

func _ready() -> void:
	reset_new_game(false)

func reset_new_game(emit_signal := true) -> void:
	resources = {"gold":620.0,"wood":260.0,"stone":180.0,"iron":95.0,"food":330.0,"mana":22.0}
	player = {"name":"Warden","level":1,"xp":0,"xp_next":120,"hp_bonus":0.0,"damage_bonus":0.0,"command_base":12,"skill_points":0,"renown":0}
	army = {"militia":4,"archer":2,"wolf":1,"mage":0}
	unit_levels = {"militia":1,"archer":1,"wolf":1,"mage":1}
	buildings = {"town_hall":1,"lumberyard":1,"quarry":1,"farm":1,"barracks":1,"forge":0,"arcane_lab":0,"market":0}
	tech = {"leadership":0,"metallurgy":0,"agriculture":0,"arcana":0,"exploration":0,"commerce":0}
	inventory = [make_item("Warden Blade","weapon","common",7,{"damage":5}),make_item("Frontier Cuirass","chest","common",6,{"armor":4}),make_item("Scout Boots","boots","uncommon",8,{"speed":0.05})]
	equipped = {"weapon":"","helm":"","shoulders":"","chest":"","gloves":"","belt":"","legs":"","boots":"","cape":""}
	for item in inventory:
		if item.slot in ["weapon","chest","boots"]: equipped[item.slot] = item.uid
	world = {"seed":947213,"day":1,"frontier_depth":1,"highest_threat":1,"selected_tile":{},"season":1}
	stats = {"expeditions":0,"victories":0,"defeats":0,"kills":0,"bosses":0,"gold_earned":0.0,"items_found":0}
	if emit_signal: changed.emit()

func make_item(name:String, slot:String, rarity:String, power:int, bonuses:={}) -> Dictionary:
	var uid = "%s_%s_%s" % [slot, Time.get_ticks_msec(), randi_range(100,999)]
	return {"uid":uid,"name":name,"slot":slot,"rarity":rarity,"power":power,"bonuses":bonuses.duplicate(true),"level":1,"upgrade":0}

func resource_income_per_minute() -> Dictionary:
	var town = buildings.town_hall
	return {"gold":10.0+town*4.0+buildings.market*8.0+tech.commerce*5.0,"wood":14.0+buildings.lumberyard*18.0,"stone":10.0+buildings.quarry*14.0,"iron":3.0+buildings.forge*7.0+tech.metallurgy*2.0,"food":18.0+buildings.farm*24.0+tech.agriculture*7.0,"mana":0.8+buildings.arcane_lab*2.0+tech.arcana*0.8}

func tick_economy(seconds:float) -> void:
	var income = resource_income_per_minute()
	for key in income: resources[key] += income[key] * seconds / 60.0
	changed.emit()

func command_capacity() -> int:
	return int(player.command_base)+int(player.level)*2+int(tech.leadership)*4+int(buildings.town_hall)*2

func unit_command_cost(unit:String) -> int:
	return {"militia":1,"archer":2,"wolf":3,"mage":4}.get(unit,1)

func command_used() -> int:
	var used := 0
	for unit in army: used += int(army[unit]) * unit_command_cost(unit)
	return used

func army_power() -> int:
	var base = {"militia":12,"archer":22,"wolf":31,"mage":48}
	var total := 0
	for unit in army: total += int(army[unit]) * int(base.get(unit,10)) * int(unit_levels.get(unit,1))
	return total

func gear_power() -> int:
	var total := 0
	for slot in equipped:
		var item = get_item(equipped[slot])
		if not item.is_empty(): total += int(item.power)+int(item.upgrade)*3
	return total

func total_power() -> int:
	return army_power()+gear_power()*5+int(player.level)*25+int(player.renown)*3

func get_item(uid:String) -> Dictionary:
	if uid == "": return {}
	for item in inventory:
		if item.uid == uid: return item
	return {}

func add_item(item:Dictionary) -> void:
	inventory.append(item); stats.items_found += 1; toast_requested.emit("New loot: %s" % item.name); changed.emit()

func equip_item(uid:String) -> void:
	var item = get_item(uid)
	if item.is_empty(): return
	equipped[item.slot] = uid; changed.emit()

func upgrade_item(uid:String) -> bool:
	for i in inventory.size():
		if inventory[i].uid == uid:
			var item = inventory[i]
			var cost = 60+int(item.upgrade)*90+int(item.power)*4
			if resources.gold < cost or resources.iron < 8+item.upgrade*4:
				toast_requested.emit("Not enough Gold / Iron."); return false
			resources.gold -= cost; resources.iron -= 8+item.upgrade*4; item.upgrade += 1; item.power += 2; inventory[i]=item
			toast_requested.emit("%s upgraded to +%d" % [item.name,item.upgrade]); changed.emit(); return true
	return false

func can_afford(cost:Dictionary) -> bool:
	for key in cost:
		if float(resources.get(key,0.0)) < float(cost[key]): return false
	return true

func spend(cost:Dictionary) -> bool:
	if not can_afford(cost): return false
	for key in cost: resources[key] -= float(cost[key])
	changed.emit(); return true

func add_resources(bundle:Dictionary) -> void:
	for key in bundle:
		resources[key] = float(resources.get(key,0.0))+float(bundle[key])
		if key == "gold": stats.gold_earned += float(bundle[key])
	changed.emit()

func building_cost(id:String) -> Dictionary:
	var level = int(buildings.get(id,0))
	var base = {"town_hall":{"wood":120,"stone":100,"gold":140},"lumberyard":{"wood":70,"stone":25,"gold":60},"quarry":{"wood":50,"stone":70,"gold":65},"farm":{"wood":55,"stone":20,"gold":50},"barracks":{"wood":90,"stone":70,"gold":90,"food":80},"forge":{"wood":80,"stone":110,"iron":25,"gold":110},"arcane_lab":{"wood":80,"stone":100,"mana":15,"gold":130},"market":{"wood":90,"stone":70,"gold":170}}.get(id,{"wood":50,"gold":50})
	var mult = pow(1.55,level); var result={}
	for key in base: result[key]=int(base[key]*mult)
	return result

func upgrade_building(id:String) -> bool:
	var cost=building_cost(id)
	if not spend(cost): toast_requested.emit("Your settlement lacks resources."); return false
	buildings[id]=int(buildings.get(id,0))+1; toast_requested.emit("%s reached level %d" % [pretty(id),buildings[id]]); changed.emit(); return true

func research_cost(branch:String) -> Dictionary:
	var level=int(tech.get(branch,0)); return {"gold":120+level*160,"mana":8+level*9,"iron":8+level*5}

func research(branch:String) -> bool:
	var cost=research_cost(branch)
	if not spend(cost): toast_requested.emit("Research requires more resources."); return false
	tech[branch]+=1; toast_requested.emit("%s advanced to tier %d" % [pretty(branch),tech[branch]]); changed.emit(); return true

func recruitment_cost(unit:String, amount:=1) -> Dictionary:
	var base={"militia":{"gold":24,"food":18},"archer":{"gold":45,"food":28,"wood":12},"wolf":{"gold":52,"food":45},"mage":{"gold":90,"food":25,"mana":8}}.get(unit,{"gold":20,"food":20}); var result={}
	for key in base: result[key]=base[key]*amount
	return result

func recruit(unit:String) -> bool:
	if command_used()+unit_command_cost(unit)>command_capacity(): toast_requested.emit("Command capacity reached."); return false
	var required_barracks={"militia":1,"archer":1,"wolf":1,"mage":2}.get(unit,1)
	if buildings.barracks<required_barracks: toast_requested.emit("Barracks level %d required." % required_barracks); return false
	if unit=="mage" and buildings.arcane_lab<1: toast_requested.emit("Build an Arcane Lab first."); return false
	if not spend(recruitment_cost(unit)): toast_requested.emit("Not enough resources to recruit."); return false
	army[unit]+=1; changed.emit(); return true

func upgrade_unit(unit:String) -> bool:
	var level=int(unit_levels[unit]); var cost={"gold":100*level,"food":50*level,"iron":12*level}
	if not spend(cost): toast_requested.emit("Unit training needs more resources."); return false
	unit_levels[unit]=level+1; toast_requested.emit("%s trained to rank %d" % [pretty(unit),level+1]); changed.emit(); return true

func add_xp(amount:int) -> void:
	player.xp += amount
	while player.xp >= player.xp_next:
		player.xp -= player.xp_next; player.level += 1; player.skill_points += 1; player.command_base += 1; player.xp_next=int(player.xp_next*1.22+30); toast_requested.emit("LEVEL UP! Warden level %d" % player.level)
	changed.emit()

func expedition_completed(result:Dictionary) -> void:
	stats.expeditions += 1; stats.kills += int(result.get("kills",0))
	if result.get("victory",false):
		stats.victories += 1; world.highest_threat=max(int(world.highest_threat),int(result.get("threat",1))); player.renown += int(result.get("threat",1))*2
		if result.get("boss_killed",false): stats.bosses += 1; player.renown += 5
	else: stats.defeats += 1
	add_resources(result.get("loot",{})); add_xp(int(result.get("xp",0)))
	if result.has("item") and not result.item.is_empty(): add_item(result.item)
	changed.emit()

func prestige_requirement() -> int: return 3000+int(world.season)*1800
func can_advance_season() -> bool: return int(player.renown)>=prestige_requirement() and int(world.highest_threat)>=8+int(world.season)*2
func advance_season() -> void:
	if not can_advance_season(): toast_requested.emit("Conquer deeper threats and earn more Renown first."); return
	world.season += 1; world.frontier_depth += 1; world.seed=randi(); player.renown=int(player.renown*0.35); resources.gold += 500*world.season; toast_requested.emit("A new Frontier Season begins. The world grows harsher."); changed.emit()
func pretty(value:String) -> String: return value.replace("_"," ").capitalize()
func to_dict() -> Dictionary: return {"resources":resources,"player":player,"army":army,"unit_levels":unit_levels,"buildings":buildings,"tech":tech,"inventory":inventory,"equipped":equipped,"world":world,"stats":stats,"market_seed":market_seed}
func from_dict(data:Dictionary) -> void:
	for key in ["resources","player","army","unit_levels","buildings","tech","inventory","equipped","world","stats"]:
		if data.has(key): set(key,data[key])
	if data.has("market_seed"): market_seed=int(data.market_seed)
	changed.emit()
