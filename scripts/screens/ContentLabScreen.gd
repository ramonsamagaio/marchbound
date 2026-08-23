extends Control

const CONTENT_EDITOR_SCENE:=preload("res://scenes/ui/ContentEditor.tscn")

func _ready()->void:
	var editor:=CONTENT_EDITOR_SCENE.instantiate()
	editor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(editor)
