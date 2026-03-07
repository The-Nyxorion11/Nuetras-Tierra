extends Label

# --- SHADER ---
var tiempo_acumulado: float = 0.0

# --- DURACION ---
const DURACION_TOTAL: float = 4.0

var progreso_actual: float = 0.0
var mostrando:       bool  = false
var timer_actual:    float = 0.0

# --- COLA DE MENSAJES ---
var cola: Array[Dictionary] = []

# --- MENSAJES POR CATEGORIA ---
const MENSAJES = {
	"golpe_leve": [
		"Eso dolió un poco...",
		"Cuidado ahí.",
		"¡Ay!",
		"Raspón nomás.",
		"Eso dejó marca."
	],
	"golpe_fuerte": [
		"¡Eso sí dolió!",
		"¡Juepucha, qué golpe!",
		"Estás mal, busca ayuda.",
		"¡Cuidado que te matan!",
		"Eso estuvo feo..."
	],
	"poca_vida": [
		"Estás muy mal, descansa.",
		"No aguantas más golpes.",
		"Busca algo pa curarte.",
		"¡Estás al límite!",
		"Un golpe más y quedas."
	],
	"vida_critica": [
		"¡VAS A MORIR!",
		"¡Corre, estás muy mal!",
		"Necesitas curarte YA.",
		"¡Aguanta, aguanta!",
		"¡Esto se pone feo!"
	],
	"hambre_leve": [
		"Algo de hambre tengo...",
		"Se me antoja algo.",
		"El estómago habló.",
		"Ya es hora de comer.",
		"Uyy, el estómago..."
	],
	"hambre_media": [
		"Necesito comer algo.",
		"El hambre ya jode.",
		"Busca comida pronto.",
		"Llevas rato sin comer.",
		"El cuerpo pide comida."
	],
	"hambre_fuerte": [
		"¡Tengo un hambre berraca!",
		"Si no como me desmayo.",
		"¡Consigue comida ya!",
		"El estómago ya protesta.",
		"¡Estoy muriendo de hambre!"
	],
	"hambre_critica": [
		"¡Me muero de hambre!",
		"¡COME ALGO YA!",
		"No puedo más sin comida.",
		"¡El cuerpo ya no da más!",
		"¡Consigue comida o te caes!"
	],
	"corriendo": [
		"¡A correr se dijo!",
		"¡Piernas pa que las quiero!",
		"¡Dale que se puede!",
		"¡Saliste en chiva!",
		"¡Volando, parce!"
	],
	"generico": [
		"Hay que seguir.",
		"Esto no es fácil.",
		"Pon cuidado por ahí.",
		"El trabajo llama.",
		"No te distraigas."
	]
}

func _ready() -> void:
	_configurar_fuente()
	text       = ""
	modulate.a = 0.0
	if material:
		material.set_shader_parameter("progreso",     0.0)
		material.set_shader_parameter("tiempo_juego", 0.0)
		material.set_shader_parameter("color_texto",  Vector3(1.0, 1.0, 1.0))

func _configurar_fuente() -> void:
	var fuente := FontFile.new()
	fuente.load_dynamic_font("res://font/bebas_neue/BebasNeue-Regular.woff")

	var fuente_settings          := LabelSettings.new()
	fuente_settings.font          = fuente
	fuente_settings.font_size     = 32        # <- sube este número
	fuente_settings.line_spacing  = 6.0
	fuente_settings.outline_color = Color(0.0, 0.0, 0.0, 0.95)
	fuente_settings.outline_size  = 4
	fuente_settings.shadow_color  = Color(0.0, 0.0, 0.0, 0.6)
	fuente_settings.shadow_size   = 3
	fuente_settings.shadow_offset = Vector2(2.0, 3.0)

	label_settings       = fuente_settings
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART

	# Tamaño mínimo del label más generoso
	custom_minimum_size = Vector2(400.0, 80.0)

func _process(delta: float) -> void:
	tiempo_acumulado += delta
	if material:
		material.set_shader_parameter("tiempo_juego", tiempo_acumulado)

	if mostrando:
		timer_actual    += delta
		progreso_actual  = clamp(timer_actual / DURACION_TOTAL, 0.0, 1.0)
		if material:
			material.set_shader_parameter("progreso", progreso_actual)
		if timer_actual >= DURACION_TOTAL:
			_terminar_notificacion()
	elif cola.size() > 0:
		_mostrar_siguiente()

# --- API PUBLICA ---

func notificar(categoria: String, color: Color = Color.WHITE) -> void:
	if not MENSAJES.has(categoria): return
	var lista: Array  = MENSAJES[categoria]
	var msg:   String = lista[randi() % lista.size()]
	_encolar(msg, color)

func notificar_texto(mensaje: String, color: Color = Color.WHITE) -> void:
	_encolar(mensaje, color)

# --- INTERNO ---

func _encolar(mensaje: String, color: Color) -> void:
	cola.append({"texto": mensaje, "color": color})

func _mostrar_siguiente() -> void:
	var siguiente: Dictionary = cola.pop_front()
	text            = siguiente["texto"]
	timer_actual    = 0.0
	progreso_actual = 0.0
	mostrando       = true
	modulate.a      = 1.0

	var c: Color = siguiente["color"]
	if material:
		material.set_shader_parameter("color_texto", Vector3(c.r, c.g, c.b))
		material.set_shader_parameter("progreso",    0.0)

func _terminar_notificacion() -> void:
	mostrando  = false
	text       = ""
	modulate.a = 0.0
	if material:
		material.set_shader_parameter("progreso", 0.0)
