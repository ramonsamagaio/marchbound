class_name PaperDoll
extends Control
var breathe:=0.0
func _ready()->void:custom_minimum_size=Vector2(300,470);set_process(true);GameState.changed.connect(queue_redraw)
func _process(delta:float)->void:breathe+=delta;queue_redraw()
func _draw()->void:
	var center=Vector2(size.x*0.5,size.y*0.5+10);var pulse=sin(breathe*1.7)*1.8;var skin=Color("#d9c4bf");var under=Color("#292b47");var metal=rarity_color_for_slot("chest",Color("#c8d2e7"));var accent=Color("#8fa7db");var gold=Color("#c9a66d")
	draw_ellipse(center+Vector2(0,200),Vector2(72,12),Color(0,0,0,0.28));draw_colored_polygon(PackedVector2Array([center+Vector2(-45,-98),center+Vector2(45,-98),center+Vector2(70,135),center+Vector2(30,190),center+Vector2(0,120),center+Vector2(-30,190),center+Vector2(-70,135)]),Color("#393956"));draw_line(center+Vector2(-25,65),center+Vector2(-34,176),metal,28);draw_line(center+Vector2(25,65),center+Vector2(34,176),metal,28);draw_line(center+Vector2(-34,176),center+Vector2(-42,207),accent,22);draw_line(center+Vector2(34,176),center+Vector2(42,207),accent,22)
	draw_colored_polygon(PackedVector2Array([center+Vector2(-42,-88),center+Vector2(42,-88),center+Vector2(34+pulse*0.2,45),center+Vector2(0,70),center+Vector2(-34-pulse*0.2,45)]),under);draw_colored_polygon(PackedVector2Array([center+Vector2(-48,-75),center+Vector2(-24,-94),center+Vector2(0,-82),center+Vector2(24,-94),center+Vector2(48,-75),center+Vector2(31,30),center+Vector2(0,54),center+Vector2(-31,30)]),metal);draw_polyline(PackedVector2Array([center+Vector2(-48,-75),center+Vector2(0,-82),center+Vector2(48,-75),center+Vector2(31,30),center+Vector2(0,54),center+Vector2(-31,30),center+Vector2(-48,-75)]),accent,4)
	draw_line(center+Vector2(-44,-65),center+Vector2(-68,50),skin,18);draw_line(center+Vector2(44,-65),center+Vector2(68,50),skin,18);draw_line(center+Vector2(-60,8),center+Vector2(-72,72),accent,22);draw_line(center+Vector2(60,8),center+Vector2(72,72),accent,22);draw_circle(center+Vector2(-53,-69),24,metal);draw_circle(center+Vector2(53,-69),24,metal);draw_arc(center+Vector2(-53,-69),24,0,TAU,24,gold,3);draw_arc(center+Vector2(53,-69),24,0,TAU,24,gold,3);draw_rect(Rect2(center+Vector2(-15,-118),Vector2(30,28)),under);draw_circle(center+Vector2(0,-148),34,skin)
	if GameState.equipped.helm!="":draw_arc(center+Vector2(0,-148),38,PI,TAU,20,metal,12)
	if GameState.equipped.weapon!="":draw_line(center+Vector2(78,50),center+Vector2(104,-78),Color("#d7e1ef"),8);draw_line(center+Vector2(88,14),center+Vector2(113,20),gold,6)
	draw_colored_polygon(PackedVector2Array([center+Vector2(0,-32),center+Vector2(9,-20),center+Vector2(0,-6),center+Vector2(-9,-20)]),Color("#8bbcff"))
func draw_ellipse(center:Vector2,radii:Vector2,color:Color)->void:
	var points=PackedVector2Array();for i in 32:var a=TAU*i/32.0;points.append(center+Vector2(cos(a)*radii.x,sin(a)*radii.y));draw_colored_polygon(points,color)
func rarity_color_for_slot(slot:String,fallback:Color)->Color:
	var uid=GameState.equipped.get(slot,"");var item=GameState.get_item(uid);if item.is_empty():return fallback
	return {"common":Color("#bcc7dc"),"uncommon":Color("#82c39c"),"rare":Color("#7da8ec"),"epic":Color("#a783dd"),"legendary":Color("#e3b267")}.get(item.rarity,fallback)
