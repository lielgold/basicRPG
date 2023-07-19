extends Panel

const button_resource  = preload("res://menus/chararter_menu/inventory_button.tscn")

onready var close_button = $close_button
onready var unequip_button = $unequip_button
onready var grid = $grid

var data_items = GameData.ALL_ITEMS_DATA
var character
var selected_item_slot #used to put the selected item in the selected item slot
var character_menu

func initialize(character, character_menu):
	self.character = character
	self.character_menu = character_menu
	grid = $grid
	close_button = $close_button
	unequip_button = $unequip_button
	
	close_button.connect("pressed",self,"_on_close_button_pressed")
	unequip_button.connect("pressed",self,"_on_unequip_button_pressed")
	
	
	# remove all old items before adding the new ones
	for i in grid.get_children():
		grid.remove_child(i)
		i.queue_free()
	
	for d in data_items:
		var b = button_resource.instance()
		b.initialize(self, d["id"], d["gui_name"])		
		grid.add_child(b)
		

# Called when the node enters the scene tree for the first time.
func _ready():
	pass		

func update_inventory_gui():
	# update the status of every item button
	var grid = $grid	
	for button in grid.get_children():
		var item_id = button.item_id
		
		button.item_is_unequiped()
		
		#check if the player found the item
		if not (item_id in Globals.main_game.found_items_ids) or !Globals.DEBUG:
			button.item_not_found() 
		else:
			#check who owns it		
			for character in Globals.player_party.get_children():
				if character.items_manager.has_item(item_id):
					if character==character:
						button.this_character_has_the_item()
						break
					else:
						button.other_character_has_the_item(character.name)
						break
				
		
		
func selected_item(item_id:int):
	var item = GameData.get_item_data(item_id)	
	
	character.items_manager.remove_item_in_slot(selected_item_slot)
	character.items_manager.add_item(item_id,selected_item_slot)
	
	update_inventory_gui()
	character_menu.emit_signal("changed_inventory_items")
	character_menu.emit_signal("stats_changed")	
	self.visible = false
	


func _on_close_button_pressed():
	self.visible = false


func _on_unequip_button_pressed():
	character.items_manager.remove_item_in_slot(selected_item_slot)
	update_inventory_gui()
	character_menu.emit_signal("changed_inventory_items")
	character_menu.emit_signal("stats_changed")	
	self.visible = false

func _input(event):
	#close the menu if clicked outside of it
	if (event is InputEventMouseButton) and event.pressed:
		var evLocal = make_input_local(event)
		if !Rect2(Vector2(0,0),rect_size).has_point(evLocal.position):
			self.visible = false
