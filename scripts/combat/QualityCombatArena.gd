class_name QualityCombatArena
extends VisualCombatArena

func begin(data:Dictionary) -> void:
	UnitRoster.ensure_schema()
	super.begin(data)

func _spawn_allies() -> void:
	allies.clear()
	UnitRoster.ensure_schema()
	var offsets=[Vector2(-45,20),Vector2(45,20),Vector2(-70,55),Vector2(70,55),Vector2(0,65),Vector2(-95,75),Vector2(95,75)]
	var idx:=0
	for record in UnitRoster.battle_instances(3):
		var family:String=String(record.get("family","militia"))
		allies.append({
			"type":family,
			"pos":player_pos+offsets[idx%offsets.size()],
			"cooldown":rng.randf_range(0.0,1.0),
			"uid":String(record.get("uid","")),
			"prefix":String(record.get("prefix","")),
			"elite":bool(record.get("elite",false))
		})
		idx+=1

func _update_allies(delta:float) -> void:
	var index:=0
	for ally in allies:
		var ally_type:String=String(ally.type)
		var angle=elapsed*0.45+index*TAU/max(1,allies.size())
		var desired=player_pos+Vector2(cos(angle),sin(angle))*(68+(index%3)*20)
		ally.pos=ally.pos.lerp(desired,min(1.0,delta*4.0))
		ally.cooldown-=delta
		if ally.cooldown<=0 and not enemies.is_empty():
			var target=nearest_enemy(ally.pos)
			var record={"family":ally_type,"prefix":String(ally.get("prefix","")),"elite":bool(ally.get("elite",false))}
			var effective_range=_unit_range(ally_type)*UnitRoster.range_mult(record)
			if not target.is_empty() and ally.pos.distance_to(target.pos)<effective_range:
				var rally_mult=1.45 if rally_time>0 else 1.0
				var momentum=1.0+min(combo,30)*0.008
				var hit=unit_damage(ally_type)*army_damage_mult*rally_mult*momentum*UnitRoster.damage_mult(record)
				var branch=UnitProgression.evolution(ally_type)
				if ally_type=="militia" and branch=="vanguard" and bool(target.get("boss",false)):hit*=1.55
				if ally_type=="wolf" and branch=="dire" and float(target.hp)/max(1.0,float(target.max_hp))<0.45:hit*=1.50
				if ally_type=="ridgeback" and float(target.hp)/max(1.0,float(target.max_hp))<0.45:hit*=1.30
				if ally_type=="stone_golem" and bool(target.get("boss",false)):hit*=1.25
				hit*=UnitRoster.execute_mult(record,float(target.hp)/max(1.0,float(target.max_hp)))
				_damage_enemy(target,hit,false)
				var quality_heal=UnitRoster.heal_on_hit(record)
				if quality_heal>0.0:player_hp=min(player_hp_max,player_hp+quality_heal)
				var chain=UnitRoster.chain_ratio(record)
				if chain>0.0:_quality_chain(target,hit*chain)
				if ally_type=="mage":
					if branch=="stormcaller":_storm_chain(target,hit)
					elif branch=="lifebinder":player_hp=min(player_hp_max,player_hp+2.2+float(GameState.unit_levels.get("mage",1))*0.38)
				elif ally_type=="mire_leech":
					player_hp=min(player_hp_max,player_hp+1.5+float(GameState.unit_levels.get(ally_type,1))*0.30)
				elif ally_type=="ember_imp":
					_wild_splash(target,hit*0.30)
				ally.cooldown=unit_cooldown(ally_type)*army_haste_mult*UnitRoster.cooldown_mult(record)
		index+=1

func _quality_chain(origin:Dictionary,amount:float)->void:
	for enemy in enemies:
		if enemy==origin:continue
		if origin.pos.distance_to(enemy.pos)<=125.0:
			_damage_enemy(enemy,amount,false)
			_spawn_ring(enemy.pos,Color("#8ebdff"))
			break
