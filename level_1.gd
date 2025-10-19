extends Node2D

@onready var truck = $Truck
@onready var parking_zone = $ParkingZone

func _ready():
	parking_zone.truck_path = truck.get_path()
	parking_zone.connect("parked_successfully", Callable(self, "_on_parked_successfully"))

func _on_parked_successfully():
	print("✅ Nivel completado!")
	await get_tree().create_timer(1.5).timeout
	get_tree().reload_current_scene()  # reinicia el nivel o más adelante pasará al siguiente
