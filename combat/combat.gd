extends Node

class_name CombatEncounter

const combat_action_button_resource = preload("res://combat/action_matrix/combat_action_button.tscn")

const do_turn_start_combat_texture = preload("res://assets/menus/do turn button start combat.png")
const do_turn_end_turn_texture = preload("res://assets/menus/do turn button end turn.png")
const do_turn_choose_abilities_texture = preload("res://assets/menus/do turn button choose abilities.png")



enum COMBAT_PHASE {SELECTING_CHARACTERS, SELECTING_ABILITIES, BEFORE_FIRST_TURN, COMBAT_STARTED,COMBAT_ENDED}
const NUMBER_OF_COMBAT_ROUNDS = 3

# signal when a character dies
signal character_died(character)


onready var end_game_menu = $"end game menu"
onready var curret_round_text = $"middle_container/current_round"
onready var winner_text = $"middle_container/winner"
onready var start_turn_button = $"middle_container/start_turn"
onready var current_phase_text = $"middle_container/current_phase"
onready var current_act = $"middle_container/current_act"
onready var go_back_button = $"middle_container/go_back_button"
onready var fast_forward_button = $"middle_container/fast_forward_button"
onready var player_character_limit = $"middle_container/player_character_limit"

onready var all_characters = $"all_characters"
onready var action_matrix = $"ScrollContainer/action_matrix"




# the character all do their turns every round. after max_combat_round ends, a new phase begins and the rounds
# start anew
var started_combat :=false # this changes to true once drafting ends
var combat_is_over := false
var combat_round := 0
var max_combat_round := 3
var phase_number := 0
var act:int = 1

var one_of_the_character_did_an_action_this_phase:=false
var previous_selected_action_button = null # this is used to switch action buttons. it refers to the selected action button, or null if none are selected

var ow_node_that_created_this_combat_scene = null
var characters_created_in_this_scene_counter := 0 # used to generate id for characters

var turn_order =[]
var end_of_phase_turn_order =[]

var action_history = [] # contains the history of actions performed in this combat. format: {character, round_number, ability, item}

var action_matrix_current_turn := 0

var phase_of_combat :int= COMBAT_PHASE.SELECTING_CHARACTERS
var phase_changed :=false

export var max_num_of_selected_player_characters :int= 3
var num_of_selected_player_characters := 1

# sort actions by their ap cost
#class CustomAPSorter:
#	static func sort_by_ap_cost(a, b):		
#		if a.ap_cost < b.ap_cost: return true
#		return false

# sort actions by their speed
class CustomSpeedSorter:
	static func sort_by_speed(a, b):		
		if a.speed < b.speed or (a.speed == b.speed and a.button.character.part_of_player_party and !b.button.character.part_of_player_party): return true
		return false

# sort character by their hp, lowest to highest
class CustomHPSorter:
	static func sort_by_hp_cost(a, b):		
		if a.get_total_hp() < b.get_total_hp(): return true
		return false


# Called when the node enters the scene tree for the first time.
func _ready():
	end_game_menu = $"end game menu"
	action_matrix = $"ScrollContainer/action_matrix"
	player_character_limit = $"middle_container/player_character_limit"
	
	Globals.combat_control = self
	Globals.action_matrix = action_matrix
	
	action_history = []
	
	# setup gui
	start_turn_button.initialize(self)	
	
	Globals.main_game.gui.party_menu.start_party_menu()
	Globals.main_game.gui.party_menu.show_draft_buttons()
	
	player_character_limit.text = "Character limit: " + String(max_num_of_selected_player_characters)
	
	end_game_menu.hide()
	
	set_turn_order_v3(true)
	
	# setup characters	
	# set teams, character id,  and signals
	for c in Globals.all_characters.get_all_characters():
		if c in Globals.all_characters.get_allies(Globals.TEAMS.PLAYER):
			c.team = Globals.TEAMS.PLAYER
		else:
			c.team = Globals.TEAMS.ENEMY

		# set character signals
		c.connect("character_died", self, "character_died_update_action_button",[c])


		

# add the player to the combat. removes it from the global player party for the duration of combat.
# return false if there was a problem
func add_player_character(character:Character)->bool:
	# limit the number of player characters
	if num_of_selected_player_characters > max_num_of_selected_player_characters:
		Globals.main_game.gui.play_general_message("Can't add any more characters.")
		return false
	num_of_selected_player_characters+=1
	
	character.team = Globals.TEAMS.PLAYER	
	character.visible = true
	
	Globals.player_party.remove_child(character)
	all_characters.allies.add_child(character)	
	
	character.combat_started_reset_character()
	
	set_turn_order_v3(true)
	character.connect("character_died", self, "character_died_update_action_button",[character])
	
	action_matrix.update_turn_indicators()
	
	return true

func remove_player_character(character:Character, fix_turn_order:=false):
	# limit the number of player characters
	num_of_selected_player_characters-=1	
	
	character.visible = false
	Globals.all_characters.remove_character(character)
	Globals.player_party.add_child(character)
	
	if fix_turn_order: set_turn_order_v3(true)



# set the turn order
# this means we remove all buttons from the action matrix, and fill it from scratch
# create action buttons and populate the action matrix with them
# set_player_default_action_to_regular_attack - set the actions of the player characters to regular attack
func set_turn_order_v3(set_player_default_action_to_regular_attack:=false, include_dead_characters:=false):
	for c in action_matrix.get_children():
		action_matrix.remove_child(c)
	
	# this sets up the action matrix
	var first_combat_round = phase_number * 3
	for combat_round_local in range(first_combat_round,first_combat_round+3):				
		var action_buttons_to_sort = []
		
		var characters = all_characters.get_all_characters()
		if !include_dead_characters: characters = all_characters.get_all_living_characters()
		
		# matrix size is equal to number of characters * number of action
		action_matrix.columns = characters.size()
		
		# create the action buttons
		for character in characters:			
			var combat_action_button = combat_action_button_resource.instance()
			# this set the action of the button
			# for enemies its the one set in the editor, the third action set in the editor is the action they'll do in the thid turn
			# for the player the action is always the regular attack.
			if set_player_default_action_to_regular_attack and character.part_of_player_party:
				var reg_attack =  character.abilities_manager.get_regular_attack()
				combat_action_button.initialize(self, character, reg_attack, true)
			else: 
				# this determines the AI of enemies. They will do action number x on turn x
				var c_count = character.abilities_manager.get_child_count()
				var ab = character.abilities_manager.get_child(combat_round_local % c_count)
				combat_action_button.initialize(self, character, ab)
				combat_action_button.change_direction_of_ability(true)
			var ability_speed = combat_action_button.get_combat_action_speed()
			action_buttons_to_sort.append({button = combat_action_button, speed = ability_speed})
			
		# sort the action buttons and add them to the matrix
		action_buttons_to_sort.sort_custom(CustomSpeedSorter, "sort_by_speed")
		
		for v in action_buttons_to_sort:
			action_matrix.add_child(v.button)
			v.button.owner = action_matrix
	
	action_matrix.mark_next_character_to_play()
	# hide movement buttons of action buttons at the edge of the matrix
	action_matrix.update_action_buttons_movement_buttons()
	action_matrix.update_turn_indicators()
	#action_matrix.hide_action_buttons_of_current_turn(false)
	

		
func call_characters_start_of_round_passives():
	for ch in Globals.all_characters.get_all_characters():
		var p_ids = ch.passives_manager.get_all_passives_id_based_on_activation_time(Passive.DO_PASSIVE_AT.START_OF_ROUND)
		for id in p_ids:
			if ch.passives_manager.has_passive_and_enabled(id):				
				if(id==Passive.PASSIVES_ID.GAIN_DAMAGE_REDUCTION):
					ch.passives_manager.get_passive(id).add_damage_reduction()
				if(id==Passive.PASSIVES_ID.GAIN_ATTACK_POWER_EVERY_ROUND):
					ch.passives_manager.get_passive(id).gain_attack_power_every_round()				
		

#func start_turn_button_pressed():
#	# if the player didn't draft any characters, do nothing and notify him
#	if all_characters.is_allies_empty():
#		Globals.main_game.gui.play_general_message("Choose your characters.")
#		return
#
#	if phase_of_combat == COMBAT_PHASE.SELECTING_CHARACTERS:
#		phase_of_combat = COMBAT_PHASE.SELECTING_ABILITIES
#		start_turn_button.text ="Choose abilities"
#		Globals.main_game.gui.party_menu.hide_draft_buttons()
#		return
#
#	elif phase_of_combat == COMBAT_PHASE.SELECTING_ABILITIES:
#		phase_of_combat = COMBAT_PHASE.BEFORE_FIRST_TURN
#		start_turn_button.text ="Start combat"
#		return
#
#	if phase_of_combat == COMBAT_PHASE.SELECTING_CHARACTERS:
#		phase_of_combat = COMBAT_PHASE.BEFORE_FIRST_TURN
#		start_turn_button.text ="End draft"
#		Globals.main_game.gui.party_menu.hide_draft_buttons()
#		return
#
#	elif phase_of_combat == COMBAT_PHASE.BEFORE_FIRST_TURN:
#		phase_of_combat = COMBAT_PHASE.COMBAT_STARTED		
#		start_turn_button.text ="Do first turn"
#		started_combat = true
#		_do_before_first_turn()
#		#action_matrix.hide_action_buttons_of_current_turn()
#		action_matrix.disable_all_action_buttons()
#		return
#
#	elif phase_of_combat == COMBAT_PHASE.COMBAT_STARTED:
#		start_turn_button.text ="Do turn"
#		do_one_character_turn_v3()
#
#		# skip turns until there's a living character
#		while !is_current_character_alive():
#			do_one_character_turn_v3()		
#		return
#
#	push_error("no legal combat phase was found inside start_turn_button_pressed")

func start_turn_button_pressed():
	# if the player didn't draft any characters, do nothing and notify him
	if all_characters.is_allies_empty():
		Globals.main_game.gui.play_general_message("Choose your characters.")
		return
	
	# at this point the player picks characters for the combat, this code will only run once	
	if phase_of_combat == COMBAT_PHASE.SELECTING_CHARACTERS or phase_of_combat == COMBAT_PHASE.SELECTING_ABILITIES:		
		#start_turn_button.text ="end draft"
		Globals.main_game.gui.party_menu.hide_draft_buttons()

		started_combat = true
		if phase_of_combat == COMBAT_PHASE.SELECTING_CHARACTERS: 
			_do_before_first_turn()
#		elif phase_of_combat == COMBAT_PHASE.SELECTING_CHARACTERS: 
#			start_turn_button.texture_hover = do_turn_choose_abilities_texture
#			start_turn_button.texture_pressed = do_turn_choose_abilities_texture
		phase_of_combat = COMBAT_PHASE.COMBAT_STARTED
		action_matrix.disable_all_action_buttons()
	
	# combat starts, this will run once per turn
	if phase_of_combat == COMBAT_PHASE.COMBAT_STARTED:
		#start_turn_button.text ="Do turn"
		start_turn_button.texture_hover = do_turn_end_turn_texture
		start_turn_button.texture_pressed = do_turn_end_turn_texture		
		do_one_character_turn_v3()
		
		# change textures of do turn button
		if phase_changed:
			start_turn_button.texture_hover = do_turn_choose_abilities_texture
			start_turn_button.texture_pressed = do_turn_choose_abilities_texture
		else:		
			start_turn_button.texture_hover = do_turn_end_turn_texture
			start_turn_button.texture_pressed = do_turn_end_turn_texture
		phase_changed = false
		
		# skip turns until there's a living character
		while !is_current_character_alive():
			do_one_character_turn_v3()		
		return
		
	push_error("no legal combat phase was found inside start_turn_button_pressed")

func do_one_character_turn_v3():		
	if combat_round==0:
		# can't switch actions after combat starts
		action_matrix.disable_all_action_buttons()	
	
	var action_button = action_matrix.get_current_turn_button_v2()
	action_button.character.do_turn_v4(action_button)	
	action_matrix.character_did_its_turn() # mark the current actor as done, and mark the next actor to play	
	var next_action_button = action_matrix.get_current_turn_button_v2() # get next actor	
	
	action_matrix.remove_dead_characters_buttons()
	
	# if everyone played or the active player moved a row	
	# TODO there's a potential but here in "active player moved a row". if some ability moves a player up / down this can cause cascading issues as the game assumes the entire row finished playing
	# it will cause weird bugs
	if next_action_button==null or action_matrix.get_coordinates_of_button(action_button).y != action_matrix.get_coordinates_of_button(next_action_button).y:
		combat_round +=1
		reduce_status_effects_for_all_characters(1)
		
		# phase over
		if next_action_button==null: # if everyone did their turn
			combat_round =0
			phase_number +=1
			phase_of_combat = COMBAT_PHASE.SELECTING_ABILITIES
			action_matrix.enable_all_action_buttons()
			
			current_phase_text.text = "Phase: " + String(phase_number+1)
			phase_changed = true
			
			if phase_number==2:
				end_game()			
			
			set_turn_order_v3(true)
		
		call_characters_start_of_round_passives()
		curret_round_text.text = "Round: " + String(combat_round+1)
		
	var winner = who_won_the_game()
	if winner!=Globals.WHO_WON.NOT_OVER_YET:
		end_game()
	
	action_matrix.update_turn_indicators()
	
	# update the action matrix
	action_matrix.update_matrix()
	
	# update the characters
	for c in all_characters.get_all_characters():
		c.set_gui()


func is_current_character_alive():
	return action_matrix.get_current_turn_button_v2().character.is_alive()
	#return action_matrix.get_child(action_matrix_current_turn).character.is_alive()

func change_winner_text(winner):
	if winner== Globals.WHO_WON.PLAYER:
		winner_text.text = "You won!"
	elif winner== Globals.WHO_WON.NOT_OVER_YET:
		winner_text.text = "It's a draw."
	else:
		winner_text.text = "You lost!"
	

func end_game():
	self.combat_is_over = true
	var winner = who_won_the_game()
	start_turn_button.disabled = true
	change_winner_text(winner)
	var end_game_timer = Timer.new()
	end_game_timer.connect("timeout", self, "_show_combat_ended_menu")
	add_child(end_game_timer)	
	end_game_timer.set_wait_time(2)
	end_game_timer.start()	



# end the fight and go back to the overworld
# record the result of the fight before leaving this scene
func end_fight_and_go_back_to_over_world():
	ow_node_that_created_this_combat_scene.who_won_combat = who_won_the_game()
	
	# record the results of the fight if it was a win.	
	# record hp lost per player character
	var records = []
	for c in Globals.all_characters.get_all_characters():
		if c.part_of_player_party:
			var lost_hp = float(c.fight_start_hp - c.hp) / float(c.max_hp)
			#lost_hp = float(round(lost_hp*100))*0.01 # this does a  10^-3 round function
			if lost_hp!=0:
				records.append({character_id = c.id, hp_percentage_lost = lost_hp})
	
	# if this is fight is a retry, add the losses of the previous fight to the new record
	if ow_node_that_created_this_combat_scene.is_mid_fight:		
		for mid_record in ow_node_that_created_this_combat_scene.mid_fight_record:
			# if the character already appears in a record, add it to the previous record rather than adding a new one
			var character_found_in_another_record = false			
			for record in records:
				if record.character_id==mid_record.character_id:
					record.hp_percentage_lost += mid_record.hp_percentage_lost
					character_found_in_another_record = true
					break
			if !character_found_in_another_record: records.append(mid_record)
	
	# if fight was won, add the record to the win_records
	if ow_node_that_created_this_combat_scene.who_won_combat==Globals.WHO_WON.PLAYER:		
		ow_node_that_created_this_combat_scene.reset_mid_fight()
		var fight_resource_path = ow_node_that_created_this_combat_scene.current_fight_event.call_scene.resource_path
		if !Globals.win_records.has(fight_resource_path):
			Globals.win_records[fight_resource_path] = [records]
		else: 
			Globals.win_records[fight_resource_path].append(records)	
		
	else:
		# handle losses
		ow_node_that_created_this_combat_scene.is_mid_fight=true # the fight ended with a loss, this allows the player to start it from  the middle next time
		ow_node_that_created_this_combat_scene.mid_fight_record = records
		# save enemies so if the fight is done again, theu'll have the same hp		
		for enemy in Globals.all_characters.get_enemies(Globals.TEAMS.PLAYER):
			ow_node_that_created_this_combat_scene.mid_fight_enemy_characters_v3.append([enemy.id, enemy.hp])
			
	for character in Globals.all_characters.get_all_characters():		
		if character.part_of_player_party:			
			remove_player_character(character)	
	
	Globals.main_game.go_back_from_combat(self)
	

func _show_combat_ended_menu():
	var winner = who_won_the_game()
	end_game_menu.activate(winner)

# returns who won the game.
func who_won_the_game():
	var characters = Globals.all_characters.get_all_characters()
	var allies_dead = true
	var enemies_dead = true
	
	for c in characters:
		if c.hp>0:
			if c.team==Globals.TEAMS.PLAYER:
				allies_dead = false
			else:
				enemies_dead = false
	
	if(allies_dead and enemies_dead): 
		return Globals.WHO_WON.TIE
	elif(allies_dead): return Globals.WHO_WON.ENEMY
	elif(enemies_dead): return Globals.WHO_WON.PLAYER
	return Globals.WHO_WON.NOT_OVER_YET

# reduce status ailments for all characters by specified duration
func reduce_status_effects_for_all_characters(duration:int):
	for ch in Globals.all_characters.get_all_characters():
		ch.status_effects.reduce_all_status_effects_by_duration(duration)


# does things that should be done before the first turn
func _do_before_first_turn():
	phase_of_combat = COMBAT_PHASE.COMBAT_STARTED
	
	# hide return to overworld button
	go_back_button.hide()
	# show fast forward button
	fast_forward_button.show()
	
	#h hide draft menu
	Globals.main_game.gui.party_menu.hide()

# changes the action in the action matrix
# does this by removing the old action button, putting the new one, and sorting the matrix
# called after the player presses an action button
func switch_action_button_to_new_action_v2(prev_action_button, character:Character, id_of_the_new_action:int):	
	var ability:Ability = character.abilities_manager.get_ability(id_of_the_new_action)	
	var new_action_button = combat_action_button_resource.instance()	
	var abil = character.abilities_manager.get_ability(id_of_the_new_action)
	new_action_button.initialize(self, character, abil)
	
	# fix bug with the tooltip	
	new_action_button.select_action_button.hint_tooltip = abil.gui_name
	
	var combat_round_of_action:int = action_matrix.get_coordinates_of_button(prev_action_button).y	
	
	var round_of_action_mod3 = combat_round_of_action%3
	
	# 1. remove the entire row of buttons that has the old action button that is going to be removed
	# 2. remove the old button
	# 3. put in the new action button in the row
	# 4. put entire row back in the matrix
	var button_row = action_matrix.get_children_row(round_of_action_mod3)
	var index_but = button_row.find(prev_action_button)
	
	# 1. remove the entire row of buttons that has the action button that is going to be removed
	var row_size = button_row.size()
	var c_row = action_matrix.get_children_row(round_of_action_mod3)
	c_row.invert()	
	for c in c_row:
		action_matrix.remove_child(c)
	
	# 2. remove the old button
	var t1 = button_row.size()
	button_row.remove( button_row.find(prev_action_button) ) # remove the prev button
	var t2 = button_row.size()
	assert(t1!=t2, "failed to remove button when switching actions")
	
	# 3. put in the new action button
	# this puts it in the proper place relative to the speed of the actions
	var added_button:=false	
	for i in range(button_row.size()):
		if new_action_button.combat_action_speed<= button_row[i].combat_action_speed:
			button_row.insert(i,new_action_button)
			added_button=true
			break
	if !added_button:
		button_row.append(new_action_button)
	
	var t3 = button_row.size()
	assert(t2!=t3, "failed to add new button when switching actions")
		
	# 4. put entire row back in the matrix
	var b_row = button_row
	b_row.invert()
	for b in b_row:
		action_matrix.add_child(b)
		action_matrix.move_child(b, row_size * round_of_action_mod3)

	for b in action_matrix.get_children():
		b.its_my_turn = false
	action_matrix.mark_next_character_to_play()

	# hide movement buttons at the edge of the matrix
	action_matrix.update_action_buttons_movement_buttons()	


func character_died_update_action_button(character:Character):
	for b in action_matrix.get_children():
		if b.character==character:
			b.show_character_died()

# ------------- targeting

# get enemy with the lowest hp after this character
func get_lowest_hp_living_enemy(character_that_looks_for_enemy:Character, get_lowest:=true)->Array:
	var enemies = all_characters.get_enemies(character_that_looks_for_enemy.team, true)
	enemies.sort_custom(CustomHPSorter, "sort_by_hp_cost")
	
	if enemies.empty(): return []	
	else:
		if get_lowest: return [enemies[0]]
		else: return [enemies[-1]] # return the highest hp

# get enemy with the highest hp after this character
func get_highest_hp_living_enemy(character_that_looks_for_enemy:Character):
	return get_lowest_hp_living_enemy(character_that_looks_for_enemy, false)


#------------------- end targeting



# this combat encounter was stopped in the middle since the player failed to win it
# but he might have wounded enemies, and did other relevant stuff
# start this combat encounter with the data from the previous round (such as enemy hp)
func initialize_combat_with_information_from_the_combat_node(overworld_combat_node):
	self.ow_node_that_created_this_combat_scene = overworld_combat_node
	
	# update the hp of enemies
	# the record is in the form of [ [enemy1.id, enemy1.hp], [enemy1.id, enemy1.hp], [enemy1.id, enemy1.hp] ]
	var mid_fight_enemies_record = overworld_combat_node.mid_fight_enemy_characters_v3
	for character_record in mid_fight_enemies_record:
		for enemy in all_characters.get_enemies(Globals.TEAMS.PLAYER):
			if enemy.id == character_record[0]:
				enemy.hp = character_record[1]
				
				enemy.emit_signal("health_changed", enemy.hp, enemy.temp_hp)
				if !enemy.is_alive():
					enemy.emit_signal("character_died")
	
	# update action matrix
	set_turn_order_v3(true)
	
	for b in action_matrix.get_children():
		b.update_healthbar()


