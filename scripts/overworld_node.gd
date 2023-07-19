extends TextureButton

class_name OverworldNode

const GAME_DATA = preload("res://scripts/game_data.gd")

onready var encounter_label_name = $encounter_label_name
onready var reward_timer_label = $reward_timer_label

export(Array, NodePath) var reachable_from_me_editor # unlocks nodes from this node to other nodes specified in unlocks_from_me. That is, specifies the edges where this node is the unlocking node/
var reachable_from_me:Array = []
#export(Array, Array, NodePath) var unlock_between_nodes = [["",""]] # unlocks nodes from unlock_between_nodes[0][0] to unlock_between_nodes[0][1]
export var call_scene:PackedScene

export var this_is_a_switch_map_node:bool = false
export var switch_to_this_map:NodePath = ""

var id:Dictionary

# rewards
export var is_timed_rewards_node := false
export (int, 0,1000)var reward_timer:=0 # 0 means the timer isn't used

onready var map = get_parent().get_parent()

export var start_node:= false # this is a start node of this map
export var reached:= false #the player can start this fight
export var unlocked = false # the player won this fight already


# rewards for reaching this node
var rewards_given = false # the player got the rewards from getting to this node. player can only get them once.
export (Array, GAME_DATA.PLAYER_CHARACTER_IDS) var character_id_to_get_xp_rewards
export (Array, int, 0, 1000) var character_xp_rewards
export (Array, GAME_DATA.ITEMS_ID) var item_rewards

var is_mid_fight=false
var mid_fight_record = [] # this records the player characters losses, after he wins they are added as win records to the node
var who_won_combat # show who won the combat after exiting the combat node
var mid_fight_enemy_characters_v3 = []

var player_refused_auto_resolve_and_chose_to_fight = false # used in the combat node menu to indicate the player want to fight rather than auto resolve the fight


# contains information on all the the wins. Each member of the list is a win, each member of the win is a character's lost hp
#export var win_records = [
#   [ 
#			[character_ID:integer of the character1 id, hp_percentage_lost = 0.17]
#			[character_ID:integer of the character2 id, hp_percentage_lost = 0.22]
#	]
#
#	
#]


# Called when the node enters the scene tree for the first time.
func _ready():
	encounter_label_name = $encounter_label_name	
	reward_timer_label = $reward_timer_label
	
	if character_id_to_get_xp_rewards.size() != character_xp_rewards.size():
		push_error(String(name) + " has different sizes for character_id_to_get_xp_rewards and character_xp_rewards")

	
	id = _init_id()
	connect("pressed", self, "_on_overworld_node_button_pressed")
	if start_node: mark_as_reached()
	else: mark_as_unreached()
	for path in reachable_from_me_editor:
		reachable_from_me.append(get_node(path))
	
	Globals.overworld.add_ow_node(self)

	
	# show encounter name
	if Globals.DEBUG and call_scene!=null:
		encounter_label_name.text = call_scene.resource_path.substr(20)
		
	update_node_texture()


# set the sprite of the node
func update_node_texture():
	pass

func reset_node_after_overworld_rest():
	is_mid_fight=false
	mid_fight_record = []
	
	mid_fight_enemy_characters_v3 = []
		

# should only be called in 
func _init_id()->Dictionary:
	var node_id = {}
	node_id["map_name"] = map.name
	node_id["node_name"] = name
	if(call_scene!=null): node_id["packed_resource"]=call_scene.resource_path
	else: node_id["packed_resource"]=""
	
	return node_id

func mark_as_reached():
	self.visible = true
	self.reached = true
	$reached_sprite.visible = true
	
	if unlocked: mark_as_unlocked()
	
func mark_as_unreached():	
	if !Globals.DEBUG: self.visible = false
	self.reached = false
	$reached_sprite.visible = false
	
	#mark_as_lock()
	

func mark_as_unlocked():
	self.unlocked = true
	
	$reached_sprite.visible = false
	$unlocked_sprite.visible = true	

func mark_as_lock():
	self.unlocked = false
	$reached_sprite.visible = false
	$unlocked_sprite.visible = false		

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
func equals(other_node:OverworldNode):
	if id["node_name"]==other_node.id["node_name"] and id["map_name"]==other_node.id["map_name"] and id["packed_resource"]==other_node.id["packed_resource"]:
		return true
	return false

func _to_string():
	return "map name: " + map.name + " node name: " + name 
	

func _on_overworld_node_button_pressed():
	# handle switch nodes	
	if this_is_a_switch_map_node:
		if switch_to_this_map.is_empty(): 
			push_error("the node " + to_string() + "is defined as a map switch node, but you forgot to pick a map to switch to")
		else:
			var p = get_node(switch_to_this_map).get_path()
			Globals.overworld.switch_map(p)
	# handle switch nodes	
	elif is_timed_rewards_node:
		Globals.overworld.unlock_node(self)
		# give player rewards for unlocking the node
		if reward_timer>0 and reward_timer<=Globals.main_game.ingame_days_since_started:
			pass # don't give reward if the player got to the node too late
		elif rewards_given==false and Globals.main_game!=null: # the null check prevents bugs at startup, when rewards aren't given anyway
			Globals.main_game.give_player_rewards(self)
			rewards_given = true		
	# handle combat nodes
	else:
		#TODO if all player characters are dead, prevent the player from starting the fight and give a notification
		if start_node or (self.unlocked and !Globals.DEBUG): # the !Globals.DEBUG allows to redo fights without resting
			return	
		elif self.reached or Globals.DEBUG:
			# if the fight was won already, offer to autoresolve it
			if call_scene.resource_path in Globals.win_records and !player_refused_auto_resolve_and_chose_to_fight:			
				Globals.main_game.gui.auto_resolve_combat_menu.initialize(Globals.overworld,self)
				Globals.main_game.gui.auto_resolve_combat_menu.show()
			else:
				# player wants to fight
				Globals.last_visited_overworld_node = self
				Globals.main_game.go_to_combat_from_world_node(call_scene.resource_path,self)
				
			
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
	_on_overworld_node_button_pressed()

func _get_call_scene_path():
	if call_scene==null: return ""
	else: return call_scene.resource_path

func _get_reachable_from_me_node_names():
	var output = []
	for node in reachable_from_me:
		if node != null:
			output.append([map.name, node.name])
	return output

# update the gui of the reward timer
func update_reward_timer():
	reward_timer_label.visible = false
	if Globals.main_game==null: return # this avoids a bug at startup	
	if reward_timer==0 or rewards_given:
		pass # there's no reward timer for this node
	elif reward_timer>0 and reward_timer - Globals.main_game.ingame_days_since_started  >= 0:
		# update timer text
		reward_timer_label.visible = true
		var dif = reward_timer - Globals.main_game.ingame_days_since_started
		if dif==0: 
			reward_timer_label.text ="Today"
		else: 
			reward_timer_label.text =String(dif)

func update_node_gui()->void:
	pass

# returns the class name since godot doesn't have it.
func get_class_name()->String:
	return "OverworldNode"

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
		"reachable_from_me_editor" : reachable_from_me_editor,
		"reachable_from_me_node_names" : _get_reachable_from_me_node_names(),
		"call_scene_resource_path" : _get_call_scene_path(),
		"this_is_a_switch_map_node" : this_is_a_switch_map_node,
		"switch_to_this_map" : switch_to_this_map,
		"id" : id,
		"reached" : reached,
		"unlocked" : unlocked,
		"rewards_given": rewards_given,
		"is_mid_fight" : is_mid_fight,
		"mid_fight_record" : mid_fight_record,
		"mid_fight_enemy_characters_v3" : mid_fight_enemy_characters_v3,
		"is_timed_rewards_node" : is_timed_rewards_node,
		"reward_timer" : reward_timer,
		
	}
	return save_dict
