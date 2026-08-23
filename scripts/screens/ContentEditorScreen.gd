extends Control

const CATEGORIES:Array[String]=["items","monsters","attacks","projectiles","tiles"]

@onready var category:OptionButton=$Margin/Root/Header/Category
@onready var list:ItemList=$Margin/Root/Body/Left/List
@onready var entry_title:Label=$Margin/Root/Body/Right/EditorPanel/EditorMargin/Column/EntryTitle
@onready var json_editor:TextEdit=$Margin/Root/Body/Right/EditorPanel/EditorMargin/Column/Json
@onready var save_button:Button=$Margin/Root/Body/Right/EditorPanel/EditorMargin/Column/Buttons/Save
@onready var reset_button:Button=$Margin/Root/Body/Right/EditorPanel/EditorMargin/Column/Buttons/DeleteOverride
@onready var validate_button:Button=$Margin/Root/Body/Right/EditorPanel/EditorMargin/Column/Buttons/Validate
@onready var preview:TextureRect=$Margin/Root/Body/Right/InfoPanel/InfoMargin/Column/Preview
@onready var summary:Label=$Margin/Root/Body/Right/InfoPanel/InfoMargin/Column/Summary
@onready var footer:Label=$Margin/Root/Footer

var current_category:="items"
var current_id:=""

func _ready()->void:
	for c in CATEGORIES: category.add_item(c.capitalize())
	category.item_selected.connect(_category_changed)
	list.item_selected.connect(_entry_selected)
	save_button.pressed.connect(_save)
	reset_button.pressed.connect(_reset_entry)
	validate_button.pressed.connect(_validate)
	ContentDB.content_changed.connect(_content_changed)
	_refresh_list()

func _category_changed(index:int)->void:
	current_category=CATEGORIES[index]
	current_id=""
	_refresh_list()

func _refresh_list()->void:
	list.clear()
	for id in ContentDB.ids(current_category):
		var d:=ContentDB.get_entry(current_category,id)
		list.add_item("%s\n%s"%[String(d.get("name",id)),id])
		list.set_item_metadata(list.item_count-1,id)
	entry_title.text=current_category.to_upper()
	json_editor.text=""
	preview.texture=null
	summary.text="%d shipped/runtime entries"%list.item_count

func _entry_selected(index:int)->void:
	current_id=String(list.get_item_metadata(index))
	_show_current()

func _show_current()->void:
	if current_id=="": return
	var d:=ContentDB.get_entry(current_category,current_id)
	entry_title.text="%s · %s"%[String(d.get("name",current_id)),current_id]
	json_editor.text=JSON.stringify(d,"  ")
	_update_preview(d)
	_update_summary(d)

func _update_preview(d:Dictionary)->void:
	preview.texture=null
	var candidates:Array[String]=[]
	for key in ["sprite_id","visual_id","inventory_sprite","attack_sprite"]:
		var value:=String(d.get(key,""))
		if value!="": candidates.append(value)
	for id in candidates:
		if VisualAtlas.has(id):
			preview.texture=VisualAtlas.texture(id)
			return

func _update_summary(d:Dictionary)->void:
	var lines:Array[String]=[]
	match current_category:
		"items":
			lines.append("Kind: %s · Slot: %s · Tier %d"%[d.get("kind","?"),d.get("slot","?"),int(d.get("tier",1))])
			if String(d.get("kind",""))=="weapon":
				lines.append("Class: %s"%String(d.get("weapon_class","?")))
				lines.append("Attack: %s"%String(d.get("attack_id","?")))
				lines.append("Projectile: %s"%String(d.get("projectile_id","none")))
				lines.append("Speed %.2f · Damage ×%.2f · Knockback %.2f"%[float(d.get("attack_speed",1.0)),float(d.get("damage_mult",1.0)),float(d.get("knockback",0.0))])
			lines.append("Biomes: "+", ".join(Array(d.get("biomes",[]))))
		"monsters":
			lines.append("Behavior: %s"%String(d.get("behavior","?")))
			lines.append("Attack: %s"%String(d.get("attack_id","?")))
			lines.append("Projectile: %s"%String(d.get("projectile_id","none")))
			lines.append("Biomes: "+", ".join(Array(d.get("biomes",[]))))
			lines.append("Drops: "+", ".join(Array(d.get("drops",[]))))
		"attacks":
			lines.append("Mode: %s · Motion: %s"%[d.get("mode","?"),d.get("motion","?")])
			lines.append("Duration %.2f · Damage ×%.2f · Knockback ×%.2f"%[float(d.get("duration",0.0)),float(d.get("damage_mult",1.0)),float(d.get("knockback_mult",1.0))])
		"projectiles":
			lines.append("Speed %d · Radius %.1f · Pierce %d"%[int(d.get("speed",0)),float(d.get("radius",0.0)),int(d.get("pierce",0))])
			lines.append("Damage ×%.2f · Knockback ×%.2f"%[float(d.get("damage_mult",1.0)),float(d.get("knockback_mult",1.0))])
		"tiles":
			lines.append("Biome: %s · Kind: %s"%[d.get("biome","?"),d.get("kind","?")])
			lines.append("Tags: "+", ".join(Array(d.get("tags",[]))))
	summary.text="\n".join(lines)

func _save()->void:
	if current_id=="": return
	var parsed:Variant=JSON.parse_string(json_editor.text)
	if not parsed is Dictionary:
		footer.text="Invalid JSON · nothing saved"
		footer.modulate=Color("#e39191")
		return
	ContentDB.update_entry(current_category,current_id,Dictionary(parsed),true)
	footer.text="Saved runtime override to user:// for %s/%s"%[current_category,current_id]
	footer.modulate=Color("#8dd5a6")
	_show_current()

func _reset_entry()->void:
	if current_id=="": return
	ContentDB.delete_override(current_category,current_id)
	footer.text="Entry restored to shipped definition"
	footer.modulate=Color("#d5c28d")
	_show_current()

func _validate()->void:
	var errors:=ContentDB.validate_references()
	if errors.is_empty():
		footer.text="All item/monster attack and projectile links are valid"
		footer.modulate=Color("#8dd5a6")
	else:
		footer.text="Reference errors: "+" | ".join(errors)
		footer.modulate=Color("#e39191")

func _content_changed(category_name:String,id:String)->void:
	if category_name=="*" or category_name==current_category:
		_refresh_list()
		if id==current_id: _show_current()
