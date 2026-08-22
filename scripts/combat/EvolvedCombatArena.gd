class_name EvolvedCombatArena
extends CombatArena

func begin(data:Dictionary) -> void:
	UnitProgression.ensure_schema()
	super.begin(data)
	if UnitProgression.evolution("wolf") == "pack_alpha" and int(GameState.army.get("wolf",0)) > 0:
		army_damage_mult *= 1.12

func _damage_player(amount:float) -> void:
	var final_amount = amount
	if UnitProgression.evolution("militia") == "shieldwall" and int(GameState.army.get("militia",0)) > 0:
		final_amount *= 0.85
	super._damage_player(final_amount)

func unit_damage(type:String) -> float:
	var value = super.unit_damage(type)
	var branch = UnitProgression.evolution(type)
	match type:
		"militia":
			if branch == "vanguard": value *= 1.35
			elif branch == "shieldwall": value *= 1.10
		"archer":
			if branch == "ranger": value *= 0.95
			elif branch == "longbow": value *= 1.65
		"wolf":
			if branch == "dire": value *= 1.45
			elif branch == "pack_alpha": value *= 1.15
		"mage":
			if branch == "stormcaller": value *= 1.20
			elif branch == "lifebinder": value *= 0.90
	return value

func unit_cooldown(type:String) -> float:
	var value = super.unit_cooldown(type)
	var branch = UnitProgression.evolution(type)
	match type:
		"militia":
			if branch == "vanguard": value *= 0.90
		"archer":
			if branch == "ranger": value *= 0.62
			elif branch == "longbow": value *= 1.18
		"wolf":
			if branch == "dire": value *= 0.78
			elif branch == "pack_alpha": value *= 0.90
		"mage":
			if branch == "stormcaller": value *= 0.92
			elif branch == "lifebinder": value *= 0.82
	return value

func _unit_range(type:String) -> float:
	var branch = UnitProgression.evolution(type)
	if type == "archer":
		if branch == "ranger": return 300.0
		if branch == "longbow": return 345.0
		return 250.0
	if type == "mage": return 270.0
	if type == "wolf": return 205.0
	return 220.0

func _update_allies(delta:float) -> void:
	var index := 0
	for ally in allies:
		var angle = elapsed*0.45 + index*TAU/max(1,allies.size())
		var desired = player_pos + Vector2(cos(angle),sin(angle))*(55+(index%3)*16)
		ally.pos = ally.pos.lerp(desired,min(1.0,delta*4.0))
		ally.cooldown -= delta
		if ally.cooldown <= 0 and enemies.size() > 0:
			var target = nearest_enemy(ally.pos)
			if not target.is_empty() and ally.pos.distance_to(target.pos) < _unit_range(String(ally.type)):
				var rally_mult = 1.45 if rally_time > 0 else 1.0
				var momentum = 1.0+min(combo,30)*0.008
				var hit = unit_damage(String(ally.type)) * army_damage_mult * rally_mult * momentum
				var branch = UnitProgression.evolution(String(ally.type))
				if String(ally.type) == "militia" and branch == "vanguard" and bool(target.get("boss",false)):
					hit *= 1.55
				if String(ally.type) == "wolf" and branch == "dire" and float(target.hp) / max(1.0,float(target.max_hp)) < 0.45:
					hit *= 1.50
				_damage_enemy(target,hit,false)
				if String(ally.type) == "mage":
					if branch == "stormcaller":
						_storm_chain(target,hit)
					elif branch == "lifebinder":
						var heal = 2.2 + float(GameState.unit_levels.get("mage",1))*0.38
						player_hp = min(player_hp_max,player_hp+heal)
				ally.cooldown = unit_cooldown(String(ally.type)) * army_haste_mult
		index += 1

func _storm_chain(origin:Dictionary,primary_hit:float) -> void:
	var chained := 0
	for enemy in enemies:
		if enemy == origin:
			continue
		if origin.pos.distance_to(enemy.pos) <= 115.0:
			_damage_enemy(enemy,primary_hit*0.35,false)
			_spawn_ring(enemy.pos,Color("#8fd5ff"))
			chained += 1
			if chained >= 2:
				break
