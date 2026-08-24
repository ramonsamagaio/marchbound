extends "res://scripts/Main.gd"

const MAIN_SHELL_SCENE:=preload("res://scenes/ui/MainShell.tscn")

var visual_shell:Control

func _ready() -> void:
	screen_scripts["city"] = preload("res://scripts/screens/CommandScreenHybrid.gd")
	screen_scripts["world"] = preload("res://scripts/screens/WorldScreenHybrid.gd")
	screen_scripts["army"] = preload("res://scripts/screens/ArmyScreenHybrid.gd")
	screen_scripts["inventory"] = preload("res://scripts/screens/InventoryScreenHybrid.gd")
	screen_scripts["expedition"] = preload("res://scripts/screens/ExpeditionScreenHybrid.gd")
	screen_scripts["content"] = preload("res://scripts/screens/ContentLabScreen.gd")
	super._ready()

func _build_shell() -> void:
	visual_shell=MAIN_SHELL_SCENE.instantiate()
	visual_shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(visual_shell)
	top_resources=visual_shell.get_node("Root/Top/Margin/Row/TopResources")
	content=visual_shell.get_node("Root/Content")
	nav=visual_shell.get_node("Root/NavPanel/Nav")
	toast_label=visual_shell.get_node("Toast")
	toast_label.modulate.a=0.0

	first_march_panel=visual_shell.get_node("Root/FirstMarch")
	first_march_title=visual_shell.get_node("Root/FirstMarch/Margin/Row/Text/Heading/Title")
	first_march_progress=visual_shell.get_node("Root/FirstMarch/Margin/Row/Text/Heading/Progress")
	first_march_description=visual_shell.get_node("Root/FirstMarch/Margin/Row/Text/Description")
	first_march_cta=visual_shell.get_node("Root/FirstMarch/Margin/Row/Go")
	first_march_claim=visual_shell.get_node("Root/FirstMarch/Margin/Row/Claim")
	first_march_cta.pressed.connect(_first_march_go)
	first_march_claim.pressed.connect(_claim_first_march)

	var routes:Dictionary={
		"City":"city",
		"World":"world",
		"Army":"army",
		"Inventory":"inventory",
		"Contracts":"contracts",
		"Market":"market",
		"Content":"content"
	}
	for button_name:Variant in routes.keys():
		var button:Button=nav.get_node(String(button_name))
		var target:String=String(routes[button_name])
		button.pressed.connect(func():show_screen(target))
	nav.get_node("City").text="COMMAND"
	nav.get_node("World").text="WORLD MAP"
	nav.get_node("Army").text="WAR-BAND"

func _refresh_resources() -> void:
	if not top_resources:
		return
	UIFactory.clear_children(top_resources)
	var macro:Vector2i = WorldAreaManager.current_macro()
	var location:=UIFactory.label("[%d,%d]"%[macro.x,macro.y],11,Color("#9fb2c8"))
	top_resources.add_child(location)
	for key in GameState.RESOURCE_ORDER:
		var item=HBoxContainer.new()
		item.add_theme_constant_override("separation",3)
		var icon=TextureRect.new()
		icon.custom_minimum_size=Vector2(20,20)
		icon.texture=VisualAtlas.texture("res_"+key)
		icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		item.add_child(icon)
		item.add_child(UIFactory.label(compact(float(GameState.resources[key])),12,Color("#e8dfc8")))
		top_resources.add_child(item)
