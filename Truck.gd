extends RigidBody2D

# Parámetros del motor y aceleración
@export var engine_power: float = 600.0  # Potencia del motor (camiones pesados aceleran lento)
@export var acceleration: float = 3.5  # Aceleración progresiva (pesado = lento)
@export var braking_force: float = 10.0  # Fuerza de frenado (buenos frenos)
@export var reverse_speed_ratio: float = 0.4  # Velocidad de reversa (40% - camiones son lentos en reversa)

# Límites de velocidad (realistas para maniobras de parking)
@export var max_speed_forward: float = 150.0  # ~54 km/h (velocidad segura para parking)
@export var max_speed_reverse: float = 60.0  # ~22 km/h (reversa lenta)

# === SISTEMA DE VOLANTE REALISTA ===
# Camiones típicos: 5-6 vueltas (1800-2160°), camiones grandes: hasta 7 vueltas (2520°)
@export var max_steering_wheel_angle: float = 1800  # 5 vueltas completas (típico camión mediano)
@export var steering_speed: float = 1200.0  # Lock-to-lock en ~3 segundos (realista)
@export var steering_return_speed: float = 600.0  # Auto-centrado en ~6 seg (moderado)
@export var max_wheel_angle: float = 30.0  # Ángulo típico camión (25-35°, limitado por tamaño)
@export var wheel_base: float = 85.0  # Distancia entre ejes ~3.5-4m (escala del juego)

# Física del vehículo
@export var traction: float = 0.96  # Agarre (camiones pesados tienen buen agarre pero no perfecto)
@export var friction: float = 4.5  # Fricción alta (vehículo pesado desacelera rápido sin motor)
@export var drift_factor: float = 0.08  # Velocidad lateral permitida (camiones son menos ágiles)

# Variables internas
var current_speed: float = 0.0
var heading_direction: Vector2 = Vector2.ZERO
var steering_wheel_position: float = 0.0  # Posición actual del volante (-1800 a +1800)

func _ready():
	# Configurar propiedades del RigidBody2D para mejor simulación
	# Camiones tienen más inercia y resistencia
	linear_damp = 0.8  # Mayor resistencia al movimiento (vehículo pesado)
	angular_damp = 3.5  # Mayor resistencia a la rotación (difícil de girar)

func _physics_process(delta):
	var input_accel = Input.get_action_strength("ui_up") - Input.get_action_strength("ui_down")
	var input_steer = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	
	# Calcular la dirección actual del vehículo
	heading_direction = Vector2.UP.rotated(rotation)
	
	# Velocidad actual en la dirección de avance
	current_speed = linear_velocity.dot(heading_direction)
	
	# === SISTEMA DE VOLANTE ===
	update_steering_wheel(input_steer, delta)
	
	# === ACELERACIÓN Y FRENADO ===
	apply_acceleration(input_accel, delta)
	
	# === DIRECCIÓN (STEERING) ===
	apply_steering_with_wheel(delta)
	
	# === ANTI-DRIFT: Eliminar velocidad lateral ===
	apply_traction()
	
	# === FRICCIÓN CUANDO NO ACELERA ===
	if input_accel == 0:
		apply_friction(delta)
	
	# Frenar completamente cuando está casi detenido
	if abs(current_speed) < 5.0 and input_accel == 0:
		linear_velocity = Vector2.ZERO
		angular_velocity = 0.0

func apply_acceleration(input_accel: float, _delta: float):
	if input_accel == 0:
		return
	
	var max_speed = max_speed_forward if input_accel > 0 else max_speed_reverse
	var power = engine_power if input_accel > 0 else engine_power * reverse_speed_ratio
	
	# Aplicar aceleración progresiva
	if abs(current_speed) < max_speed:
		var force = heading_direction * input_accel * power
		apply_central_force(force)
	
	# Limitar velocidad máxima
	if current_speed > max_speed:
		linear_velocity = heading_direction * max_speed
	elif current_speed < -max_speed_reverse:
		linear_velocity = heading_direction * -max_speed_reverse

func update_steering_wheel(input_steer: float, delta: float):
	# Simular rotación del volante
	if input_steer != 0:
		# Girar el volante según el input
		steering_wheel_position += input_steer * steering_speed * delta
		# Limitar a +/- max_steering_wheel_angle
		steering_wheel_position = clamp(steering_wheel_position, -max_steering_wheel_angle, max_steering_wheel_angle)
	else:
		# Auto-centrado del volante cuando no hay input
		if abs(steering_wheel_position) > 1.0:
			var return_direction = -sign(steering_wheel_position)
			steering_wheel_position += return_direction * steering_return_speed * delta
			# Evitar que pase de 0
			if sign(steering_wheel_position) != sign(steering_wheel_position + return_direction * steering_return_speed * delta):
				steering_wheel_position = 0.0
		else:
			steering_wheel_position = 0.0

func apply_steering_with_wheel(delta: float):
	if abs(current_speed) < 5.0:
		return
	
	# Calcular el ángulo de las ruedas basado en la posición del volante
	# El volante gira 1800° para alcanzar el máximo ángulo de las ruedas
	var wheel_angle_normalized = steering_wheel_position / max_steering_wheel_angle  # -1 a +1
	var actual_wheel_angle = wheel_angle_normalized * max_wheel_angle  # en grados
	
	# Sistema de dirección tipo Ackermann (más realista)
	var steering_rad = deg_to_rad(actual_wheel_angle)
	
	# Calcular velocidad angular basada en la geometría del vehículo
	var turn_radius = wheel_base / tan(abs(steering_rad)) if abs(steering_rad) > 0.01 else 9999.0
	var angular_vel = (abs(current_speed) / turn_radius) * sign(actual_wheel_angle)
	
	# Mantener el mismo sentido de giro en reversa
	if current_speed < 0:
		angular_vel = -angular_vel
	
	# Suavizar la rotación
	var target_rotation = rotation + angular_vel * delta
	rotation = lerp_angle(rotation, target_rotation, 0.5)

func apply_traction():
	# Calcular velocidad lateral (perpendicular a la dirección del vehículo)
	var right_direction = Vector2.RIGHT.rotated(rotation)
	var lateral_velocity = right_direction * linear_velocity.dot(right_direction)
	
	# Eliminar la velocidad lateral (simula agarre de neumáticos)
	var traction_force = -lateral_velocity * traction / get_physics_process_delta_time()
	apply_central_force(traction_force)

func apply_friction(_delta: float):
	# Fricción que desacelera el vehículo cuando no se acelera
	var friction_force = -linear_velocity.normalized() * friction * 100.0
	apply_central_force(friction_force)

func get_speed_kmh() -> float:
	# Útil para mostrar velocímetro (opcional)
	return abs(current_speed) * 0.36  # Conversión aproximada a km/h

func get_steering_wheel_turns() -> float:
	# Retorna cuántas vueltas ha dado el volante (-5 a +5 para 1800°)
	return steering_wheel_position / 360.0

func get_steering_wheel_percentage() -> float:
	# Retorna el porcentaje de giro del volante (-1 a +1)
	return steering_wheel_position / max_steering_wheel_angle
