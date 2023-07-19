extends GridContainer

const TARGETING_TYPE = preload("res://character/ability_v2.gd").TARGETING_TYPE

# get a list of characters after the given character in the action buttons
# character_looking_for_others - characters looking for others
# get_enemies - whether to look for enemies or not
# after_character - if true, get characters after character_looking_for_others, if not get characters before him
# say the actions buttons are [enemy1, ally2, character_looking_for_others, enemy2, enemy3, ally2]
# and we look for enemies, the return value will be [enemy2, enemy3]
# if get_enemies=false, the return value will be [ally2]
# use_attack_range - output will be limieted to characters that are within the main character attack range. if it's 1, than in the example above the return value will be [enemy2]
func _get_characters_after_given_character(character_looking_for_others:Character, use_attack_range:bool, get_enemies:=true, after_character:=true)->Array:
	var found_button = false	
	var output_characters = []
	var search_range_limit = character_looking_for_others.attack_range
	if !use_attack_range: search_range_limit = 999 #there's not limit to the search

	var action_buttons = get_children()
	if !after_character: action_buttons.invert()

	# find the first button of the character looking for enemies, and then find enemies after him
	# and return them
	var search_counter = 1
	for b in action_buttons:
		if b.character==character_looking_for_others: 
			found_button = true
			continue

		if found_button:
			if get_enemies and character_looking_for_others.team!=b.character.team:
				output_characters.append(b.character)
			if !get_enemies and character_looking_for_others.team==b.character.team:
				output_characters.append(b.character)

			# only add targets in the attack range
			search_counter +=1
			if search_counter==search_range_limit: break

	return output_characters

# unused, move to action matrix and fix it 
# get the closest enemy from character_that_looks_for_enemy
# character_that_looks_for_enemy - the character that looks for an enemy
# number_of_enemies_to_find - how many targets 
# get_furthest - get furthest enemies intead of closest
func get_closest_enemies(character_that_looks_for_enemy:Character, number_of_enemies_to_find:int, get_furthest:bool, use_attack_range=true, after_character=true)->Array:
	var targets = []
	var num_of_enemies_found :=0

	var enemies = _get_characters_after_given_character(character_that_looks_for_enemy, use_attack_range,true,after_character)
	if get_furthest: enemies.invert()

	for enemy in enemies:
		targets.append(enemy)
		num_of_enemies_found +=1
		if num_of_enemies_found==number_of_enemies_to_find: break
	return targets

# get characters in search_range of character
# example: search_range=1, include_allies=true, include_enemies=true
# [enemy1, ally2, character_looking_for_others, enemy2, enemy3, ally2] --> [ally2, enemy2]
# ally_team - this is the team used as reference when looking for allies and enemies. if ally_team == TEAM.PLAYER and include_allies=true than the output includes character that are of TEAM.PLAYER
func get_characters_in_range_of_character(character:Character, search_range:int, ally_team, include_allies=true, include_enemies=true):
	var output = []
	if !include_allies and !include_allies: return output

	var action_buttons = get_children()
	var character_action_button_index = get_button_index(character, Globals.combat_control.combat_round)
	
	for i in range(1,search_range+1):
		for j in [i, i*-1]: # search both before and after the character:
			var other_character = action_buttons[character_action_button_index+i].character
			if (include_allies and character.team == other_character.team) or (include_enemies and character.team != other_character.team):
				output.append(other_character)
	return output

# get the closest enemy from character_that_looks_for_enemy
# character_that_looks_for_enemy - the character that looks for an enemy
# number_of_enemies_to_find - how many targets 
# get_furthest - get furthest enemies intead of closest
# get_allies_instead - get allies instead of enemies
func get_closest_enemies_v3(character_that_looks_for_enemy:Character, number_of_enemies_to_find:int, get_furthest:bool, use_attack_range:=true, 
get_allies_instead:=false, only_characters_to_the_right:=false, only_characters_to_the_left:=false)->Array:
	var targets := []
	var buttons = get_children()
	var ind := get_button_index(character_that_looks_for_enemy, Globals.combat_control.combat_round)
	
	if only_characters_to_the_right and only_characters_to_the_left: return []
	for i in range(1,buttons.size()):
		# check attack range
		if use_attack_range and character_that_looks_for_enemy.attack_range < i: break
		
		# add targets
		# add targets to the right
		if !only_characters_to_the_left and (ind+i)<buttons.size():
			if (!get_allies_instead and buttons[ind+i].character.team != character_that_looks_for_enemy.team) or \
				(get_allies_instead and buttons[ind+i].character.team == character_that_looks_for_enemy.team): 
					if targets.find(buttons[ind+i].character)==-1: # don't add the same character twice
						targets.append(buttons[ind+i].character)
		# add targets to the left
		if !only_characters_to_the_right and (ind-i)>=0:
			if (!get_allies_instead and buttons[ind-i].character.team != character_that_looks_for_enemy.team) or \
				(get_allies_instead and buttons[ind-i].character.team == character_that_looks_for_enemy.team): 
					if targets.find(buttons[ind-i].character)==-1: # don't add the same character twice
						targets.append(buttons[ind-i].character)	
	
	if get_furthest: targets.invert()
	
	# get only number_of_enemies_to_find
	var targets2 := []
	for j in range(0,min(number_of_enemies_to_find,targets.size())): targets2.append(targets[j])
	
	return targets2

func get_furthest_enemies_v3(character_that_looks_for_enemy:Character, character_index:int, number_of_enemies_to_find:int, get_furthest:bool, use_attack_range:=true, get_allies_instead:=false)->Array:
	return get_closest_enemies_v3(character_that_looks_for_enemy, number_of_enemies_to_find, true, use_attack_range, false)


# return the index of an action button based on the character to search for, and the combat round to search for
# return -1 if not found (usually means that it's dead, and thus wasn't added to the action matrix)
func get_button_index(character_to_search_for,combat_round)->int:
	for i in range(0, columns):
		var button = get_child(combat_round*columns + i)
		if button.character==character_to_search_for: 
			return combat_round*columns + i			
	return -1

# get characters to the right of looking character
# character_that_looks_for_characters - the characters looking for other characters 
# number_of_characters_to_find - number of characters to find
# get_allies - include allies in the search
# get_enemies - includes enemies in the search
# limit_search_to_looking_characters_row - if true, only include characters in the same row rather the other rows
# TODO finish this. start working with matrix ffs, fix this entire code
func get_characters_from_index_of_character(character_that_looks_for_characters:Character, number_of_characters_to_find:int, get_allies:=true, get_enemies:=true, 
	limit_search_to_looking_characters_row:=true, get_characters_to_the_right:=true, get_characters_to_the_left:=true):
	var character_index = get_button_index(character_that_looks_for_characters, Globals.combat_control.combat_round)
	var buttons = get_children_row(Globals.combat_control.combat_round)
	var found_characters = []
	
	var x_looking_character = get_button_index(character_that_looks_for_characters, Globals.combat_control.combat_round)
	var y_looking_character = Globals.combat_control.combat_round

	
	# get the action buttons where we need to search
	var action_buttons = [] # these are the action buttons where there are characters we are looking for
	if limit_search_to_looking_characters_row:
		# get the action buttons of characters after the character is found
		var found_character := false
		for action_button in get_children_row(Globals.combat_control.combat_round):
			if action_button.Character==character_that_looks_for_characters:
				found_character=true
				continue
			
			if found_character:
				action_buttons.append(action_button)
	else:
		action_buttons = get_children().slice(character_index+1, get_children().size())

	# add the characters	
	for button in action_buttons:
		if get_allies and button.character.team == character_that_looks_for_characters.team:
			found_characters.append(button.character)
		elif get_enemies and button.character.team != character_that_looks_for_characters.team:
			found_characters.append(button.character)
	
	# remove duplicates and the looking character from the found_characters
	var output = []
	for c in found_characters:
		if c!=character_that_looks_for_characters and output.find(c)==-1:
			output.append(c)
	
	# get only number_of_characters_to_find
	var output2 = []
	for j in range(0,min(number_of_characters_to_find,output.size())): 
		output2.append(output[j])
	return output2


# get the character om the given coordinates, null if it's out of the matrix
func get_character_in_index(x:int, y:int)->Character:
	if y<0 or y>=Globals.combat_control.NUMBER_OF_COMBAT_ROUNDS: return null
	var row = get_children_row(y)
	if x<0 or x>=row.size(): return null
	return row[x].character
	

# --------- started targeting rework using coordinates instead of wierd lists

# get characters in a column. The column is relative to the character, so If the character is in 5 and column_number==1 
# than the function returns:
#  7 8 9       9
#  4 5 6   ->  6
#  1 2 3       3
# column_number == -1  return:
#  7 8 9       7
#  4 5 6   ->  4
#  1 2 3       1
func get_column_v2(character:Character, column_number:int, get_allies:=true, get_enemies:=true):
	var output := []
	var coordinates = get_coordinates_of_character(character)
	for i in [-1,0,1]:
		var character_button = get_button_in_coordinates(coordinates.x+column_number, coordinates.y+i)
		if character_button!=null:
			if get_allies and character_button.character.team == character.team:
				output.append(character_button)
			elif get_enemies and character_button.character.team != character.team:
				output.append(character_button)
	return output


func get_enemy_column_v2(character:Character, column_number:int):
	return get_column_v2(character,column_number,false,true)

func get_ally_column_v2(character:Character, column_number:int):
	return get_column_v2(character,column_number,true,false)

# get the (x,y) coordinates of the given character in the current combat round
func get_coordinates_of_character(character:Character):
	var row = get_children_row(Globals.combat_control.combat_round)
	var i =0
	for j in range(0,row.size()):
		if row[j].character == character:
			i=j
			break
	return {x = i, y = Globals.combat_control.combat_round}	
	
func get_button_in_coordinates(x:int,y:int):
	var row_size = get_child_count()/3
	
	# return null if coordinates are out of the matrix
	if x<0 or y<0 or y>2 or x>row_size: return null	
	
	var tx = 0
	var ty = 0
	for button in get_children():
		if tx%row_size==x and ty == y: return button
				
		tx+=1
		if tx > row_size + row_size*ty:
			ty +=1
		

# returns the coordinates of a given action button, raise error otherwise
func get_coordinates_of_button(action_button):
	var row_size = get_child_count()/3	
	var x = 0
	for button in get_children():
		if button == action_button:
			return Vector2(x%row_size, int(x/row_size))
		x+=1
	# raise error if button not ound because this function should never be called with an action button that it doesn't contain
	push_error("get_coordinates_of_button called with a button it doesn't contain")

# get acrion button in add_index relative position to the given character. 
# so for character=character3 and add_index=1, the result would be:
# [character1, character2, character3, character4] -> [character4]
func get_action_button_in_same_row_v2(character:Character, add_index:int)->Array:
	var output = []
	var coordinates = get_coordinates_of_character(character)
	var button = get_button_in_coordinates(coordinates.x+add_index, coordinates.y)
	if button !=null: output.append(button)
	return output


# get which character is in front of the other in the same row. 
# For character=chararacter1, target= character2, Returns:
# [character1, character2, character3, character4] ->    Globals.DIRECTION.RIGHT
# [character2, character1, character3, character4] ->    Globals.DIRECTION.LEFT
# if character==target ->     Globals.DIRECTION.SELF
func get_direction_between_characters_in_same_row(character_a:Character,character_b:Character)->int:
	if character_a==character_b: return Globals.DIRECTION.NONE
	var character_a_coordinates = get_coordinates_of_character(character_a)
	var character_b_coordinates = get_coordinates_of_character(character_b)
	
	if character_a_coordinates.x < character_b_coordinates.x: return Globals.DIRECTION.RIGHT
	else: return Globals.DIRECTION.LEFT

# get the action button of the given character in the current row
func get_action_button_from_character(character:Character):
	for b in get_children_row(Globals.combat_control.combat_round):
		if b.character==character:
			return b
	return null

# push a character 1 time in a given direction, for the specified number of times
# not to be confused with combat.move_action_button which is called when the player clicks on 
# movement button, and pays for it with charges / movement points
# this is a push done for some other reason (ability that pushes, for example)
# push_direction - direction to push the character as defined in Globals.DIRECTION

# For push_target=chararacter1, push_direction= Globals.DIRECTION.RIGHT.   does:
# [character1, character2, character3, character4] ->    [character2, character1, character3, character4]
# For push_target=chararacter1, push_direction= Globals.DIRECTION.LEFT.    does:
# [character1, character2, character3, character4] ->    does nothing
func push_character(push_target:Character, push_direction:int):
	if push_direction==Globals.DIRECTION.NONE: return # can't push self
	var action_button = get_action_button_from_character(push_target)
	
	var index = action_button.get_index()
	if push_direction==Globals.DIRECTION.RIGHT and not is_right_edge_button(action_button):
		move_child(action_button, index + 1)
	elif push_direction==Globals.DIRECTION.LEFT and not is_left_edge_button(action_button):
		move_child(action_button, index - 1)
	
	# hide movement buttons of action buttons at the edge of the matrix
	update_action_buttons_movement_buttons()	


# get the action buttons of the slowest enemies. Those are the enemies whose actions have the most speed, so the rightmost enemies on the row
# character_that_looks_for_others - the characters that looks for targets
# get_fastest_instead - get the fastest character instead
func get_slowest_characters(character_that_looks_for_others:Character,number_of_characters_to_find:int, get_enemies :=true, get_allies :=true, get_fastest_instead:=false)->Array:
	var output :=[]
	var row := get_children_row(Globals.combat_control.combat_round)
	if get_fastest_instead==false: row.invert()
	var num_characters_found :=0
	for button in row:
		if num_characters_found == number_of_characters_to_find: break
		if (get_enemies and character_that_looks_for_others.team != button.character.team) or \
			(get_allies and character_that_looks_for_others.team == button.character.team):
			num_characters_found+=1
			output.append(button)
	
	return output

func get_slowest_enemies(character_that_looks_for_others:Character,number_of_characters_to_find:int):
	return get_slowest_characters(character_that_looks_for_others,number_of_characters_to_find, true, false)

func get_slowest_allies(character_that_looks_for_others:Character,number_of_characters_to_find:int):
	return get_slowest_characters(character_that_looks_for_others,number_of_characters_to_find, false, true)

func get_fastest_enemies(character_that_looks_for_others:Character,number_of_characters_to_find:int):
	return get_slowest_characters(character_that_looks_for_others,number_of_characters_to_find, true, false, true)

func get_characters_in_the_same_row(character_that_looks_for_others:Character,get_allies:=true, get_enemies:=true) ->Array:
	var output :=[]
	for button in get_children_row(Globals.combat_control.combat_round):
		if (get_allies and button.character.team == character_that_looks_for_others.team) or \
			(get_enemies and button.character.team != character_that_looks_for_others.team):
				output.append(button)
	return output

func get_allies_of_character(character_that_looks_for_others) ->Array:
	return get_characters_in_the_same_row(character_that_looks_for_others, true, false)

func get_enemies_of_character(character_that_looks_for_others) ->Array:
	return get_characters_in_the_same_row(character_that_looks_for_others, false, true)
		

# get the first action buttons of characters after character_that_looks_for_others that are allies or enemies, as specified
# get_characters_to_the_right - if true, the characters are to the right of character_that_looks_for_others. Otherwise, get characters to the left.
# num_to_find - number of characters to find
# get_allies - get allies of character_that_looks_for_others
# get_enemies - get enemies of character_that_looks_for_others
func get_first_characters(character_that_looks_for_others:Character, get_characters_to_the_right:bool, num_to_find:int, get_allies:bool, get_enemies:bool):	
	var button_row := get_children_row(Globals.combat_control.combat_round)
	if not get_characters_to_the_right: button_row.invert()
	
	var output =[]
	var found_character :=false
	var num_found := 0
	for button in button_row:
		if num_found==num_to_find: break
		
		# only start adding characters after we found character_that_looks_for_others
		if found_character ==false and  button.character == character_that_looks_for_others: 
			found_character =true
		elif found_character:
			if  (get_allies and button.character.team == character_that_looks_for_others.team) or \
				(get_enemies and button.character.team != character_that_looks_for_others.team):
					output.append(button)
					num_found+=1
	return output

func get_first_enemies(character_that_looks_for_others:Character, get_characters_to_the_right:bool, num_to_find:int):
	return get_first_characters(character_that_looks_for_others, get_characters_to_the_right, num_to_find, false, true)

func get_first_allies(character_that_looks_for_others:Character, get_characters_to_the_right:bool, num_to_find:int):
	return get_first_characters(character_that_looks_for_others, get_characters_to_the_right, num_to_find, true, false)

# get the living enemy with the lowest total hp
func get_lowest_hp_enemy(character_that_looks_for_others:Character)->Array:
	var button_of_lowest_hp_character = null
	var min_total_hp = -1
	for button in get_children_row(Globals.combat_control.combat_round):
		if button.character != character_that_looks_for_others and button.character.is_alive() and button.character.team != character_that_looks_for_others.team:
			var total_hp = button.character.get_total_hp()
			if min_total_hp==-1 or  total_hp < min_total_hp:
				min_total_hp = total_hp
				button_of_lowest_hp_character = button
	if button_of_lowest_hp_character == null: return []
	else: return [button_of_lowest_hp_character]

# --------- end targeting rework



# return true if there are enemies near the given character
func is_enemy_nearby(character)->bool:
	var index = get_button_index(character,Globals.combat_control.combat_round)
	var buttons = get_children()
	if (index-1)>=0 and buttons[index-1].character.team!=character.team: return true
	if (index+1)<buttons.size() and buttons[index+1].character.team!=character.team: return true
	return false

# get distance between character a and b. return b if one of them is not found
func get_distance_between_characters(character_a:Character, character_b:Character)->int:
	var index_a = get_button_index(character_a,Globals.combat_control.combat_round)
	var index_b = get_button_index(character_a,Globals.combat_control.combat_round)

	return int(abs(index_a-index_b))

# return true if attacked_character is in attack range of attacking_character
func is_in_attack_range(attacking_character:Character,attacked_character:Character)->bool:
	if get_distance_between_characters(attacking_character,attacked_character) <= attacking_character.attack_range:
		return true
	return false

# return the action button row, according to the given combat round
func get_children_row(combat_round:int)->Array:
	return get_children().slice(combat_round*columns, combat_round*columns+columns-1)

#return true if the button is at the right edge of the matrix
func is_right_edge_button(button:ActionButton)->bool:
	var b =columns
	var a =button.get_index()%columns
	
	if button.get_index()%columns== (columns-1): return true
	return false

#return true if the button is at the left edge of the matrix
func is_left_edge_button(button:ActionButton)->bool:
	if button.get_index()%columns==0: return true
	return false

# hide all movement buttons of the action buttons at the edge of the matrix
func update_action_buttons_movement_buttons():
	for b in get_children():
		var is_alive = b.character.is_able_to_act()
		b.hide_right_move_buttons()
		b.hide_left_move_buttons()
		b.hide_change_direction()
		
		if is_alive and !b.did_turn:
			b.show_change_direction()
			
			if !is_right_edge_button(b): 
				b.show_right_move_buttons()
			if !is_left_edge_button(b): 
				b.show_left_move_buttons()
	

# hide movment buttons of the action button of the current turn and the left movement buttons of the next one
#func hide_action_buttons_of_current_turn(started_combat:=true):	
#	if !started_combat: return # only hide the buttons of the current turn if the combat started
#
#	var action_button = get_child(Globals.combat_control.action_matrix_current_turn)	
#	for b in get_children():
#		b.hide_left_move_buttons()
#		b.hide_right_move_buttons()
#		b.hide_change_direction()
#		if b == action_button: break
#
#	# hide the left action buttons of the current turn
#	var next_turn_action_button = get_child(Globals.combat_control.action_matrix_current_turn+1)	
#	if next_turn_action_button!=null: next_turn_action_button.hide_left_move_buttons()

func enable_all_action_buttons():
	for a in get_children():
		if a.character.part_of_player_party:
			a.enable_action_selection()

func disable_all_action_buttons():
	for a in get_children():
		a.disable_action_selection()

# update the state of the matrix (health bars, status effects, everything)
func update_matrix(reset_start_positions:bool = true)->void:
	# reset the start position of the buttons when a new turn starts. This prevent the player from constantly moving between turns to dodge attacks
	# without paying ap / movement points
	
	# a character moves, it's not saved yet so the player can undo the the moves
	# and only when he a turn is done we commit the changes. reset_start_position does this	
	if reset_start_positions == true:
		for b in get_children():
			b.reset_start_position()
	
	update_action_buttons_movement_buttons()	
	
	for b in get_children(): 
		b.update_healthbar()
		b.update_charges_indicator()
		b.updates_status_effects()
	
	
# returns the current actor whos turn is to play
# null if everyone played
func get_current_turn_button_v2():
	for b in get_children():
		if b.character.is_alive() and b.its_my_turn: 
			#assert(b.character.is_alive(), "It's the turn of a character who's dead. Probably an error.")
			return b
	# if no one is set as the next actor, set it as the first one who didn't act from top-left to botom-right
	return null

# character did its turn. Mark it as done, find the next character to play, and mark it accordingly
func character_did_its_turn()->void:
	var current_actor_button = get_current_turn_button_v2()	
	if current_actor_button!=null: current_actor_button.did_turn() # even if a character killed himself somehow, this will still mark him as done with his turn
	mark_next_character_to_play()

# find the next character to play and mark it accordingly
func mark_next_character_to_play()->void:
	for b in get_children():
		if b.did_turn==false and b.character.is_alive(): 
			b.its_my_turn = true
			break	
	

func remove_dead_characters_buttons()->void:
	var children_reverse = get_children()
	children_reverse.invert()
	for b in children_reverse:
		if !b.character.is_alive():
			remove_child(b)
	columns = get_child_count()/3

# action_button - the action button to move
# use_ap - If true, use ap to move. If false use movement points.
# move_right - if true move the button right, if false move it left
func move_action_button(action_button:ActionButton, move_right:bool, use_charges:bool):	
	# Get the buttons the action_button is moving before / after
	var i :=action_button.get_index()	
	var child_index = i
	# Get the next / preceding child node, or null if none exists
	var next_child = get_child(child_index + 1) if child_index + 1 < get_child_count() else null	
	var preceding_child = get_child(child_index - 1) if child_index - 1 >= 0 else null	
	
	# the movement doesn't cost anything if the moving button has the same speed as the one its moving through, and it's an ally
	var free_movement:=false
	if 	(move_right and next_child!=null and action_button.character.part_of_player_party==next_child.character.part_of_player_party and action_button.ability_speed==next_child.ability_speed) or \
		(!move_right and preceding_child!=null and action_button.character.part_of_player_party==preceding_child.character.part_of_player_party and action_button.ability_speed==preceding_child.ability_speed):
			free_movement = true
	
	# this entire deals with calculating the movement cost, and its irrelevant if the movement is free
	if !free_movement:
		# lower_stat = the movement would lower the stat. 
		# index_relative_to_start_position - is used to know whether to lower the stat or not, it's used to undo movements
		# We move from 0 to 1 -> charges goes down (same for 0 to -1)
		# We move back from 1 to 0 -> charges goes back up (same for -1 to 0)
		var lower_stat :=true 
		if (action_button.index_relative_to_start_position<0 and move_right) or (action_button.index_relative_to_start_position>0 and !move_right):
			lower_stat = false
			
		# lower / increase charges
		if use_charges:
			if !lower_stat:
				action_button.combat_ability.charges+=1
			else:
				if action_button.combat_ability.charges>0:
					action_button.combat_ability.charges-=1
				else:
					Globals.main_game.gui.play_general_message("Not enough charges.")
					return
		# lower / increase movement
		if !use_charges:
			if !lower_stat:
				action_button.character.movement_points+=1		
			else:
				if action_button.character.movement_points>0:
					action_button.character.movement_points-=1
				else:				
					Globals.main_game.gui.play_general_message("Not enough movement points.")
					return

	# move the button	
	if move_right:
		# if the moved character passed another, than their speed is matched
		if next_child!=null and action_button.combat_action_speed < next_child.combat_action_speed:
			action_button.combat_action_speed = next_child.combat_action_speed
		move_child(action_button,i+1)
		if !free_movement: action_button.index_relative_to_start_position +=1 # the index is used to calulate cost, that is non free movement 
	else: 
		# if the moved character passed another, than their speed is 
		if preceding_child!=null and action_button.combat_action_speed > preceding_child.combat_action_speed:
			action_button.combat_action_speed = preceding_child.combat_action_speed		
		move_child(action_button,i-1)
		if !free_movement: action_button.index_relative_to_start_position -=1 # the index is used to calulate cost, that is non free movement 
	
	# hide movement buttons at the edge of the matrix
	update_action_buttons_movement_buttons()
	
	# update the gui
	update_turn_indicators()
	action_button.character._on_character_ap_points_changed()
	action_button.character.movement_points_changed()
	action_button.update_charges_indicator()
	action_button.update_speed_indicator()

# update the turn and target indicators showing who's turn is it, and who is targeted
func update_turn_indicators():	
	# update turn indicator in the character gui
	var current_turn_button =  get_current_turn_button_v2()
	
	# update character gui
	current_turn_button.character.show_current_turn_indicator()
	
	# update the action matrix	
	for b in get_children():
		b.hide_its_my_turn_indicator()
		if b.did_turn: b.hide_has_played_indicator()
	current_turn_button.show_its_my_turn_indicator()

	# show targets of current ability in the matrix gui
	var action_buttons_targets = get_targets(false)
	for b in get_children():
		b.hide_target_indicator()
		
	for button in action_buttons_targets:
		button.show_target_indicator()

# get targets of ability based on its target type
# get_characters - if true, get characters. Otherwise get action buttons of the characters.
func get_targets(get_characters:=true)->Array:
	var targets_for_ability = []
	var cur_button = get_current_turn_button_v2()
	
	if !cur_button.character.is_able_to_act(): return []
	
	# this should give a list, even if there's only one target
	# the code here can be cleaned, as there's no need to find the current acting button over and over again
	# in each of the inside functions like get_lowest_hp_enemy, get_lowest_hp_enemy
	match cur_button.targeting_type:
		TARGETING_TYPE.NONE: pass
		TARGETING_TYPE.SELF: 
			targets_for_ability =  [cur_button]
		TARGETING_TYPE.ALL_ALLIES:
			targets_for_ability =  get_allies_of_character(cur_button.character)			
		TARGETING_TYPE.ALL_ENEMIES: 
			targets_for_ability =  get_enemies_of_character(cur_button.character)
		TARGETING_TYPE.EVERYONE: 
			targets_for_ability =  get_children_row(Globals.combat_control.combat_round)
#		TARGETING_TYPE.CLOSEST_ENEMY: 
#			targets_for_ability = Globals.combat_control.action_matrix.get_closest_enemies_v3(character,1,false, true)
#		TARGETING_TYPE.FURTHEST_ENEMY: 
#			targets_for_ability = Globals.combat_control.action_matrix.get_furthest_enemies_v3(character,1,true, true)	
		TARGETING_TYPE.LOWEST_HP_ENEMY:
			targets_for_ability = get_lowest_hp_enemy(cur_button.character)
		TARGETING_TYPE.SLOWEST_ENEMY:
			targets_for_ability = get_slowest_characters(cur_button.character,1)
		TARGETING_TYPE.FIRST_RIGHT_ENEMY: 
			targets_for_ability = get_first_enemies(cur_button.character, true, 1)
		TARGETING_TYPE.FIRST_LEFT_ENEMY: 
			targets_for_ability = get_first_enemies(cur_button.character, false, 1)
		TARGETING_TYPE.RIGHT_ENEMY_COLUMN:  
			targets_for_ability = get_enemy_column_v2(cur_button.character,1)
		TARGETING_TYPE.LEFT_ENEMY_COLUMN:   
			targets_for_ability = get_enemy_column_v2(cur_button.character,-1)
		TARGETING_TYPE.FIRST_RIGHT_CHARACTER_IN_SAME_ROW:
			targets_for_ability = get_action_button_in_same_row_v2(cur_button.character,1)
		TARGETING_TYPE.FIRST_LEFT_CHARACTER_IN_SAME_ROW:
			targets_for_ability = get_action_button_in_same_row_v2(cur_button.character,-1)
		TARGETING_TYPE.RIGHT_COLUMN:
			targets_for_ability = get_column_v2(cur_button.character,1)
		TARGETING_TYPE.LEFT_COLUMN:
			targets_for_ability = get_column_v2(cur_button.character,-1)
		TARGETING_TYPE.CHARACTERS_ON_BOTH_SIDES:
			targets_for_ability = get_action_button_in_same_row_v2(cur_button.character,1)
			var t2 = get_action_button_in_same_row_v2(cur_button.character,-1)
			targets_for_ability.append_array(t2)
		TARGETING_TYPE.FASTEST_ENEMY:
			targets_for_ability = get_fastest_enemies(cur_button.character,1)
		
		_: push_error(_to_string() + " has a illegal target type target_type")	

	# change output from action button to the characters	
	if get_characters: 
		var output := []
		for b in targets_for_ability: 
			output.append(b.character)
		targets_for_ability = output
	
	return targets_for_ability


# Called when the node enters the scene tree for the first time.
func _ready():
	#combat_control = Globals.combat_control
	pass


