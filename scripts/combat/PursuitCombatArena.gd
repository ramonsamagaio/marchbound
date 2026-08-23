class_name PursuitCombatArena
extends RetentionCombatArena

var pursuit_level:int = 0
var hunter_pack_spawned:bool = false

func begin(data:Dictionary) -> void:
	pursuit_level = RetentionManager.chain_count()
	hunter_pack_spawned = false
	super.begin(data)
	if pursuit_level > 0:
		_float_text(player_pos+Vector2(0,-72),"PURSUIT %d · THE FRONTIER IS WATCHING"%pursuit_level,Color("#e79a82"),1.4)

func _process(delta:float) -> void:
	super._process(delta)
	if ended or paused_for_upgrade:
		return
	if pursuit_level >= 3 and not hunter_pack_spawned and elapsed >= 7.5:
		_spawn_hunter_pack()

func _spawn_enemy(boss:bool) -> void:
	var before:int = enemies.size()
	super._spawn_enemy(boss)
	if enemies.size() <= before:
		return
	var enemy:Dictionary = enemies[enemies.size()-1]
	_apply_pursuit_scaling(enemy,boss)
	enemies[enemies.size()-1] = enemy

func _apply_pursuit_scaling(enemy:Dictionary,boss:bool) -> void:
	if pursuit_level <= 0 or bool(enemy.get("pursuit_scaled",false)):
		return
	var level:float = float(mini(pursuit_level,8))
	var hp_mult:float = 1.0 + level*0.045
	var damage_mult:float = 1.0 + level*0.035
	var speed_mult:float = 1.0 + level*0.018
	if boss:
		hp_mult = 1.0 + level*0.025
		damage_mult = 1.0 + level*0.025
		speed_mult = 1.0 + level*0.010
	enemy["hp"] = float(enemy.get("hp",1.0))*hp_mult
	enemy["max_hp"] = float(enemy["hp"])
	enemy["damage_mult"] = float(enemy.get("damage_mult",1.0))*damage_mult
	enemy["speed"] = float(enemy.get("speed",60.0))*speed_mult
	enemy["base_speed"] = float(enemy["speed"])
	enemy["pursuit_scaled"] = true
	if not boss and not bool(enemy.get("elite",false)):
		var elite_chance:float = minf(0.24,level*0.032)
		if rng.randf() < elite_chance:
			enemy["elite"] = true
			enemy["hp"] = float(enemy["hp"])*1.75
			enemy["max_hp"] = float(enemy["hp"])
			enemy["damage_mult"] = float(enemy["damage_mult"])*1.28
			enemy["radius"] = float(enemy.get("radius",14.0))*1.12

func _spawn_hunter_pack() -> void:
	hunter_pack_spawned = true
	var count:int = 2 + mini(4,pursuit_level-2)
	for i:int in range(count):
		_spawn_forced_elite()
	_float_text(player_pos+Vector2(0,-84),"HUNTER PACK · %d ELITES"%count,Color("#f0a17f"),1.3)
	_spawn_ring(player_pos,Color("#d76f5e"))
	_shake(0.18,6.0)
