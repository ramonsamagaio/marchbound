class_name HybridRuntimeArena
extends HybridAreaCombatArena

func _offer_gambit() -> void:
	if safe_area:
		return
	super._offer_gambit()

func _spawn_nemesis() -> void:
	if safe_area:
		return
	super._spawn_nemesis()

func _gear_color(item:Dictionary) -> Color:
	return Color(EquipmentVisualResolver.profile(item).get("primary",Color("#778ca8")))
