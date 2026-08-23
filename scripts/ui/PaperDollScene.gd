class_name PaperDollScene
extends PaperDoll

@onready var character_art:TextureRect=$Frame/CharacterStage/CharacterArt
@onready var aura:TextureRect=$Frame/CharacterStage/Aura
@onready var level_label:Label=$Frame/Level
@onready var power_label:Label=$Frame/Power
@onready var build_label:Label=$Frame/Build

var visual_time:=0.0

func _ready()->void:
	super._ready()
	custom_minimum_size=Vector2(440,620)
	if not GameState.changed.is_connected(_refresh_visual):
		GameState.changed.connect(_refresh_visual)
	_refresh_visual()

func _exit_tree()->void:
	if GameState.changed.is_connected(_refresh_visual):
		GameState.changed.disconnect(_refresh_visual)
	super._exit_tree()

func _process(delta:float)->void:
	visual_time+=delta
	var breathe_offset:=sin(visual_time*1.55)*3.0
	character_art.position.y=62.0+breathe_offset
	aura.rotation=sin(visual_time*0.35)*0.03

func _draw()->void:
	# Intentionally empty. All visible paper-doll composition now lives in the .tscn.
	pass

func _refresh_visual()->void:
	if not is_inside_tree():return
	level_label.text="WARDEN · LEVEL %d"%int(GameState.player.level)
	power_label.text="POWER %d · RENOWN %d"%[GameState.total_power(),int(GameState.player.renown)]
	var sets=LootFamilies.active_set_summary()
	build_label.text=" · ".join(sets) if not sets.is_empty() else "No active regional set bonus"
	for slot in ["helm","shoulders","chest","gloves","belt","legs","boots","cape","weapon"]:
		var node=get_node_or_null("Frame/Slots/"+slot.capitalize())
		if node is TextureButton:
			var uid:String=String(GameState.equipped.get(slot,""))
			var item:Dictionary=GameState.get_item(uid)
			node.modulate=rarity_color_for_slot(slot,Color("#9aa6bd")) if not item.is_empty() else Color(0.48,0.52,0.62,0.72)
			node.tooltip_text="%s: %s"%[slot.capitalize(),String(item.get("name","Empty"))]
