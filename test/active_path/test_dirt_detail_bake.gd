extends SceneTree

const DETAIL_PATH := "res://assets/village/ground_dirt_detail.png"
const EXPECTED_SHA256 := "9a0d28cd2a50c7c9d754bae3b4acc33d9d8962f630ff197adf1f37ae88bf6f94"
const MIN_R_STD_BYTES := 18.0
const MIN_R_MEAN_GRADIENT_BYTES := 7.0


func _initialize() -> void:
	var failures := 0
	var image := Image.load_from_file(DETAIL_PATH)
	failures += _check(image != null and not image.is_empty(), "committed dirt detail loads")
	if image == null or image.is_empty():
		quit(1)
		return
	failures += _check(image.get_width() == 1024 and image.get_height() == 1024, "dirt detail matches the 1024x1024 plate resolution")
	image.convert(Image.FORMAT_RG8)
	failures += _check(_sha256(image.get_data()) == EXPECTED_SHA256, "decoded RG8 bytes match the bake fingerprint")

	var count := image.get_width() * image.get_height()
	var mean := 0.0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			mean += image.get_pixel(x, y).r * 255.0
	mean /= count
	var variance := 0.0
	var gradient := 0.0
	var gradient_count := 0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var value := image.get_pixel(x, y).r * 255.0
			variance += (value - mean) * (value - mean)
			if x + 1 < image.get_width():
				gradient += absf(value - image.get_pixel(x + 1, y).r * 255.0)
				gradient_count += 1
			if y + 1 < image.get_height():
				gradient += absf(value - image.get_pixel(x, y + 1).r * 255.0)
				gradient_count += 1
	var std_bytes := sqrt(variance / count)
	var mean_gradient_bytes := gradient / gradient_count
	failures += _check(std_bytes >= MIN_R_STD_BYTES, "R shoulder detail is materially non-flat (std %.2f >= %.1f bytes)" % [std_bytes, MIN_R_STD_BYTES])
	failures += _check(mean_gradient_bytes >= MIN_R_MEAN_GRADIENT_BYTES, "R shoulder detail has material spatial structure (gradient %.2f >= %.1f bytes)" % [mean_gradient_bytes, MIN_R_MEAN_GRADIENT_BYTES])

	if failures == 0:
		print("\nAll dirt-detail bake checks passed.")
		quit(0)
	else:
		print("\n%d dirt-detail bake check(s) FAILED." % failures)
		quit(1)


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()


func _check(condition: bool, label: String) -> int:
	if condition:
		print("[PASS] %s" % label)
		return 0
	print("[FAIL] %s" % label)
	return 1
