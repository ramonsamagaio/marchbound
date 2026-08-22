extends Control

var active_box:VBoxContainer
var board_box:VBoxContainer
var summary:VBoxContainer

func _ready()->void:
	_build()
	ContractManager.changed.connect(refresh)
	GameState.changed.connect(refresh)
	refresh()

func _exit_tree()->void:
	if ContractManager.changed.is_connected(refresh):
		ContractManager.changed.disconnect(refresh)
	if GameState.changed.is_connected(refresh):
		GameState.changed.disconnect(refresh)

func _build()->void:
	var margin=MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",24)
	margin.add_theme_constant_override("margin_right",24)
	margin.add_theme_constant_override("margin_top",18)
	margin.add_theme_constant_override("margin_bottom",18)
	add_child(margin)
	var root=HBoxContainer.new()
	root.add_theme_constant_override("separation",16)
	margin.add_child(root)

	var left=VBoxContainer.new()
	left.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	root.add_child(left)
	var head=HBoxContainer.new()
	left.add_child(head)
	head.add_child(UIFactory.title("Frontier Contracts",28))
	head.add_child(UIFactory.spacer())
	var reroll=UIFactory.button("Refresh Board",func():ContractManager.reroll_board(),Color("#4a3e57"))
	reroll.custom_minimum_size.x=125
	head.add_child(reroll)
	left.add_child(UIFactory.label("Take work that bends your next expeditions toward a goal. Contracts are optional, persistent and designed to create a reason for one more run.",13,Color("#9ca8c5")))
	left.add_child(UIFactory.hsep())
	var scroll=ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	left.add_child(scroll)
	board_box=VBoxContainer.new()
	board_box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	board_box.add_theme_constant_override("separation",10)
	scroll.add_child(board_box)

	var right=PanelContainer.new()
	right.custom_minimum_size.x=390
	right.add_theme_stylebox_override("panel",UIFactory.panel(Color("#141a29"),12,Color("#34405d")))
	root.add_child(right)
	var side_scroll=ScrollContainer.new()
	right.add_child(side_scroll)
	summary=VBoxContainer.new()
	summary.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	summary.add_theme_constant_override("separation",8)
	side_scroll.add_child(summary)

func refresh()->void:
	if not is_inside_tree():
		return
	UIFactory.clear_children(board_box)
	board_box.add_child(UIFactory.label("AVAILABLE WRITS",15,Color("#f0dfae")))
	if ContractManager.available.is_empty():
		board_box.add_child(UIFactory.label("No open writs. Complete or refresh the board.",13,Color("#8f9bb8")))
	else:
		for contract in ContractManager.available:
			board_box.add_child(_available_card(contract))

	UIFactory.clear_children(summary)
	summary.add_child(UIFactory.title("Contract Log",23))
	summary.add_child(UIFactory.label("Active %d / %d · Completed %d"%[ContractManager.active.size(),ContractManager.MAX_ACTIVE,ContractManager.completed_count],13,Color("#a8d2aa")))
	summary.add_child(UIFactory.label("Board refresh: %d Gold"%ContractManager.reroll_cost(),11,Color("#9ca8c5")))
	summary.add_child(UIFactory.hsep())
	if ContractManager.active.is_empty():
		summary.add_child(UIFactory.label("No active contracts. Pick a writ from the board and let it shape the next march.",12,Color("#8f9bb8")))
	else:
		for contract in ContractManager.active:
			summary.add_child(_active_card(contract))
	summary.add_child(UIFactory.hsep())
	summary.add_child(UIFactory.label("WHY THIS EXISTS",13,Color("#f0dfae")))
	summary.add_child(UIFactory.label("The contract board is a second layer over the core loop. A good contract should make a tile, boss or extra expedition suddenly feel worth doing without becoming mandatory busywork.",11,Color("#8f9bb8")))

func _available_card(contract:Dictionary)->PanelContainer:
	var p=PanelContainer.new()
	p.add_theme_stylebox_override("panel",UIFactory.panel(Color("#181f31"),10,Color("#35415f")))
	var v=VBoxContainer.new()
	p.add_child(v)
	var h=HBoxContainer.new()
	v.add_child(h)
	h.add_child(UIFactory.label(String(contract.title),18,Color("#eadfbf")))
	h.add_child(UIFactory.spacer())
	var accept=UIFactory.button("Accept",func(uid=String(contract.uid)):ContractManager.accept_contract(uid),Color("#3e5260"))
	accept.disabled=ContractManager.active.size()>=ContractManager.MAX_ACTIVE
	accept.custom_minimum_size.x=92
	h.add_child(accept)
	v.add_child(UIFactory.label(String(contract.description),12,Color("#9ca8c5")))
	v.add_child(UIFactory.label("Reward  %s · Renown +%d"%[UIFactory.cost_text(contract.reward),int(contract.renown)],11,Color("#c9b57d")))
	return p

func _active_card(contract:Dictionary)->PanelContainer:
	var p=PanelContainer.new()
	var ready:=ContractManager.is_complete(contract)
	p.add_theme_stylebox_override("panel",UIFactory.panel(Color("#21312a") if ready else Color("#1a2234"),8,Color("#56705d") if ready else Color("#35415f")))
	var v=VBoxContainer.new()
	p.add_child(v)
	var row=HBoxContainer.new()
	v.add_child(row)
	row.add_child(UIFactory.label(String(contract.title),15,Color("#e5d9b7")))
	row.add_child(UIFactory.spacer())
	var current:=ContractManager.progress(contract)
	var target:=float(contract.target)
	row.add_child(UIFactory.label("%d / %d"%[int(min(current,target)),int(target)],13,Color("#9fd3a7") if ready else Color("#a8b4ce")))
	v.add_child(UIFactory.label(String(contract.description),11,Color("#98a5c2")))
	var bar=ProgressBar.new()
	bar.custom_minimum_size.y=12
	bar.show_percentage=false
	bar.max_value=max(1.0,target)
	bar.value=min(current,target)
	v.add_child(bar)
	var actions=HBoxContainer.new()
	v.add_child(actions)
	actions.add_child(UIFactory.label("%s · +%d Renown"%[UIFactory.cost_text(contract.reward),int(contract.renown)],10,Color("#c9b57d")))
	actions.add_child(UIFactory.spacer())
	if ready:
		var claim=UIFactory.button("CLAIM",func(uid=String(contract.uid)):ContractManager.claim_contract(uid),Color("#496143"))
		claim.custom_minimum_size.x=82
		actions.add_child(claim)
	else:
		var abandon=UIFactory.button("Abandon",func(uid=String(contract.uid)):ContractManager.abandon_contract(uid),Color("#4c343a"))
		abandon.custom_minimum_size.x=82
		actions.add_child(abandon)
	return p
