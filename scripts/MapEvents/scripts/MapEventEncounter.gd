extends AbstractMapEvent

# show encounter menu
# the encounter is only shown once, and is considered finished after the player press the OK button
# TODO MapEventCombatEncounter should extend this and override execute

# encounter menu related variables
# if boths encounter_menu_text and encounter_menu_picture aren't defined, than there is no encounter menu
export var encounter_menu_text :=""
export(Texture) var encounter_menu_picture

# defines to what the event does
func execute():
	Globals.main_game.gui.encounter_menu.initialize(self, encounter_menu_text, encounter_menu_picture)
	Globals.main_game.gui.encounter_menu.show()

# called when the player opens the encounter menu and presses the OK button
# the encounter menu closes and calls this function to do stuff (start fight for example)
# by defualt it does nothing and continues executing events
func encounter_menu_pressed_fight():
	redo_event=false
	is_finished=true
	node_of_this_event._on_map_node_button_pressed()	

# returns the class name since godot doesn't have it.
func get_class_name()->String:
	return "MapEventEncounter"
	
# Used for saving the node. returns a dict of the node's features to be saved. 
func save()->Dictionary:
	var base_save = .save()
	return base_save
	
