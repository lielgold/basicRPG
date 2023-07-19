extends Button


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var item_id
var item_gui_name:String
var menu

func initialize(menu, item_id:int,item_gui_name:String):
	self.item_id = item_id	
	self.item_gui_name = item_gui_name
	self.menu = menu
	self.text = item_gui_name	

func item_is_unequiped():	
	self.text = item_gui_name
	visible=true
	disabled=false

func this_character_has_the_item():
	self.text = item_gui_name + " - equipped"
	disabled=true
	
func other_character_has_the_item(other_character_name:String):
	self.text = item_gui_name + " - equipped by " + other_character_name
	
func item_not_found():
	visible=false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _on_inventory_button_pressed():
	menu.selected_item(item_id)	
