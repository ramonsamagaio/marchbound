extends Control

var arena: CombatArena
var hp_bar: ProgressBar
var status: Label
var cooldowns: Label
var objective_label: Label
var upgrade_overlay: PanelContainer
var result_overlay: PanelContainer
var tile := {}
var upgrade_defs = {
	"damage":["Edge of War","+25% Warden damage"],
	"speed":["Windstep","+15% movement speed"],
	"haste":["Quickened Sigil","+18% attack speed"],
	"projectile":["Twin Oath","+1 projectile per attack"],
	"army":["Battle Doctrine","+30% army damage"],
	"vitality":["Ironblood","+25% max health and heal the increase"],
	"crit":["Executioner's Eye","+13% crit chance and stronger crits"],
	"vampire":["Blood Oath","Damage heals a small amount of HP"],
	"arc":["Stormbound","Hits can arc into two nearby enemies"],
	"shockwave":["Siegebreaker","Larger, harder Shockwave with faster recovery"],
	"war_drum":["War Drums","Army attacks much faster and gains damage"],
	"blink":["Marchstep","Shorter dash cooldown and bonus movement speed"]
}

func _ready() -> void:
	tile = GameState.world.selected_tile
	if tile.is_empty():
		GameState.screen_requested.emit("world")
		return
	_build()
	arena.begin(tile)

func _objective_description(name:String) -> String:
	return {"Frontier Claim":"Survive until the territory guardian is forced into the open.","Monster Hunt":"Kill aggressively. Enough kills force the local alpha to reveal itself.","Resource Sweep":"Harvest frontier sites while fighting. Enough extraction awakens the guardian.","Ruin Siege":"A named regional boss controls this ruin. Read its pattern and survive the early confrontation."}.get(name,"Secure the territory and defeat its guardian.")

func _active_evolutions_text() -> String:
	UnitProgression.ensure_schema()
	var names := []
	for unit in UnitProgression.UNIT_ORDER:
		if int(GameState.army.get(unit,0)) > 0 and UnitProgression.is_evolved(unit):
			names.append(UnitProgression.display_name(unit))
	return " · ".join(names)

func _build() -> void:
	var bg=ColorRect.new(); bg.color=Color("#0d111c"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	var layout=HBoxContainer.new(); layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); layout.add_theme_constant_override("separation",12); layout.offset_left=14; layout.offset_top=14; layout.offset_right=-14; layout.offset_bottom=-14; add_child(layout)
	var arena_panel=PanelContainer.new(); arena_panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL; arena_panel.size_flags_vertical=Control.SIZE_EXPAND_FILL; arena_panel.add_theme_stylebox_override("panel",UIFactory.panel(Color("#111724"),12,Color("#33405c"))); layout.add_child(arena_panel)
	var holder=Control.new(); holder.custom_minimum_size=Vector2(900,560); arena_panel.add_child(holder); arena=EvolvedCombatArena.new(); holder.add_child(arena); arena.hud_changed.connect(_hud); arena.upgrade_requested.connect(_show_upgrade); arena.finished.connect(_finished)
	var side=PanelContainer.new(); side.custom_minimum_size.x=310; side.add_theme_stylebox_override("panel",UIFactory.panel(Color("#151b2a"),12,Color("#35415d"))); layout.add_child(side)
	var hud=VBoxContainer.new(); side.add_child(hud)
	hud.add_child(UIFactory.title(tile.biome,22))
	hud.add_child(UIFactory.label("Territory [%d,%d] · Threat %d%s"%[tile.x,tile.y,tile.threat," · BOSS TERRITORY" if tile.boss else ""],13,Color("#e0b58d")))
	if bool(tile.get("boss",false)):
		hud.add_child(UIFactory.label("★ %s"%String(tile.get("boss_name","Regional Boss")),17,Color("#f0b7c0")))
		hud.add_child(UIFactory.label(String(tile.get("boss_tell","Expect an unusual boss pattern.")),11,Color("#c5a8bb")))
	hud.add_child(UIFactory.hsep())
	hud.add_child(UIFactory.label("OBJECTIVE · %s"%String(tile.get("objective","Frontier Claim")).to_upper(),14,Color("#f0dfae")))
	hud.add_child(UIFactory.label(_objective_description(String(tile.get("objective","Frontier Claim"))),12,Color("#a5b1cb")))
	objective_label=UIFactory.label("Preparing objective...",13,Color("#e0c684")); hud.add_child(objective_label)
	var evolved = _active_evolutions_text()
	if evolved != "":
		hud.add_child(UIFactory.label("EVOLVED WAR-BAND · %s"%evolved,11,Color("#a7d9c5")))
	hud.add_child(UIFactory.hsep())
	hp_bar=ProgressBar.new(); hp_bar.custom_minimum_size.y=26; hp_bar.show_percentage=false; hud.add_child(hp_bar)
	status=UIFactory.label("Entering the frontier...",14); hud.add_child(status)
	cooldowns=UIFactory.label("",12,Color("#98a7c6")); hud.add_child(cooldowns)
	hud.add_child(UIFactory.hsep())
	hud.add_child(UIFactory.label("FRONTIER RULES",14,Color("#f0dfae")))
	hud.add_child(UIFactory.label("Purple-ring enemies are Elites. Ranged threats and bosses fire projectiles. Dash is briefly invulnerable, so read tells instead of treating movement as decoration.",12,Color("#a5b1cb")))
	hud.add_child(UIFactory.hsep())
	hud.add_child(UIFactory.label("CONTROLS",14,Color("#f0dfae")))
	hud.add_child(UIFactory.label("WASD  move\nSpace  dash / evade\nQ  rally army\nE  shockwave\n\nWarden auto-attacks. Your army fights around you.",12,Color("#a5b1cb")))
	hud.add_child(UIFactory.spacer())
	hud.add_child(UIFactory.button("Retreat to World",func():GameState.screen_requested.emit("world"),Color("#4e3337")))

func _objective_progress_text(data:Dictionary) -> String:
	if bool(data.boss):
		return "★ %s ACTIVE · read the pattern and break it"%String(data.get("boss_name","Guardian"))
	var name=String(data.objective)
	var progress=int(data.objective_progress)
	var target=int(data.objective_target)
	match name:
		"Monster Hunt": return "Hunt progress  %d / %d kills"%[min(progress,target),target]
		"Resource Sweep": return "Extraction  %d / %d sites"%[min(progress,target),target]
		"Ruin Siege": return "%s incoming  %d / %ds"%[String(tile.get("boss_name","Regional Boss")),min(progress,target),target]
		_: return "Hold the frontier  %d / %ds"%[min(progress,target),target]

func _hud(data: Dictionary) -> void:
	hp_bar.max_value=data.hp_max; hp_bar.value=data.hp
	objective_label.text=_objective_progress_text(data)
	var combo_text=" · Momentum ×%d"%data.combo if int(data.combo)>1 else ""
	var boss_line="\n★ %s"%String(data.get("boss_name","Guardian")) if bool(data.boss) else ""
	status.text="HP %d / %d\nRun Lv.%d · Kills %d · Elites %d%s\nHarvest %d / %d · %ds%s"%[data.hp,data.hp_max,data.level,data.kills,data.elite_kills,combo_text,data.nodes,data.nodes_total,int(data.time),boss_line]
	cooldowns.text="Dash %.1fs · Rally %.1fs · Burst %.1fs"%[data.dash_cd,data.rally_cd,data.burst_cd]

func _show_upgrade() -> void:
	upgrade_overlay=PanelContainer.new()
	upgrade_overlay.set_anchors_preset(Control.PRESET_CENTER)
	upgrade_overlay.position=Vector2(300,150)
	upgrade_overlay.size=Vector2(680,385)
	upgrade_overlay.add_theme_stylebox_override("panel",UIFactory.panel(Color("#111827"),14,Color("#8b7449")))
	add_child(upgrade_overlay)
	var v=VBoxContainer.new()
	upgrade_overlay.add_child(v)
	var t=UIFactory.title("Choose a Field Doctrine",25)
	t.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	v.add_child(UIFactory.label("Stack synergies during the run. Build the Warden, the army, mobility, sustain or a hybrid that gets gloriously unreasonable.",12,Color("#a6b2cc")))
	var choices=upgrade_defs.keys()
	choices.shuffle()
	for i in 3:
		var id=choices[i]
		var b=UIFactory.button("%s\n%s"%[upgrade_defs[id][0],upgrade_defs[id][1]],func(x=id):_choose_upgrade(x),Color("#303b59"))
		b.custom_minimum_size.y=72
		v.add_child(b)

func _choose_upgrade(id: String) -> void:
	arena.apply_upgrade(id)
	if upgrade_overlay:
		upgrade_overlay.queue_free()
		upgrade_overlay=null

func _finished(result: Dictionary) -> void:
	GameState.expedition_completed(result)
	SaveManager.save_game()
	result_overlay=PanelContainer.new()
	result_overlay.set_anchors_preset(Control.PRESET_CENTER)
	result_overlay.position=Vector2(330,65)
	result_overlay.size=Vector2(620,565)
	result_overlay.add_theme_stylebox_override("panel",UIFactory.panel(Color("#111827"),15,Color("#856f48")))
	add_child(result_overlay)
	var v=VBoxContainer.new()
	result_overlay.add_child(v)
	var text="VICTORY · TERRITORY CLAIMED" if result.get("territory_claimed",false) else ("VICTORY · FRONTIER SECURED" if result.victory else "EXPEDITION BROKEN")
	var tl=UIFactory.title(text,25)
	tl.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(tl)
	v.add_child(UIFactory.label("%s · Threat %d"%[String(result.get("objective","Expedition")),result.threat],14,Color("#e0c684")))
	if bool(tile.get("boss",false)):
		v.add_child(UIFactory.label("Regional Boss: %s"%String(result.get("boss_name",tile.get("boss_name","Unknown"))),14,Color("#f0b7c0")))
	v.add_child(UIFactory.label("%d kills · %d elites · %d XP · Harvested %d/%d"%[result.kills,result.get("elite_kills",0),result.xp,result.get("nodes_collected",0),result.get("nodes_total",0)],13,Color("#aebad2")))
	v.add_child(UIFactory.label("Best Momentum ×%d"%result.get("best_combo",0),13,Color("#d1bd85")))
	if result.get("territory_claimed",false):
		v.add_child(UIFactory.label("New adjacent territories are now reachable from this claim.",12,Color("#9fd3a7")))
	v.add_child(UIFactory.hsep())
	v.add_child(UIFactory.label("LOOT",15,Color("#f0dfae")))
	for key in GameState.RESOURCE_ORDER:
		var amount=float(result.loot.get(key,0))
		if amount>0:
			v.add_child(UIFactory.label("%s +%d"%[key.capitalize(),int(amount)],13))
	if not result.item.is_empty():
		var affixes=result.item.get("affixes",[])
		var affix_suffix=" · %d AFFIX%s"%[affixes.size(),"ES" if affixes.size()!=1 else ""] if affixes.size()>0 else ""
		v.add_child(UIFactory.label("GEAR DROP: %s · %s%s"%[result.item.name,result.item.rarity.to_upper(),affix_suffix],15,Color("#9fc6f1")))
		for affix in affixes:
			v.add_child(UIFactory.label("◆ %s"%String(affix.get("text","")),11,Color("#b9c9ed")))
	v.add_child(UIFactory.spacer())
	var return_screen="world" if result.victory else "city"
	var return_label="Return to World Map" if result.victory else "Return to Settlement"
	var next=UIFactory.button(return_label,func():GameState.screen_requested.emit(return_screen),Color("#4d563d"))
	next.custom_minimum_size.y=50
	v.add_child(next)
