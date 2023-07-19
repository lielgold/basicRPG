extends TextureButton


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var combat_screen
var fast_forward_fight = false
var started_combat = false

func initialize(combat_screen):	
	self.combat_screen = combat_screen		
	connect("pressed", combat_screen, "start_turn_button_pressed")
	

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# when clicking on fast forward, set the fight ASAP
func _on_fast_forward_button_pressed():
	fast_forward_fight = true
	while !combat_screen.combat_is_over:
		emit_signal("pressed")
