extends "res://scripts/screens/ArmyScreen.gd"

func _ready()->void:
	UnitRoster.ensure_schema()
	super._ready()

func refresh()->void:
	UnitRoster.ensure_schema()
	super.refresh()

func _unit_card(unit:String)->PanelContainer:
	var panel:PanelContainer=super._unit_card(unit)
	var v:VBoxContainer=panel.get_child(0)
	var specimens:Array=UnitRoster.units_for_family(unit)
	if specimens.is_empty():
		return panel
	v.add_child(UIFactory.hsep())
	var head=HBoxContainer.new()
	v.add_child(head)
	head.add_child(UIFactory.label("UNIT QUALITY",12,Color("#d5c59a")))
	head.add_child(UIFactory.spacer())
	head.add_child(UIFactory.label("Prefix chance %d%% · Elite ≈ 1/96"%int(round(UnitRoster.PREFIX_CHANCE*100.0)),10,Color("#7886a6")))
	var row=HBoxContainer.new()
	row.add_theme_constant_override("separation",8)
	v.add_child(row)
	for i in min(4,specimens.size()):
		var record:Dictionary=specimens[i]
		var card=PanelContainer.new()
		card.custom_minimum_size=Vector2(150,78)
		var border=Color("#c797ee") if bool(record.get("elite",false)) else Color("#394965")
		card.add_theme_stylebox_override("panel",UIFactory.panel(Color("#111827"),8,border))
		row.add_child(card)
		var inner=HBoxContainer.new()
		inner.add_theme_constant_override("separation",7)
		card.add_child(inner)
		var art=TextureRect.new()
		art.custom_minimum_size=Vector2(46,58)
		art.texture=VisualAtlas.texture(VisualAtlas.unit_sprite_id(unit))
		art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		inner.add_child(art)
		var text=VBoxContainer.new()
		text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		inner.add_child(text)
		text.add_child(UIFactory.label(UnitRoster.quality_line(record),11,Color("#e4d4ac") if not bool(record.get("elite",false)) else Color("#ddb9ff")))
		var prefix:String=String(record.get("prefix",""))
		if prefix!="":
			text.add_child(UIFactory.label(String(UnitRoster.prefix_data(prefix).get("description","")),9,Color("#8f9db8")))
		elif bool(record.get("elite",false)):
			text.add_child(UIFactory.label("Rare radiant specimen · stronger and faster.",9,Color("#a99bc0")))
	if specimens.size()>4:
		row.add_child(UIFactory.label("+%d more"%(specimens.size()-4),10,Color("#7f8ca5")))
	return panel
