extends "res://scripts/Main.gd"

func _ready() -> void:
	screen_scripts["city"] = preload("res://scripts/screens/CityScreenVisual.gd")
	screen_scripts["world"] = preload("res://scripts/screens/WorldScreenVisual.gd")
	screen_scripts["army"] = preload("res://scripts/screens/ArmyScreenVisual.gd")
	screen_scripts["expedition"] = preload("res://scripts/screens/ExpeditionScreenVisual.gd")
	super._ready()

func _refresh_resources() -> void:
	if not top_resources:
		return
	UIFactory.clear_children(top_resources)
	for key in GameState.RESOURCE_ORDER:
		var item=HBoxContainer.new()
		item.add_theme_constant_override("separation",5)
		var icon=TextureRect.new()
		icon.custom_minimum_size=Vector2(24,24)
		icon.texture=VisualAtlas.texture("res_"+key)
		icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		item.add_child(icon)
		item.add_child(UIFactory.label(compact(float(GameState.resources[key])),13,Color("#e8dfc8")))
		top_resources.add_child(item)
