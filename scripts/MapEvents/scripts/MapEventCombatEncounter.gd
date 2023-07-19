extends AbstractMapEvent

# executing this event does the following:
# 1. starts an encounter menu
# 2. starts a fight
# an encounter can have one of the two, or both
# an encounter menu can start the fight, or close it ("run away from the fight")

# encounter menu related variables
# if boths encounter_menu_text and encounter_menu_picture aren't defined, than there is no encounter menu
export var encounter_menu_text :=""
export(Texture) var encounter_menu_picture
var player_closed_menu_and_chose_to_fight :=false # used to indicate the player closed the menu and chose to fight

# fight related variables
export var call_scene:PackedScene = null
var player_refused_auto_resolve_and_chose_to_fight := false # used to indicate the player want to fight rather than auto resolve the fight
var is_mid_fight=false
var mid_fight_record = [] # this records the player characters losses, after he wins they are added as win records to the node
var mid_fight_enemy_characters_v3 = []


# defines to what the event does
func execute():
	node_of_this_event.current_fight_event = self
	
	# encounter menu
	# TODO simplify this
	# if (there is an encounter menu) and this is a combat encounter and (the player chose not to ignore it during combat)
	if (!encounter_menu_text.empty() or encounter_menu_picture!=null) and \
	(!player_refused_auto_resolve_and_chose_to_fight and !player_closed_menu_and_chose_to_fight):
		Globals.main_game.gui.encounter_menu.initialize(self, encounter_menu_text, encounter_menu_picture)
		Globals.main_game.gui.encounter_menu.show()
		return
	
	# start combat
	if call_scene==null: 
		is_finished=true
		return
	
	#TODO if all player characters are dead, prevent the player from starting the fight and give a notification
	# if the fight was won already, offer to autoresolve it
	player_closed_menu_and_chose_to_fight = false # bugfix: this ensures that if the player start the combat, presses back, and start the fight again, he will see the menu
	
	if call_scene.resource_path in Globals.win_records and !player_refused_auto_resolve_and_chose_to_fight:
		node_of_this_event.current_fight_event = self
		Globals.main_game.gui.auto_resolve_combat_menu.initialize_v2(Globals.overworld,self)
		Globals.main_game.gui.auto_resolve_combat_menu.show()
	else:
		# player wants to fight
		Globals.last_visited_overworld_node = node_of_this_event
		Globals.main_game.go_to_combat_from_world_node(call_scene.resource_path,node_of_this_event)
	
	player_refused_auto_resolve_and_chose_to_fight = false

# reset the mid fight variables
# prevents the player from restarting the fight with the same wounded enemies
func reset_mid_fight():
	is_mid_fight=false
	mid_fight_record = []


# called when the player rejects the auto-resolve option and starts the fight
func auto_resolve_refused():
	player_refused_auto_resolve_and_chose_to_fight = true
	reset_mid_fight()
	execute()
#	_on_overworld_node_button_pressed()

# called when the player opens the encounter menu and presses the fight button
# the encounter menu closes and calls this function to start the fight
func encounter_menu_pressed_fight():
	player_closed_menu_and_chose_to_fight = true
	execute()
	

# called after the fight is won
func fight_won():
	redo_event=false
	is_finished=true
	
# this is called after the player rests. It defines what events should be replayed
# by default fights should be done again
func reset_after_rest():	
	redo_event = true 	
	player_closed_menu_and_chose_to_fight=false

# returns the class name since godot doesn't have it.
func get_class_name()->String:
	return "MapEventCombatEncounter"
	
# Used for saving the node. returns a dict of the node's features to be saved. 
func save()->Dictionary:
	var base_save = .save()
	
	base_save["is_mid_fight"] = is_mid_fight
	base_save["mid_fight_record"] = mid_fight_record
	base_save["mid_fight_enemy_characters_v3"] = mid_fight_enemy_characters_v3	
	
	return base_save		
	
