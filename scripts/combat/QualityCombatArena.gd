class_name QualityCombatArena
extends VisualCombatArena

const FIELD_WATCHTOWER_WOOD_COST := 6.0
const FIELD_WATCHTOWER_RANGE := 390.0
const FIELD_WATCHTOWER_COOLDOWN := 0.72
const FIELD_WATCHTOWER_LIMIT := 12

var field_towers:Array = []

func begin(data:Dictionary) -> void:
	UnitRoster.ensure_schema()
	field_towers.clear()
	super.begin(data)

func _process(delta:float) -> void:
	super._process(delta)
	if ended or paused_for_upgrade:
		return
	if Input.is_action_just_pressed("build_outpost"):
		_try_build_field_watchtower()
	_update_field_towers(delta)
	queue_redraw()

func _try_build_field_watchtower() -> void:
	if field_towers.size() >= FIELD_WATCHTOWER_LIMIT:
		_float_text(player_pos+Vector2(0,-52),"FIELD LIMIT REACHED",Color("#d4b28d"),0.9)
		return
	if float(loot.get("wood",0.0)) < FIELD_WATCHTOWER_WOOD_COST:
		_float_text(player_pos+Vector2(0,-52),"NEED 6 HARVESTED WOOD",Color("#d7a48b"),0.9)
		return
	var snapped := Vector2(
		round(player_pos.x/float(LOCAL_TILE_PX))*LOCAL_TILE_PX,
		round(player_pos.y/float(LOCAL_TILE_PX))*LOCAL_TILE_PX
	)
	for tower in field_towers:
		if Vector2(tower.get("pos",Vector2.ZERO)).distance_to(snapped) < 78.0:
			_float_text(player_pos+Vector2(0,-52),"TOO CLOSE TO ANOTHER TOWER",Color("#d7a48b"),0.9)
			return
	for building in local_structures:
		if Vector2(building.get("pos",Vector2.ZERO)).distance_to(snapped) < 110.0:
			_float_text(player_pos+Vector2(0,-52),"BUILD SPACE BLOCKED",Color("#d7a48b"),0.9)
			return
	loot["wood"] = float(loot.get("wood",0.0)) - FIELD_WATCHTOWER_WOOD_COST
	field_towers.append({"pos":snapped,"cooldown":0.18,"level":1})
	_spawn_ring(snapped,Color("#e1c278"))
	_float_text(snapped+Vector2(0,-56),"FIELD WATCHTOWER BUILT",Color("#f0d68d"),1.0)
	_shake(0.08,2.2)

func _update_field_towers(delta:float) -> void:
	if field_towers.is_empty():
		return
	for i in field_towers.size():
		var tower:Dictionary = field_towers[i]
		tower["cooldown"] = max(0.0,float(tower.get("cooldown",0.0))-delta)
		if float(tower.cooldown) <= 0.0 and not enemies.is_empty():
			var target := nearest_enemy(Vector2(tower.pos))
			if not target.is_empty() and Vector2(tower.pos).distance_to(Vector2(target.pos)) <= FIELD_WATCHTOWER_RANGE:
				var tower_damage := 9.0 + float(GameState.player.level)*0.55 + float(tile.get("threat",1))*0.9
				_damage_enemy(target,tower_damage,false)
				particles.append({"pos":Vector2(target.pos),"life":0.20,"max":0.20,"color":Color("#e5c578")})
				tower["cooldown"] = FIELD_WATCHTOWER_COOLDOWN
		field_towers[i] = tower

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

func _draw_ground() -> void:
	super._draw_ground()
	for tower in field_towers:
		var p:Vector2=Vector2(tower.get("pos",Vector2.ZERO))
		if _visible_world_rect(140.0).has_point(p):
			_draw_atlas("building_watchtower",p,Vector2(78,72),true)
			draw_circle(p+Vector2(0,18),30,Color(0.85,0.73,0.38,0.10),false,2.0)
