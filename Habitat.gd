extends Node2D

@export_group("Settings")
@export var habitat_type: String = "Tide" 

@export_group("Visuals")
@export var tree_texture: Texture2D
@export var glow_color: Color = Color(1, 1, 1, 1) 
@export var particle_color: Color = Color(1, 1, 1, 1)


@export_group("Setup")
@export var wisp_scene: PackedScene = preload("res://base_echo.tscn")

# 🌟 NEW: THIS HABITAT'S PERSONAL BRAIN!
var stored_ink: float = 0.0
var max_ink: float = 200.0
var resident_echoes: Array = [] # The specific echoes living in THIS tree

func _ready():
	# 1. Apply the visuals
	if tree_texture:
		%TreeSprite.texture = tree_texture
		
	%Glow.color = glow_color
	%Particles1.modulate = particle_color
	%Particles2.modulate = particle_color
	
	%CollectIcon.visible = false

	# 2. Make the collect icon bob up and down forever
	var bounce = create_tween().set_loops()
	bounce.tween_property(%CollectIcon, "position:y", %CollectIcon.position.y - 10, 1.2).set_trans(Tween.TRANS_SINE)
	bounce.tween_property(%CollectIcon, "position:y", %CollectIcon.position.y, 1.2).set_trans(Tween.TRANS_SINE)

func _process(delta):
	# 1. Calculate how much Ink THIS specific tree makes per second
	var my_ink_rate = 0.0
	var core = get_tree().root.find_child("ReverieCore", true, false)
	
	if core:
		for echo_name in resident_echoes:
			var base_name = core.get_base_name(echo_name)
			if core.echo_database.has(base_name):
				my_ink_rate += core.echo_database[base_name].ink_rate

	# 2. Generate the Ink into this tree's personal bucket
	if stored_ink < max_ink:
		stored_ink += my_ink_rate * delta
		if stored_ink > max_ink:
			stored_ink = max_ink
			
	# 3. Show the Collect Icon if we have at least 10 Ink ready!
	%CollectIcon.visible = (stored_ink >= 10.0)

# --- VISUAL EFFECTS ---
func _on_click_area_mouse_entered():
	var tween = create_tween()
	tween.tween_property(%TreeSprite, "scale", Vector2(1.05, 1.05), 0.1)
	%TreeSprite.modulate = Color(1.2, 1.2, 1.2)

func _on_click_area_mouse_exited():
	var tween = create_tween()
	tween.tween_property(%TreeSprite, "scale", Vector2(1.0, 1.0), 0.1)
	%TreeSprite.modulate = Color(1, 1, 1)

# --- CLICK LOGIC ---
func _on_click_area_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var core = get_tree().root.find_child("ReverieCore", true, false)
		if not core: return
		
		# 🌟 NEW: Instead of passing "Tide" as a string, we pass THIS ENTIRE NODE!
		# This tells the UI exactly which physical tree on the grid we just clicked.
		if core.has_method("show_habitat_footer"):
			core.show_habitat_footer(self) 
			
		get_viewport().set_input_as_handled()
		
		
		
# ==========================================
# --- WISP VISUALS & WANDERING ---
# ==========================================

func refresh_visuals():
	# 1. Clear out old physical wisps so we don't accidentally double-draw them
	for child in get_children():
		if child.is_in_group("habitat_wisps"):
			child.queue_free()
			
	# 2. Spawn a brand new physical wisp for every name in our pocket
	var core = get_tree().root.find_child("ReverieCore", true, false)
	
	for wisp_name in resident_echoes:
		var new_wisp = wisp_scene.instantiate()
		add_child(new_wisp)
		new_wisp.add_to_group("habitat_wisps") # Tag it so we remember it's a visual wisp
		
		# 3. Give it the correct elemental color
		if core:
			var base_name = core.get_base_name(wisp_name)
			if core.echo_database.has(base_name):
				new_wisp.modulate = core.echo_database[base_name].color
		
		# 4. Tell it to start gliding around!
		make_wisp_wander(new_wisp)

func make_wisp_wander(wisp):
	# 1. THE SHIELD: If the wisp was recalled or destroyed, stop everything immediately!
	if not is_instance_valid(wisp) or wisp.is_queued_for_deletion():
		return 
		
	var random_x = randf_range(-120, 120)
	var random_y = randf_range(-60, 60)
	var target_position = Vector2(random_x, random_y)
	
	var travel_time = randf_range(4.0, 7.0)
	
	# 2. Tie the animation directly to the wisp so it gets destroyed if the wisp gets recalled!
	var tween = wisp.create_tween()
	
	# 3. Double-check the tween was created successfully, then animate!
	if tween:
		tween.tween_property(wisp, "position", target_position, travel_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_callback(make_wisp_wander.bind(wisp))
