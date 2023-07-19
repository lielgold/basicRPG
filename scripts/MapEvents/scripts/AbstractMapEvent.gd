extends Node

# this class defines an abstract map event. it does nothing, do initialize it
class_name AbstractMapEvent

# whether the event was finished, or stopped in the middle. If the event finished, the next event can be executed
# for example, combat encounter can be stopped in the middle, 
var is_finished:=false 

# redo_event - whether the event should be executed again if the player clicks it twice. 
# for example, unlock events should be executed again after the player rests, while rewards giving events shouldn't be executed again
var redo_event:=true 

var node_of_this_event:MapNode # the node where this event is done


func initialize(node_of_this_event:MapNode):
	self.node_of_this_event = node_of_this_event

# this is called to execute the event
# override this to define to what the event does
func execute():
	is_finished = true


# this is called after the player rests. It defines what events should be replayed
# unlock nodes events should be replayed, so the relevant nodes could be unlocked
# rewards are only given once, so reward giving events don't get played twice
func reset_after_rest():
	# by default events don't get replayed, but it's better to always specify this.
	pass 
	
# returns the class name since godot doesn't have it.
func get_class_name()->String:
	return "AbstractMapEvent"

# Used for saving the node. returns a dict of the node's features to be saved. 
func save()->Dictionary:
	var save_dict = {
		"filename" : get_filename(),
		"parent" : get_parent().get_path(),
		"name": name,
		"map_name": node_of_this_event.map.name,
		"path": get_path(),		
		
		"is_finished" : is_finished,
		"redo_event" : redo_event,		
	}
	return save_dict	

