extends Node3D
class_name DayNight

# DayNight is a deliberately minimal day/night clock plus the sleep action's
# screen fade. It exists only to make sleep meaningful (advancing time), not to
# be a full lighting system, per the M2 scope note. RENDER-side.
#
# It builds its own sun (DirectionalLight3D), a WorldEnvironment for sky/ambient,
# and a fullscreen fade overlay in code so the main scene stays small.

# Seconds of real time for one full day/night cycle. Short so a playtester sees
# the cycle without waiting.
const DAY_LENGTH_SECONDS := 240.0

# time_of_day is 0..1: 0.0 = midnight, 0.25 = sunrise, 0.5 = noon, 0.75 = sunset.
var time_of_day := 0.30
var day_count := 0
var _sleeping := false

var _sun: DirectionalLight3D
var _env: WorldEnvironment
var _fade: ColorRect


func _ready() -> void:
	_sun = DirectionalLight3D.new()
	_sun.shadow_enabled = true
	add_child(_sun)

	_env = WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 1.0
	_env.environment = environment
	add_child(_env)

	# Fullscreen fade overlay on its own CanvasLayer so it draws over the 3D view.
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.anchor_right = 1.0
	_fade.anchor_bottom = 1.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)

	_apply_time()


func _process(delta: float) -> void:
	if _sleeping:
		return
	time_of_day = fmod(time_of_day + delta / DAY_LENGTH_SECONDS, 1.0)
	_apply_time()


# Map time_of_day to sun orientation and light/ambient energy.
func _apply_time() -> void:
	# The sun pitches from the horizon at sunrise (0.25), to straight down at
	# noon (0.5), to the horizon again at sunset (0.75). A DirectionalLight3D
	# shines along its local -Z, so rotation.x = -PI/2 points it at the ground.
	# A small yaw gives a nicer raking angle than a perfectly vertical noon sun.
	var pitch := -(time_of_day - 0.25) * TAU
	_sun.rotation = Vector3(pitch, 0.35, 0.0)

	# Daylight strength: how far the sun is above the horizon (1 at noon, 0 at
	# the horizon, clamped to 0 through the night).
	var daylight := clampf(-sin(pitch), 0.0, 1.0)
	_sun.light_energy = lerpf(0.03, 1.1, daylight)
	_sun.visible = daylight > 0.0
	if _env.environment != null:
		_env.environment.ambient_light_energy = lerpf(0.08, 1.0, daylight)


# Sleep: fade to black, jump the clock forward to the next sunrise, fade back.
# Advances day_count. No-op if already mid-sleep.
func sleep() -> void:
	if _sleeping:
		return
	_sleeping = true
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, 0.6)
	tween.tween_callback(_advance_to_morning)
	tween.tween_interval(0.4)
	tween.tween_property(_fade, "color:a", 0.0, 0.8)
	tween.tween_callback(func(): _sleeping = false)


func _advance_to_morning() -> void:
	# If it is already past sunrise, sleeping rolls over to the next day.
	if time_of_day >= 0.25:
		day_count += 1
	time_of_day = 0.28
	_apply_time()


func time_string() -> String:
	var total_minutes := int(round(time_of_day * 24.0 * 60.0))
	var hh := total_minutes / 60
	var mm := total_minutes % 60
	return "Day %d  %02d:%02d" % [day_count, hh, mm]
