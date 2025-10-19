extends Area2D

signal parked_successfully

# Referencia al camión
@export var truck_path: NodePath


# Called when the node enters the scene tree for the first time.
func _ready():
	if truck_path:
		var truck = get_node(truck_path)
		connect("body_entered", Callable(self, "_on_body_entered").bind(truck))


func _on_body_entered(body, truck):
	if body == truck:
		# Verifica que el camión esté detenido
		if truck.linear_velocity.length() < 10.0:
			print("🅿️ Estacionado correctamente!")
			emit_signal("parked_successfully")
