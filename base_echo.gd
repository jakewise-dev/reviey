extends Node2D

@export var float_speed = 2.0
@export var float_distance = 10.0
@export var echo_color: Color = Color(1, 1, 1)

func _ready():
	# Use the actual name of your node: GlowBody
	if has_node("GlowBody"):
		var bob = create_tween().set_loops()
		
		# We bob the body up and down locally.
		# This leaves the 'position' of the main node free to wander!
		bob.tween_property($GlowBody, "position:y", -float_distance, 1.2).set_trans(Tween.TRANS_SINE)
		bob.tween_property($GlowBody, "position:y", 0, 1.2).set_trans(Tween.TRANS_SINE)
	else:
		print("Warning: GlowBody node not found for bobbing!")

# THE _process FUNCTION IS GONE! 
# Deleting it stops the 'Two Brains' fighting over the position.
