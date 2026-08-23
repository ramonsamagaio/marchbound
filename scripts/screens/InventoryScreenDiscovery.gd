extends "res://scripts/screens/InventoryScreenVisual.gd"

func _add_weapon_memory(item:Dictionary) -> void:
	super._add_weapon_memory(item)
	var echoes:Array = Array(item.get("echo_traits",[]))
	if echoes.is_empty():
		return
	detail.add_child(UIFactory.label("FRONTIER ECHOES",11,Color("#9ed5d0")))
	for raw_echo:Variant in echoes:
		var echo_id:String = String(raw_echo)
		detail.add_child(UIFactory.label("◇ %s · permanent expedition modifier"%FrontierManager.echo_name(echo_id),11,Color("#8bbfba")))
