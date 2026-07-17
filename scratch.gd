extends SceneTree

func _initialize() -> void:
	var grade = Color(1.0, 0.95, 0.88)
	var modulate = Color(1.0, 1.0 / 0.95, 1.0 / 0.88)
	
	var c1 = Color(0.760784, 0.780392, 0.788235)
	var final1 = c1 * modulate * grade
	print("Stop 0 final hue: ", final1.h * 360.0)

	var c2 = Color(0.639216, 0.678431, 0.686275)
	var final2 = c2 * modulate * grade
	print("Stop 1 final hue: ", final2.h * 360.0)
	
	var c3 = Color(0.580392, 0.619608, 0.639216)
	var final3 = c3 * modulate * grade
	print("Stop 2 final hue: ", final3.h * 360.0)
	
	quit(0)
