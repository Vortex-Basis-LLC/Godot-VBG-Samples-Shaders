extends Node3D

@onready var kuwahara: MeshInstance3D = $Kuwahara


func _input(event: InputEvent) -> void:
	# Toggle Kuwahara filter if space bar is pressed.
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.is_pressed() && key_event.keycode == KEY_SPACE:
			kuwahara.visible = !kuwahara.visible
