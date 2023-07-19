extends Button

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var character_menu
var item_slot #the item slot this button represents. every button should have a different slot.

func initialize(character_menu, item_slot):
	self.character_menu = character_menu
	self.item_slot = item_slot
	
	self.connect("pressed",character_menu,"open_inventory_item_button_pressed",[self,item_slot])

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
