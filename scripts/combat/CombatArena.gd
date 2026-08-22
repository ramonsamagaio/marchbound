class_name CombatArena
extends Node2D

signal hud_changed(data: Dictionary)
signal upgrade_requested
signal finished(result: Dictionary)

var bounds := Rect2(0, 0, 900, 560)
var tile := {}
var objective := "Frontier Claim"
var objective_target := 44
var player_pos := Vector2(450, 280)
var player_hp := 100.0
var player_hp_max := 100.0
var player_speed := 210.0
var damage := 15.0
var attack_interval := 0.55
var projectile_count := 1
var army_damage_mult := 1.0
var attack_timer := 0.0
var spawn_timer := 0.0
var elapsed := 0.0
var kills := 0
var xp := 0
var run_level := 1
var next_level_kills := 10
var paused_for_upgrade := false
var boss_spawned := false
var boss_killed := false
var ended := false
var dash_cd := 0.0
var dash_time := 0.0
var dash_dir := Vector2.ZERO
var rally_cd := 0.0
var rally_time := 0.0
var burst_cd := 0.0
var combo := 0
var best_combo := 0
var combo_timer := 0.0
var nodes_collected := 0
var enemies := []
var projectiles := []
var allies := []
var particles := []
var resource_nodes := []
var loot := {"gold":0.0,"wood":0.0,"stone":0.0,"iron":0.0,"food":0.0,"mana":0.0}
var rng := RandomNumberGenerator.new()

func begin(data: Dictionary) -> void:
	tile = data.duplicate(true)
	objective = String(tile.get("objective", "Frontier Claim"))
	rng.seed = int(tile.get("seed", Time.get_ticks_msec()))
	player_hp_max = 100.0 + GameState.player.hp_bonus + GameState.gear_power() * 0.8
	player_hp = player_hp_max
	damage = 14.0 + GameState.player.level * 1.8 + GameState.gear_power() * 0.8
	_spawn_allies()
	_spawn_resource_nodes()
	_configure_objective()
	set_process(true)
	queue_redraw()

func _configure_objective() -> void:
	var threat = int(tile.get("threat",1))
	match objective:
		"Monster Hunt": objective_target = 15 + threat * 3
		"Resource Sweep": objective_target = min(resource_nodes.size(), 2 + int(ceil(float(threat) / 3.0)))
		"Ruin Siege": objective_target = 20
		_: objective_target = 44

func _objective_progress() -> int:
	match objective:
		"Monster Hunt": return kills
		"Resource Sweep": return nodes_collected
		_: return int(elapsed)

func _objective_ready() -> bool:
	if boss_spawned: return true
	match objective:
		"Monster Hunt": return kills >= objective_target or elapsed >= 68.0
		"Resource Sweep": return nodes_collected >= objective_target or elapsed >= 72.0
		"Ruin Siege": return elapsed >= float(objective_target)
		_: return elapsed >= float(objective_target)

func _spawn_allies() -> void:
	allies.clear()
	var offsets = [Vector2(-45,20),Vector2(45,20),Vector2(-70,55),Vector2(70,55),Vector2(0,65),Vector2(-95,75),Vector2(95,75)]
	var idx := 0
	for unit in GameState.army:
		for n in min(int(GameState.army[unit]), 3):
			allies.append({"type":unit,"pos":player_pos+offsets[idx%offsets.size()],"cooldown":rng.randf_range(0.0,1.0)})
			idx += 1

func _spawn_resource_nodes() -> void:
	resource_nodes.clear()
	var choices = _resource_choices_for_biome(String(tile.get("biome","Greenlands")))
	var count = 3 + int(tile.get("richness",1))
	for i in count:
		var p = Vector2(rng.randf_range(80.0,bounds.size.x-80.0),rng.randf_range(70.0,bounds.size.y-70.0))
		if p.distance_to(player_pos) < 120.0:
			p += Vector2(145.0,0.0).rotated(float(i)*1.7)
		p.x=clamp(p.x,60.0,bounds.size.x-60.0)
		p.y=clamp(p.y,60.0,bounds.size.y-60.0)
		var type = choices[i%choices.size()]
		var richness = int(tile.get("richness",1))
		var base_value = {"wood":8,"stone":7,"iron":4,"food":10,"mana":2,"gold":15}.get(type,6)
		resource_nodes.append({"pos":p,"type":type,"progress":0.0,"collected":false,"value":base_value*richness,"pulse":rng.randf_range(0.0,TAU)})

func _resource_choices_for_biome(biome:String) -> Array:
	return {
		"Greenlands":["food","wood","gold"],
		"Ancient Forest":["wood","wood","mana"],
		"Iron Hills":["stone","iron","iron"],
		"Mistfen":["food","mana","wood"],
		"Ash Wastes":["iron","stone","gold"],
		"Frostwild":["mana","iron","stone"]
	}.get(biome,["wood","stone","food"])

func _process(delta: float) -> void:
	if ended or paused_for_upgrade:
		queue_redraw()
		return
	elapsed += delta
	attack_timer -= delta
	spawn_timer -= delta
	dash_cd = max(0.0, dash_cd-delta)
	rally_cd = max(0.0, rally_cd-delta)
	rally_time = max(0.0, rally_time-delta)
	burst_cd = max(0.0, burst_cd-delta)
	combo_timer = max(0.0,combo_timer-delta)
	if combo_timer <= 0.0:
		combo = 0
	_handle_input(delta)
	_update_resource_nodes(delta)
	_spawn_logic()
	_update_enemies(delta)
	_update_allies(delta)
	_update_projectiles(delta)
	_update_particles(delta)
	_auto_attack()
	_check_level()
	_check_end()
	hud_changed.emit({"hp":player_hp,"hp_max":player_hp_max,"time":elapsed,"kills":kills,"level":run_level,"threat":tile.get("threat",1),"boss":boss_spawned,"dash_cd":dash_cd,"rally_cd":rally_cd,"burst_cd":burst_cd,"combo":combo,"best_combo":best_combo,"nodes":nodes_collected,"nodes_total":resource_nodes.size(),"objective":objective,"objective_progress":_objective_progress(),"objective_target":objective_target})
	queue_redraw()

func _handle_input(delta: float) -> void:
	var dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if Input.is_action_just_pressed("dash") and dash_cd <= 0.0 and dir.length() > 0.1:
		dash_time = 0.18
		dash_cd = 2.3
		dash_dir = dir.normalized()
	if dash_time > 0.0:
		dash_time -= delta
		player_pos += dash_dir * 560.0 * delta
	else:
		player_pos += dir * player_speed * delta
	player_pos.x = clamp(player_pos.x, bounds.position.x+24, bounds.end.x-24)
	player_pos.y = clamp(player_pos.y, bounds.position.y+24, bounds.end.y-24)
	if Input.is_action_just_pressed("ability_rally") and rally_cd <= 0.0:
		rally_cd = 12.0
		rally_time = 6.0
		_spawn_ring(player_pos, Color("#f0d67d"))
	if Input.is_action_just_pressed("ability_burst") and burst_cd <= 0.0:
		burst_cd = 8.0
		for e in enemies:
			if player_pos.distance_to(e.pos) < 125:
				e.hp -= damage * 1.6
				e.flash = 0.12
		_spawn_ring(player_pos, Color("#84b9ff"))

func _update_resource_nodes(delta:float) -> void:
	for node in resource_nodes:
		if bool(node.collected):
			continue
		node.pulse = float(node.pulse)+delta*2.0
		if player_pos.distance_to(node.pos) <= 34.0:
			node.progress = float(node.progress)+delta
			if float(node.progress) >= 1.15:
				node.collected = true
				nodes_collected += 1
				var type = String(node.type)
				loot[type] = float(loot.get(type,0.0))+float(node.value)
				xp += 8 + int(tile.get("threat",1))*2
				player_hp = min(player_hp_max,player_hp+5.0)
				_spawn_ring(node.pos,_resource_color(type))
		else:
			node.progress = max(0.0,float(node.progress)-delta*0.4)

func _spawn_logic() -> void:
	var threat = int(tile.get("threat", 1))
	if not boss_spawned and _objective_ready():
		_spawn_enemy(true)
		boss_spawned = true
		_spawn_ring(player_pos, Color("#e3b76e"))
	if spawn_timer <= 0.0:
		var objective_pressure = 1 if objective == "Monster Hunt" else 0
		var count = 1 + int(elapsed/22.0) + int(threat/4) + objective_pressure
		for i in count:
			_spawn_enemy(false)
		spawn_timer = max(0.32, 1.25 - elapsed*0.008 - threat*0.035)

func _spawn_enemy(boss: bool) -> void:
	var edge = rng.randi_range(0,3)
	var p = Vector2.ZERO
	if edge == 0:
		p = Vector2(rng.randf_range(10,bounds.size.x-10),10)
	elif edge == 1:
		p = Vector2(bounds.size.x-10,rng.randf_range(10,bounds.size.y-10))
	elif edge == 2:
		p = Vector2(rng.randf_range(10,bounds.size.x-10),bounds.size.y-10)
	else:
		p = Vector2(10,rng.randf_range(10,bounds.size.y-10))
	var threat = int(tile.get("threat",1))
	var etype = ["raider","slime","wolf","wisp"][rng.randi_range(0,3)]
	var hp = 25.0 + threat*8.0 + elapsed*0.35
	var speed = 58.0 + threat*2.3 + rng.randf_range(-8,8)
	var radius = 14.0
	var damage_mult = 1.0
	if boss:
		etype = "boss"
		hp = 520.0 + threat*115.0
		speed = 42.0 + threat
		radius = 34.0
		if objective == "Ruin Siege":
			hp *= 1.45
			speed *= 1.08
			damage_mult = 1.35
	enemies.append({"pos":p,"hp":hp,"max_hp":hp,"speed":speed,"type":etype,"radius":radius,"boss":boss,"flash":0.0,"attack_cd":0.0,"damage_mult":damage_mult})

func _update_enemies(delta: float) -> void:
	for i in range(enemies.size()-1,-1,-1):
		var e = enemies[i]
		e.flash = max(0.0,float(e.flash)-delta)
		e.attack_cd = max(0.0,float(e.attack_cd)-delta)
		if e.hp <= 0:
			_kill_enemy(e)
			enemies.remove_at(i)
			continue
		var dir = (player_pos-e.pos).normalized()
		e.pos += dir * e.speed * delta
		if e.pos.distance_to(player_pos) < e.radius + 16 and e.attack_cd <= 0:
			var hit = (7.0 + int(tile.get("threat",1))*1.7) * float(e.get("damage_mult",1.0))
			if e.boss:
				hit *= 2.2
			player_hp -= hit
			e.attack_cd = 0.75
			_spawn_ring(player_pos, Color("#d85e69"))
		enemies[i] = e

func _kill_enemy(e: Dictionary) -> void:
	kills += 1
	combo = combo+1 if combo_timer>0.0 else 1
	combo_timer = 2.6
	best_combo = max(best_combo,combo)
	xp += 4 + int(tile.get("threat",1))
	var richness = int(tile.get("richness",1))
	loot.gold += rng.randi_range(2,5) * richness
	if combo>0 and combo%10==0:
		loot.gold += 5*richness + combo
		_spawn_ring(player_pos,Color("#f4df8c"))
	if rng.randf() < 0.22: loot.wood += rng.randi_range(1,4) * richness
	if rng.randf() < 0.16: loot.stone += rng.randi_range(1,3) * richness
	if rng.randf() < 0.09: loot.iron += rng.randi_range(1,2) * richness
	if rng.randf() < 0.08: loot.food += rng.randi_range(1,4) * richness
	if rng.randf() < 0.025: loot.mana += 1 * richness
	if e.boss:
		boss_killed = true
		loot.gold += 120 * int(tile.get("threat",1))
		loot.mana += 5 + int(tile.get("threat",1))
		_spawn_ring(e.pos, Color("#f1c36e"))
	else:
		_spawn_ring(e.pos, Color("#ad8c67"))

func _update_allies(delta: float) -> void:
	var index := 0
	for ally in allies:
		var angle = elapsed*0.45 + index*TAU/max(1,allies.size())
		var desired = player_pos + Vector2(cos(angle),sin(angle))*(55+(index%3)*16)
		ally.pos = ally.pos.lerp(desired,min(1.0,delta*4.0))
		ally.cooldown -= delta
		if ally.cooldown <= 0 and enemies.size() > 0:
			var target = nearest_enemy(ally.pos)
			if not target.is_empty() and ally.pos.distance_to(target.pos) < 220:
				var rally_mult = 1.45 if rally_time > 0 else 1.0
				var momentum = 1.0+min(combo,30)*0.008
				target.hp -= unit_damage(ally.type) * army_damage_mult * rally_mult * momentum
				target.flash = 0.08
				ally.cooldown = unit_cooldown(ally.type)
		index += 1

func unit_damage(type: String) -> float:
	return {"militia":6.0,"archer":8.0,"wolf":10.0,"mage":13.0}.get(type,6.0) * GameState.unit_levels.get(type,1)

func unit_cooldown(type: String) -> float:
	return {"militia":0.85,"archer":1.05,"wolf":0.7,"mage":1.35}.get(type,1.0)

func _auto_attack() -> void:
	if attack_timer > 0 or enemies.is_empty():
		return
	var target = nearest_enemy(player_pos)
	if target.is_empty():
		return
	var momentum = 1.0+min(combo,30)*0.012
	for i in projectile_count:
		var spread = (i-(projectile_count-1)/2.0)*0.16
		var dir = (target.pos-player_pos).normalized().rotated(spread)
		projectiles.append({"pos":player_pos,"vel":dir*430.0,"damage":damage*momentum,"life":1.6})
	attack_timer = attack_interval

func nearest_enemy(pos: Vector2) -> Dictionary:
	var best := {}
	var best_d := INF
	for e in enemies:
		var d = pos.distance_squared_to(e.pos)
		if d < best_d:
			best_d = d
			best = e
	return best

func _update_projectiles(delta: float) -> void:
	for i in range(projectiles.size()-1,-1,-1):
		var p = projectiles[i]
		p.pos += p.vel * delta
		p.life -= delta
		var hit := false
		for e in enemies:
			if p.pos.distance_to(e.pos) < e.radius + 5:
				e.hp -= p.damage
				e.flash = 0.08
				hit = true
				break
		if hit or p.life <= 0 or not bounds.grow(30).has_point(p.pos):
			projectiles.remove_at(i)
		else:
			projectiles[i] = p

func _update_particles(delta: float) -> void:
	for i in range(particles.size()-1,-1,-1):
		particles[i].life -= delta
		if particles[i].life <= 0:
			particles.remove_at(i)

func _spawn_ring(pos: Vector2, color: Color) -> void:
	particles.append({"pos":pos,"life":0.35,"max":0.35,"color":color})

func _check_level() -> void:
	if kills >= next_level_kills:
		run_level += 1
		next_level_kills += 10 + run_level*4
		paused_for_upgrade = true
		upgrade_requested.emit()

func apply_upgrade(id: String) -> void:
	match id:
		"damage": damage *= 1.25
		"speed": player_speed *= 1.15
		"haste": attack_interval *= 0.82
		"projectile": projectile_count += 1
		"army": army_damage_mult *= 1.3
		"vitality":
			player_hp_max *= 1.25
			player_hp += player_hp_max*0.25
	paused_for_upgrade = false

func _check_end() -> void:
	if player_hp <= 0:
		_finish(false)
	elif boss_spawned and boss_killed:
		_finish(true)

func _apply_objective_reward(victory:bool) -> int:
	if not victory:
		return 0
	var threat = int(tile.get("threat",1))
	var richness = int(tile.get("richness",1))
	match objective:
		"Monster Hunt":
			loot.gold += 28 * threat
			return 24 * threat
		"Resource Sweep":
			loot.wood += 4 * richness
			loot.stone += 4 * richness
			loot.iron += 2 * richness
			return 18 * threat
		"Ruin Siege":
			loot.gold += 55 * threat
			loot.mana += 2 * threat
			return 40 * threat
		_:
			loot.gold += 15 * threat
			return 12 * threat

func _finish(victory: bool) -> void:
	if ended:
		return
	ended = true
	var threat = int(tile.get("threat",1))
	var objective_xp = _apply_objective_reward(victory)
	var item = {}
	var chance = 0.18 + threat*0.025 + (0.35 if boss_killed else 0.0)
	if objective == "Ruin Siege" and victory:
		chance += 0.20
	if rng.randf() < chance:
		item = generate_loot_item(threat)
	finished.emit({"victory":victory,"kills":kills,"xp":xp+objective_xp+(80*threat if victory else 0),"loot":loot.duplicate(true),"threat":threat,"boss_killed":boss_killed,"item":item,"nodes_collected":nodes_collected,"nodes_total":resource_nodes.size(),"best_combo":best_combo,"objective":objective,"objective_progress":_objective_progress(),"objective_target":objective_target})

func generate_loot_item(threat: int) -> Dictionary:
	var slots = ["weapon","helm","shoulders","chest","gloves","belt","legs","boots","cape"]
	var slot = slots[rng.randi_range(0,slots.size()-1)]
	var rarity = "common"
	var roll = rng.randf()+threat*0.025
	if objective == "Ruin Siege":
		roll += 0.12
	if roll > 1.18: rarity="legendary"
	elif roll > 0.98: rarity="epic"
	elif roll > 0.72: rarity="rare"
	elif roll > 0.42: rarity="uncommon"
	var prefix = {"common":"Frontier","uncommon":"Tempered","rare":"Runebound","epic":"Sovereign","legendary":"Mythic"}[rarity]
	var noun = {"weapon":"Blade","helm":"Helm","shoulders":"Pauldrons","chest":"Cuirass","gloves":"Gauntlets","belt":"Warbelt","legs":"Greaves","boots":"Sabatons","cape":"Mantle"}[slot]
	var power = 5+threat*3+{"common":0,"uncommon":3,"rare":7,"epic":13,"legendary":22}[rarity]
	return GameState.make_item("%s %s"%[prefix,noun],slot,rarity,power,{})

func _draw() -> void:
	_draw_ground()
	for node in resource_nodes:
		if not bool(node.collected):
			_draw_resource_node(node)
	for p in particles:
		var t = p.life/p.max
		draw_arc(p.pos,48*(1.0-t)+8,0,TAU,28,Color(p.color,t),3)
	for a in allies:
		_draw_ally(a)
	for e in enemies:
		_draw_enemy(e)
	for p in projectiles:
		draw_circle(p.pos,5,Color("#bfe4ff"))
		draw_circle(p.pos,2,Color.WHITE)
	_draw_player()

func _draw_ground() -> void:
	var colors={"Greenlands":Color("#253b2c"),"Ancient Forest":Color("#1d3529"),"Iron Hills":Color("#333638"),"Mistfen":Color("#263b3d"),"Ash Wastes":Color("#3b2b28"),"Frostwild":Color("#2d3a49")}
	var base=colors.get(tile.get("biome","Greenlands"),Color("#253b2c"))
	draw_rect(bounds,base)
	for x in range(0,int(bounds.size.x),64):
		draw_line(Vector2(x,0),Vector2(x,bounds.size.y),base.lightened(0.04),1)
	for y in range(0,int(bounds.size.y),64):
		draw_line(Vector2(0,y),Vector2(bounds.size.x,y),base.lightened(0.04),1)
	for i in 16:
		var hx=abs(hash("%s:%s"%[tile.get("seed",1),i]))%int(bounds.size.x)
		var hy=abs(hash("%s:Y:%s"%[tile.get("seed",1),i]))%int(bounds.size.y)
		draw_circle(Vector2(hx,hy),8+(i%4)*3,Color(base.lightened(0.08),0.55))

func _resource_color(type:String)->Color:
	return {"wood":Color("#9b7a4f"),"stone":Color("#9ba2aa"),"iron":Color("#7793a7"),"food":Color("#d4ad58"),"mana":Color("#8a79d6"),"gold":Color("#e2bf66")}.get(type,Color.WHITE)

func _draw_resource_node(node:Dictionary)->void:
	var p:Vector2=node.pos
	var c=_resource_color(String(node.type))
	var pulse=sin(float(node.pulse))*1.5
	draw_circle(p,20.0+pulse,Color(c,0.10),false,3.0)
	match String(node.type):
		"wood":
			draw_line(p+Vector2(-12,9),p+Vector2(11,-9),c,7)
			draw_line(p+Vector2(-8,-8),p+Vector2(12,8),c.darkened(0.15),5)
			draw_circle(p+Vector2(10,-9),5,Color("#547449"))
		"stone":
			draw_colored_polygon(PackedVector2Array([p+Vector2(-15,9),p+Vector2(-10,-8),p+Vector2(2,-15),p+Vector2(15,-4),p+Vector2(12,12),p+Vector2(-3,16)]),c)
			draw_line(p+Vector2(-5,-7),p+Vector2(8,6),c.lightened(0.2),2)
		"iron":
			draw_colored_polygon(PackedVector2Array([p+Vector2(-14,10),p+Vector2(-9,-10),p+Vector2(5,-15),p+Vector2(15,-2),p+Vector2(9,14),p+Vector2(-6,15)]),c.darkened(0.15))
			draw_circle(p+Vector2(2,-2),6,c.lightened(0.25))
			draw_circle(p+Vector2(-7,7),4,c.lightened(0.1))
		"food":
			draw_line(p+Vector2(-9,14),p+Vector2(-4,-13),c,3)
			draw_line(p+Vector2(0,14),p+Vector2(2,-15),c,3)
			draw_line(p+Vector2(9,14),p+Vector2(8,-10),c,3)
			draw_circle(p+Vector2(-4,-12),4,c.lightened(0.18))
			draw_circle(p+Vector2(3,-14),4,c.lightened(0.18))
			draw_circle(p+Vector2(8,-9),4,c.lightened(0.18))
		"mana":
			draw_colored_polygon(PackedVector2Array([p+Vector2(0,-18),p+Vector2(11,-3),p+Vector2(5,16),p+Vector2(-7,14),p+Vector2(-12,-2)]),c)
			draw_colored_polygon(PackedVector2Array([p+Vector2(0,-12),p+Vector2(5,-2),p+Vector2(1,10),p+Vector2(-4,-1)]),c.lightened(0.25))
		_:
			draw_circle(p,12,c)
			draw_circle(p,7,c.lightened(0.22))
	if float(node.progress)>0.0:
		var ratio=clamp(float(node.progress)/1.15,0.0,1.0)
		draw_rect(Rect2(p+Vector2(-20,24),Vector2(40,5)),Color("#17202c"))
		draw_rect(Rect2(p+Vector2(-20,24),Vector2(40*ratio,5)),c.lightened(0.2))

func _draw_player() -> void:
	var p=player_pos
	draw_circle(p+Vector2(0,7),18,Color(0,0,0,0.3))
	draw_colored_polygon(PackedVector2Array([p+Vector2(-13,16),p+Vector2(13,16),p+Vector2(8,-10),p+Vector2(0,-20),p+Vector2(-8,-10)]),Color("#c8d5ea"))
	draw_circle(p+Vector2(0,-15),8,Color("#dcc8c1"))
	draw_line(p+Vector2(10,-3),p+Vector2(22,-17),Color("#edf4ff"),4)
	draw_circle(p,23,Color(0.45,0.68,1.0,0.07),false,2)
	if combo>=10:
		draw_arc(p,27,0,TAU,28,Color("#f0d77a"),2)

func _draw_ally(a: Dictionary) -> void:
	var c={"militia":Color("#9ca6bb"),"archer":Color("#7cad80"),"wolf":Color("#9b8368"),"mage":Color("#917ec2")}.get(a.type,Color.WHITE)
	draw_circle(a.pos,8,c)
	if a.type=="archer":
		draw_line(a.pos+Vector2(-6,-6),a.pos+Vector2(7,6),Color("#d3bd91"),2)
	elif a.type=="wolf":
		draw_colored_polygon(PackedVector2Array([a.pos+Vector2(-10,5),a.pos+Vector2(0,-8),a.pos+Vector2(11,5)]),c)
	elif a.type=="mage":
		draw_circle(a.pos,12,Color(c,0.16),false,2)
	else:
		draw_line(a.pos+Vector2(4,0),a.pos+Vector2(10,-8),Color("#dbe3ee"),2)

func _draw_enemy(e: Dictionary) -> void:
	var c={"raider":Color("#b46058"),"slime":Color("#73a86d"),"wolf":Color("#84645b"),"wisp":Color("#806eb7"),"boss":Color("#b14761")}.get(e.type,Color("#bb6666"))
	if e.flash>0:
		c=Color.WHITE
	if e.type=="slime":
		draw_circle(e.pos,e.radius,c)
		draw_rect(Rect2(e.pos+Vector2(-e.radius,e.radius-5),Vector2(e.radius*2,7)),c)
	elif e.type=="wolf":
		draw_colored_polygon(PackedVector2Array([e.pos+Vector2(-e.radius,8),e.pos+Vector2(0,-e.radius),e.pos+Vector2(e.radius,8)]),c)
	elif e.type=="wisp":
		draw_circle(e.pos,e.radius,c)
		draw_circle(e.pos,e.radius+7,Color(c,0.18),false,3)
	else:
		draw_circle(e.pos,e.radius,c)
		draw_colored_polygon(PackedVector2Array([e.pos+Vector2(-e.radius*.6,-e.radius*.7),e.pos+Vector2(0,-e.radius*1.35),e.pos+Vector2(e.radius*.6,-e.radius*.7)]),c.darkened(0.2))
	if e.boss:
		draw_arc(e.pos,e.radius+10,0,TAU,30,Color("#f3c65d"),3)
	var ratio=max(0.0,float(e.hp)/float(e.max_hp))
	if e.boss or e.hp<e.max_hp:
		draw_rect(Rect2(e.pos+Vector2(-e.radius,-e.radius-12),Vector2(e.radius*2,4)),Color("#351c25"))
		draw_rect(Rect2(e.pos+Vector2(-e.radius,-e.radius-12),Vector2(e.radius*2*ratio,4)),Color("#df6b74"))
