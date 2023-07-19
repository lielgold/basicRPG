extends Button


var character_menu
var selected_item
var item_slot

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	

func initialize(character_menu,item_slot):
	self.character_menu = character_menu
	self.item_slot = item_slot


func _on_item_active_pressed():
	character_menu.choose_ability_for_item_active(selected_item,item_slot)

