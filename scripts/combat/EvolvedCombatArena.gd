class_name EvolvedCombatArena
extends CombatArena

var family_damage_reduction := 0.0

func begin(data:Dictionary) -> void:
	UnitProgression.ensure_schema()
	super.begin(data)
	if UnitProgression.evolution("wolf") == "pack_alpha" and int(GameState.army.get("wolf",0)) > 0:
		army_damage_mult *= 1.12
	_apply_family_sets()

func _apply_family_sets() -> void:
	var counts = LootFamilies.equipped_counts()
	var dawnward = int(counts.get("dawnward",0))
	if dawnward >= 2:
		army_damage_mult *= 1.08
	if dawnward >= 4:
		army_haste_mult *= 0.90

	var briarbound = int(counts.get("briarbound",0))
	if briarbound >= 2:
		for node in resource_nodes:
			node.value = int(round(float(node.value)*1.10))
	if briarbound >= 4:
		player_speed *= 1.08

	var deepforge = int(counts.get("deepforge",0))
	if deepforge >= 2:
		var old_hp = player_hp_max
		player_hp_max *= 1.12
		player_hp += player_hp_max-old_hp
	if deepforge >= 4:
		family_damage_reduction = 0.10

	var mireglass = int(counts.get("mireglass",0))
	if mireglass >= 2:
		lifesteal += 0.02
	if mireglass >= 4:
		lifesteal += 0.03

	var cinderborn = int(counts.get("cinderborn",0))
	if cinderborn >= 2:
		crit_chance += 0.05
	if cinderborn >= 4:
		damage *= 1.12

	var rimebound = int(counts.get("rimebound",0))
	if rimebound >= 2:
		dash_cooldown_max *= 0.88
	if rimebound >= 4:
		player_speed *= 1.08

func _damage_player(amount:float) -> void:
	var final_amount = amount
	if UnitProgression.evolution("militia") == "shieldwall" and int(GameState.army.get("militia",0)) > 0:
		final_amount *= 0.85
	if int(GameState.army.get("thornkin",0)) > 0:
		final_amount *= 0.95
	if family_damage_reduction > 0.0:
		final_amount *= 1.0-family_damage_reduction
	super._damage_player(final_amount)

func unit_damage(type:String) -> float:
	if MonsterRoster.has(type):
		return MonsterRoster.damage(type) * float(GameState.unit_levels.get(type,1))
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
	if MonsterRoster.has(type):
		return MonsterRoster.cooldown(type)
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
	if MonsterRoster.has(type):
		return MonsterRoster.attack_range(type)
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
		var ally_type:String = String(ally.type)
		var angle = elapsed*0.45 + index*TAU/max(1,allies.size())
		var desired = player_pos + Vector2(cos(angle),sin(angle))*(55+(index%3)*16)
		ally.pos = ally.pos.lerp(desired,min(1.0,delta*4.0))
		ally.cooldown -= delta
		if ally.cooldown <= 0 and enemies.size() > 0:
			var target = nearest_enemy(ally.pos)
			if not target.is_empty() and ally.pos.distance_to(target.pos) < _unit_range(ally_type):
				var rally_mult = 1.45 if rally_time > 0 else 1.0
				var momentum = 1.0+min(combo,30)*0.008
				var hit = unit_damage(ally_type) * army_damage_mult * rally_mult * momentum
				var branch = UnitProgression.evolution(ally_type)
				if ally_type == "militia" and branch == "vanguard" and bool(target.get("boss",false)):
					hit *= 1.55
				if ally_type == "wolf" and branch == "dire" and float(target.hp) / max(1.0,float(target.max_hp)) < 0.45:
					hit *= 1.50
				if ally_type == "ridgeback" and float(target.hp) / max(1.0,float(target.max_hp)) < 0.45:
					hit *= 1.30
				if ally_type == "stone_golem" and bool(target.get("boss",false)):
					hit *= 1.25
				_damage_enemy(target,hit,false)
				if ally_type == "mage":
					if branch == "stormcaller":
						_storm_chain(target,hit)
					elif branch == "lifebinder":
						var heal = 2.2 + float(GameState.unit_levels.get("mage",1))*0.38
						player_hp = min(player_hp_max,player_hp+heal)
				elif ally_type == "mire_leech":
					var leech_heal:float = 1.5 + float(GameState.unit_levels.get(ally_type,1))*0.30
					player_hp = min(player_hp_max,player_hp+leech_heal)
				elif ally_type == "ember_imp":
					_wild_splash(target,hit*0.30)
				ally.cooldown = unit_cooldown(ally_type) * army_haste_mult
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

func _wild_splash(origin:Dictionary,amount:float) -> void:
	for enemy in enemies:
		if enemy == origin:
			continue
		if origin.pos.distance_to(enemy.pos) <= 95.0:
			_damage_enemy(enemy,amount,false)
			_spawn_ring(enemy.pos,Color("#f0a166"))
			break

func _draw_ally(a:Dictionary) -> void:
	var id:String = String(a.get("type",""))
	if not MonsterRoster.has(id):
		super._draw_ally(a)
		return
	var colors:Dictionary = {
		"ridgeback":Color("#b58a66"),
		"thornkin":Color("#739264"),
		"stone_golem":Color("#9ba0a4"),
		"mire_leech":Color("#9c6474"),
		"ember_imp":Color("#dc7652"),
		"frost_wisp":Color("#93c7dc")
	}
	var c:Color = Color(colors.get(id,Color.WHITE))
	match id:
		"ridgeback":
			draw_colored_polygon(PackedVector2Array([a.pos+Vector2(-11,6),a.pos+Vector2(0,-9),a.pos+Vector2(12,6)]),c)
			draw_line(a.pos+Vector2(7,-4),a.pos+Vector2(12,-10),c.lightened(0.25),2)
		"thornkin":
			draw_rect(Rect2(a.pos-Vector2(8,8),Vector2(16,16)),c)
			draw_line(a.pos,a.pos+Vector2(0,-15),c.lightened(0.25),3)
		"stone_golem":
			draw_rect(Rect2(a.pos-Vector2(10,10),Vector2(20,20)),c)
			draw_circle(a.pos,3,c.lightened(0.3))
		"mire_leech":
			draw_colored_polygon(PackedVector2Array([a.pos+Vector2(-12,4),a.pos+Vector2(-5,-7),a.pos+Vector2(7,-6),a.pos+Vector2(12,5),a.pos+Vector2(0,9)]),c)
		"ember_imp":
			draw_circle(a.pos,8,c)
			draw_circle(a.pos,13,Color(c,0.18),false,2)
		"frost_wisp":
			draw_circle(a.pos,7,c)
			draw_circle(a.pos,14,Color(c,0.16),false,2)
			draw_line(a.pos+Vector2(-6,0),a.pos+Vector2(6,0),c.lightened(0.35),1)

func generate_loot_item(threat:int) -> Dictionary:
	var item = super.generate_loot_item(threat)
	item = LootFamilies.decorate_item(item,String(tile.get("biome","Greenlands")))
	item["origin_biome"] = String(tile.get("biome","Greenlands"))
	if bool(tile.get("boss",false)):
		item["origin_boss"] = boss_name
		if String(item.get("rarity","common")) in ["epic","legendary"]:
			item["name"] = "%s's %s"%[boss_name,String(item.name)]
	return item
