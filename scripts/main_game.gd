extends Control

onready var overworld = $overworld
onready var gui = $gui
onready var player_party = $player_party

const GAME_DATA = preload("res://scripts/game_data.gd")


var started_the_game:=false # is this the first time the game is run?

onready var first_map_of_the_game := $overworld/maps/map_001

export (Array, GAME_DATA.ITEMS_ID) var found_items_ids
export var ingame_days_since_started = 1
export var character_xp_rewarded = {}
export var character_xp_awarded_to_characters_not_in_player_party = {} # A character not in the player's party got xp. document it here and later on give the xp when the character joins the party.

# this is used to move information from overworld nodes to combat and back
var the_player_retries_the_fight_so_add_the_same_wounded_enemy_characters_v3 = []

# Called when the node enters the scene tree for the first time.
func _ready():	
	overworld = $overworld
	gui = $gui
	player_party = $player_party
	
	Globals.main_game = self
	Globals.player_party = player_party
	Globals.overworld = $overworld
	
	if started_the_game==false: 
		started_the_game=true
		setup_initial_player_party()
		
		# set initial map
		for map in overworld.maps.get_children(): 
			map.visible = false
			if map == first_map_of_the_game:
				map.visible = true
		
	setup_player_party()
	gui.reset_gui()
	
	#overworld.check_entire_graph_for_unlocks_and_reachable_v2()
	#overworld.check_entire_graph_for_unlocks_and_reachable(true)
	

func add_character_resource_to_player_party(character_resource):
	var character = load(character_resource).instance()
	player_party.add_child(character)	
	# set id 
	var i=0
	for path in GAME_DATA.PLAYER_IDS_TO_CHARACTER_RESOURCE_PATHS.values():
		if path==character_resource:
			character.id = GAME_DATA.PLAYER_IDS_TO_CHARACTER_RESOURCE_PATHS.keys()[i]
		i+=1
	
	character.team=Globals.TEAMS.PLAYER
	character.part_of_player_party = true
	
	# TODO test this. add a character mid game that got xp beforehand
	if character.id in character_xp_awarded_to_characters_not_in_player_party.keys():
		give_xp_to_character(character.id, character_xp_awarded_to_characters_not_in_player_party[character.id])
		character_xp_awarded_to_characters_not_in_player_party.erase(character.id)
	
	character.add_to_group("save_me",true)
	character.hide()
	
	# update gui
	gui.party_menu.start_party_menu()

# setup the initial player party. This is used the first time starting the game 
func setup_initial_player_party():
	for resource_path in GAME_DATA.INITIAL_PARTY_RESOURCE_PATHS:
		add_character_resource_to_player_party(resource_path)

# prepare player party for play
func setup_player_party():
	for character in player_party.get_children():
		character.team=Globals.TEAMS.PLAYER		
		character.part_of_player_party = true
		character.hide()
		
# change scene from the overworld to a combat scene
func go_to_combat_from_world_node(call_scene_resource_path:String, ow_node_which_called_the_function):		
	overworld.hide()
	Globals.number_of_characters_created_in_the_node =0
	
	var combat_scene = load(call_scene_resource_path)
	combat_scene = combat_scene.instance()	
	add_child(combat_scene)
	move_child(combat_scene, 0)
	
	combat_scene.initialize_combat_with_information_from_the_combat_node(ow_node_which_called_the_function)	

# return the player character with the given id, or null
func get_character_from_id(id:int):
	for c in player_party.get_children():
		if c.id == id:
			return c
	return null

# combat ended, change scene back to the overworld
func go_back_from_combat(combat_node):
	remove_child(combat_node)
	var ow_node = combat_node.ow_node_that_created_this_combat_scene
	combat_node.queue_free()
	
	overworld.initialize_gui()
	overworld.show()
	overworld.return_from_combat_encounter(ow_node)

# give the player characters rewards (items, rewards)
# ow_node - the node that gives rewards. To set rewards, change the variables in the node.
func give_player_rewards(ow_node:OverworldNode =null):
	if ow_node==null: return # TODO remove this after I finish refactoring MapNode
	# check if the player should get rewards
	if ow_node.rewards_given ==true: return # don't give rewards twice
	if ow_node.is_timed_rewards_node and ow_node.reward_timer <= ingame_days_since_started:
		# this is a timed rewards node, and too days have passed, so don't give any reward
		return
	ow_node.rewards_given =true
	
	# both character_id_to_get_xp_rewards, character_xp_rewards must be the same size
	if ow_node.character_id_to_get_xp_rewards.size() != ow_node.character_xp_rewards.size():
		var t = ow_node._to_string()
		push_error("error in node " +t+ ": character_id_to_get_xp_rewards.size() != character_xp_rewards.size()")
		
	# give item rewards
	found_items_ids.append_array(ow_node.item_rewards)
	
	# give xp rewards
	for i in range(0, ow_node.character_id_to_get_xp_rewards.size()):
		# register the xp reward given
		var character_id = ow_node.character_id_to_get_xp_rewards[i]
		var xp_reward = ow_node.character_xp_rewards[i]
		give_xp_to_character(character_id, xp_reward)
	
	# show rewards menu
	gui.player_got_rewards_menu.initialize(ow_node)
	gui.player_got_rewards_menu.visible = true

#give xp to character with specified id
# record xp given if the character is not part of player's party
func give_xp_to_character(character_id:int, xp_to_give:int):
	var xp_given = Globals.main_game.character_xp_rewarded
	# record xp given
	if xp_given.has(character_id):
		xp_given[character_id] += xp_to_give
	else: 
		xp_given[character_id] = xp_to_give
	
	# give the reward to the character
	var xp_given_non_party = Globals.main_game.character_xp_awarded_to_characters_not_in_player_party
	var character = get_character_from_id(character_id)
	if character==null:
		# A character not in the player's party got xp. document it here and later on give the xp when the character joins the party.
		if not xp_given_non_party.has(character_id): 
			xp_given_non_party[character_id] = xp_to_give
		else: xp_given_non_party[character_id] += xp_to_give
	else:
		character.total_xp += xp_to_give	
	
	
