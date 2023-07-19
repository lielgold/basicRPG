extends Control

class_name Overworld

const line_resource = preload("res://scripts/line2d_between_nodes.tscn")

var all_ow_nodes = [] # contains all nodes. this gets rebuilt in at the start to contain all the nodes
var unlocked_ow_nodes = [] # assume the rest of the nodes are locked. this can be used to save and load the game.
var edges = []


# contains record about fights. 
# the mid fight refers to a fight that is in the middle, with enemies half wounded
# win records are records of won fight, used to autoresolve
# dictionary in the form of:
#export var records = {
#	call_scene : {
#		is_mid_fight = false,
#		win_records = [
#   		[ 
#				[character_ID:integer of the character1 id, hp_percentage_lost = 0.17]
#				[character_ID:integer of the character2 id, hp_percentage_lost = 0.22]
#			]
#		]
#	}
#}
onready var main_game = get_parent()

onready var rest_button = $rest_button
onready var day_indicator = $day_indicator

#export var the_first_map_of_the_game:NodePath
export var start_map:NodePath # the first map of the game, this is where you start
onready var current_map = get_node(start_map)	
onready var debug_button = $debug_button
onready var maps = $maps
onready var open_save_load_menu_button = $open_save_load_menu_button


class OW_Edge:
	var from:OverworldNode
	var to:OverworldNode
	var line:Line2D
	
	func _init(from_node:OverworldNode, to_node:OverworldNode, new_line:Line2D):
		from=from_node
		to=to_node
		line=new_line
		
	#return if this edge is equal to another
	func equals(other_edge:OW_Edge)->bool:
		if (from==other_edge.from and to==other_edge.to) or (to==other_edge.from and from==other_edge.to): return true
		return false

func _enter_tree():
	#if the overworld is loaded after a fight was won, we need to proccess the fight results	
	Globals.overworld = self


# return from combat enounter, check if the fight was won and we need to unlock the node
# this can be called after the fight was over in a OverworldNode, or if a fight was auto-resolved
func return_from_combat_encounter(ow_node_of_combat_encounter):	
	if ow_node_of_combat_encounter!=null:		
		if ow_node_of_combat_encounter.who_won_combat==Globals.WHO_WON.PLAYER:
			unlock_node(ow_node_of_combat_encounter)
			Globals.main_game.give_player_rewards(ow_node_of_combat_encounter)
			ow_node_of_combat_encounter.current_fight_event.fight_won()
			ow_node_of_combat_encounter._on_map_node_button_pressed() # the fight was won, process the next events
		
		Globals.reset_fight_results()	
	
# Called when the node enters the scene tree for the first time.
func _ready():	
	rest_button = $rest_button
	open_save_load_menu_button = $open_save_load_menu_button
	
	Globals.overworld = self
	
	rest_button.connect("pressed",self,"rest_characters_and_reset_overworld")	
	open_save_load_menu_button.connect("pressed",self,"open_save_load_menu")
	debug_button.connect("pressed",self,"_on_debug_button_pressed")
	
	# update the day gui indicator
	_update_days_indicator()
	
	# initialize nodes
	for map in maps.get_children():
		for n in map.get_node("nodes").get_children():
			n.map = map
	
	
# show only the current map, hide the others
#func show_only_current_map():
#	#hide all maps and show the current one
#	for map in $maps.get_children():
#		map.hide()	
#	if current_map==null:
#		# this sets the default map on the first time the game runs
#		current_map = get_node(the_first_map_of_the_game)
#	elif current_map is String:
#		#this happens after the game loads
#		current_map = get_node(current_map)	
#	current_map.show()

func initialize_gui():
	#show party 
	Globals.main_game.gui.party_menu.start_party_menu()


func add_ow_node(ow_node:OverworldNode):	
	if all_ow_nodes.has(ow_node):
		push_error("tried to add a node that already exists. Node ID: " + ow_node.to_string())
	all_ow_nodes.append(ow_node)

# return the OverworldNode with the proper id, or null if not found
# untested and unused
func get_ow_node_by_id(node_id:Dictionary)->OverworldNode:
	for other_node in all_ow_nodes:
		if OverworldNode.is_equal_nodes_id(node_id, other_node.id):
			return other_node
	return null
	

func unlock_node(node:OverworldNode):
	if node==null: return # TODO remove this after I finish refactoring MapNode
	if !unlocked_ow_nodes.has(node):
		unlocked_ow_nodes.append(node)
		
	node.mark_as_unlocked()
	
	for n in node.reachable_from_me:
		n.mark_as_reached()
		add_edge(node, n)

func print_data():	
	for map in maps.get_children():
		for node in map.get_node("nodes").get_children():
			print(node)
			print(node.unlocked)
			print(node.mid_fight_enemy_characters_v3)
					


# updates graph state
# start from the start_node, and than follow the graph and mark nodes as reached / unlock according to their status
func check_entire_graph_for_unlocks_and_reachable_v2():
	var all_map_nodes = get_all_nodes()

	for n in all_map_nodes:			
		if Globals.DEBUG: 
			n.visible = true
			n.mark_as_unlocked()
		else: 
			n.visible = false
			n.mark_as_lock()
			
		
	
	for n in all_map_nodes:
		if n.start_node: 
			n.visible = true
			n.mark_as_unlocked()
		elif n.reached:
			n.visible = true
			n.mark_as_unreached()


func reset_overworld_after_rest():
	for n in get_all_nodes():
		if not n.start_node:
#			n.mark_as_unreached()
			n.mark_as_lock()
			n.reset_node_after_overworld_rest()
	
func switch_map(absolute_path_to_node):	
	self.current_map = get_node(absolute_path_to_node)	
	
	# hide all maps and show the right one
	for map in $maps.get_children():
		map.hide()	
	if current_map==null:
		# this sets the default map on the first time the game runs
		get_node(absolute_path_to_node).show()
	else:
		current_map.show()	

func rest_characters_and_reset_overworld():
	Globals.main_game.ingame_days_since_started +=1	
	Globals.last_visited_overworld_node = null
	Globals.number_of_characters_created_in_the_node = 0
	
	for character in Globals.player_party.get_children():
		character.rest()
	
	# reset overworld
	reset_overworld_after_rest()
	
	# update the day gui indicator
	_update_days_indicator()

# called when pressing the open save load menu button
func open_save_load_menu():
	Globals.main_game.gui.save_load_menu.visible = true
	Globals.main_game.gui.save_load_menu.update_saves_in_menu()

#--------------------------- edge functions

func add_edge(from_node:OverworldNode,to_node:OverworldNode)->void:	
	var new_line = line_resource.instance()
	var new_edge = OW_Edge.new(from_node,to_node,new_line)
	# check if the edge was already added
	for e in edges:
		if e.equals(new_edge): 
			e.line.visible = true
			return
	
	edges.append(new_edge)
	var edges_container = from_node.get_parent().get_parent().get_node("edges")
	
	new_line.clear_points()
	new_line.add_point(from_node.rect_position+from_node.rect_size*0.5)
	new_line.add_point(to_node.rect_position+to_node.rect_size*0.5)
	edges_container.add_child(new_line)	


#--------------------------- end edge functions

# update the day gui indicator
func _update_days_indicator():
	day_indicator.text = "day: " + String(main_game.ingame_days_since_started)


# sets up the debug button
func _on_debug_button_pressed():
	if Globals.DEBUG: Globals.DEBUG=false
	else: Globals.DEBUG = true	
	#debug_button.text = "Set debug to " + String(!Globals.DEBUG)
	
	check_entire_graph_for_unlocks_and_reachable_v2()
	
	# show all nodes
	if Globals.DEBUG:
		for n in all_ow_nodes:
			n.visible = true
		

func get_all_nodes():
	var all_nodes = []
	for map in $maps.get_children():
		all_nodes.append_array(map.get_node("nodes").get_children())
	return all_nodes

# get node by its name and its map name. return null if not found.
func get_node_by_name(map_name:String, node_name:String)->OverworldNode:
	var map = null
	for m in maps.get_children():
		if m.name==map_name:
			map = m
	if map==null: return null
		
	for n in map.get_node("nodes").get_children():
		if n.name==node_name:
			return n
	return null
	

# Used for saving the node. returns a dict of the node's features to be saved. 
func save()->Dictionary:
	var save_dict = {		
		"filename" : get_filename(),
		"parent" : get_parent().get_path(),
		"this_is_the_overworld":true,
		"rect_position_x": rect_position.x,
		"rect_position_y": rect_position.y,
		"current_map_path": current_map.get_path(),
	}
	return save_dict
