extends Node2D

@export var wisp_scene: PackedScene = preload("res://base_echo.tscn")

var is_weaving: bool = false
var time_left: float = 0.0
var total_time: float = 0.0
var baby_color: Color = Color.WHITE

var spawned_parent_a: Node2D = null
var spawned_parent_b: Node2D = null
var egg_tween: Tween # 🌟 Remembers the idle animation so we can stop it later

func _ready():
    # Hide the UI and Egg when the game first loads
    %ProgressBar.visible = false
    %EggSprite.visible = false

func _process(delta):
    # If we are weaving, tick down the clock and fill the bar!
    if is_weaving:
        time_left -= delta
        
        if total_time > 0:
            var progress = 100.0 - ((time_left / total_time) * 100.0)
            %ProgressBar.value = progress
            
        # When the timer hits zero, trigger the egg!
        if time_left <= 0:
            finish_weaving()

# 🌟 Core tells this function to run when you click "WEAVE!"
# 🌟 We added 'result_color' to the arguments!
func start_weaving(parent_a_color: Color, parent_b_color: Color, result_color: Color, duration: float):
    total_time = duration
    time_left = duration
    is_weaving = true
    baby_color = result_color # 🌟 Save it in the Altar's memory!
    
    # ... (Keep the rest of your start_weaving function exactly the same!) ...
    
    # Reset visuals
    %ProgressBar.visible = true
    %ProgressBar.value = 0
    %EggSprite.visible = false
    
    # Spawn Parent A and make it float
    if wisp_scene:
        spawned_parent_a = wisp_scene.instantiate()
        %ParentAPos.add_child(spawned_parent_a)
        spawned_parent_a.modulate = parent_a_color
        make_wisp_bob(spawned_parent_a)
        
        # Spawn Parent B and make it float
        spawned_parent_b = wisp_scene.instantiate()
        %ParentBPos.add_child(spawned_parent_b)
        spawned_parent_b.modulate = parent_b_color
        make_wisp_bob(spawned_parent_b)

func finish_weaving():
    is_weaving = false
    %ProgressBar.visible = false
    
    if is_instance_valid(spawned_parent_a): spawned_parent_a.queue_free()
    if is_instance_valid(spawned_parent_b): spawned_parent_b.queue_free()
    
    %EggSprite.modulate = baby_color
    %EggSprite.visible = true
    
    # Start tiny!
    %EggSprite.scale = Vector2(0.1, 0.1) 
    
    # If an old animation is still running, kill it
    if egg_tween:
        egg_tween.kill()
        
    egg_tween = create_tween()
    
    # 1. THE POP IN (Fast and bouncy)
    egg_tween.tween_property(%EggSprite, "scale", Vector2(0.8, 1.2), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    egg_tween.tween_property(%EggSprite, "scale", Vector2(0.6, 1.0), 0.2)
    
    # 2. THE IDLE BREATHE (Infinite smooth loop)
    # We chain a new looping tween to start exactly after the pop finishes
    egg_tween.tween_callback(start_egg_idle)

func start_egg_idle():
    if egg_tween:
        egg_tween.kill()
        
    egg_tween = create_tween().set_loops()
    
    # Gently swells up and gets slightly brighter, then shrinks down to normal
    egg_tween.tween_property(%EggSprite, "scale", Vector2(0.65, 1.05), 1.2).set_trans(Tween.TRANS_SINE)
    # To make it "glow", we multiply the baby color by 1.2 so it shines!
    egg_tween.parallel().tween_property(%EggSprite, "modulate", baby_color * 1.2, 1.2).set_trans(Tween.TRANS_SINE)
    
    egg_tween.tween_property(%EggSprite, "scale", Vector2(0.6, 1.0), 1.2).set_trans(Tween.TRANS_SINE)
    egg_tween.parallel().tween_property(%EggSprite, "modulate", baby_color, 1.2).set_trans(Tween.TRANS_SINE)

# 🌟 Core tells this function to run when you click "Send Egg to Hatchery"
func reset_altar():
    %EggSprite.visible = false
    if egg_tween:
        egg_tween.kill() # Stop the breathing animation!

func make_wisp_bob(wisp: Node2D):
    # A gentle floating animation up and down
    var bob = create_tween().set_loops()
    bob.tween_property(wisp, "position:y", -15.0, 1.5).set_trans(Tween.TRANS_SINE)
    bob.tween_property(wisp, "position:y", 0.0, 1.5).set_trans(Tween.TRANS_SINE)
