extends CharacterBody3D

@export var mouse_camera_rotation_speed := Vector2(0.01, 0.01)
@export var joystick_camera_rotation_speed := Vector2(5.0, 5.0)

@export var max_vertical_look_angle := PI / 2.5
@export var min_vertical_look_angle := -PI / 2.5

@onready var camera_holder: Node3D = %CameraHolder
@onready var camera_3d: Camera3D = %Camera3D

const SPEED = 5.0

func _physics_process(delta: float) -> void:
	var up_down_axis := Input.get_axis("move_vertical_down", "move_vertical_up")
	var input_vec := Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	var direction := (transform.basis * Vector3(input_vec.x, 0, input_vec.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	if up_down_axis:
		velocity.y = up_down_axis * SPEED
	else:
		velocity.y = move_toward(velocity.y, 0, SPEED)

	move_and_slide()
	
	# camera look
	var look_dir_y := Input.get_axis("look_down", "look_up")
	
	var look_dir_x := Input.get_axis("look_left", "look_right")		
	self.rotate_y(-look_dir_x * joystick_camera_rotation_speed.x * delta)
	set_vertical_look_angle(camera_3d.rotation.x + (look_dir_y * joystick_camera_rotation_speed.y * delta))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		self.rotate_y(-event.relative.x * mouse_camera_rotation_speed.x)
		set_vertical_look_angle(camera_3d.rotation.x + -event.relative.y * mouse_camera_rotation_speed.y)


func set_vertical_look_angle(new_rotation_x: float) -> void:
	camera_3d.rotation.x = clampf(new_rotation_x, min_vertical_look_angle, max_vertical_look_angle)
