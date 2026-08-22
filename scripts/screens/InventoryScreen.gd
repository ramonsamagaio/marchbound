extends Control
var item_list:VBoxContainer
var detail:VBoxContainer
var doll:PaperDoll
var selected_uid:=""
func _ready()->void:_build();GameState.changed.connect(refresh);refresh()
func _exit_tree()->void:
	if GameState.changed.is_connected(refresh):GameState.changed.disconnect(refresh)
func _build()->void:
	var margin=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);margin.add_theme_constant_override("margin_left",24);margin.add_theme_constant_override("margin_right",24);margin.add_theme_constant_override("margin_top",16);margin.add_theme_constant_override("margin_bottom",16);add_child(margin);var root=HBoxContainer.new();root.add_theme_constant_override("separation",14);margin.add_child(root)
	var left=PanelContainer.new();left.custom_minimum_size.x=320;left.add_theme_stylebox_override("panel",UIFactory.panel(Color("#151b2a"),12,Color("#35415d")));root.add_child(left);item_list=VBoxContainer.new();left.add_child(item_list)
	var middle=PanelContainer.new();middle.size_flags_horizontal=Control.SIZE_EXPAND_FILL;middle.add_theme_stylebox_override("panel",UIFactory.panel(Color("#121827"),12,Color("#38445f")));root.add_child(middle);var mid=VBoxContainer.new();middle.add_child(mid);var title=UIFactory.title("Warden",24);title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;mid.add_child(title);var subtitle=UIFactory.label("Level %d · Renown %d · Power %d"%[GameState.player.level,GameState.player.renown,GameState.total_power()],13,Color("#99a7c7"));subtitle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;mid.add_child(subtitle);doll=PaperDoll.new();doll.size_flags_horizontal=Control.SIZE_EXPAND_FILL;doll.size_flags_vertical=Control.SIZE_EXPAND_FILL;mid.add_child(doll);var hint=UIFactory.label("Target: Spine paper-doll with modular RGBA armor layers. Current drawing is the functional rig preview.",11,Color("#7f8ca9"));hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;mid.add_child(hint)
	var right=PanelContainer.new();right.custom_minimum_size.x=330;right.add_theme_stylebox_override("panel",UIFactory.panel(Color("#151b2a"),12,Color("#35415d")));root.add_child(right);detail=VBoxContainer.new();right.add_child(detail)
func refresh()->void:
	if not is_inside_tree():return
	UIFactory.clear_children(item_list);item_list.add_child(UIFactory.title("Inventory",22));item_list.add_child(UIFactory.label("Equipment is both progression and social display.",12,Color("#92a0bf")));item_list.add_child(UIFactory.hsep())
	for item in GameState.inventory:
		var mark=" ◆" if GameState.equipped.get(item.slot,"")==item.uid else "";var txt="%s%s\n%s · Power %d%s"%[item.name,mark,item.slot.capitalize(),item.power,(" +%d"%item.upgrade) if item.upgrade>0 else ""];var b=UIFactory.button(txt,func(uid=item.uid):select(uid),rarity_color(item.rarity).darkened(0.45));b.custom_minimum_size=Vector2(285,54);item_list.add_child(b)
	if selected_uid=="" and GameState.inventory.size()>0:selected_uid=GameState.inventory[0].uid
	_refresh_detail()
func select(uid:String)->void:selected_uid=uid;_refresh_detail()
func _refresh_detail()->void:
	UIFactory.clear_children(detail);var item=GameState.get_item(selected_uid)
	if item.is_empty():detail.add_child(UIFactory.label("Select an item.",14));return
	detail.add_child(UIFactory.title(item.name,21));detail.add_child(UIFactory.label("%s · %s"%[item.rarity.to_upper(),item.slot.capitalize()],12,rarity_color(item.rarity)));detail.add_child(UIFactory.hsep());detail.add_child(UIFactory.label("Item Power  %d"%item.power,22,Color("#f0dfae")));detail.add_child(UIFactory.label("Upgrade  +%d"%item.upgrade,14));detail.add_child(UIFactory.spacer());var equip=UIFactory.button("Equip",func():GameState.equip_item(item.uid),Color("#344e61"));equip.disabled=GameState.equipped.get(item.slot,"")==item.uid;detail.add_child(equip);var up=UIFactory.button("Forge Upgrade",func():GameState.upgrade_item(item.uid),Color("#5a4637"));up.disabled=GameState.buildings.forge<1;detail.add_child(up)
	if GameState.buildings.forge<1:detail.add_child(UIFactory.label("Build the Forge to upgrade gear.",11,Color("#b38f8f")))
	detail.add_child(UIFactory.hsep());detail.add_child(UIFactory.label("Inspect Profile Preview",15,Color("#f0dfae")));detail.add_child(UIFactory.label("Other players will see this paper-doll, equipped pieces, level, Renown, Army Power, guild and achievements.",12,Color("#91a0bf")))
func rarity_color(r:String)->Color:return {"common":Color("#aeb9ce"),"uncommon":Color("#72b78c"),"rare":Color("#6f9ee5"),"epic":Color("#9f77d1"),"legendary":Color("#d7a454")}.get(r,Color.WHITE)
