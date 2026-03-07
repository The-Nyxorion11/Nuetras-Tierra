extends Node
class_name HungerComponent

# --- SEÑALES ---
signal hambre_actualizada(hambre_actual, hambre_maxima)
signal murio_de_hambre

# --- CONFIGURACIÓN ---
@export_group("Configuración")
@export var hambre_maxima: float = 100.0
@export var tasa_desgaste: float = 0.5    # Hambre que pierde por segundo
@export var daño_por_hambre: float = 2.0  # Daño a la salud si el hambre es 0

var hambre_actual: float

func _ready():
	hambre_actual = hambre_maxima
	# Esperar un frame para asegurar que el HUD esté listo para recibir la señal
	await get_tree().process_frame
	hambre_actualizada.emit(hambre_actual, hambre_maxima)

func _physics_process(delta):
	if hambre_actual > 0:
		hambre_actual -= tasa_desgaste * delta
		hambre_actual = max(hambre_actual, 0)
		hambre_actualizada.emit(hambre_actual, hambre_maxima)
	else:
		# Si llega a 0, emitimos señal de que el jugador debe recibir daño
		# Pasamos delta para que el daño sea constante por segundo
		murio_de_hambre.emit(delta)

# Función para cuando el jugador encuentre comida o use consumibles
func comer(cantidad: float):
	hambre_actual = clamp(hambre_actual + cantidad, 0, hambre_maxima)
	hambre_actualizada.emit(hambre_actual, hambre_maxima)
