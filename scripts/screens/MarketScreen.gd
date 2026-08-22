extends Control

var offers_box: VBoxContainer
var offer_defs = [
	["Iron Vanguard Helm", "helm", "uncommon", 11, 220],
	["Mistwalker Cape", "cape", "rare", 18, 430],
	["Ashen Longblade", "weapon", "rare", 21, 520],
	["Frostbound Greaves", "boots", "epic", 27, 880],
	["Runed Warbelt", "belt", "uncommon", 13, 270],
	["Dawnwatch Pauldrons", "shoulders", "rare", 19, 460],
]

func _ready() -> void:
	_build()
	GameState.changed.connect(refresh)
	refresh()

func _exit_tree() -> void:
	if GameState.changed.is_connected(refresh):
		GameState.changed.disconnect(refresh)

func _build() -> void:
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)
	var root = VBoxContainer.new()
	margin.add_child(root)
	root.add_child(UIFactory.title("Frontier Marketplace", 28))
	root.add_child(UIFactory.label("MVP uses deterministic NPC listings. Online version will route listings, escrow and purchases through an authoritative backend.", 13, Color("#96a5c4")))
	root.add_child(UIFactory.hsep())
	offers_box = VBoxContainer.new()
	offers_box.add_theme_constant_override("separation", 8)
	root.add_child(offers_box)

func refresh() -> void:
	if not is_inside_tree():
		return
	UIFactory.clear_children(offers_box)
	for i in 5:
		var def = offer_defs[(i + int(GameState.world.day)) % offer_defs.size()]
		var p = PanelContainer.new()
		p.add_theme_stylebox_override("panel", UIFactory.panel(Color("#171e30"), 9, Color("#35415f")))
		var h = HBoxContainer.new()
		p.add_child(h)
		var v = VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		v.add_child(UIFactory.label(def[0], 17, Color("#eadfbf")))
		v.add_child(UIFactory.label("%s · %s · Power %d" % [str(def[2]).capitalize(), str(def[1]).capitalize(), def[3]], 12, Color("#99a7c6")))
		h.add_child(UIFactory.label("%d Gold" % def[4], 17, Color("#d8bf83")))
		var buy = UIFactory.button("Buy", func(d=def): buy_offer(d), Color("#405042"))
		buy.custom_minimum_size.x = 84
		h.add_child(buy)
		offers_box.add_child(p)
	offers_box.add_child(UIFactory.hsep())
	offers_box.add_child(UIFactory.label("Planned online market rules", 16, Color("#f0dfae")))
	offers_box.add_child(UIFactory.label("Tradable / bound item flags · listing fees · server-side escrow · price history · anti-dupe transaction ledger · regional taxes · resource orders.", 12, Color("#97a5c4")))

func buy_offer(def: Array) -> void:
	var price = int(def[4])
	if GameState.resources.gold < price:
		GameState.toast_requested.emit("Not enough Gold.")
		return
	GameState.resources.gold -= price
	var item = GameState.make_item(def[0], def[1], def[2], def[3], {})
	GameState.add_item(item)
