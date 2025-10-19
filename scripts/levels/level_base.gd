extends Node2D
# LevelBase - Clase base para todos los niveles
# Hereda de esta clase para crear nuevos niveles

## Referencias comunes
@onready var truck: RigidBody2D
@onready var parking_zone: Area2D

## Configuración del nivel
@export var level_number: int = 1
@export var time_limit: float = 180.0  # 3 minutos
@export var par_time: float = 60.0  # Tiempo para 3 estrellas

## Estado del nivel
var level_completed: bool = false
var level_failed: bool = false
var elapsed_time: float = 0.0

## Señales
signal level_started()
signal level_completed_signal(stars: int)
signal level_failed_signal()

func _ready():
	setup_level()
	connect_signals()
	start_level()

## Configuración inicial (override en niveles hijos)
func setup_level():
	# Buscar truck y parking zone automáticamente
	truck = get_node_or_null("Truck")
	parking_zone = get_node_or_null("ParkingZone")
	
	if not truck:
		push_error("❌ No se encontró el Truck en el nivel")
	if not parking_zone:
		push_error("❌ No se encontró el ParkingZone en el nivel")

## Conectar señales
func connect_signals():
	if parking_zone:
		parking_zone.parked_successfully.connect(_on_parked_successfully)

## Iniciar nivel
func start_level():
	print("🎮 Nivel", level_number, "iniciado")
	emit_signal("level_started")

## Actualizar temporizador
func _process(delta):
	if level_completed or level_failed:
		return
	
	elapsed_time += delta
	
	# Verificar límite de tiempo
	if elapsed_time >= time_limit:
		fail_level()

## Nivel completado
func _on_parked_successfully():
	if level_completed:
		return
	
	level_completed = true
	var stars = calculate_stars()
	print("✅ Nivel completado en %.1f segundos - %d estrellas" % [elapsed_time, stars])
	emit_signal("level_completed_signal", stars)
	
	# Esperar antes de cargar siguiente nivel
	await get_tree().create_timer(2.0).timeout
	
## Nivel fallado
func fail_level():
	if level_failed:
		return
	
	level_failed = true
	print("❌ Nivel fallado - Tiempo agotado")
	emit_signal("level_failed_signal")

## Calcular estrellas basado en tiempo
func calculate_stars() -> int:
	if elapsed_time <= par_time:
		return 3  # ⭐⭐⭐
	elif elapsed_time <= par_time * 1.5:
		return 2  # ⭐⭐
	else:
		return 1  # ⭐

## Reiniciar nivel
func restart():
	get_tree().reload_current_scene()

## Obtener tiempo restante
func get_remaining_time() -> float:
	return max(0, time_limit - elapsed_time)
