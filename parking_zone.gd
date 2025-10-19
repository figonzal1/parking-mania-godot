extends Area2D

signal parked_successfully

@export var truck_path: NodePath
@export var speed_threshold: float = 10.0  # Velocidad máxima permitida
@export var check_interval: float = 0.2  # Intervalo de verificación en segundos

var truck: RigidBody2D
var truck_collision_shape: CollisionShape2D
var parking_collision_shape: CollisionShape2D
var is_truck_inside: bool = false
var check_timer: float = 0.0

func _ready():
	if truck_path:
		truck = get_node(truck_path)
		print("Camión detectado:", truck.name)
		
		# Obtener las collision shapes
		truck_collision_shape = truck.get_node("CollisionShape2D")
		parking_collision_shape = get_node("CollisionShape2D")
		
		# Conectar señales
		self.body_entered.connect(_on_body_entered)
		self.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body == truck:
		is_truck_inside = true
		print("🚛 Camión entrando al área...")

func _on_body_exited(body: Node) -> void:
	if body == truck:
		is_truck_inside = false
		print("🚛 Camión salió del área")

func _process(delta):
	if not is_truck_inside or not truck:
		return
	
	check_timer += delta
	if check_timer < check_interval:
		return
	
	check_timer = 0.0
	
	# Verificar si el camión está completamente dentro
	if is_truck_completely_inside() and truck.linear_velocity.length() < speed_threshold:
		print("🅿️ Estacionado correctamente!")
		emit_signal("parked_successfully")

func is_truck_completely_inside() -> bool:
	if not truck_collision_shape or not parking_collision_shape:
		return false
	
	# Obtener las formas y transformaciones
	var truck_shape = truck_collision_shape.shape as RectangleShape2D
	var parking_shape = parking_collision_shape.shape as RectangleShape2D
	
	if not truck_shape or not parking_shape:
		return false
	
	# Obtener las transformaciones globales
	var truck_transform = truck.global_transform * truck_collision_shape.transform
	var parking_transform = global_transform * parking_collision_shape.transform
	
	# Obtener los tamaños
	var truck_size = truck_shape.size
	var parking_size = parking_shape.size
	
	# Calcular las esquinas del camión (rotadas)
	var truck_corners = [
		truck_transform * Vector2(-truck_size.x/2, -truck_size.y/2),
		truck_transform * Vector2(truck_size.x/2, -truck_size.y/2),
		truck_transform * Vector2(truck_size.x/2, truck_size.y/2),
		truck_transform * Vector2(-truck_size.x/2, truck_size.y/2)
	]
	
	# Calcular el rectángulo del parking
	var parking_center = parking_transform.origin
	var parking_rect = Rect2(
		parking_center - parking_size / 2,
		parking_size
	)
	
	# Verificar si todas las esquinas del camión están dentro del rectángulo de parking
	for corner in truck_corners:
		if not parking_rect.has_point(corner):
			return false
	
	return true
