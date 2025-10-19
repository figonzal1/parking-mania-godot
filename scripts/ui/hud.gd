extends CanvasLayer
# HUD - Indicador de volante profesional

## Referencia al volante
@onready var steering_wheel: Sprite2D = $SteeringWheelContainer/SteeringWheel

## Configuración de animación (ajustables en el Inspector)
@export var max_visual_rotation: float = 1080.0  # Rotación visual máxima (3 vueltas)
@export var rotation_speed: float = 1200.0  # Velocidad máxima en grados/segundo (controla qué tan rápido gira)
@export var smoothing: float = 0.45 # Suavizado de 0 a 1 (0.05=muy suave, 0.3=responsive)

## Referencia al camión
var truck: RigidBody2D

## Variables de animación
var target_rotation: float = 0.0  # Rotación objetivo
var current_rotation: float = 0.0  # Rotación actual (suavizada)

func _ready():
	# Buscar el camión automáticamente
	var level = get_parent()
	if level and level.has_node("Truck"):
		truck = level.get_node("Truck")
		print("🎮 HUD: Camión encontrado")
	else:
		print("❌ HUD: No se encontró el camión")
		# Intentar buscar en toda la escena
		truck = get_tree().get_first_node_in_group("truck")
		if truck:
			print("🎮 HUD: Camión encontrado por grupo")

func _process(_delta):
	update_steering_wheel(_delta)

## Actualizar rotación del volante con animación suave
func update_steering_wheel(delta: float):
	if not steering_wheel or not truck:
		return
	
	# Obtener el porcentaje de giro del volante del camión (-1 a +1)
	if truck.has_method("get_steering_wheel_percentage"):
		var steering_percentage = truck.get_steering_wheel_percentage()
		
		# Calcular la rotación objetivo
		target_rotation = steering_percentage * max_visual_rotation
		
		# Sistema híbrido: velocidad controlada + suavizado
		# Paso 1: Calcular hacia dónde queremos ir con velocidad limitada
		var angle_delta = target_rotation - current_rotation
		var max_change = rotation_speed * delta
		var speed_limited_target = current_rotation + clamp(angle_delta, -max_change, max_change)
		
		# Paso 2: Aplicar suavizado sobre el movimiento limitado por velocidad
		current_rotation = lerp(current_rotation, speed_limited_target, smoothing)
		
		# Aplicar la rotación
		steering_wheel.rotation_degrees = current_rotation
