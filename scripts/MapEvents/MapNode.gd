extends TextureButton

class_name MapNode

const GAME_DATA = preload("res://scripts/game_data.gd")

var active_events_list:Node # this are the events that are done when the player clicks on the button. By default the first event list is the active one.

onready var reward_timer_label = $reward_timer_label
onready var event_lists = $events_lists

var id:Dictionary

onready var map = get_parent().get_parent()

export var start_node:= false # this node is unlocked by default, this is where the player starts
export var reached:= false #the player reached this node (not unlocked in this day, but previously unlocked)
export var unlocked = false # the player unlocked this node

var is_mid_fight=false
var mid_fight_record = [] # this records the player characters losses, after he wins they are added as win records to the node
var who_won_combat # show who won the combat after exiting the combat node
var mid_fight_enemy_characters_v3 = []
var current_fight_event # this points to the current fight event TODO - remove this after refactoring the code


func initialize():
	event_lists = $events_lists
	active_events_list = event_lists.get_child(0) # by default the first event list is the active one
	
	# initialize the events of this node	
	for event_list in event_lists.get_children():
		for event in event_list.get_children():
			event.initialize(self)	
	

# Called when the node enters the scene tree for the first time.
func _ready():
	initialize()
	reward_timer_label = $reward_timer_label

	
	id = _init_id()
	connect("pressed", self, "_on_map_node_button_pressed")
	if start_node: 
		mark_as_unlocked()
		mark_as_reached()
	else: 
		mark_as_unreached()

	reward_timer_label.visible = false
	
	# initialize events
	for e in _get_all_events():
		e.initialize(self)
		

func reset_node_after_overworld_rest():
	# this prevents the player from starting a combat encounter in the middle after a rest
	is_mid_fight=false
	mid_fight_record = []	
	mid_fight_enemy_characters_v3 = []
	
	# reset events
	for event_list in event_lists.get_children():
		for event in event_list.get_children():
			event.reset_after_rest()
	
	# update timed rewards gui
	for event in active_events_list.get_children():		
		if !event.is_finished and "is_there_a_rewards_timer" in event and event.is_there_a_rewards_timer:
			var days_diff = event.reward_timer - Globals.main_game.ingame_days_since_started
			update_reward_timer_v2(days_diff)


# should only be called in 
func _init_id()->Dictionary:
	var node_id = {}
	node_id["map_name"] = map.name
	node_id["node_name"] = name
	
	return node_id

func mark_as_reached():
	self.visible = true
	self.reached = true
	$reached_sprite.visible = true

func mark_as_unreached():	
	if !Globals.DEBUG: self.visible = false
	self.reached = false
	$reached_sprite.visible = false
	
func mark_as_unlocked():
	self.unlocked = true
	$reached_sprite.visible = false
	$unlocked_sprite.visible = true

func mark_as_lock():
	self.unlocked = false
	$reached_sprite.visible = false
	$unlocked_sprite.visible = false
	mark_as_unfinished()
	
	if Globals.DEBUG: 
		self.unlocked = false

func mark_as_finished():
	$finished_sprite.visible=true

func mark_as_unfinished():
	$finished_sprite.visible=false

func disable_node():
	disabled=true
	modulate.a = 0.5

# unused and untested	
static func is_equal_nodes_id(node_id_a:Dictionary, node_id_b:Dictionary):
	if node_id_a["map_name"]==node_id_b["map_name"] and \
		node_id_a["node_name"]==node_id_b["node_name"] and \
		node_id_a["packed_resource"]==node_id_b["packed_resource"]: return true
	return false	

# return true if both nodes have the same id
# unused and untested
func equals(other_node:MapNode):
	if id["node_name"]==other_node.id["node_name"] and id["map_name"]==other_node.id["map_name"] and id["packed_resource"]==other_node.id["packed_resource"]:
		return true
	return false

func _to_string():
	return "map name: " + map.name + " node name: " + name 
	

func _on_map_node_button_pressed():
	if !Globals.DEBUG and !unlocked: 
		return
	for event in active_events_list.get_children():
		if !event.is_finished  or event.redo_event:
			event.execute()
			# if the event was stopped in the middle ("player ran from fight"), don't process more events
			if !event.is_finished: break
	# all events are done, mark node as finished
	mark_as_finished()

# reset the mid fight variables
# prevents the player from restarting the fight with the same wounded enemies
func reset_mid_fight():
	is_mid_fight=false
	mid_fight_record = []


# update the gui of the reward timer
func update_reward_timer_v2(days_till_reward_expiration:int):	
	if Globals.main_game==null: return # this avoids a bug at startup	
	
	# update timer text
	reward_timer_label.visible = true
	if days_till_reward_expiration<0:
		reward_timer_label.visible = false
		return
	elif days_till_reward_expiration==0: 
		reward_timer_label.text ="Today"
	else: 
		reward_timer_label.text =String(days_till_reward_expiration)

# returns the class name since godot doesn't have it.
func get_class_name()->String:
	return "MapNode"

# returns all the events
# used when saving, not really useful otherwise
func _get_all_events()->Array:
	var all_events = []
	for event_list in event_lists.get_children():
		all_events.append_array(event_list.get_children())
	return all_events

# this updates the gui of the MapNode
# don't forget to specify whether the node is visible or not
# called after load
func update_node_gui()->void:
	if unlocked or reached:
		visible=true
	else:
		visible=false
		
	if unlocked:
		mark_as_unlocked()
	
	# update the finished sprite
	var all_events_finished:=true
	for event in active_events_list.get_children():
		if !event.is_finished: 
			all_events_finished=false
			break
	if all_events_finished: mark_as_finished()	
	

# Used for saving the node. returns a dict of the node's features to be saved. 
func save()->Dictionary:
	var save_dict = {
		"filename" : get_filename(),
		"parent" : get_parent().get_path(),
		"rect_position_x": rect_position.x,
		"rect_position_y": rect_position.y,
		"name": name,
		"map_name": map.name,
		"start_node" : start_node,
		"id" : id,
		"reached" : reached,
		"unlocked" : unlocked,

		"is_mid_fight" : is_mid_fight,
		"mid_fight_record" : mid_fight_record,
		"mid_fight_enemy_characters_v3" : mid_fight_enemy_characters_v3,
		
		"active_events_list_index":active_events_list.get_index(),
	}
	# add all events as
	# event list name : [event save 1, event save 2, event save 3 ...]
#	for event_list in event_lists.get_children():
#		for e in event_list.get_children():
#			var a = event_list.name
#			if save_dict.has(event_list.name):				
#				save_dict[event_list.name].append(e.save())
#			else:
#				save_dict[e.name] = [e.save()]
	return save_dict
