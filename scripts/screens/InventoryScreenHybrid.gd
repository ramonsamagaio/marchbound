extends "res://scripts/screens/InventoryScreenDiscovery.gd"

func refresh() -> void:
	if not is_inside_tree(): return
	UIFactory.clear_children(item_list)
	for raw:Variant in GameState.inventory:
		if not (raw is Dictionary): continue
		var item:Dictionary = Dictionary(raw)
		var card:=PanelContainer.new()
		var rarity:String = String(item.get("rarity","common"))
		card.add_theme_stylebox_override("panel",UIFactory.panel(rarity_color(rarity).darkened(0.57),7,rarity_color(rarity).darkened(0.12)))
		card.custom_minimum_size.y = 70
		var row:=HBoxContainer.new(); row.add_theme_constant_override("separation",8); card.add_child(row)
		var glyph:=EquipmentGlyph.new(); glyph.custom_minimum_size=Vector2(58,58); glyph.set_item(item); row.add_child(glyph)
		var mark:String = " ◆ EQUIPPED" if GameState.equipped.get(String(item.get("slot","")),"")==item.get("uid","") else ""
		var affix_count:int = Array(item.get("affixes",[])).size()
		var family_text:String = " · %s"%String(item.get("family_name","")) if String(item.get("family_name","")) != "" else ""
		var memory_rank:int = int(item.get("memory_rank",0))
		var echo_count:int = Array(item.get("echo_traits",[])).size()
		var line2:String = "%s · Power %d%s"%[String(item.get("slot","item")).capitalize(),int(item.get("power",0)),(" +%d"%int(item.get("upgrade",0))) if int(item.get("upgrade",0))>0 else ""]
		if family_text != "": line2 += family_text
		if affix_count > 0: line2 += " · %d affix%s"%[affix_count,"es" if affix_count != 1 else ""]
		if memory_rank > 0: line2 += " · Memory %d"%memory_rank
		if echo_count > 0: line2 += " · %d Echo%s"%[echo_count,"es" if echo_count != 1 else ""]
		var button:=Button.new(); button.flat=true; button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		button.text = "%s%s\n%s"%[String(item.get("name","Item")),mark,line2]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var uid:String = String(item.get("uid","")); button.pressed.connect(func(id=uid):select(id)); row.add_child(button)
		item_list.add_child(card)
	if selected_uid == "" and not GameState.inventory.is_empty(): selected_uid = String(Dictionary(GameState.inventory[0]).get("uid",""))
	_refresh_build_summary()
	_refresh_detail()

func _refresh_detail() -> void:
	super._refresh_detail()
	var item:Dictionary = GameState.get_item(selected_uid)
	if item.is_empty(): return
	detail.add_child(UIFactory.hsep())
	detail.add_child(UIFactory.label("VISUAL IDENTITY",14,Color("#d2c394")))
	var profile:Dictionary = EquipmentVisualResolver.profile(item)
	var glyph:=EquipmentGlyph.new(); glyph.custom_minimum_size=Vector2(104,104); glyph.set_item(item); detail.add_child(glyph)
	var shipped_inventory:String = String(profile.get("inventory_sprite",""))
	var shipped_equipped:String = String(profile.get("equipped_sheet",""))
	var shipped_attack:String = String(profile.get("attack_sprite",""))
	var links:=UIFactory.label("content_id: %s\ninventory: %s\nequipped: %s\nattack: %s"%[
		String(profile.get("content_id","procedural")),shipped_inventory if shipped_inventory!="" else "generated glyph",
		shipped_equipped if shipped_equipped!="" else "generated equipped layer",shipped_attack if shipped_attack!="" else "generated attack silhouette"
	],10,Color("#8190a8"))
	links.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(links)
