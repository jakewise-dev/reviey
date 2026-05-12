extends Node2D

@export var grid_layer: TileMapLayer
@export var cursor_sprite: Sprite2D 

@export var tide_scene: PackedScene
@export var pyre_scene: PackedScene

# 🌟 THE RETURN OF THE INK LABEL
@export var ink_label: Label
var current_cost: int = 0 

var item_to_move: Node2D = null
var is_valid_location: bool = false 
var occupied_tiles = {}

var core: Node

func _ready():
	core = get_tree().root.find_child("ReverieCore", true, false)
	update_ink_display() # Show the money when the game starts!

func _process(_delta):
	if cursor_sprite == null or grid_layer == null: return 
		
	if not item_to_move:
		cursor_sprite.visible = false
		return
	
	cursor_sprite.visible = true
	
	var global_mouse = get_global_mouse_position()
	var local_mouse = grid_layer.to_local(global_mouse)
	var grid_coords = grid_layer.local_to_map(local_mouse)
	var local_center = grid_layer.map_to_local(grid_coords)
	var snapped_global_pos = grid_layer.to_global(local_center)
	
	item_to_move.global_position = snapped_global_pos
	cursor_sprite.global_position = snapped_global_pos
	
	var has_floor = grid_layer.get_cell_source_id(grid_coords) != -1
	var is_occupied = occupied_tiles.has(grid_coords)
	
	if has_floor and not is_occupied:
		cursor_sprite.modulate = Color(0, 1, 0, 0.6)
		is_valid_location = true
	else:
		cursor_sprite.modulate = Color(1, 0, 0, 0.6)
		is_valid_location = false

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if item_to_move and is_valid_location:
				var global_mouse = get_global_mouse_position()
				var local_mouse = grid_layer.to_local(global_mouse)
				var grid_coords = grid_layer.local_to_map(local_mouse)
				
				# 🌟 SPEND THE REAL INK AND UPDATE OUR TOP-LEFT LABEL
				if core:
					core.ink_count -= current_cost
					core.update_ui() # Updates the old greybox stuff just in case
					update_ink_display() # Updates our shiny new top-left label!
					core.save_game()
				
				occupied_tiles[grid_coords] = true
				item_to_move = null 
				get_viewport().set_input_as_handled()
		
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if item_to_move:
				item_to_move.queue_free()
				item_to_move = null
				current_cost = 0 
				get_viewport().set_input_as_handled()

# --- BUTTON SIGNALS ---

func buy_tide():
	if core and core.ink_count >= 50:
		current_cost = 50
		start_placement(tide_scene)
	else:
		print("Not enough Ink!")

func buy_pyre():
	if core and core.ink_count >= 75:
		current_cost = 75
		start_placement(pyre_scene)
	else:
		print("Not enough Ink!")

func start_placement(blueprint: PackedScene):
	if item_to_move:
		item_to_move.queue_free() 
		
	if blueprint:
		var new_item = blueprint.instantiate()
		get_tree().current_scene.add_child(new_item)
		item_to_move = new_item

# 🌟 NEW: Update the specific top-left UI
func update_ink_display():
	if ink_label and core:
		ink_label.text = "Ink: " + str(int(core.ink_count))
