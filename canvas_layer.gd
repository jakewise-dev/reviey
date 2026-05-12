extends CanvasLayer

func _ready():
	# Make sure the menu is closed when the game starts
	$BuildMenu.visible = false

# Connect your OpenShopButton's "pressed()" signal to this function!
func _on_open_shop_button_pressed():
	# This flips the visibility! If it's hidden, it shows. If it's showing, it hides.
	$BuildMenu.visible = not $BuildMenu.visible
