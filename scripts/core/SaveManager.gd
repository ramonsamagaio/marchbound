extends Node

const SAVE_PATH := "user://marchbound_save.json"
const SAVE_VERSION := 2
var last_save_unix := 0
var autosave_accumulator := 0.0
var economy_accumulator := 0.0

func _ready() -> void:
	await get_tree().process_frame
	load_game()
	last_save_unix = int(Time.get_unix_time_from_system())

func _process(delta:float) -> void:
	economy_accumulator += delta; autosave_accumulator += delta
	if economy_accumulator >= 1.0:
		GameState.tick_economy(economy_accumulator); economy_accumulator=0.0
	if autosave_accumulator >= 12.0:
		save_game(); autosave_accumulator=0.0

func save_game() -> void:
	var payload={
		"version":SAVE_VERSION,
		"saved_at":int(Time.get_unix_time_from_system()),
		"game":GameState.to_dict(),
		"retention":RetentionManager.to_dict()
	}
	var file=FileAccess.open(SAVE_PATH,FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(payload)); file.close(); last_save_unix=payload.saved_at

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH): return
	var file=FileAccess.open(SAVE_PATH,FileAccess.READ)
	if not file: return
	var text=file.get_as_text(); file.close(); var data=JSON.parse_string(text)
	if typeof(data)!=TYPE_DICTIONARY or not data.has("game"): return
	GameState.from_dict(data.game)
	if data.has("retention") and data.retention is Dictionary:
		RetentionManager.from_dict(Dictionary(data.retention))
	else:
		RetentionManager.reset(false)
	var saved_at=int(data.get("saved_at",Time.get_unix_time_from_system())); apply_offline_progress(saved_at)

func apply_offline_progress(saved_at:int) -> void:
	var now=int(Time.get_unix_time_from_system()); var elapsed=clamp(now-saved_at,0,8*60*60)
	if elapsed<30: return
	var income=GameState.resource_income_per_minute(); var bundle={}
	for key in income: bundle[key]=income[key]*elapsed/60.0
	GameState.add_resources(bundle); GameState.toast_requested.emit("Your settlement worked for %s while you were away." % format_duration(elapsed))

func format_duration(seconds:int) -> String:
	var hours=seconds/3600; var minutes=(seconds%3600)/60
	if hours>0: return "%dh %dm" % [hours,minutes]
	return "%dm" % minutes

func wipe_save() -> void:
	if FileAccess.file_exists(SAVE_PATH): DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	GameState.reset_new_game(); RetentionManager.reset(); save_game()
