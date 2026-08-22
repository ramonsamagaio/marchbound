extends Control

var top_resources:HBoxContainer
var content:Control
var nav:HBoxContainer
var toast_label:Label
var current_screen:Control
var current_name := ""
var screen_scripts={"city":preload("res://scripts/screens/CityScreen.gd"),"world":preload("res://scripts/screens/WorldScreen.gd"),"army":preload("res://scripts/screens/ArmyScreen.gd"),"inventory":preload("res://scripts/screens/InventoryScreen.gd"),"market":preload("res://scripts/screens/MarketScreen.gd"),"contracts":preload("res://scripts/screens/ContractsScreen.gd"),"expedition":preload("res://scripts/screens/ExpeditionScreen.gd")}
var toast_tween:Tween

func _ready() -> void:
	_build_shell(); GameState.changed.connect(_refresh_resources); GameState.toast_requested.connect(_toast); GameState.screen_requested.connect(show_screen); _refresh_resources(); show_screen("city")

func _build_shell() -> void:
	var bg=ColorRect.new(); bg.color=Color("#0d111c"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	var root=VBoxContainer.new(); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.add_theme_constant_override("separation",0); add_child(root)
	var top=PanelContainer.new(); top.custom_minimum_size.y=66; top.add_theme_stylebox_override("panel",UIFactory.panel(Color("#111726"),0,Color("#2d3750"))); root.add_child(top)
	var top_h=HBoxContainer.new(); top_h.add_theme_constant_override("separation",16); top.add_child(top_h)
	top_h.add_child(UIFactory.title("MARCHBOUND",28)); var season=UIFactory.label("PRE-ALPHA · FRONTIER SEASON",12,Color("#9eabd0")); season.size_flags_vertical=Control.SIZE_SHRINK_CENTER; top_h.add_child(season); top_h.add_child(UIFactory.spacer())
	top_resources=HBoxContainer.new(); top_resources.add_theme_constant_override("separation",12); top_h.add_child(top_resources)
	content=Control.new(); content.size_flags_vertical=Control.SIZE_EXPAND_FILL; content.size_flags_horizontal=Control.SIZE_EXPAND_FILL; root.add_child(content)
	nav=HBoxContainer.new(); nav.alignment=BoxContainer.ALIGNMENT_CENTER; nav.custom_minimum_size.y=64; nav.add_theme_constant_override("separation",8); root.add_child(nav)
	for item in [["city","Settlement"],["world","World Map"],["army","Army"],["inventory","Inventory"],["contracts","Contracts"],["market","Marketplace"]]:
		var b=UIFactory.button(item[1],func():show_screen(item[0]),Color("#222b42")); b.custom_minimum_size.x=132; nav.add_child(b)
	toast_label=UIFactory.label("",15,Color("#fff1c8")); toast_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; toast_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; toast_label.mouse_filter=Control.MOUSE_FILTER_IGNORE; toast_label.set_anchors_preset(Control.PRESET_CENTER_TOP); toast_label.position=Vector2(390,78); toast_label.size=Vector2(500,46); toast_label.modulate.a=0.0; add_child(toast_label)

func _refresh_resources() -> void:
	UIFactory.clear_children(top_resources)
	for key in GameState.RESOURCE_ORDER: top_resources.add_child(UIFactory.label("%s  %s" % [key.capitalize(),compact(float(GameState.resources[key]))],13))
func compact(value:float) -> String:
	if value>=1000000:return "%.1fM"%(value/1000000.0)
	if value>=10000:return "%.1fk"%(value/1000.0)
	return "%d"%int(value)
func show_screen(name:String) -> void:
	if not screen_scripts.has(name): return
	if current_screen: current_screen.queue_free()
	current_name=name; current_screen=screen_scripts[name].new(); current_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); content.add_child(current_screen); nav.visible=name!="expedition"
func _toast(message:String) -> void:
	toast_label.text=message
	if toast_tween and toast_tween.is_valid(): toast_tween.kill()
	toast_label.modulate.a=1.0; toast_tween=create_tween(); toast_tween.tween_interval(2.2); toast_tween.tween_property(toast_label,"modulate:a",0.0,0.4)
func _notification(what:int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST: SaveManager.save_game()
