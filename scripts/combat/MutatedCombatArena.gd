class_name MutatedCombatArena
extends EvolvedCombatArena

var mutation_ids:Array = []
var mutation_fx:Dictionary = {}

func begin(data:Dictionary) -> void:
	mutation_ids = data.get("mutations",[]).duplicate(true)
	mutation_fx = FrontierMutations.combined_effects(mutation_ids)
	super.begin(data)

func _spawn_resource_nodes() -> void:
	super._spawn_resource_nodes()
	if mutation_fx.is_empty():
		return
	var harvest_mult=float(mutation_fx.get("harvest",1.0))
	for node in resource_nodes:
		node.value=int(round(float(node.value)*harvest_mult))
	var bonus=int(mutation_fx.get("resource_nodes",0))
	if bonus<=0:
		return
	var choices=_resource_choices_for_biome(String(tile.get("biome","Greenlands")))
	var scavenger_mult=1.0+GameState.talent_rank("scavenger")*0.12+float(gear_bonuses.get("harvest",0.0))
	var richness=int(tile.get("richness",1))
	for i in bonus:
		var p=Vector2(rng.randf_range(80.0,bounds.size.x-80.0),rng.randf_range(70.0,bounds.size.y-70.0))
		if p.distance_to(player_pos)<120.0:
			p+=Vector2(145.0,0.0).rotated(float(i+3)*1.7)
		p.x=clamp(p.x,60.0,bounds.size.x-60.0)
		p.y=clamp(p.y,60.0,bounds.size.y-60.0)
		var type=String(choices[(resource_nodes.size()+i)%choices.size()])
		var base_value={"wood":8,"stone":7,"iron":4,"food":10,"mana":2,"gold":15}.get(type,6)
		resource_nodes.append({"pos":p,"type":type,"progress":0.0,"collected":false,"value":int(round(base_value*richness*scavenger_mult*harvest_mult)),"pulse":rng.randf_range(0.0,TAU)})

func _spawn_logic() -> void:
	var threat=int(tile.get("threat",1))
	if not boss_spawned and _objective_ready():
		_spawn_enemy(true)
		boss_spawned=true
		_spawn_ring(player_pos,Color("#e3b76e"))
		_float_text(player_pos+Vector2(0,-54),(boss_name if bool(tile.get("boss",false)) else "GUARDIAN")+" AWAKENED",Color("#f2c56f"),1.2)
		_shake(0.22,7.0)
	if spawn_timer<=0.0 and enemies.size()<150:
		var objective_pressure=1 if objective=="Monster Hunt" else 0
		var count=1+int(elapsed/22.0)+int(threat/4)+objective_pressure+int(mutation_fx.get("spawn_bonus",0))
		count=min(count,9)
		for i in count:
			_spawn_enemy(false)
		spawn_timer=max(0.34,1.25-elapsed*0.008-threat*0.035)

func _spawn_enemy(boss:bool) -> void:
	var before=enemies.size()
	super._spawn_enemy(boss)
	if enemies.size()<=before:
		return
	var e=enemies[enemies.size()-1]
	if not boss and not bool(e.get("elite",false)) and rng.randf()<float(mutation_fx.get("elite",0.0)):
		e.elite=true
		e.hp*=2.25
		e.max_hp=e.hp
		e.speed*=1.08
		e.radius*=1.2
		e.damage_mult=float(e.get("damage_mult",1.0))*1.45
	e.hp*=float(mutation_fx.get("enemy_hp",1.0))
	e.max_hp=e.hp
	e.speed*=float(mutation_fx.get("enemy_speed",1.0))
	e.damage_mult=float(e.get("damage_mult",1.0))*float(mutation_fx.get("enemy_damage",1.0))
	enemies[enemies.size()-1]=e

func _spawn_enemy_shot(pos:Vector2,dir:Vector2,shot_damage:float,elite:bool=false,color:Color=Color("#e89975"),speed_override:float=0.0) -> void:
	var before=enemy_projectiles.size()
	super._spawn_enemy_shot(pos,dir,shot_damage,elite,color,speed_override)
	if enemy_projectiles.size()>before:
		var p=enemy_projectiles[enemy_projectiles.size()-1]
		p.vel*=float(mutation_fx.get("projectile_speed",1.0))
		enemy_projectiles[enemy_projectiles.size()-1]=p

func _kill_enemy(e:Dictionary) -> void:
	var gold_before=float(loot.get("gold",0.0))
	var xp_before=xp
	super._kill_enemy(e)
	var gold_delta=float(loot.get("gold",0.0))-gold_before
	var xp_delta=xp-xp_before
	var gold_mult=float(mutation_fx.get("gold",1.0))
	var xp_mult=float(mutation_fx.get("xp",1.0))
	if gold_mult>1.0 and gold_delta>0.0:
		loot.gold+=gold_delta*(gold_mult-1.0)
	if xp_mult>1.0 and xp_delta>0:
		xp+=int(round(float(xp_delta)*(xp_mult-1.0)))

func _finish(victory:bool) -> void:
	if ended:
		return
	ended=true
	var threat=int(tile.get("threat",1))
	var gold_before=float(loot.get("gold",0.0))
	var objective_xp=_apply_objective_reward(victory)
	var objective_gold=float(loot.get("gold",0.0))-gold_before
	var gold_mult=float(mutation_fx.get("gold",1.0))
	if gold_mult>1.0 and objective_gold>0.0:
		loot.gold+=objective_gold*(gold_mult-1.0)
	if victory and int(mutation_fx.get("victory_mana",0))>0:
		loot.mana+=int(mutation_fx.get("victory_mana",0))+int(threat/3)
	var item={}
	var chance=0.18+threat*0.025+(0.35 if boss_killed else 0.0)+GameState.talent_rank("fortune")*0.03+float(gear_bonuses.get("fortune",0.0))+float(mutation_fx.get("rarity",0.0))
	if objective=="Ruin Siege" and victory:
		chance+=0.20
	if rng.randf()<chance:
		item=generate_loot_item(threat)
	var bonus_xp=objective_xp+(80*threat if victory else 0)
	bonus_xp=int(round(float(bonus_xp)*float(mutation_fx.get("xp",1.0))))
	finished.emit({"victory":victory,"kills":kills,"elite_kills":elite_kills,"xp":xp+bonus_xp,"loot":loot.duplicate(true),"threat":threat,"boss_killed":boss_killed,"boss_name":boss_name if bool(tile.get("boss",false)) else "Frontier Guardian","boss_archetype":boss_archetype,"item":item,"nodes_collected":nodes_collected,"nodes_total":resource_nodes.size(),"best_combo":best_combo,"objective":objective,"objective_progress":_objective_progress(),"objective_target":objective_target,"mutations":mutation_ids.duplicate(true)})
