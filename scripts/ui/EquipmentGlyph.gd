class_name EquipmentGlyph
extends Control

var item:Dictionary = {}

func set_item(value:Dictionary) -> void:
	item = value.duplicate(true)
	queue_redraw()

func _draw() -> void:
	if item.is_empty(): return
	var p:Dictionary = EquipmentVisualResolver.profile(item)
	var center:Vector2 = size*0.5
	var primary:Color = Color(p.get("primary",Color("#89939f")))
	var accent:Color = Color(p.get("accent",Color("#bcc8d8")))
	var dark:Color = Color(p.get("dark",Color("#4a5058")))
	var slot:String = String(p.get("slot","weapon"))
	if slot == "weapon": _draw_weapon(center,String(p.get("weapon_class","sword")),primary,accent,dark)
	else: _draw_armor(center,slot,primary,accent,dark)

func _draw_weapon(c:Vector2,weapon_class:String,primary:Color,accent:Color,dark:Color) -> void:
	match weapon_class:
		"spear":
			draw_line(c+Vector2(-22,21),c+Vector2(22,-25),dark,5)
			draw_colored_polygon(PackedVector2Array([c+Vector2(17,-24),c+Vector2(30,-34),c+Vector2(27,-18)]),accent)
		"bow":
			draw_arc(c,27,-1.25,1.25,18,primary,5)
			draw_line(c+Vector2(8,-25),c+Vector2(8,25),accent,2)
		"crossbow":
			draw_line(c+Vector2(-20,0),c+Vector2(25,0),dark,6)
			draw_arc(c+Vector2(8,0),23,-1.0,1.0,16,primary,4)
		"staff","wand":
			draw_line(c+Vector2(-16,27),c+Vector2(15,-25),dark,6)
			draw_circle(c+Vector2(17,-27),8,accent)
			draw_circle(c+Vector2(17,-27),13,Color(accent,0.15),false,2)
		"hammer":
			draw_line(c+Vector2(-15,25),c+Vector2(13,-18),dark,7)
			draw_rect(Rect2(c+Vector2(1,-29),Vector2(29,18)),primary)
			draw_rect(Rect2(c+Vector2(6,-25),Vector2(19,5)),accent)
		"axe":
			draw_line(c+Vector2(-15,25),c+Vector2(13,-20),dark,6)
			draw_colored_polygon(PackedVector2Array([c+Vector2(9,-25),c+Vector2(31,-30),c+Vector2(28,-8),c+Vector2(11,-12)]),primary)
		"dagger":
			draw_line(c+Vector2(-16,18),c+Vector2(19,-20),accent,7)
			draw_line(c+Vector2(-5,7),c+Vector2(5,16),primary,4)
		_:
			draw_line(c+Vector2(-17,24),c+Vector2(17,-26),accent,7)
			draw_line(c+Vector2(-6,7),c+Vector2(7,16),primary,5)

func _draw_armor(c:Vector2,slot:String,primary:Color,accent:Color,dark:Color) -> void:
	match slot:
		"helm":
			draw_colored_polygon(PackedVector2Array([c+Vector2(-22,16),c+Vector2(-21,-10),c+Vector2(-10,-25),c+Vector2(10,-25),c+Vector2(21,-10),c+Vector2(22,16),c+Vector2(9,25),c+Vector2(-9,25)]),primary)
			draw_rect(Rect2(c+Vector2(-14,-2),Vector2(28,8)),dark)
			draw_line(c+Vector2(0,-22),c+Vector2(0,-8),accent,3)
		"chest":
			draw_colored_polygon(PackedVector2Array([c+Vector2(-25,-20),c+Vector2(25,-20),c+Vector2(20,22),c+Vector2(0,31),c+Vector2(-20,22)]),primary)
			draw_line(c+Vector2(0,-17),c+Vector2(0,24),accent,3)
		"shoulders":
			draw_circle(c+Vector2(-18,0),15,primary); draw_circle(c+Vector2(18,0),15,primary)
			draw_arc(c+Vector2(-18,0),15,PI,TAU,12,accent,3); draw_arc(c+Vector2(18,0),15,PI,TAU,12,accent,3)
		"gloves":
			draw_rect(Rect2(c+Vector2(-27,-10),Vector2(17,30)),primary); draw_rect(Rect2(c+Vector2(10,-10),Vector2(17,30)),primary)
			draw_line(c+Vector2(-24,8),c+Vector2(-12,8),accent,2); draw_line(c+Vector2(12,8),c+Vector2(24,8),accent,2)
		"belt":
			draw_rect(Rect2(c+Vector2(-28,-8),Vector2(56,16)),dark); draw_rect(Rect2(c+Vector2(-7,-10),Vector2(14,20)),accent)
		"legs":
			draw_colored_polygon(PackedVector2Array([c+Vector2(-23,-23),c+Vector2(23,-23),c+Vector2(17,25),c+Vector2(3,25),c+Vector2(0,3),c+Vector2(-3,25),c+Vector2(-17,25)]),primary)
		"boots":
			draw_rect(Rect2(c+Vector2(-24,-13),Vector2(17,31)),primary); draw_rect(Rect2(c+Vector2(7,-13),Vector2(17,31)),primary)
			draw_rect(Rect2(c+Vector2(-29,13),Vector2(22,9)),dark); draw_rect(Rect2(c+Vector2(7,13),Vector2(22,9)),dark)
		"cape":
			draw_colored_polygon(PackedVector2Array([c+Vector2(-19,-28),c+Vector2(19,-28),c+Vector2(28,28),c+Vector2(0,20),c+Vector2(-28,28)]),primary)
			draw_line(c+Vector2(-16,-23),c+Vector2(16,-23),accent,4)
		_:
			draw_rect(Rect2(c-Vector2(22,22),Vector2(44,44)),primary)
