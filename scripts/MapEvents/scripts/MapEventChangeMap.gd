extends AbstractMapEvent

# executing this event changes the active map of game to the map specified in switch_to_this_map
# in other words, it moves the player to this map
export var switch_to_this_map:NodePath

# defines to what the event does
func execute():	
	is_finished=true
	var p = get_node(switch_to_this_map).get_path()
	Globals.overworld.switch_map(p)

# returns the class name since godot doesn't have it.
func get_class_name()->String:
	return "MapEventChangeMap"
	
# Used for saving the node. returns a dict of the node's features to be saved. 
#func save()->Dictionary:
#	var base_save = .save()
#
#	return base_save	
