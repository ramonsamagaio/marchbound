extends Control

var item_list:VBoxContainer
var detail:VBoxContainer
var doll:PaperDoll
var selected_uid:=""
var build_summary:Label

func _ready()->void:
	_build()
	GameState.changed.connect(refresh)
	refresh()

func _exit_tree()->void:
	if GameState.changed.is_connected(refresh):
		GameState.changed.disconnect(refresh)

func _build()->void:
	var margin=MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",24)
	margin.add_theme_constant_override("margin_right",24)
	margin.add_theme_constant_override("margin_top",16)
	margin.add_theme_constant_override("margin_bottom",16)
	add_child(margin)
	var root=HBoxContainer.new()
	root.add_theme_constant_override("separation",14)
	margin.add_child(root)

	var left=PanelContainer.new()
	left.custom_minimum_size.x=338
	left.add_theme_stylebox_override("panel",UIFactory.panel(Color("#151b2a"),12,Color("#35415d")))
	root.add_child(left)
	var left_v=VBoxContainer.new()
	left.add_child(left_v)
	left_v.add_child(UIFactory.title("Inventory",22))
	left_v.add_child(UIFactory.label("Regional equipment families make where an item came from matter. Mix affixes, sets and raw power instead of chasing one number.",12,Color("#92a0bf")))
	left_v.add_child(UIFactory.hsep())
	var item_scroll=ScrollContainer.new()
	item_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	left_v.add_child(item_scroll)
	item_list=VBoxContainer.new()
	item_list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	item_list.add_theme_constant_override("separation",6)
	item_scroll.add_child(item_list)

	var middle=PanelContainer.new()
	middle.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	middle.add_theme_stylebox_override("panel",UIFactory.panel(Color("#121827"),12,Color("#38445f")))
	root.add_child(middle)
	var mid=VBoxContainer.new()
	middle.add_child(mid)
	var title=UIFactory.title("Warden",24)
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	mid.add_child(title)
	var subtitle=UIFactory.label("Level %d · Renown %d · Power %d"%[GameState.player.level,GameState.player.renown,GameState.total_power()],13,Color("#99a7c7"))
	subtitle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	mid.add_child(subtitle)
	build_summary=UIFactory.label("",11,Color("#c5b98e"))
	build_summary.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	build_summary.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	mid.add_child(build_summary)
	doll=PaperDoll.new()
	doll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	doll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	mid.add_child(doll)
	var hint=UIFactory.label("Target: Spine paper-doll with modular RGBA armor layers. Current drawing is the functional rig preview.",11,Color("#7f8ca9"))
	hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	mid.add_child(hint)

	var right=PanelContainer.new()
	right.custom_minimum_size.x=360
	right.add_theme_stylebox_override("panel",UIFactory.panel(Color("#151b2a"),12,Color("#35415d")))
	root.add_child(right)
	var detail_scroll=ScrollContainer.new()
	right.add_child(detail_scroll)
	detail=VBoxContainer.new()
	detail.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation",7)
	detail_scroll.add_child(detail)

func refresh()->void:
	if not is_inside_tree():
		return
	UIFactory.clear_children(item_list)
	for item in GameState.inventory:
		var mark=" ◆" if GameState.equipped.get(item.slot,"")==item.uid else ""
		var affix_count = item.get("affixes",[]).size()
		var affix_text = " · %d affix%s"%[affix_count,"es" if affix_count!=1 else ""] if affix_count>0 else ""
		var family_text = " · %s"%String(item.get("family_name","")) if String(item.get("family_name","")) != "" else ""
		var txt="%s%s\n%s · Power %d%s%s%s"%[item.name,mark,item.slot.capitalize(),item.power,(" +%d"%item.upgrade) if item.upgrade>0 else "",family_text,affix_text]
		var b=UIFactory.button(txt,func(uid=item.uid):select(uid),rarity_color(item.rarity).darkened(0.45))
		b.custom_minimum_size=Vector2(300,58)
		item_list.add_child(b)
	if selected_uid=="" and GameState.inventory.size()>0:
		selected_uid=GameState.inventory[0].uid
	_refresh_build_summary()
	_refresh_detail()

func _refresh_build_summary()->void:
	var b=GameState.equipped_bonuses()
	var parts=[]
	if float(b.get("damage",0.0))>0: parts.append("+%.1f DMG"%float(b.damage))
	if float(b.get("health",0.0))>0: parts.append("+%d HP"%int(round(float(b.health))))
	if float(b.get("crit",0.0))>0: parts.append("+%d%% Crit"%int(round(float(b.crit)*100.0)))
	if float(b.get("army_damage",0.0))>0: parts.append("+%d%% Army"%int(round(float(b.army_damage)*100.0)))
	if float(b.get("speed",0.0))>0: parts.append("+%d%% Move"%int(round(float(b.speed)*100.0)))
	if float(b.get("command",0.0))>0: parts.append("+%d Command"%int(round(float(b.command))))
	if float(b.get("harvest",0.0))>0: parts.append("+%d%% Harvest"%int(round(float(b.harvest)*100.0)))
	if float(b.get("fortune",0.0))>0: parts.append("+%d%% Fortune"%int(round(float(b.fortune)*100.0)))
	if float(b.get("lifesteal",0.0))>0: parts.append("+%.1f%% Lifesteal"%(float(b.lifesteal)*100.0))
	if float(b.get("dash_cdr",0.0))>0: parts.append("-%d%% Dash CD"%int(round(float(b.dash_cdr)*100.0)))
	build_summary.text="Equipped build · "+(" · ".join(parts) if parts.size()>0 else "no special affixes yet")
	var sets = LootFamilies.active_set_summary()
	if sets.size()>0:
		build_summary.text += "\nActive sets · "+" · ".join(sets)

func select(uid:String)->void:
	selected_uid=uid
	_refresh_detail()

func _refresh_detail()->void:
	UIFactory.clear_children(detail)
	var item=GameState.get_item(selected_uid)
	if item.is_empty():
		detail.add_child(UIFactory.label("Select an item.",14))
		return
	detail.add_child(UIFactory.title(item.name,21))
	detail.add_child(UIFactory.label("%s · %s"%[item.rarity.to_upper(),item.slot.capitalize()],12,rarity_color(item.rarity)))
	var family_id = String(item.get("family",""))
	if family_id != "":
		var family = LootFamilies.family_by_id(family_id)
		var count = LootFamilies.equipped_count(family_id)
		detail.add_child(UIFactory.label("SET · %s · %d equipped"%[String(family.get("name",item.get("family_name","Regional"))).to_upper(),count],13,Color("#a7d9c5")))
		var lore=UIFactory.label(String(family.get("lore",item.get("family_lore",""))),11,Color("#8fa1bd"))
		lore.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		detail.add_child(lore)
		detail.add_child(UIFactory.label(String(family.get("two_piece","")),11,Color("#c9b783") if count>=2 else Color("#78859f")))
		detail.add_child(UIFactory.label(String(family.get("four_piece","")),11,Color("#c9b783") if count>=4 else Color("#78859f")))
		if String(item.get("origin_boss","")) != "":
			detail.add_child(UIFactory.label("Boss trophy · %s"%String(item.origin_boss),11,Color("#e0a9b8")))
	elif String(item.get("origin_biome","")) != "":
		detail.add_child(UIFactory.label("Recovered in %s"%String(item.origin_biome),11,Color("#8fa1bd")))
	detail.add_child(UIFactory.hsep())
	detail.add_child(UIFactory.label("Item Power  %d"%item.power,22,Color("#f0dfae")))
	detail.add_child(UIFactory.label("Forge Upgrade  +%d"%item.upgrade,13,Color("#aab5cf")))
	_add_comparison(item)
	detail.add_child(UIFactory.hsep())
	detail.add_child(UIFactory.label("AFFIXES",15,Color("#f0dfae")))
	var affixes=item.get("affixes",[])
	if affixes.size()>0:
		for affix in affixes:
			detail.add_child(UIFactory.label("◆ %s  %s"%[String(affix.get("name","Affix")),String(affix.get("text",""))],12,Color("#b8c8eb")))
	else:
		var bonuses=item.get("bonuses",{})
		if bonuses.size()>0:
			for key in bonuses:
				detail.add_child(UIFactory.label("◆ %s"%_bonus_text(String(key),float(bonuses[key])),12,Color("#aebbd6")))
		else:
			detail.add_child(UIFactory.label("No special affixes. Pure item power.",11,Color("#77849f")))
	detail.add_child(UIFactory.hsep())
	var equip=UIFactory.button("Equip",func():GameState.equip_item(item.uid),Color("#344e61"))
	equip.disabled=GameState.equipped.get(item.slot,"")==item.uid
	detail.add_child(equip)
	var up=UIFactory.button("Forge Upgrade",func():GameState.upgrade_item(item.uid),Color("#5a4637"))
	up.disabled=GameState.buildings.forge<1
	detail.add_child(up)
	if GameState.buildings.forge<1:
		detail.add_child(UIFactory.label("Build the Forge to upgrade item power.",11,Color("#b38f8f")))
	detail.add_child(UIFactory.hsep())
	detail.add_child(UIFactory.label("Inspect Profile Preview",15,Color("#f0dfae")))
	detail.add_child(UIFactory.label("Other players will eventually see the complete paper-doll plus affixes, regional set identity, level, Renown, Army Power, guild and achievements.",12,Color("#91a0bf")))

func _add_comparison(item:Dictionary)->void:
	var equipped_uid=String(GameState.equipped.get(item.slot,""))
	if equipped_uid=="" or equipped_uid==String(item.uid):
		detail.add_child(UIFactory.label("Currently equipped" if equipped_uid==String(item.uid) else "Nothing equipped in this slot",12,Color("#89b798")))
		return
	var current=GameState.get_item(equipped_uid)
	if current.is_empty():
		return
	var delta=int(item.power)-int(current.power)
	var sign="+" if delta>=0 else ""
	var color=Color("#91c49b") if delta>=0 else Color("#ca8d8d")
	detail.add_child(UIFactory.label("Compared with %s · Power %s%d"%[current.name,sign,delta],12,color))
	var current_keys=current.get("bonuses",{}).keys()
	var candidate_keys=item.get("bonuses",{}).keys()
	var special=[]
	for key in candidate_keys:
		var d=float(item.bonuses.get(key,0.0))-float(current.bonuses.get(key,0.0))
		if abs(d)>0.0001:
			special.append(_delta_text(String(key),d))
	for key in current_keys:
		if key not in candidate_keys:
			var d=-float(current.bonuses.get(key,0.0))
			if abs(d)>0.0001:
				special.append(_delta_text(String(key),d))
	if special.size()>0:
		var compare=UIFactory.label("Swap changes: "+", ".join(special),11,Color("#9ca9c6"))
		compare.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		detail.add_child(compare)

func _delta_text(key:String,value:float)->String:
	var sign="+" if value>=0 else ""
	if key in ["speed","crit","lifesteal","army_damage","harvest","fortune","dash_cdr"]:
		return "%s%d%% %s"%[sign,int(round(value*100.0)),_bonus_label(key)]
	return "%s%.1f %s"%[sign,value,_bonus_label(key)]

func _bonus_text(key:String,value:float)->String:
	if key in ["speed","crit","lifesteal","army_damage","harvest","fortune","dash_cdr"]:
		return "+%d%% %s"%[int(round(value*100.0)),_bonus_label(key)]
	return "+%.1f %s"%[value,_bonus_label(key)]

func _bonus_label(key:String)->String:
	return {"damage":"Warden damage","health":"max HP","speed":"movement","crit":"critical chance","lifesteal":"lifesteal","army_damage":"army damage","harvest":"harvest yield","fortune":"gear-drop chance","command":"Command","dash_cdr":"dash cooldown reduction"}.get(key,GameState.pretty(key))

func rarity_color(r:String)->Color:
	return {"common":Color("#aeb9ce"),"uncommon":Color("#72b78c"),"rare":Color("#6f9ee5"),"epic":Color("#9f77d1"),"legendary":Color("#d7a454")}.get(r,Color.WHITE)