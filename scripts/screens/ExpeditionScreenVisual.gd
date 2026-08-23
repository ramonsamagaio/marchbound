extends "res://scripts/screens/ExpeditionScreen.gd"

const LAYOUT_SCENE := preload("res://scenes/ui/ExpeditionLayout.tscn")
const RESULT_SCENE := preload("res://scenes/ui/ExpeditionResult.tscn")

var layout_scene:Control
var gambit_overlay:PanelContainer

func _build() -> void:
	layout_scene = LAYOUT_SCENE.instantiate()
	add_child(layout_scene)

	var holder:Control = layout_scene.get_node("Margin/MainRow/ArenaPanel/ArenaHolder")
	arena = PursuitCombatArena.new()
	holder.add_child(arena)
	arena.set_view_size(Vector2(1400,840))
	arena.hud_changed.connect(_hud)
	arena.upgrade_requested.connect(_show_upgrade)
	arena.finished.connect(_finished)
	arena.gambit_requested.connect(_show_gambit)

	var hud:VBoxContainer = layout_scene.get_node("Margin/MainRow/SidePanel/SideMargin/Scroll/HUD")
	var biome_title:Label = hud.get_node("BiomeTitle")
	var territory_label:Label = hud.get_node("TerritoryLabel")
	var boss_label:Label = hud.get_node("BossLabel")
	var mutation_label:Label = hud.get_node("MutationLabel")
	var bond_label:Label = hud.get_node("BondLabel")
	var objective_title:Label = hud.get_node("ObjectiveTitle")
	var objective_description:Label = hud.get_node("ObjectiveDescription")

	biome_title.text = String(tile.get("biome","Frontier"))
	territory_label.text = "Territory [%d,%d] · Threat %d%s" % [int(tile.get("x",0)),int(tile.get("y",0)),int(tile.get("threat",1))," · BOSS TERRITORY" if bool(tile.get("boss",false)) else ""]
	boss_label.text = ""
	if bool(tile.get("boss",false)):
		boss_label.text = "★ %s\n%s" % [String(tile.get("boss_name","Regional Boss")),String(tile.get("boss_tell","Expect an unusual boss pattern."))]
	var mutations:Array = tile.get("mutations",[])
	mutation_label.text = ""
	if not mutations.is_empty():
		mutation_label.text = "✦ " + FrontierMutations.names(mutations)
	var local_bond:String = MonsterRoster.id_for_biome(String(tile.get("biome","Greenlands")))
	bond_label.text = ""
	if local_bond != "" and not GameState.monster_unlocked(local_bond):
		bond_label.text = "♢ WILD BOND · %s\nVictory can form the bond. Named regional bosses guarantee it." % MonsterRoster.display_name(local_bond)
	var n:Dictionary = RetentionManager.nemesis_data()
	if bool(n.get("active",false)) and RetentionManager.nemesis_can_invade(String(tile.get("biome","Greenlands"))):
		boss_label.text += ("\n" if boss_label.text != "" else "") + "☠ NEMESIS HUNTING · %s · Rank %d"%[String(n.get("name","Unknown")),int(n.get("rank",1))]
	objective_title.text = "OBJECTIVE · %s" % String(tile.get("objective","Frontier Claim")).to_upper()
	objective_description.text = _objective_description(String(tile.get("objective","Frontier Claim")))
	objective_label = hud.get_node("ObjectiveProgress")
	hp_bar = hud.get_node("HP")
	status = hud.get_node("Status")
	cooldowns = hud.get_node("Cooldowns")
	var map_scale:Label = hud.get_node("MapScale")
	var chain:int = RetentionManager.chain_count()
	var chain_text:String = " · March Chain ×%d (+%d%% next-loot)"%[chain,int(round((RetentionManager.chain_reward_mult()-1.0)*100.0))] if chain > 0 else ""
	map_scale.text = "%d × %d local tiles · %d Warden capacity%s\nC cycles field construction · B builds · Gambits may interrupt the march." % [VisualCombatArena.LOCAL_MAP_TILES,VisualCombatArena.LOCAL_MAP_TILES,int(tile.get("local_player_capacity",3)),chain_text]
	var retreat:Button = hud.get_node("Retreat")
	retreat.pressed.connect(func():GameState.screen_requested.emit("world"))

func _show_gambit(options:Array) -> void:
	if gambit_overlay:
		return
	gambit_overlay = PanelContainer.new()
	gambit_overlay.set_anchors_preset(Control.PRESET_CENTER)
	gambit_overlay.position = Vector2(-410,-265)
	gambit_overlay.size = Vector2(820,530)
	gambit_overlay.add_theme_stylebox_override("panel",UIFactory.panel(Color("#17131f"),16,Color("#8c5f77")))
	add_child(gambit_overlay)
	var margin:=MarginContainer.new()
	margin.add_theme_constant_override("margin_left",26)
	margin.add_theme_constant_override("margin_right",26)
	margin.add_theme_constant_override("margin_top",22)
	margin.add_theme_constant_override("margin_bottom",22)
	gambit_overlay.add_child(margin)
	var column:=VBoxContainer.new()
	column.add_theme_constant_override("separation",12)
	margin.add_child(column)
	var title:=UIFactory.title("THE FRONTIER OFFERS A TERRIBLE IDEA",28)
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var intro:=UIFactory.label("Take power now and let the expedition become stranger. Gambits stack with your build, mutations and March Chain.",13,Color("#b9a9c2"))
	intro.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	intro.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(intro)
	for raw_id:Variant in options:
		var id:String=String(raw_id)
		var d:Dictionary=ContentDB.gambit(id)
		var text:String="%s\n[color=#b6d6a8]%s[/color]\n[color=#e1a0a8]%s[/color]\nVictory bounty +%d Gold"%[String(d.get("name",id)),String(d.get("boon","Power")),String(d.get("curse","Price")),int(d.get("victory_bounty",0))]
		var button:=Button.new()
		button.text=text.replace("[color=#b6d6a8]","").replace("[/color]","").replace("[color=#e1a0a8]","")
		button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size.y=105
		button.pressed.connect(func(choice=id):_choose_gambit(choice))
		column.add_child(button)

func _choose_gambit(id:String) -> void:
	if arena is RetentionCombatArena:
		arena.choose_gambit(id)
	if gambit_overlay:
		gambit_overlay.queue_free()
		gambit_overlay=null

func _show_upgrade() -> void:
	if upgrade_overlay:
		return
	upgrade_overlay=PanelContainer.new()
	upgrade_overlay.set_anchors_preset(Control.PRESET_CENTER)
	upgrade_overlay.position=Vector2(-380,-240)
	upgrade_overlay.size=Vector2(760,480)
	upgrade_overlay.add_theme_stylebox_override("panel",UIFactory.panel(Color("#111827"),14,Color("#8b7449")))
	add_child(upgrade_overlay)
	var margin=MarginContainer.new()
	margin.add_theme_constant_override("margin_left",24)
	margin.add_theme_constant_override("margin_right",24)
	margin.add_theme_constant_override("margin_top",20)
	margin.add_theme_constant_override("margin_bottom",20)
	upgrade_overlay.add_child(margin)
	var v=VBoxContainer.new()
	v.add_theme_constant_override("separation",12)
	margin.add_child(v)
	var t=UIFactory.title("Choose a Field Doctrine",28)
	t.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var sub=UIFactory.label("Stack synergies during the run. Build the Warden, army, mobility, sustain or an aggressively unreasonable hybrid.",13,Color("#a6b2cc"))
	sub.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	v.add_child(sub)
	var choices=upgrade_defs.keys()
	choices.shuffle()
	for i in 3:
		var id=choices[i]
		var b=UIFactory.button("%s\n%s"%[upgrade_defs[id][0],upgrade_defs[id][1]],func(x=id):_choose_upgrade(x),Color("#303b59"))
		b.custom_minimum_size.y=88
		v.add_child(b)

func _finished(result:Dictionary) -> void:
	RetentionManager.prepare_expedition_result(result,tile)
	GameState.expedition_completed(result)
	SaveManager.save_game()
	result_overlay = RESULT_SCENE.instantiate()
	add_child(result_overlay)
	var title:Label = result_overlay.get_node("Margin/Column/Title")
	var subtitle:Label = result_overlay.get_node("Margin/Column/Subtitle")
	var summary:Label = result_overlay.get_node("Margin/Column/Scroll/Body/Summary")
	var special:Label = result_overlay.get_node("Margin/Column/Scroll/Body/Special")
	var loot:RichTextLabel = result_overlay.get_node("Margin/Column/Scroll/Body/Loot")
	var next:Button = result_overlay.get_node("Margin/Column/Continue")

	title.text = "VICTORY · TERRITORY CLAIMED" if result.get("territory_claimed",false) else ("VICTORY · FRONTIER SECURED" if result.get("victory",false) else "EXPEDITION BROKEN")
	subtitle.text = "%s · Threat %d" % [String(result.get("objective","Expedition")),int(result.get("threat",1))]
	var lines:Array[String] = []
	lines.append("%d kills · %d elites · %d XP · Harvested %d/%d" % [int(result.get("kills",0)),int(result.get("elite_kills",0)),int(result.get("xp",0)),int(result.get("nodes_collected",0)),int(result.get("nodes_total",0))])
	lines.append("Best Momentum ×%d" % int(result.get("best_combo",0)))
	if bool(result.get("victory",false)):
		lines.append("March Chain ×%d · %d Gold now at risk until you return to Dawnkeep"%[int(result.get("march_chain",0)),int(result.get("march_chain_bounty",0))])
		var mult:float=float(result.get("march_chain_mult",1.0))
		if mult>1.0: lines.append("Chain reward multiplier this expedition: +%d%%"%int(round((mult-1.0)*100.0)))
	elif int(result.get("march_chain_lost",0))>0:
		lines.append("March Chain broken · lost ×%d streak and %d unbanked bounty"%[int(result.get("march_chain_lost",0)),int(result.get("march_chain_bounty_lost",0))])
	var memory_rank:int=RetentionManager.equipped_weapon_memory_rank()
	if memory_rank>0:
		lines.append("Equipped weapon Memory %d · %d remembered combat XP"%[memory_rank,RetentionManager.equipped_weapon_memory_xp()])
	var mutations:Array=result.get("mutations",tile.get("mutations",[]))
	if not mutations.is_empty():
		lines.append("Frontier Mutations: %s" % FrontierMutations.names(mutations))
	if bool(tile.get("boss",false)):
		lines.append("Regional Boss: %s" % String(result.get("boss_name",tile.get("boss_name","Unknown"))))
	if result.get("territory_claimed",false):
		lines.append("New adjacent territories are now reachable from this claim.")
	summary.text = "\n".join(lines)

	var specials:Array[String]=[]
	if bool(result.get("wild_bond_unlocked",false)):
		var bond_id:String=String(result.get("wild_bond",""))
		specials.append("WILD BOND FORMED · %s\n%s · now recruitable and trainable from Warband."%[MonsterRoster.display_name(bond_id),MonsterRoster.role(bond_id)])
	var nemesis:Dictionary=RetentionManager.nemesis_data()
	if bool(nemesis.get("active",false)):
		specials.append("NEMESIS ACTIVE · %s · Rank %d · %s"%[String(nemesis.get("name","Unknown")),int(nemesis.get("rank",1)),String(nemesis.get("trait","relentless")).capitalize()])
	special.text="\n\n".join(specials)

	var loot_lines:Array[String] = []
	for key in GameState.RESOURCE_ORDER:
		var amount=float(result.get("loot",{}).get(key,0.0))
		if amount>0.0:
			loot_lines.append("[color=#e7dec4]%s[/color]  +%d" % [key.capitalize(),int(amount)])
	var item:Dictionary=result.get("item",{})
	if not item.is_empty():
		loot_lines.append("\n[color=#9fc6f1][b]GEAR DROP · %s · %s[/b][/color]" % [String(item.get("name","Unknown")),String(item.get("rarity","common")).to_upper()])
		if item.has("weapon_class"):
			loot_lines.append("[color=#9ab2d4]%s · %s · Knockback %.1f[/color]"%[String(item.get("weapon_class","weapon")).capitalize(),String(item.get("attack_id","attack")).replace("_"," ").capitalize(),float(item.get("knockback",0.0))])
		for affix in item.get("affixes",[]):
			loot_lines.append("[color=#b9c9ed]◆ %s[/color]" % String(affix.get("text","")))
	loot.text="\n".join(loot_lines)

	var return_screen="world" if bool(result.get("victory",false)) else "city"
	next.text="KEEP THE CHAIN · RETURN TO WORLD MAP" if bool(result.get("victory",false)) else "RETURN TO DAWNKEEP"
	next.pressed.connect(func():GameState.screen_requested.emit(return_screen))
