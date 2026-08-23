extends Control

const CATEGORIES:Array[String] = ["items","monsters","attacks","projectiles","tiles"]

@onready var category:OptionButton = $Margin/Root/Header/Category
@onready var list:ItemList = $Margin/Root/Body/Left/List
@onready var entry_title:Label = $Margin/Root/Body/Right/EditorPanel/EditorMargin/Column/EntryTitle
@onready var json_editor:TextEdit = $Margin/Root/Body/Right/EditorPanel/EditorMargin/Column/Json
@onready var save_button:Button = $Margin/Root/Body/Right/EditorPanel/EditorMargin/Column/Buttons/Save
@onready var reset_button:Button = $Margin/Root/Body/Right/EditorPanel/EditorMargin/Column/Buttons/DeleteOverride
@onready var validate_button:Button = $Margin/Root/Body/Right/EditorPanel/EditorMargin/Column/Buttons/Validate
@onready var preview:TextureRect = $Margin/Root/Body/Right/InfoPanel/InfoMargin/Column/Preview
@onready var summary:Label = $Margin/Root/Body/Right/InfoPanel/InfoMargin/Column/Summary
@onready var footer:Label = $Margin/Root/Footer

var current_category:String = "items"
var current_id:String = ""

func _ready() -> void:
	for category_name:String in CATEGORIES:
		category.add_item(category_name.capitalize())
	category.item_selected.connect(_category_changed)
	list.item_selected.connect(_entry_selected)
	save_button.pressed.connect(_save)
	reset_button.pressed.connect(_reset_entry)
	validate_button.pressed.connect(_validate)
	ContentDB.content_changed.connect(_content_changed)
	_refresh_list()

func _category_changed(index:int) -> void:
	current_category = CATEGORIES[index]
	current_id = ""
	_refresh_list()

func _refresh_list() -> void:
	list.clear()
	for id:String in ContentDB.ids(current_category):
		var definition:Dictionary = ContentDB.get_entry(current_category,id)
		list.add_item("%s\n%s"%[String(definition.get("name",id)),id])
		list.set_item_metadata(list.item_count-1,id)
	entry_title.text = current_category.to_upper()
	json_editor.text = ""
	preview.texture = null
	summary.text = "%d shipped/runtime entries"%list.item_count

func _entry_selected(index:int) -> void:
	current_id = String(list.get_item_metadata(index))
	_show_current()

func _show_current() -> void:
	if current_id == "":
		return
	var definition:Dictionary = ContentDB.get_entry(current_category,current_id)
	entry_title.text = "%s · %s"%[String(definition.get("name",current_id)),current_id]
	json_editor.text = JSON.stringify(definition,"  ")
	_update_preview(definition)
	_update_summary(definition)

func _update_preview(definition:Dictionary) -> void:
	preview.texture = null
	var candidates:Array[String] = []
	for key:String in ["sprite_id","visual_id","inventory_sprite","attack_sprite"]:
		var value:String = String(definition.get(key,""))
		if value != "":
			candidates.append(value)
	for id:String in candidates:
		if VisualAtlas.has(id):
			preview.texture = VisualAtlas.texture(id)
			return

func _update_summary(definition:Dictionary) -> void:
	var lines:Array[String] = []
	match current_category:
		"items":
			lines.append("Kind: %s · Slot: %s · Tier %d"%[String(definition.get("kind","?")),String(definition.get("slot","?")),int(definition.get("tier",1))])
			if String(definition.get("kind","")) == "weapon":
				lines.append("Class: %s"%String(definition.get("weapon_class","?")))
				lines.append("Attack: %s"%String(definition.get("attack_id","?")))
				lines.append("Projectile: %s"%String(definition.get("projectile_id","none")))
				lines.append("Speed %.2f · Damage ×%.2f · Knockback %.2f"%[float(definition.get("attack_speed",1.0)),float(definition.get("damage_mult",1.0)),float(definition.get("knockback",0.0))])
			lines.append("Biomes: "+_join_values(Array(definition.get("biomes",[]))))
		"monsters":
			lines.append("Behavior: %s"%String(definition.get("behavior","?")))
			lines.append("Attack: %s"%String(definition.get("attack_id","?")))
			lines.append("Projectile: %s"%String(definition.get("projectile_id","none")))
			lines.append("Biomes: "+_join_values(Array(definition.get("biomes",[]))))
			lines.append("Drops: "+_join_values(Array(definition.get("drops",[]))))
		"attacks":
			lines.append("Mode: %s · Motion: %s"%[String(definition.get("mode","?")),String(definition.get("motion","?"))])
			lines.append("Duration %.2f · Damage ×%.2f · Knockback ×%.2f"%[float(definition.get("duration",0.0)),float(definition.get("damage_mult",1.0)),float(definition.get("knockback_mult",1.0))])
		"projectiles":
			lines.append("Speed %d · Radius %.1f · Pierce %d"%[int(definition.get("speed",0)),float(definition.get("radius",0.0)),int(definition.get("pierce",0))])
			lines.append("Damage ×%.2f · Knockback ×%.2f"%[float(definition.get("damage_mult",1.0)),float(definition.get("knockback_mult",1.0))])
		"tiles":
			lines.append("Biome: %s · Kind: %s"%[String(definition.get("biome","?")),String(definition.get("kind","?"))])
			lines.append("Tags: "+_join_values(Array(definition.get("tags",[]))))
	summary.text = "\n".join(lines)

func _join_values(values:Array) -> String:
	var strings:Array[String] = []
	for value:Variant in values:
		strings.append(String(value))
	return ", ".join(strings)

func _save() -> void:
	if current_id == "":
		return
	var parsed:Variant = JSON.parse_string(json_editor.text)
	if not parsed is Dictionary:
		footer.text = "Invalid JSON · nothing saved"
		footer.modulate = Color("#e39191")
		return
	ContentDB.update_entry(current_category,current_id,Dictionary(parsed),true)
	footer.text = "Saved runtime override to user:// for %s/%s"%[current_category,current_id]
	footer.modulate = Color("#8dd5a6")
	_show_current()

func _reset_entry() -> void:
	if current_id == "":
		return
	ContentDB.delete_override(current_category,current_id)
	footer.text = "Entry restored to shipped definition"
	footer.modulate = Color("#d5c28d")
	_show_current()

func _validate() -> void:
	var errors:Array[String] = ContentDB.validate_references()
	if errors.is_empty():
		footer.text = "All item/monster attack and projectile links are valid"
		footer.modulate = Color("#8dd5a6")
	else:
		footer.text = "Reference errors: "+" | ".join(errors)
		footer.modulate = Color("#e39191")

func _content_changed(category_name:String,id:String) -> void:
	if category_name == "*" or category_name == current_category:
		_refresh_list()
		if id == current_id:
			_show_current()
