extends Control

var arena: CombatArena
var hp_bar: ProgressBar
var status: Label
var cooldowns: Label
var upgrade_overlay: PanelContainer
var result_overlay: PanelContainer
var tile := {}
var upgrade_defs = {"damage":["Edge of War","+25% Warden damage"],"speed":["Windstep","+15% movement speed"],"haste":["Quickened Sigil","+18% attack speed"],"projectile":["Twin Oath","+1 projectile"],"army":["Battle Doctrine","+30% army damage"],"vitality":["Ironblood","+25% max health & heal"]}

func _ready() -> void:
	tile = GameState.world.selected_tile
	if tile.is_empty():
		GameState.screen_requested.emit("world")
		return
	_build()
	arena.begin(tile)

func _build() -> void:
	var bg=ColorRect.new(); bg.color=Color("#0d111c"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	var layout=HBoxContainer.new(); layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); layout.add_theme_constant_override("separation",12); layout.offset_left=14; layout.offset_top=14; layout.offset_right=-14; layout.offset_bottom=-14; add_child(layout)
	var arena_panel=PanelContainer.new(); arena_panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL; arena_panel.size_flags_vertical=Control.SIZE_EXPAND_FILL; arena_panel.add_theme_stylebox_override("panel",UIFactory.panel(Color("#111724"),12,Color("#33405c"))); layout.add_child(arena_panel)
	var holder=Control.new(); holder.custom_minimum_size=Vector2(900,560); arena_panel.add_child(holder); arena=CombatArena.new(); holder.add_child(arena); arena.hud_changed.connect(_hud); arena.upgrade_requested.connect(_show_upgrade); arena.finished.connect(_finished)
	var side=PanelContainer.new(); side.custom_minimum_size.x=300; side.add_theme_stylebox_override("panel",UIFactory.panel(Color("#151b2a"),12,Color("#35415d"))); layout.add_child(side); var hud=VBoxContainer.new(); side.add_child(hud); hud.add_child(UIFactory.title(tile.biome,22)); hud.add_child(UIFactory.label("Territory [%d,%d] · Threat %d%s"%[tile.x,tile.y,tile.threat," · BOSS TERRITORY" if tile.boss else ""],13,Color("#e0b58d"))); hud.add_child(UIFactory.hsep()); hp_bar=ProgressBar.new(); hp_bar.custom_minimum_size.y=26; hp_bar.show_percentage=false; hud.add_child(hp_bar); status=UIFactory.label("Entering the frontier...",14); hud.add_child(status); cooldowns=UIFactory.label("",12,Color("#98a7c6")); hud.add_child(cooldowns); hud.add_child(UIFactory.hsep()); hud.add_child(UIFactory.label("FRONTIER RULES",14,Color("#f0dfae"))); hud.add_child(UIFactory.label("Harvest glowing resource sites by standing beside them. Keep killing quickly to build Momentum: higher Momentum boosts Warden and army damage and pays Gold at each 10-kill chain.",12,Color("#a5b1cb"))); hud.add_child(UIFactory.hsep()); hud.add_child(UIFactory.label("CONTROLS",14,Color("#f0dfae"))); hud.add_child(UIFactory.label("WASD  move\nSpace  dash\nQ  rally army\nE  shockwave\n\nYour Warden auto-attacks. Your army fights around you.",12,Color("#a5b1cb"))); hud.add_child(UIFactory.spacer()); hud.add_child(UIFactory.button("Retreat to World",func():GameState.screen_requested.emit("world"),Color("#4e3337")))

func _hud(data: Dictionary) -> void:
	hp_bar.max_value=data.hp_max; hp_bar.value=data.hp
	var combo_text=" · Momentum ×%d"%data.combo if int(data.combo)>1 else ""
	status.text="HP %d / %d\nRun Lv.%d · Kills %d%s\nHarvest %d / %d · %ds%s"%[data.hp,data.hp_max,data.level,data.kills,combo_text,data.nodes,data.nodes_total,int(data.time),"\n★ BOSS ARRIVED" if data.boss else ""]
	cooldowns.text="Dash %.1fs · Rally %.1fs · Burst %.1fs"%[data.dash_cd,data.rally_cd,data.burst_cd]

func _show_upgrade() -> void:
	upgrade_overlay=PanelContainer.new(); upgrade_overlay.set_anchors_preset(Control.PRESET_CENTER); upgrade_overlay.position=Vector2(300,170); upgrade_overlay.size=Vector2(680,330); upgrade_overlay.add_theme_stylebox_override("panel",UIFactory.panel(Color("#111827"),14,Color("#8b7449"))); add_child(upgrade_overlay); var v=VBoxContainer.new(); upgrade_overlay.add_child(v); var t=UIFactory.title("Choose a Field Doctrine",25); t.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; v.add_child(t); v.add_child(UIFactory.label("The run bends around your choices. Build power now, then carry loot home.",12,Color("#a6b2cc"))); var choices=upgrade_defs.keys(); choices.shuffle()
	for i in 3:
		var id=choices[i]; var b=UIFactory.button("%s\n%s"%[upgrade_defs[id][0],upgrade_defs[id][1]],func(x=id):_choose_upgrade(x),Color("#303b59")); b.custom_minimum_size.y=62; v.add_child(b)

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
	result_overlay.position=Vector2(330,105)
	result_overlay.size=Vector2(620,485)
	result_overlay.add_theme_stylebox_override("panel",UIFactory.panel(Color("#111827"),15,Color("#856f48")))
	add_child(result_overlay)
	var v=VBoxContainer.new()
	result_overlay.add_child(v)
	var text="VICTORY · TERRITORY CLAIMED" if result.get("territory_claimed",false) else ("VICTORY · FRONTIER SECURED" if result.victory else "EXPEDITION BROKEN")
	var tl=UIFactory.title(text,25)
	tl.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(tl)
	v.add_child(UIFactory.label("Threat %d · %d kills · %d XP"%[result.threat,result.kills,result.xp],14,Color("#aebad2")))
	v.add_child(UIFactory.label("Harvested %d/%d sites · Best Momentum ×%d"%[result.get("nodes_collected",0),result.get("nodes_total",0),result.get("best_combo",0)],13,Color("#d1bd85")))
	if result.get("territory_claimed",false):
		v.add_child(UIFactory.label("New adjacent territories are now reachable from this claim.",12,Color("#9fd3a7")))
	v.add_child(UIFactory.hsep())
	v.add_child(UIFactory.label("LOOT",15,Color("#f0dfae")))
	for key in GameState.RESOURCE_ORDER:
		var amount=float(result.loot.get(key,0))
		if amount>0:
			v.add_child(UIFactory.label("%s +%d"%[key.capitalize(),int(amount)],13))
	if not result.item.is_empty():
		v.add_child(UIFactory.label("GEAR DROP: %s · %s"%[result.item.name,result.item.rarity.capitalize()],15,Color("#9fc6f1")))
	v.add_child(UIFactory.spacer())
	var return_screen="world" if result.victory else "city"
	var return_label="Return to World Map" if result.victory else "Return to Settlement"
	var next=UIFactory.button(return_label,func():GameState.screen_requested.emit(return_screen),Color("#4d563d"))
	next.custom_minimum_size.y=50
	v.add_child(next)
