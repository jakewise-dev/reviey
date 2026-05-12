extends Camera2D

var target_zoom = 1.0
var zoom_speed = 0.1
var min_zoom = 0.5
var max_zoom = 2.0

func _unhandled_input(event):
	# 1. Zooming with Mouse Wheel
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom = clamp(target_zoom + zoom_speed, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom = clamp(target_zoom - zoom_speed, min_zoom, max_zoom)
			
	# 2. Panning/Dragging the Map
	if event is InputEventMouseMotion:
		if event.button_mask == MOUSE_BUTTON_MASK_MIDDLE or (event.button_mask == MOUSE_BUTTON_MASK_LEFT and Input.is_key_pressed(KEY_SPACE)):
			position -= event.relative / zoom
			
func _process(delta):
	# Smoothly interpolate the zoom
	zoom = zoom.lerp(Vector2(target_zoom, target_zoom), 0.1)
