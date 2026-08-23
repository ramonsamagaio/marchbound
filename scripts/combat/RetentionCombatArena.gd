class_name RetentionCombatArena
extends StatusCombatArena

signal gambit_requested(options:Array)

var gambit_offered:bool = false
var gambit_active:bool = false
var chosen_gambits:Array[String] = []
var gambit_victory_bounty:int = 0
var gambit_enemy_hp_mult:float = 1.0
var gambit_enemy_speed_mult:float = 1.0
var gambit_enemy_damage_mult:float = 1.0
var nemesis_spawned:bool = false
var nemesis_killed:bool = false
var nemesis_eligible:bool = false
var reaction_lock:bool = false
var reaction_count:int = 0

func begin(data:Dictionary) -> void:
	gambit_offered = false
	gambit_active = false
	chosen_gambits.clear()
	gambit_victory_bounty = 0
	gambit_enemy_hp_mult = 1.0
	gambit_enemy_speed_mult = 1.0
	gambit_enemy_damage_mult = 1.0
	nemesis_spawned = false
	nemesis_killed = false
	reaction_count = 0
	super.begin(data)
	nemesis_eligible = RetentionManager.nemesis_can_invade(String(tile.get("biome","Greenlands")))
	_apply_weapon_memory()

func _process(delta:float) -> void:
	super._process(delta)
	if ended:
		return
	if not paused_for_upgrade and nemesis_eligible and not nemesis_spawned and elapsed >= 11.0:
		_spawn_nemesis()
	if not paused_for_upgrade and not gambit_offered and elapsed >= 19.0:
		_offer_gambit()

func _apply_weapon_memory() -> void:
	var rank:int = RetentionManager.equipped_weapon_memory_rank()
	if rank <= 0:
		return
	weapon_profile["damage_mult"] = float(weapon_profile.get("damage_mult",1.0))*(1.0+float(rank)*0.055)
	weapon_profile["attack_speed"] = float(weapon_profile.get("attack_speed",1.0))*(1.0+float(rank)*0.045)
	weapon_profile["knockback"] = float(weapon_profile.get("knockback",0.5))+float(rank)*0.08
	crit_chance += float(rank)*0.012
	var mode:String = String(attack_profile.get("mode",""))
	if mode.begins_with("melee"):
		attack_profile["reach"] = float(attack_profile.get("reach",70.0))+float(rank)*7.0
	elif rank >= 3:
		projectile_count += 1

func _spawn_enemy(boss:bool) -> void:
	var before:int = enemies.size()
	super._spawn_enemy(boss)
	if enemies.size() <= before:
		return
	var enemy:Dictionary = enemies[enemies.size()-1]
	_apply_gambit_enemy_scaling(enemy)
	enemies[enemies.size()-1] = enemy

func _apply_gambit_enemy_scaling(enemy:Dictionary) -> void:
	if gambit_enemy_hp_mult != 1.0:
		enemy["hp"] = float(enemy.get("hp",1.0))*gambit_enemy_hp_mult
		enemy["max_hp"] = float(enemy["hp"])
	if gambit_enemy_speed_mult != 1.0:
		enemy["speed"] = float(enemy.get("speed",60.0))*gambit_enemy_speed_mult
		enemy["base_speed"] = float(enemy["speed"])
	if gambit_enemy_damage_mult != 1.0:
		enemy["damage_mult"] = float(enemy.get("damage_mult",1.0))*gambit_enemy_damage_mult

func _offer_gambit() -> void:
	var ids:Array[String] = ContentDB.ids("gambits")
	if ids.size() < 3:
		return
	gambit_offered = true
	gambit_active = true
	paused_for_upgrade = true
	var choices:Array[String] = []
	var pool:Array[String] = ids.duplicate()
	while choices.size() < 3 and not pool.is_empty():
		var index:int = rng.randi_range(0,pool.size()-1)
		choices.append(pool[index])
		pool.remove_at(index)
	gambit_requested.emit(choices)

func choose_gambit(id:String) -> void:
	if not gambit_active:
		return
	var definition:Dictionary = ContentDB.gambit(id)
	if definition.is_empty():
		paused_for_upgrade = false
		gambit_active = false
		return
	chosen_gambits.append(id)
	var effects:Dictionary = Dictionary(definition.get("effects",{}))
	if effects.has("damage_mult"):
		damage *= float(effects.get("damage_mult",1.0))
	if effects.has("hp_mult"):
		var old_max:float = player_hp_max
		player_hp_max *= float(effects.get("hp_mult",1.0))
		player_hp = minf(player_hp_max,maxf(1.0,player_hp*(player_hp_max/maxf(1.0,old_max))))
	if effects.has("attack_speed_mult"):
		attack_interval /= maxf(0.15,float(effects.get("attack_speed_mult",1.0)))
	if effects.has("projectile_bonus"):
		projectile_count += int(effects.get("projectile_bonus",0))
	if effects.has("move_speed_mult"):
		player_speed *= float(effects.get("move_speed_mult",1.0))
	if effects.has("army_damage_mult"):
		army_damage_mult *= float(effects.get("army_damage_mult",1.0))
	if effects.has("army_haste_mult"):
		army_haste_mult *= float(effects.get("army_haste_mult",1.0))
	if effects.has("arc_chance_add"):
		arc_chance = minf(0.95,arc_chance+float(effects.get("arc_chance_add",0.0)))
	if effects.has("crit_add"):
		crit_chance = minf(0.85,crit_chance+float(effects.get("crit_add",0.0)))
	if effects.has("fortune_add"):
		gear_bonuses["fortune"] = float(gear_bonuses.get("fortune",0.0))+float(effects.get("fortune_add",0.0))
	if effects.has("harvest_add"):
		gear_bonuses["harvest"] = float(gear_bonuses.get("harvest",0.0))+float(effects.get("harvest_add",0.0))
	if effects.has("knockback_mult"):
		weapon_profile["knockback"] = float(weapon_profile.get("knockback",0.5))*float(effects.get("knockback_mult",1.0))
	if effects.has("enemy_hp_mult"):
		gambit_enemy_hp_mult *= float(effects.get("enemy_hp_mult",1.0))
	if effects.has("enemy_speed_mult"):
		gambit_enemy_speed_mult *= float(effects.get("enemy_speed_mult",1.0))
	if effects.has("enemy_damage_mult"):
		gambit_enemy_damage_mult *= float(effects.get("enemy_damage_mult",1.0))
	for enemy:Dictionary in enemies:
		_apply_gambit_enemy_scaling(enemy)
	var elites:int = int(effects.get("spawn_elites",0))
	for i:int in range(elites):
		_spawn_forced_elite()
	gambit_victory_bounty += int(definition.get("victory_bounty",0))
	paused_for_upgrade = false
	gambit_active = false
	_float_text(player_pos+Vector2(0,-58),String(definition.get("name",id)).to_upper(),Color(String(definition.get("color","#f2d28d"))),1.1)
	_spawn_ring(player_pos,Color(String(definition.get("color","#f2d28d"))))

func _spawn_forced_elite() -> void:
	var before:int = enemies.size()
	_spawn_enemy(false)
	if enemies.size() <= before:
		return
	var enemy:Dictionary = enemies[enemies.size()-1]
	if not bool(enemy.get("elite",false)):
		enemy["elite"] = true
		enemy["hp"] = float(enemy.get("hp",1.0))*2.0
		enemy["max_hp"] = float(enemy["hp"])
		enemy["damage_mult"] = float(enemy.get("damage_mult",1.0))*1.35
		enemy["radius"] = float(enemy.get("radius",14.0))*1.15
		enemies[enemies.size()-1] = enemy

func _spawn_nemesis() -> void:
	if not RetentionManager.nemesis_active():
		return
	var before:int = enemies.size()
	_spawn_enemy(false)
	if enemies.size() <= before:
		return
	var n:Dictionary = RetentionManager.nemesis_data()
	var species:String = String(n.get("species","raider"))
	var definition:Dictionary = ContentDB.monster(species)
	var enemy:Dictionary = enemies[enemies.size()-1]
	enemy["type"] = species
	enemy["behavior"] = String(definition.get("behavior",enemy.get("behavior","melee")))
	enemy["attack_id"] = String(definition.get("attack_id",enemy.get("attack_id","enemy_claw")))
	enemy["projectile_id"] = String(definition.get("projectile_id",enemy.get("projectile_id","")))
	enemy["nemesis"] = true
	enemy["name"] = String(n.get("name","Nemesis"))
	enemy["elite"] = true
	var rank:int = int(n.get("rank",1))
	enemy["hp"] = float(enemy.get("hp",25.0))*(3.2+float(rank)*0.85)
	enemy["max_hp"] = float(enemy["hp"])
	enemy["damage_mult"] = float(enemy.get("damage_mult",1.0))*(1.35+float(rank)*0.14)
	enemy["radius"] = float(enemy.get("radius",14.0))*1.35
	var nemesis_trait:String = String(n.get("trait","relentless"))
	match nemesis_trait:
		"swift": enemy["speed"] = float(enemy.get("speed",60.0))*1.55
		"ironhide": enemy["hp"] = float(enemy["hp"])*1.45; enemy["max_hp"] = float(enemy["hp"])
		"vicious": enemy["damage_mult"] = float(enemy["damage_mult"])*1.42
		"stormtouched": enemy["behavior"] = "ranged"; enemy["projectile_id"] = "arcane_bolt"
		"hexed": enemy["behavior"] = "ranged"; enemy["projectile_id"] = "enemy_hex"
		"relentless":
			enemy["speed"] = float(enemy.get("speed",60.0))*1.18
			enemy["hp"] = float(enemy["hp"])*1.18; enemy["max_hp"] = float(enemy["hp"])
	enemy["base_speed"] = float(enemy.get("speed",60.0))
	enemies[enemies.size()-1] = enemy
	nemesis_spawned = true
	_float_text(player_pos+Vector2(0,-70),"NEMESIS INVASION · %s"%String(n.get("name","Unknown")),Color("#ef8f98"),1.5)
	_shake(0.25,8.0)

func _apply_status(enemy:Dictionary,status_id:String,source_power:float) -> void:
	super._apply_status(enemy,status_id,source_power)
	if not reaction_lock:
		_try_status_reaction(enemy,source_power)

func _try_status_reaction(enemy:Dictionary,source_power:float) -> void:
	var status_map:Dictionary = Dictionary(enemy.get("statuses",{}))
	if status_map.size() < 2:
		return
	var cooldowns:Dictionary = Dictionary(enemy.get("reaction_cooldowns",{}))
	for id:String in ContentDB.ids("reactions"):
		if float(cooldowns.get(id,0.0)) > elapsed:
			continue
		var reaction:Dictionary = ContentDB.reaction(id)
		var requirements:Array = Array(reaction.get("requires",[]))
		var ready:bool = true
		for raw_status:Variant in requirements:
			if not status_map.has(String(raw_status)):
				ready = false
				break
		if not ready:
			continue
		_trigger_reaction(enemy,id,reaction,source_power,status_map)
		cooldowns[id] = elapsed+1.25
		enemy["reaction_cooldowns"] = cooldowns
		break

func _trigger_reaction(enemy:Dictionary,id:String,reaction:Dictionary,source_power:float,status_map:Dictionary) -> void:
	for raw_status:Variant in Array(reaction.get("consume",[])):
		status_map.erase(String(raw_status))
	enemy["statuses"] = status_map
	var damage_amount:float = maxf(2.0,source_power*float(reaction.get("damage_mult",0.5)))
	_damage_enemy(enemy,damage_amount,false)
	var radius:float = float(reaction.get("radius",60.0))
	var applied:String = String(reaction.get("apply_status",""))
	var center:Vector2 = Vector2(enemy.get("pos",Vector2.ZERO))
	reaction_lock = true
	for other:Dictionary in enemies:
		if other == enemy:
			continue
		if Vector2(other.get("pos",Vector2.ZERO)).distance_to(center) <= radius:
			_damage_enemy(other,damage_amount*0.55,false)
			if applied != "":
				_apply_status(other,applied,damage_amount*0.7)
	reaction_lock = false
	var color:Color = Color(String(reaction.get("color","#ffffff")))
	_spawn_ring(center,color)
	_float_text(center+Vector2(0,-48),String(reaction.get("name",id)).to_upper(),color,0.85)
	_shake(0.08,3.0)
	reaction_count += 1

func _kill_enemy(enemy:Dictionary) -> void:
	if bool(enemy.get("nemesis",false)) and not nemesis_killed:
		nemesis_killed = true
		RetentionManager.defeat_nemesis()
	super._kill_enemy(enemy)

func _finish(victory:bool) -> void:
	if victory and gambit_victory_bounty > 0:
		loot["gold"] = float(loot.get("gold",0.0))+float(gambit_victory_bounty)
	if not victory and nemesis_spawned and not nemesis_killed:
		RetentionManager.mark_nemesis_escape()
	super._finish(victory)

func _draw_enemy(enemy:Dictionary) -> void:
	super._draw_enemy(enemy)
	if not bool(enemy.get("nemesis",false)):
		return
	var p:Vector2 = Vector2(enemy.get("pos",Vector2.ZERO))
	draw_arc(p,float(enemy.get("radius",20.0))+22.0,0,TAU,32,Color("#ef6f7f"),4.0)
	draw_string(ThemeDB.fallback_font,p+Vector2(-70,-68),String(enemy.get("name","NEMESIS")),HORIZONTAL_ALIGNMENT_CENTER,140,13,Color("#ffd8dc"))
