extends Control

var top_resources:HBoxContainer
var content:Control
var nav:HBoxContainer
var toast_label:Label
var current_screen:Control
var current_name := ""
var screen_scripts={"city":preload("res://scripts/screens/CityScreen.gd"),"world":preload("res://scripts/screens/WorldScreen.gd"),"army":preload("res://scripts/screens/ArmyScreen.gd"),"inventory":preload("res://scripts/screens/InventoryScreen.gd"),"market":preload("res://scripts/screens/MarketScreen.gd"),"contracts":preload("res://scripts/screens/ContractsScreen.gd"),"expedition":preload("res://scripts/screens/ExpeditionScreen.gd")}
var toast_tween:Tween

var first_march_panel:PanelContainer
var first_march_title:Label
var first_march_description:Label
var first_march_progress:Label
var first_march_cta:Button
var first_march_claim:Button

func _ready() -> void:
	_build_shell()
	GameState.changed.connect(_refresh_resources)
	GameState.changed.connect(_refresh_first_march)
	GameState.toast_requested.connect(_toast)
	GameState.screen_requested.connect(show_screen)
	_refresh_resources()
	_refresh_first_march()
	show_screen("city")

func _build_shell() -> void:
	var bg=ColorRect.new(); bg.color=Color("#0d111c"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	var root=VBoxContainer.new(); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.add_theme_constant_override("separation",0); add_child(root)
	var top=PanelContainer.new(); top.custom_minimum_size.y=66; top.add_theme_stylebox_override("panel",UIFactory.panel(Color("#111726"),0,Color("#2d3750"))); root.add_child(top)
	var top_h=HBoxContainer.new(); top_h.add_theme_constant_override("separation",16); top.add_child(top_h)
	top_h.add_child(UIFactory.title("MARCHBOUND",28)); var season=UIFactory.label("PRE-ALPHA · FRONTIER SEASON",12,Color("#9eabd0")); season.size_flags_vertical=Control.SIZE_SHRINK_CENTER; top_h.add_child(season); top_h.add_child(UIFactory.spacer())
	top_resources=HBoxContainer.new(); top_resources.add_theme_constant_override("separation",12); top_h.add_child(top_resources)

	_build_first_march_bar(root)

	content=Control.new(); content.size_flags_vertical=Control.SIZE_EXPAND_FILL; content.size_flags_horizontal=Control.SIZE_EXPAND_FILL; root.add_child(content)
	nav=HBoxContainer.new(); nav.alignment=BoxContainer.ALIGNMENT_CENTER; nav.custom_minimum_size.y=64; nav.add_theme_constant_override("separation",8); root.add_child(nav)
	for item in [["city","Settlement"],["world","World Map"],["army","Army"],["inventory","Inventory"],["contracts","Contracts"],["market","Marketplace"]]:
		var b=UIFactory.button(item[1],func():show_screen(item[0]),Color("#222b42")); b.custom_minimum_size.x=132; nav.add_child(b)
	toast_label=UIFactory.label("",15,Color("#fff1c8")); toast_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; toast_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; toast_label.mouse_filter=Control.MOUSE_FILTER_IGNORE; toast_label.set_anchors_preset(Control.PRESET_CENTER_TOP); toast_label.position=Vector2(390,78); toast_label.size=Vector2(500,46); toast_label.modulate.a=0.0; add_child(toast_label)

func _build_first_march_bar(root:VBoxContainer) -> void:
	first_march_panel=PanelContainer.new()
	first_march_panel.custom_minimum_size.y=70
	first_march_panel.add_theme_stylebox_override("panel",UIFactory.panel(Color("#182132"),0,Color("#665a3d")))
	root.add_child(first_march_panel)
	var margin=MarginContainer.new()
	margin.add_theme_constant_override("margin_left",18)
	margin.add_theme_constant_override("margin_right",18)
	margin.add_theme_constant_override("margin_top",7)
	margin.add_theme_constant_override("margin_bottom",7)
	first_march_panel.add_child(margin)
	var row=HBoxContainer.new()
	row.add_theme_constant_override("separation",12)
	margin.add_child(row)
	var text=VBoxContainer.new()
	text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.add_child(text)
	var heading=HBoxContainer.new()
	text.add_child(heading)
	first_march_title=UIFactory.label("FIRST MARCH",14,Color("#f1d997"))
	heading.add_child(first_march_title)
	heading.add_child(UIFactory.spacer())
	first_march_progress=UIFactory.label("",11,Color("#a9b7d0"))
	heading.add_child(first_march_progress)
	first_march_description=UIFactory.label("",11,Color("#c2cce0"))
	first_march_description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	text.add_child(first_march_description)
	first_march_cta=UIFactory.button("GO",_first_march_go,Color("#31445b"))
	first_march_cta.custom_minimum_size=Vector2(128,46)
	row.add_child(first_march_cta)
	first_march_claim=UIFactory.button("CLAIM",_claim_first_march,Color("#536245"))
	first_march_claim.custom_minimum_size=Vector2(128,46)
	row.add_child(first_march_claim)

func _refresh_resources() -> void:
	if not top_resources:
		return
	UIFactory.clear_children(top_resources)
	for key in GameState.RESOURCE_ORDER:
		top_resources.add_child(UIFactory.label("%s  %s" % [key.capitalize(),compact(float(GameState.resources[key]))],13))

func _refresh_first_march() -> void:
	if not first_march_panel:
		return
	FirstMarch.ensure_schema()
	var should_show = not FirstMarch.completed() and current_name != "expedition"
	first_march_panel.visible = should_show
	if not should_show:
		return
	var data=FirstMarch.current()
	first_march_title.text="FIRST MARCH %d/%d · %s"%[FirstMarch.step()+1,FirstMarch.STEP_COUNT,String(data.get("title",""))]
	first_march_description.text=String(data.get("description",""))+"  Reward: "+String(data.get("reward",""))
	first_march_progress.text=FirstMarch.progress_text()
	first_march_cta.text=String(data.get("cta","GO"))
	first_march_claim.text="CLAIM REWARD" if FirstMarch.condition_met() else "NOT READY"
	first_march_claim.disabled=not FirstMarch.condition_met()

func _first_march_go() -> void:
	var data=FirstMarch.current()
	var target=String(data.get("screen",""))
	if target!="":
		show_screen(target)

func _claim_first_march() -> void:
	FirstMarch.claim_reward()
	_refresh_first_march()

func compact(value:float) -> String:
	if value>=1000000:return "%.1fM"%(value/1000000.0)
	if value>=10000:return "%.1fk"%(value/1000.0)
	return "%d"%int(value)

func show_screen(name:String) -> void:
	if not screen_scripts.has(name): return
	if current_screen: current_screen.queue_free()
	current_name=name
	current_screen=screen_scripts[name].new()
	current_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_child(current_screen)
	nav.visible=name!="expedition"
	_refresh_first_march()

func _toast(message:String) -> void:
	toast_label.text=message
	if toast_tween and toast_tween.is_valid(): toast_tween.kill()
	toast_label.modulate.a=1.0; toast_tween=create_tween(); toast_tween.tween_interval(2.2); toast_tween.tween_property(toast_label,"modulate:a",0.0,0.4)

func _notification(what:int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST: SaveManager.save_game()