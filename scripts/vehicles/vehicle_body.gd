class_name VehicleBody
extends RigidBody2D

# Requires child Marker2D nodes: FrontAxle, RearAxle (HitchPoint optional, used by trailers)
@export var stats: VehicleStats

var steering_wheel_position: float = 0.0  # degrees, -max_steering_wheel_angle to +max
var current_wheel_angle: float = 0.0      # degrees, actual wheel turn
var current_speed: float = 0.0            # px/s, positive = forward

@onready var _front_axle: Marker2D = $FrontAxle
@onready var _rear_axle: Marker2D = $RearAxle

var _steering_speed: float  # deg/s computed from lock_to_lock_time_s
var _throttle_state: float = 0.0  # filtered throttle input (0..1 or -1..0)

func _ready() -> void:
	assert(stats != null, "VehicleBody requires a VehicleStats resource assigned to 'stats'")
	assert(_front_axle != null, "VehicleBody requires a FrontAxle Marker2D child node")
	assert(_rear_axle != null, "VehicleBody requires a RearAxle Marker2D child node")

	mass = stats.mass
	center_of_mass = Vector2(0.0, stats.cog_y_offset)
	gravity_scale = 0.0
	linear_damp = 0.3
	angular_damp = 2.5

	_steering_speed = stats.max_steering_wheel_angle_deg / stats.lock_to_lock_time_s

func _physics_process(delta: float) -> void:
	var input_accel := Input.get_action_strength("ui_up") - Input.get_action_strength("ui_down")
	var input_steer := Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")

	var heading := Vector2.UP.rotated(rotation)
	current_speed = linear_velocity.dot(heading)

	_update_steering_wheel(input_steer, delta)
	_update_throttle(input_accel, delta)
	_apply_engine_and_brake(input_accel, heading)
	_apply_lateral_forces()
	_apply_deceleration_forces(input_accel, heading)

func _update_steering_wheel(input: float, delta: float) -> void:
	if input != 0.0:
		steering_wheel_position += input * _steering_speed * delta
		steering_wheel_position = clamp(
			steering_wheel_position,
			-stats.max_steering_wheel_angle_deg,
			stats.max_steering_wheel_angle_deg
		)
	else:
		# Auto-center only while moving (simulates caster self-aligning torque).
		# Return rate scales with speed: stopped = no return, fast = full return.
		var speed_factor := minf(abs(current_speed) / 100.0, 1.0)
		if speed_factor > 0.0:
			steering_wheel_position *= exp(-stats.steering_return_factor * speed_factor * delta)
			if abs(steering_wheel_position) < 0.5:
				steering_wheel_position = 0.0

	current_wheel_angle = (steering_wheel_position / stats.max_steering_wheel_angle_deg) \
		* stats.max_wheel_angle_deg

func _update_throttle(input: float, delta: float) -> void:
	if stats.throttle_response_time > 0.0:
		# First-order lag: _throttle_state converges toward input
		_throttle_state += (input - _throttle_state) * (1.0 - exp(-delta / stats.throttle_response_time))
	else:
		_throttle_state = input

func _apply_engine_and_brake(raw_input: float, heading: Vector2) -> void:
	# Brakes use raw input (no lag — pedal response is mechanical)
	if raw_input > 0.0 and current_speed < -5.0:
		apply_central_force(heading * stats.brake_force * raw_input)
		return
	if raw_input < 0.0 and current_speed > 5.0:
		apply_central_force(heading * stats.brake_force * raw_input)
		return

	# Engine force uses filtered throttle and tapers off near max speed
	if _throttle_state > 0.0 and current_speed > -5.0:
		var speed_ratio := clampf(current_speed / stats.max_speed_forward, 0.0, 1.0)
		var taper := 1.0 - speed_ratio * speed_ratio
		apply_central_force(heading * stats.engine_force * _throttle_state * taper)
	elif _throttle_state < 0.0 and current_speed < 5.0:
		var speed_ratio := clampf(-current_speed / stats.max_speed_reverse, 0.0, 1.0)
		var taper := 1.0 - speed_ratio * speed_ratio
		apply_central_force(heading * stats.engine_force * stats.reverse_force_ratio * _throttle_state * taper)

func _apply_lateral_forces() -> void:
	# Axle offsets in world space (relative to body origin, rotated)
	var front_offset := _front_axle.position.rotated(rotation)
	var rear_offset := _rear_axle.position.rotated(rotation)

	# Velocity at each axle: v_axle = v_cm + omega x r
	# In 2D: omega x r = Vector2(-r.y, r.x) * angular_velocity
	var v_front := linear_velocity + Vector2(-front_offset.y, front_offset.x) * angular_velocity
	var v_rear := linear_velocity + Vector2(-rear_offset.y, rear_offset.x) * angular_velocity

	# Lateral (sideways) direction for each axle; front axle is steered
	var steer_rad := deg_to_rad(current_wheel_angle)
	var front_right := Vector2.RIGHT.rotated(rotation + steer_rad)
	var rear_right := Vector2.RIGHT.rotated(rotation)

	# Lateral velocity component at each axle
	var lat_v_front := v_front.dot(front_right)
	var lat_v_rear := v_rear.dot(rear_right)

	# Corrective lateral force opposing the slip
	var f_front := clampf(
		-stats.cornering_stiffness_front * lat_v_front,
		-stats.lateral_force_max,
		stats.lateral_force_max
	)
	var f_rear := clampf(
		-stats.cornering_stiffness_rear * lat_v_rear,
		-stats.lateral_force_max,
		stats.lateral_force_max
	)

	# Apply at axle positions — this generates torque automatically
	apply_force(front_right * f_front, front_offset)
	apply_force(rear_right * f_rear, rear_offset)

func _apply_deceleration_forces(raw_input: float, heading: Vector2) -> void:
	if abs(current_speed) < 0.5:
		return
	var resistance := stats.rolling_resistance
	if absf(raw_input) < 0.01:
		# Off-throttle: add engine braking proportional to speed
		resistance += stats.engine_brake_coef * abs(current_speed)
	apply_central_force(-heading * sign(current_speed) * resistance)

# --- Public API used by HUD and other systems ---

func get_speed_kmh() -> float:
	return abs(current_speed) * (3.6 / VehicleStats.PX_PER_M)

func get_steering_wheel_percentage() -> float:
	return steering_wheel_position / stats.max_steering_wheel_angle_deg

func get_steering_wheel_turns() -> float:
	return steering_wheel_position / 360.0
