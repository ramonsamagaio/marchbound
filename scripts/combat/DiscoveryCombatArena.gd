class_name DiscoveryCombatArena
extends PursuitCombatArena

signal discovery_requested(discovery_id:String,choices:Array)

var discoveries:Array = []
var active_discovery_index:int = -1
var frontier_enemy_hp_mult:float = 1.0
var frontier_enemy_speed_mult:float = 1.0
var frontier_enemy_damage_mult:float = 1.0

func begin(data:Dictionary) -> void:
	discoveries.clear()
	active_discovery_index = -1
	frontier_enemy_hp_mult = 1.0
	frontier_enemy_speed_mult = 1.0
	frontier_enemy_damage_mult = 1.0
	FrontierManager.begin_expedition(data)
	super.begin(data)
	_apply_frontier_bonuses()
	_spawn_discoveries()

func _apply_frontier_bonuses() -> void:
	var bonuses:Dictionary = FrontierManager.combat_bonuses()
	damage *= float(bonuses.get("damage_mult",1.0))
	var hp_mult:float = float(bonuses.get("hp_mult",1.0))
	player_hp_max *= hp_mult
	player_hp = player_hp_max
	player_speed *= float(bonuses.get("move_speed_mult",1.0))
	attack_interval /= maxf(0.20,float(bonuses.get("attack_speed_mult",1.0)))
	crit_chance = minf(0.85,crit_chance+float(bonuses.get("crit_add",0.0)))
	arc_chance = minf(0.95,arc_chance+float(bonuses.get("arc_chance_add",0.0)))
	lifesteal = minf(0.18,lifesteal+float(bonuses.get("lifesteal_add",0.0)))
	army_damage_mult *= float(bonuses.get("army_damage_mult",1.0))
	army_haste_mult *= float(bonuses.get("army_haste_mult",1.0))
	projectile_count += int(bonuses.get("projectile_bonus",0))
	gear_bonuses["fortune"] = float(gear_bonuses.get("fortune",0.0))+float(bonuses.get("fortune_add",0.0))
	frontier_enemy_hp_mult *= float(bonuses.get("enemy_hp_mult",1.0))
	frontier_enemy_speed_mult *= float(bonuses.get("enemy_speed_mult",1.0))
	frontier_enemy_damage_mult *= float(bonuses.get("enemy_damage_mult",1.0))

func _process(delta:float) -> void:
	super._process(delta)
	if ended or paused_for_upgrade:
		return
	_update_discoveries(delta)

func _spawn_enemy(boss:bool) -> void:
	var before:int = enemies.size()
	super._spawn_enemy(boss)
	if enemies.size() <= before:
		return
	var enemy:Dictionary = enemies[enemies.size()-1]
	if bool(enemy.get("frontier_meta_scaled",false)):
		return
	enemy["hp"] = float(enemy.get("hp",1.0))*frontier_enemy_hp_mult
	enemy["max_hp"] = float(enemy["hp"])
	enemy["speed"] = float(enemy.get("speed",60.0))*frontier_enemy_speed_mult
	enemy["base_speed"] = float(enemy["speed"])
	enemy["damage_mult"] = float(enemy.get("damage_mult",1.0))*frontier_enemy_damage_mult
	enemy["frontier_meta_scaled"] = true
	enemies[enemies.size()-1] = enemy

func _spawn_discoveries() -> void:
	var candidates:Array[String] = []
	var biome:String = String(tile.get("biome","Greenlands"))
	for id:String in FrontierManager.discovery_ids():
		var definition:Dictionary = FrontierManager.discovery(id)
		var allowed:Array = Array(definition.get("biomes",[]))
		if allowed.is_empty() or biome in allowed:
			candidates.append(id)
	if candidates.is_empty():
		return
	var count:int = 3 + mini(2,int(floor(float(tile.get("threat",1))/4.0))) + (1 if FrontierManager.atlas_level() >= 3 else 0)
	count = mini(count,candidates.size())
	var chosen:Array[String] = []
	var rumor:Dictionary = FrontierManager.rumor()
	if FrontierManager.rumor_for(int(tile.get("x",0)),int(tile.get("y",0))):
		var forced_id:String = String(rumor.get("discovery_id",""))
		if forced_id in candidates:
			chosen.append(forced_id)
	while chosen.size() < count:
		var next_id:String = _weighted_discovery(candidates,chosen)
		if next_id == "":
			break
		chosen.append(next_id)
	for i:int in range(chosen.size()):
		var radius:float = rng.randf_range(780.0,2200.0)
		if i == 0 and not rumor.is_empty() and chosen[i] == String(rumor.get("discovery_id","")):
			radius = rng.randf_range(700.0,1100.0)
		var angle:float = rng.randf_range(0.0,TAU)
		var pos:Vector2 = player_pos + Vector2.RIGHT.rotated(angle)*radius
		pos.x = clampf(pos.x,120.0,bounds.size.x-120.0)
		pos.y = clampf(pos.y,120.0,bounds.size.y-120.0)
		discoveries.append({"id":chosen[i],"pos":pos,"resolved":false,"pulse":rng.randf_range(0.0,TAU)})

func _weighted_discovery(candidates:Array[String],excluded:Array[String]) -> String:
	var ids:Array[String] = []
	var weights:Array[float] = []
	var total:float = 0.0
	for id:String in candidates:
		if id in excluded:
			continue
		var definition:Dictionary = FrontierManager.discovery(id)
		var rarity:String = String(definition.get("rarity","common"))
		var weight:float = float({"common":100.0,"uncommon":58.0,"rare":25.0,"epic":8.0,"legendary":2.0}.get(rarity,30.0))
		if rarity in ["rare","epic","legendary"]:
			weight *= FrontierManager.rarity_multiplier()
		total += weight
		ids.append(id)
		weights.append(weight)
	if ids.is_empty():
		return ""
	var roll:float = rng.randf_range(0.0,total)
	var cursor:float = 0.0
	for i:int in range(ids.size()):
		cursor += weights[i]
		if roll <= cursor:
			return ids[i]
	return ids[ids.size()-1]

func _update_discoveries(delta:float) -> void:
	for i:int in range(discoveries.size()):
		var discovery:Dictionary = discoveries[i]
		if bool(discovery.get("resolved",false)):
			continue
		discovery["pulse"] = float(discovery.get("pulse",0.0))+delta*2.2
		discoveries[i] = discovery
		if active_discovery_index < 0 and player_pos.distance_to(Vector2(discovery.get("pos",Vector2.ZERO))) <= 58.0:
			active_discovery_index = i
			paused_for_upgrade = true
			var id:String = String(discovery.get("id",""))
			var definition:Dictionary = FrontierManager.discovery(id)
			discovery_requested.emit(id,Array(definition.get("choices",[])).duplicate(true))
			_float_text(Vector2(discovery.get("pos",player_pos))+Vector2(0,-54),"DISCOVERY",Color(String(definition.get("color","#ffffff"))),0.9)
			break

func choose_discovery(choice_id:String) -> bool:
	if active_discovery_index < 0 or active_discovery_index >= discoveries.size():
		return false
	var discovery:Dictionary = discoveries[active_discovery_index]
	var discovery_id:String = String(discovery.get("id",""))
	var definition:Dictionary = FrontierManager.discovery(discovery_id)
	var choice:Dictionary = {}
	for raw_choice:Variant in Array(definition.get("choices",[])):
		if raw_choice is Dictionary and String(Dictionary(raw_choice).get("id","")) == choice_id:
			choice = Dictionary(raw_choice)
			break
	if choice.is_empty():
		return false
	var effects:Dictionary = Dictionary(choice.get("effects",{}))
	var gold_cost:int = int(choice.get("cost_gold",0))
	if gold_cost > 0 and not GameState.spend({"gold":gold_cost}):
		GameState.toast_requested.emit("The frontier asks for %d Gold. You do not have it."%gold_cost)
		return false
	_apply_discovery_effects(effects)
	discovery["resolved"] = true
	discoveries[active_discovery_index] = discovery
	FrontierManager.record_discovery(discovery_id,choice_id,tile)
	if bool(effects.get("rumor_refresh",false)):
		FrontierManager.ensure_rumor(true)
	var color:Color = Color(String(definition.get("color","#ffffff")))
	_spawn_ring(Vector2(discovery.get("pos",player_pos)),color)
	_float_text(Vector2(discovery.get("pos",player_pos))+Vector2(0,-44),String(choice.get("name",choice_id)).to_upper(),color,1.1)
	active_discovery_index = -1
	paused_for_upgrade = false
	return true

func _apply_discovery_effects(effects:Dictionary) -> void:
	if effects.has("run_damage_mult"):
		damage *= float(effects.get("run_damage_mult",1.0))
	if effects.has("run_hp_mult"):
		var old_max:float = player_hp_max
		player_hp_max *= float(effects.get("run_hp_mult",1.0))
		player_hp = clampf(player_hp*(player_hp_max/maxf(1.0,old_max)),1.0,player_hp_max)
	if effects.has("move_speed_mult"):
		player_speed *= float(effects.get("move_speed_mult",1.0))
	if effects.has("attack_speed_mult"):
		attack_interval /= maxf(0.20,float(effects.get("attack_speed_mult",1.0)))
	if effects.has("crit_add"):
		crit_chance = minf(0.90,crit_chance+float(effects.get("crit_add",0.0)))
	if effects.has("arc_chance_add"):
		arc_chance = minf(0.95,arc_chance+float(effects.get("arc_chance_add",0.0)))
	if effects.has("lifesteal_add"):
		lifesteal = minf(0.18,lifesteal+float(effects.get("lifesteal_add",0.0)))
	if effects.has("run_army_damage_mult"):
		army_damage_mult *= float(effects.get("run_army_damage_mult",1.0))
	if effects.has("run_army_haste_mult"):
		army_haste_mult *= float(effects.get("run_army_haste_mult",1.0))
	if effects.has("projectile_bonus"):
		projectile_count += int(effects.get("projectile_bonus",0))
	if effects.has("fortune_add"):
		gear_bonuses["fortune"] = float(gear_bonuses.get("fortune",0.0))+float(effects.get("fortune_add",0.0))
	if effects.has("heal_fraction"):
		player_hp = minf(player_hp_max,player_hp+player_hp_max*float(effects.get("heal_fraction",0.0)))
	for resource:String in GameState.RESOURCE_ORDER:
		var key:String = "loot_"+resource
		if effects.has(key):
			loot[resource] = float(loot.get(resource,0.0))+float(effects[key])
	if effects.has("renown"):
		GameState.player["renown"] = int(GameState.player.get("renown",0))+int(effects.get("renown",0))
	if effects.has("insight"):
		FrontierManager.add_insight(int(effects.get("insight",0)))
	if effects.has("memory_xp"):
		FrontierManager.add_weapon_memory(int(effects.get("memory_xp",0)),"Frontier anomaly")
	if effects.has("weapon_echo"):
		FrontierManager.awaken_weapon_echo(String(effects.get("weapon_echo","")))
	if effects.has("campaign_mark"):
		FrontierManager.add_mark(String(effects.get("campaign_mark","")))
	if bool(effects.get("remove_oldest_mark",false)):
		FrontierManager.remove_mark("oldest")
	if effects.has("warband_legacy"):
		FrontierManager.grant_warband_legacy(String(effects.get("warband_legacy","")))
	if bool(effects.get("bond_local",false)):
		var bond_id:String = MonsterRoster.id_for_biome(String(tile.get("biome","Greenlands")))
		if bond_id != "":
			GameState.unlock_monster(bond_id)
	if effects.has("enemy_hp_mult"):
		frontier_enemy_hp_mult *= float(effects.get("enemy_hp_mult",1.0))
		_scale_existing_enemies(float(effects.get("enemy_hp_mult",1.0)),1.0,1.0)
	if effects.has("enemy_speed_mult"):
		frontier_enemy_speed_mult *= float(effects.get("enemy_speed_mult",1.0))
		_scale_existing_enemies(1.0,float(effects.get("enemy_speed_mult",1.0)),1.0)
	if effects.has("enemy_damage_mult"):
		frontier_enemy_damage_mult *= float(effects.get("enemy_damage_mult",1.0))
		_scale_existing_enemies(1.0,1.0,float(effects.get("enemy_damage_mult",1.0)))
	var elites:int = int(effects.get("spawn_elites",0))
	for _i:int in range(elites):
		_spawn_forced_elite()
	if bool(effects.get("hunter_pack",false)):
		if not hunter_pack_spawned:
			_spawn_hunter_pack()
		else:
			for _i:int in range(3):
				_spawn_forced_elite()

func _scale_existing_enemies(hp_mult:float,speed_mult:float,damage_mult:float) -> void:
	for i:int in range(enemies.size()):
		var enemy:Dictionary = enemies[i]
		if hp_mult != 1.0:
			enemy["hp"] = float(enemy.get("hp",1.0))*hp_mult
			enemy["max_hp"] = float(enemy.get("max_hp",enemy["hp"]))*hp_mult
		if speed_mult != 1.0:
			enemy["speed"] = float(enemy.get("speed",60.0))*speed_mult
			enemy["base_speed"] = float(enemy.get("base_speed",enemy["speed"]))*speed_mult
		if damage_mult != 1.0:
			enemy["damage_mult"] = float(enemy.get("damage_mult",1.0))*damage_mult
		enemies[i] = enemy

func _draw_ground() -> void:
	super._draw_ground()
	var visible:Rect2 = _visible_world_rect(120.0)
	for discovery:Dictionary in discoveries:
		if bool(discovery.get("resolved",false)):
			continue
		var pos:Vector2 = Vector2(discovery.get("pos",Vector2.ZERO))
		if not visible.has_point(pos):
			continue
		var definition:Dictionary = FrontierManager.discovery(String(discovery.get("id","")))
		var color:Color = Color(String(definition.get("color","#ffffff")))
		var pulse:float = 3.0+sin(float(discovery.get("pulse",0.0)))*2.0
		draw_circle(pos,25.0+pulse,Color(color,0.10))
		draw_arc(pos,24.0+pulse,0.0,TAU,28,color,3.0)
		draw_circle(pos,9.0,Color(color,0.75))
		var symbol:String = String(definition.get("symbol","?"))
		draw_string(ThemeDB.fallback_font,pos+Vector2(-7,6),symbol,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color.WHITE)
		if player_pos.distance_to(pos) < 180.0:
			draw_string(ThemeDB.fallback_font,pos+Vector2(-80,-38),String(definition.get("name","Anomaly")),HORIZONTAL_ALIGNMENT_CENTER,160,13,color)
