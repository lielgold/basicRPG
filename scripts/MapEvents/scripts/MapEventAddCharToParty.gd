extends AbstractMapEvent

# add a character to the player's party

export(Resource) var charcter_to_add_resource 

# defines to what the event does
func execute():	
	Globals.main_game.add_character_resource_to_player_party(charcter_to_add_resource.resource_path)
	
	redo_event=false
	is_finished=true

# returns the class name since godot doesn't have it.
func get_class_name()->String:
	return "MapEventAddCharToParty"
	
# Used for saving the node. returns a dict of the node's features to be saved. 
func save()->Dictionary:
	var base_save = .save()
	
	return base_save		
	
