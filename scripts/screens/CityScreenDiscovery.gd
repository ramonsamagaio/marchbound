extends "res://scripts/screens/CityScreenVisual.gd"

func _ready() -> void:
	FrontierManager.ensure_rumor()
	super._ready()
	if not FrontierManager.changed.is_connected(refresh):
		FrontierManager.changed.connect(refresh)

func _exit_tree() -> void:
	if FrontierManager.changed.is_connected(refresh):
		FrontierManager.changed.disconnect(refresh)
	super._exit_tree()

func refresh() -> void:
	super.refresh()
	if not settlement_summary:
		return
	var rumor:Dictionary = FrontierManager.rumor()
	if bool(rumor.get("active",false)):
		var rumor_label:=UIFactory.label("RUMOR · %s near [%d,%d] · reward +%d Renown"%[String(rumor.get("name","Unknown anomaly")),int(rumor.get("x",0)),int(rumor.get("y",0)),int(rumor.get("reward_renown",0))],12,Color("#d6b9ef"))
		rumor_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		settlement_summary.add_child(rumor_label)
	var meta:Dictionary = Dictionary(GameState.world.get(FrontierManager.META_KEY,{}))
	settlement_summary.add_child(UIFactory.label("ATLAS · Insight %d · Wonder %d · Codex %d/%d · Rumors solved %d"%[FrontierManager.insight(),FrontierManager.wonder(),FrontierManager.codex_count(),FrontierManager.discovery_ids().size(),int(meta.get("rumors_resolved",0))],11,Color("#8fb9c7")))
	var marks:String = FrontierManager.mark_summary()
	if marks != "":
		settlement_summary.add_child(UIFactory.label("CAMPAIGN MARKS · "+marks,11,Color("#d79a9f")))
	var legacies:String = FrontierManager.legacy_summary()
	if legacies != "":
		var legacy_label:=UIFactory.label("WARBAND LEGACIES · "+legacies,11,Color("#a9cfab"))
		legacy_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		settlement_summary.add_child(legacy_label)
