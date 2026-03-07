extends CanvasLayer

# --- REFERENCIAS ---
@onready var barra_vida: ColorRect   = $ContenedorUI/BarraVida
@onready var barra_hambre: ColorRect = $ContenedorUI/BarraHambre
@onready var vinieta: Control        = $VinietaSangre
@onready var notificaciones: Label   = $ContenedorUI/Notificaciones

# --- CONFIGURACION ---
@export_group("Configuracion Visual")
@export var duracion_animacion: float = 0.3
@export var intensidad_vinieta: float = 0.7

# --- ESTADO INTERNO ---
var salud_norm_actual:  float = 1.0
var hambre_norm_actual: float = 1.0

# --- MÉTODOS PRINCIPALES ---
func _ready() -> void:
	_inicializar_ui()
	# FORZAR MODO VISIBLE Y DESBLOQUEADO
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Esto evita que al hacer click en la ventana se capture el mouse
	process_mode = PROCESS_MODE_ALWAYS
	
func _inicializar_ui() -> void:
	if vinieta:
		vinieta.modulate.a = 0.0
		vinieta.visible    = true
	if barra_vida and barra_vida.material:
		barra_vida.material.set_shader_parameter("salud",        1.0)
		barra_vida.material.set_shader_parameter("flash_danio",  0.0)
		barra_vida.material.set_shader_parameter("tiempo_juego", 0.0)
	if barra_hambre and barra_hambre.material:
		barra_hambre.material.set_shader_parameter("hambre",       1.0)
		barra_hambre.material.set_shader_parameter("tiempo_juego", 0.0)

func _process(delta: float) -> void:
	var t: float = float(Time.get_ticks_msec()) / 1000.0

	if barra_vida and barra_vida.material:
		barra_vida.material.set_shader_parameter("tiempo_juego", t)
		var flash: float = barra_vida.material.get_shader_parameter("flash_danio")
		if flash > 0.0:
			barra_vida.material.set_shader_parameter("flash_danio", maxf(flash - delta * 4.0, 0.0))

	if barra_hambre and barra_hambre.material:
		barra_hambre.material.set_shader_parameter("tiempo_juego", t)

# --- VIDA ---
func actualizar_barra_vida(valor_actual: int, valor_maximo: int) -> void:
	if not barra_vida or not barra_vida.material: return

	var nueva_norm: float = clamp(float(valor_actual) / float(valor_maximo), 0.0, 1.0)

	if nueva_norm < salud_norm_actual - 0.01:
		_disparar_efecto_sangre()
		barra_vida.material.set_shader_parameter("flash_danio", 1.0)
		# Notificacion segun nivel de vida
		if nueva_norm <= 0.1:
			notificaciones.notificar("vida_critica", Color(1.0, 0.0, 0.0))
		elif nueva_norm <= 0.25:
			notificaciones.notificar("poca_vida", Color(1.0, 0.3, 0.0))
		elif nueva_norm <= 0.5:
			notificaciones.notificar("golpe_fuerte", Color(1.0, 0.5, 0.0))
		else:
			notificaciones.notificar("golpe_leve", Color(1.0, 0.85, 0.4))

	var desde: float = salud_norm_actual
	salud_norm_actual = nueva_norm

	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_method(
		func(v: float):
			if barra_vida and barra_vida.material:
				barra_vida.material.set_shader_parameter("salud", v),
		desde,
		nueva_norm,
		duracion_animacion
	)

# --- HAMBRE ---
func actualizar_barra_hambre(actual: float, maxima: float) -> void:
	if not barra_hambre or not barra_hambre.material: return

	var nueva_norm: float = clamp(actual / maxima, 0.0, 1.0)

	if nueva_norm < hambre_norm_actual - 0.01:
		# Notificacion segun nivel de hambre
		if nueva_norm <= 0.1:
			notificaciones.notificar("hambre_critica", Color(1.0, 0.4, 0.0))
		elif nueva_norm <= 0.25:
			notificaciones.notificar("hambre_fuerte", Color(1.0, 0.6, 0.1))
		elif nueva_norm <= 0.5:
			notificaciones.notificar("hambre_media", Color(1.0, 0.8, 0.2))
		else:
			notificaciones.notificar("hambre_leve", Color(1.0, 0.95, 0.5))

	var desde: float = hambre_norm_actual
	hambre_norm_actual = nueva_norm

	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_method(
		func(v: float):
			if barra_hambre and barra_hambre.material:
				barra_hambre.material.set_shader_parameter("hambre", v),
		desde,
		nueva_norm,
		duracion_animacion + 0.1
	)

# --- EFECTOS ---
func _disparar_efecto_sangre() -> void:
	if not vinieta: return
	vinieta.modulate.a = intensidad_vinieta
	var tween := create_tween()
	tween.tween_property(vinieta, "modulate:a", 0.0, 0.5)

# --- API PUBLICA para llamar desde otros scripts ---
func mostrar_notificacion(mensaje: String, color: Color = Color.WHITE) -> void:
	if notificaciones:
		notificaciones.notificar_texto(mensaje, color)

func mostrar_notificacion_categoria(categoria: String, color: Color = Color.WHITE) -> void:
	if notificaciones:
		notificaciones.notificar(categoria, color)
