extends Node2D
const Routine = preload("res://src/sim/citizen_routine.gd")
var citizen = Routine.new()
var paused := false
var speed := 1.0
var status: Label
var pause_button: Button
var speed_slider: HSlider
var capture_mode := false

func _ready() -> void:
 RenderingServer.set_default_clear_color(Color("172329"))
 var title := Label.new()
 title.text = "LONGWALK  /  CITIZEN ROUTINE"
 title.position = Vector2(45,32)
 title.add_theme_font_size_override("font_size",28)
 add_child(title)
 var subtitle := Label.new()
 subtitle.text = "Schedule diagram: one citizen, one repeating 60-second day. No terrain or work production."
 subtitle.position = Vector2(45,78)
 subtitle.add_theme_color_override("font_color",Color("a9b9bd"))
 add_child(subtitle)
 status = Label.new()
 status.position = Vector2(45,119)
 status.add_theme_font_size_override("font_size",20)
 add_child(status)
 var controls := HBoxContainer.new()
 controls.position = Vector2(45,661)
 controls.add_theme_constant_override("separation",18)
 add_child(controls)
 pause_button = Button.new()
 pause_button.text = "Pause"
 pause_button.custom_minimum_size = Vector2(115,44)
 pause_button.pressed.connect(_toggle_pause)
 controls.add_child(pause_button)
 var reset := Button.new()
 reset.text = "Reset day"
 reset.custom_minimum_size = Vector2(120,44)
 reset.pressed.connect(_reset)
 controls.add_child(reset)
 var speed_text := Label.new()
 speed_text.text = "Simulation speed: 1.0x"
 speed_text.custom_minimum_size.x = 210
 controls.add_child(speed_text)
 speed_slider = HSlider.new()
 speed_slider.min_value = 0.25
 speed_slider.max_value = 8.0
 speed_slider.step = 0.25
 speed_slider.value = 1.0
 speed_slider.custom_minimum_size = Vector2(250,44)
 speed_slider.value_changed.connect(func(value:float):
  speed = value
  speed_text.text = "Simulation speed: %.2fx" % value)
 controls.add_child(speed_slider)
 var footer := Label.new()
 footer.text = "Home 0-10s   |   Walk 10-20s   |   Work 20-35s   |   Walk 35-40s   |   Square 40-50s   |   Homeward 50-60s"
 footer.position = Vector2(45,732)
 footer.add_theme_color_override("font_color",Color("a9b9bd"))
 add_child(footer)
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--capture="):
   capture_mode = true
   _capture(arg.trim_prefix("--capture="))

func _toggle_pause() -> void:
 paused = not paused
 pause_button.text = "Resume" if paused else "Pause"

func _reset() -> void:
 citizen = Routine.new()

func _advance(delta:float) -> void:
 if not paused:
  citizen.advance(delta*speed)

func _process(delta:float) -> void:
 if not capture_mode:
  _advance(delta)
 var current:Dictionary = citizen.state()
 status.text = "Day %d  |  %04.1f / 60 seconds  |  %s%s" % [current.day+1,current.time,current.activity,"  (paused)" if paused else ""]
 queue_redraw()

func _point(world:Vector2) -> Vector2:
 return Vector2(610,420)+world*12.0

func _draw() -> void:
 var font := ThemeDB.fallback_font
 var points := [Routine.HOME,Routine.WORK,Routine.SQUARE,Routine.HOME]
 for i in range(3):
  draw_line(_point(points[i]),_point(points[i+1]),Color("41545b"),3,true)
 var labels := [[Routine.HOME,"HOME"],[Routine.WORK,"WORK"],[Routine.SQUARE,"SQUARE"]]
 for place in labels:
  var at := _point(place[0])
  draw_circle(at,25,Color("2d454e"))
  draw_arc(at,25,0,TAU,40,Color("9caeb4"),2,true)
  draw_string(font,at+Vector2(-36,51),place[1],HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("e3eaec"))
 var location := _point(citizen.state().position)
 draw_circle(location,13,Color("e3b669"))
 draw_arc(location,18,0,TAU,32,Color("e3b669"),1.5,true)
 draw_string(font,Vector2(45,604),"Gold marker: citizen. Lines: simplified scheduled travel, without obstacle routing.",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("a9b9bd"))

func _capture(path:String) -> void:
 var valid := true
 citizen.advance(15.0)
 _toggle_pause()
 var before:float = citizen.elapsed_seconds
 _advance(1.0)
 valid = valid and citizen.elapsed_seconds == before and paused
 speed_slider.value = 2.0
 valid = valid and speed == 2.0
 _toggle_pause()
 _advance(1.0)
 valid = valid and citizen.elapsed_seconds == before+2.0
 _toggle_pause()
 _reset()
 valid = valid and citizen.elapsed_seconds == 0.0
 citizen.advance(15.0)
 speed_slider.value = 1.0
 await get_tree().process_frame
 await RenderingServer.frame_post_draw
 var error := get_viewport().get_texture().get_image().save_png(path)
 valid = valid and error == OK
 print("NPC VIEWER CHECKS PASSED: pause, speed control, reset, rendered capture" if valid else "NPC VIEWER CHECKS FAILED")
 get_tree().quit(0 if valid else 1)
