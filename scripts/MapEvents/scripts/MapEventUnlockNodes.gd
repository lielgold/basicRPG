extends AbstractMapEvent

# executing this event unlocks nodes in the map
export(Array, NodePath) var unlock_nodes_editor # these nodes will be unlocked when execute is called

# defines to what the event does
func execute():	
	is_finished=true
	for node_path in unlock_nodes_editor:
		var n:MapNode = get_node(node_path)
		n.mark_as_reached()
		n.mark_as_unlocked()	

# this defines what happens after the player rests
# unlocked nodes get locked again after the player rests
func reset_after_rest():
	node_of_this_event.mark_as_lock()

# returns the class name since godot doesn't have it.
func get_class_name()->String:
	return "MapEventUnlockNodes"

# Used for saving the node. returns a dict of the node's features to be saved. 
#func save()->Dictionary:
#	var base_save = .save()
#
#	return base_save		
