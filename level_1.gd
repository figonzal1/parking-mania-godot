extends Node2D

# Referencias a nodos
@onready var truck: RigidBody2D = $Truck
@onready var parking_zone: Area2D = $ParkingZone

# Parámetros de parking
@export var speed_threshold: float = 5.0  # velocidad máxima para considerar estacionado
@export var angle_threshold: float = 15.0  # tolerancia de orientación en grados

func _ready():
	# Configurar truck_path en la zona de parking
	if parking_zone.has_method("set_truck"):
		parking_zone.call("set_truck", truck)
	else:
		# Si usamos propiedad export
		parking_zone.truck_path = truck.get_path()
	
	# Conectar señal
	parking_zone.connect("parked_successfully", Callable(self, "_on_parked_successfully"))
	print("🎮 Nivel iniciado")

func _on_parked_successfully():
	print("✅ Nivel completado!")
	# Espera 1.5 segundos antes de reiniciar nivel
	await get_tree().create_timer(1.5).timeout
	# Reinicia el nivel (o cambiar a siguiente)
	get_tree().reload_current_scene()
