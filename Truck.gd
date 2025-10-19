extends RigidBody2D

@export var engine_force: float = 1000.0
@export var max_speed: float = 400.0
@export var steering_speed: float = 2.5
@export var damping_idle: float = 6.0
@export var damping_drive: float = 0.3

func _physics_process(delta):
	var accel = Input.get_action_strength("ui_up") - Input.get_action_strength("ui_down")
	var steer = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")

	var forward = Vector2.UP.rotated(rotation)

	# Aplica fuerza
	if accel != 0:
		apply_central_force(forward * accel * engine_force)
		linear_damp = damping_drive
	else:
		linear_damp = damping_idle

	# Limita velocidad
	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed

	# Girar solo si nos movemos
	if linear_velocity.length() > 5.0:
		rotation += steer * steering_speed * delta * (linear_velocity.length() / max_speed)

	# Frenado total si estamos casi quietos
	if accel == 0 and linear_velocity.length() < 5.0:
		linear_velocity = Vector2.ZERO
		angular_velocity = 0
