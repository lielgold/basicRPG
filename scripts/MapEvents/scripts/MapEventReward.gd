extends AbstractMapEvent

const GAME_DATA = preload("res://scripts/game_data.gd")

# executing this event gives the player characters rewards
export (Array, GAME_DATA.PLAYER_CHARACTER_IDS) var character_id_to_get_xp_rewards
export (Array, int, 0, 1000) var character_xp_rewards
export (Array, GAME_DATA.ITEMS_ID) var item_rewards
# these set a timer for the rewards
export (int, 0,1000)var reward_timer:=0 # 0 means the timer isn't used

func _ready():
	redo_event=false

# make a proper list of xp rewards
# sadly godot 3 can't export an array of arrays with a fixed size
func get_xp_data()->Array:
	# check for errors: character_id_to_get_xp_rewards, character_xp_rewards must be the same size
	if character_id_to_get_xp_rewards.size() != character_xp_rewards.size():
		var t = node_of_this_event._to_string()
		push_error("error in node " +t+ ": character_id_to_get_xp_rewards.size() != character_xp_rewards.size()")	
	
	var output :=[]
	var i:=0
	for c_id in character_id_to_get_xp_rewards:
		output.append([c_id,character_xp_rewards[i]])		
		i+=1
	return output

# defines to what the event does
func execute():
	# in timed rewards events, don't give rewards if the player got to the event too late
	if reward_timer>0 and reward_timer<=Globals.main_game.ingame_days_since_started:
		return
	
	# xp rewards
	var xp_rewards = get_xp_data()
	for i in range(xp_rewards.size()):
		Globals.main_game.give_xp_to_character(xp_rewards[i][0],xp_rewards[i][1])	
	
	# item rewards
	Globals.main_game.found_items_ids.append_array(item_rewards)
	
	is_finished=true
	
	# show rewards menu
	Globals.main_game.gui.player_got_rewards_menu.initialize_v2(xp_rewards, item_rewards)
	Globals.main_game.gui.player_got_rewards_menu.visible = true

# returns the class name since godot doesn't have it.
func get_class_name()->String:
	return "MapEventReward"
	
# Used for saving the node. returns a dict of the node's features to be saved. 
#func save()->Dictionary:
#	var base_save = .save()
#
#	return base_save	
