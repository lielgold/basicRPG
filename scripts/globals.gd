extends Node

const SAVE_GAME_DIRECTORIES = "user://save_games/"

enum WHO_WON{PLAYER, ENEMY, TIE, NOT_OVER_YET}
enum TEAMS{PLAYER,ENEMY}
enum DIRECTION{NONE, RIGHT, LEFT}

const STATUS_EFFECTS = preload("res://character/status_effects.gd")
const STATUS_EFFECTS_ID = STATUS_EFFECTS.STATUS_EFFECTS_ID

# system setting
export var DEBUG=false
export var COMBAT_V2 = true
export var animation_speed = 5

const game_data = preload("res://scripts/game_data.gd")

# character
var CHARACTER_STATS = game_data.CHARACTER_STATS
export var characters_created_counter = 0 #this is used to create an id for characters, so it must be saved and reloaded


# items
const ITEMS_ID = game_data.ITEMS_ID
const DO_ITEM_AT = game_data.DO_ITEM_AT

var main = null
var main_game = null
var overworld_path = "res://overworld.tscn"
var overworld = null
var all_characters = null
var combat_control = null
var action_matrix = null
var current_scene = null

# used for switching between scenes
var previous_scene = null
var previous_scene_index_in_parent


# this is a reference to the last node that was visited in the overworld
var last_visited_overworld_node

# this is used to create an id for enemy characters created in this node
# it's only persistant inside the node, not between nodes. used for mid fight initialization.
var number_of_characters_created_in_the_node:int=0


#records the result of each won fight, can be used to autoresolve fights
var win_records ={} #structed as    {packed_scene.resource_path : {character:Character = ..., hp_percentage_lost = 123, fight_was_won:bool}}

# this should contain all the player's characters, to be used when switching from scene to scene
var player_party


func _ready():
	var root = get_tree().get_root()
	current_scene = root.get_child(root.get_child_count() - 1)
	reset_fight_results()

	

func reset_fight_results():
	last_visited_overworld_node=null

# switch to a new scene (battle, level up, story) without removing the current one (overworld) from memory
# this new version was done after the refactor where I added the main scene as the root, so it works a bit different
# after a loss these characters will be added as enemies
func switch_scene_while_maintaining_the_previous_one_in_memory_v2(path_to_new_scene, scene_to_go_back_to, add_as_first:bool=false):
	assert(scene_to_go_back_to!=null)
	self.previous_scene = scene_to_go_back_to	
	self.previous_scene_index_in_parent = scene_to_go_back_to.get_index()
	
	#if pause_previous_scene: scene_to_go_back_to.get_tree().paused = true
	main_game.gui.hide_all_gui_elements()
	main_game.remove_child(scene_to_go_back_to)
	
	
	var new_scene = load(path_to_new_scene)
	new_scene = new_scene.instance()
	
	main_game.add_child(new_scene)
	if add_as_first:
		# add the new scene as first so other scenes would draw over it (for example, gui elements)
		main_game.move_child(new_scene, 0)
		
	new_scene.set_owner(main_game)
	
	return new_scene


# switch to a new scene (battle, level up, story) without removing the current one (overworld) from memory
# go back to the scene that was saved in self.previous_scene
# previous scene must implement an initialize_gui function that decides what gui elements to show by default
func go_back_to_previous_scene_v2(the_current_scene):
	assert(self.previous_scene!=null)	  

	main_game.remove_child(the_current_scene)
	the_current_scene.queue_free()
	self.previous_scene.initialize_gui()
	main_game.add_child(self.previous_scene)
	self.previous_scene.set_owner(main_game)
	main_game.move_child(self.previous_scene, self.previous_scene_index_in_parent)
	

func goto_scene(path):
	# This function will usually be called from a signal callback,
	# or some other function in the current scene.
	# Deleting the current scene at this point is
	# a bad idea, because it may still be executing code.
	# This will result in a crash or unexpected behavior.

	# The solution is to defer the load to a later time, when
	# we can be sure that no code from the current scene is running:
	call_deferred("_deferred_goto_scene", path)


func _deferred_goto_scene(path):
	# It is now safe to remove the current scene
	current_scene.free()

	# Load the new scene.
	var s = ResourceLoader.load(path)

	# Instance the new scene.
	current_scene = s.instance()

	# Add it to the active scene, as child of root.
	get_tree().get_root().add_child(current_scene)
	current_scene.set_owner(get_tree().get_root())

	# Optionally, to make it compatible with the SceneTree.change_scene() API.
	get_tree().set_current_scene(current_scene)


# Used for saving the node. returns a dict of the node's features to be saved. 
func save()->Dictionary:
	var save_dict = {
		"this_is_the_globals_node" : true,
		"filename" : get_filename(),
		"parent" : get_parent().get_path(),
		"DEBUG": DEBUG,
		"COMBAT_V2": COMBAT_V2,
		"animation_speed" : animation_speed,
		"characters_created_counter" : characters_created_counter,
		"win_records" : win_records,		
		"number_of_characters_created_in_the_node": number_of_characters_created_in_the_node,
		
	}
	return save_dict
