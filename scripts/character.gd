extends Control

class_name Character

const status_effect_resource = preload("res://character/status_effects.gd")


# initial stats and stat growth
enum CHARACTER_HP_ARCHTYPE {FRAGILE, NORMAL, TANKY, NONE}
enum CHARACTER_SPEED_ARCHTYPE {VERY_SLOW, SLOW, NORMAL, FAST, VERY_FAST, NONE}
enum CHARACTER_ATTACK_ARCHTYPE {VERY_WEAK, WEAK, NORMAL, STRONG, VERY_STRONG,  NONE}

export(CHARACTER_HP_ARCHTYPE) var character_hp_archtype = CHARACTER_HP_ARCHTYPE.NORMAL
export(CHARACTER_SPEED_ARCHTYPE) var character_speed_archtype = CHARACTER_SPEED_ARCHTYPE.NORMAL
export(CHARACTER_ATTACK_ARCHTYPE) var character_attack_archtype = CHARACTER_ATTACK_ARCHTYPE.NORMAL



signal ap_points_changed()
signal health_changed(new_hp_value, new_temp_hp_value)
signal status_ailments_changed()
signal character_did_ability()
signal character_took_damage(damage)
signal character_healed(heal_amount)
signal character_notification_text(text)
signal ability_charges_changed(ability)
signal character_died()



onready var passives_manager = $passives_manager
onready var items_manager = $items_manager
onready var animationPlayer = $AnimationPlayer
onready var abilities_manager = $abilities_manager
onready var open_character_menu_button = $open_character_menu_button
onready var target_indicator = $open_character_menu_button/target_indicator
onready var movement_text = $movement_text


const ACTION_ORDER_MAX_SIZE = 9
const INVENTORY_SIZE = 2 # can easily change this, but I need to change the character_menu accordingly

export var portrait:Texture

export var character_name = ""
export var team:int
export var part_of_player_party = false
export var id:int=-1 # this is set in combat.gd in set_character_id, since id must consistant inside the combat scene, which Character has no way to know about

export var max_hp :=20
export var hp:int = max_hp
var temp_hp:int = 0
export var hp_levelup_cost := 1
export var hp_gained_per_levelup  := 3

var fight_start_hp:int = hp
export var base_attack_power := 4 # the basic attack power of the character, can't be changed mid fight
export var attack_power:int = base_attack_power #the mid fight attack power. can be changed mid fight 
export var attack_levelup_cost := 3
export var attack_gained_per_levelup := 1

export var damage_reduction:int = 0
export var lifesteal:float = 0
export var start_ap:int = 16
onready var ap:int = start_ap

export var initial_movement_points:int = 1
var movement_points:int = initial_movement_points
export var movement_xp_levelup_cost:=1
export var movement_gained_per_levelup:=1 # right now this is always 1, but I decided to put it here for the sake of consistancy


export var initial_attack_range:int = 100 # TODO decide whether to keep attack range or remove it. maybe it should be per ability.
var attack_range:int = initial_attack_range

export var total_xp:int = 5
export var used_xp:int = 1


export (float,0,10) var stat_multiplier =1


# can't use a dictionary to levelup because of this:
# https://github.com/godotengine/godot/issues/24995
# the entire levelup system sould be changed to something normal after Godot 4 release

# these are the stats that can be level up. If they are set to -1 than they aren't used by this character to levelup
# Can't go lower than 1
export var level_up_max_hp := 1
export var level_up_base_attack := 1
export var level_up_initial_movement := 1


# these are the stat you can levelup, and should have a levelup widget.
# remove one of those, and no widget will apear
var stat_levelups_v2 = [Globals.game_data.CHARACTER_STATS.max_hp, Globals.game_data.CHARACTER_STATS.base_attack, Globals.game_data.CHARACTER_STATS.movement]

# get the level of the stat based on its id
func get_stat_level(stat:int)->int:
	if stat==Globals.game_data.CHARACTER_STATS.max_hp: return level_up_max_hp
	elif stat==Globals.game_data.CHARACTER_STATS.base_attack: return level_up_base_attack
	elif stat==Globals.game_data.CHARACTER_STATS.movement: return level_up_initial_movement
	push_error("stat " + String(stat) + " not found in function get_stat_levelup")
	return -1	

func levelup_stat(stat, is_increase:bool):
	var levelup_cost = 1 #TODO when I revamp the levelup system, this would be something like levelup_cost = character.get_level_up_cost(stat)
	#var level = get_stat_level(stat)
	if is_increase:
		if used_xp+levelup_cost <= total_xp: 
			used_xp +=levelup_cost
			print(Globals.game_data.CHARACTER_STATS_GUI_NAMES[stat] + " has increased")
			increase_stat_level_based_on_its_id_in_game_data(stat, is_increase)			
		else:
			print("not enough xp")		
	elif !is_increase:	
		if get_stat_level(stat)==1:
			print("stat is already at the minimal level")
		else: 
			used_xp -=levelup_cost
			increase_stat_level_based_on_its_id_in_game_data(stat, is_increase)
			print(Globals.game_data.CHARACTER_STATS_GUI_NAMES[stat] + " has decreased")	

# gain passive stats from the item. item gives +5 attack -> character.base_attack_power +=5
# to decrease the stat, put a negative amount
# used when equiping and unequiping an item, or when initializing the character
# is_increase - if true, increase the stat by the specified amount, if false change it to the specified amount
func increase_stat_level_based_on_its_id_in_game_data(stat_id, is_increase:=true):
	var mult = 1
	if !is_increase: mult =-1
	
	match stat_id:
		Globals.game_data.CHARACTER_STATS.base_attack: 
			base_attack_power += mult*attack_gained_per_levelup
			level_up_base_attack +=mult
		Globals.game_data.CHARACTER_STATS.max_hp: 
			max_hp += mult*hp_gained_per_levelup
			level_up_max_hp +=mult
		Globals.game_data.CHARACTER_STATS.movement: 
			initial_movement_points += mult*movement_gained_per_levelup
			level_up_initial_movement +=mult

	

# setup the character for the first time
export var _run_first_time_setup = true

# history variables
var action_history_type_count = {}

# action_order second try
class Action:
	var character:Character
	var round_number:int
	var ability:Ability
	var item
	
	func _init(character,round_number,ability,item=null):
		self.character = character
		self.round_number = round_number
		self.ability = ability
		self.item = item
	

var action_order_v2 = [] #an array filled with Actions objects

export var ability_item_active_pairs = [null,null] # represents the character active item slots. Each is a dictionary of {ability, item}

var channeled_ability = null

var selected_button = null

# the characters abilities are chosen with this
export (Array, Ability.ABILITIES_ID) var abilities_to_add_v2 = [Ability.ABILITIES_ID.REGULAR_DEFENSE,Ability.ABILITIES_ID.REGULAR_DEFENSE,Ability.ABILITIES_ID.REGULAR_ATTACK,Ability.ABILITIES_ID.REGULAR_ATTACK]
# the characters passives are chosen with this
export (Array, Passive.PASSIVES_ID) var passives_to_add_v2 = []


var status_effects = status_effect_resource.new(self)


# Called when the node enters the scene tree for the first time.
func _ready():
	open_character_menu_button = $open_character_menu_button
	target_indicator = $open_character_menu_button/target_indicator
	movement_text = $movement_text
	
	connect("ability_charges_changed", self, "_on_character_ability_charges_changed")	
	connect("character_died", self, "_on_character_died_signal")
	
	if(_run_first_time_setup): first_time_setup()

	# set portrait button
	open_character_menu_button.initialize(self)
	open_character_menu_button.hide_draft_button()

	#set_action_order_v3()
	set_gui()
	
	

func first_time_setup():
	_run_first_time_setup=false
	
	set_character_id()
	
	# initial stat setup	
	# setup movement speed for the first time
	if character_speed_archtype !=CHARACTER_SPEED_ARCHTYPE.NONE:		
		initial_movement_points = Globals.game_data.CHARACTER_STAT_SPEED_ARCHTYPE_DATA[character_speed_archtype].init_movement_speed
		movement_xp_levelup_cost = Globals.game_data.CHARACTER_STAT_SPEED_ARCHTYPE_DATA[character_speed_archtype].levelup_cost
		movement_gained_per_levelup = Globals.game_data.CHARACTER_STAT_SPEED_ARCHTYPE_DATA[character_speed_archtype].stat_gained_per_levelup
	
	
	# setup hp for the first time
	if character_hp_archtype !=CHARACTER_HP_ARCHTYPE.NONE:		
		#max_hp = Globals.game_data.CHARACTER_STAT_HP_ARCHTYPE_DATA[character_hp_archtype].init_base_hp
		hp_levelup_cost = Globals.game_data.CHARACTER_STAT_HP_ARCHTYPE_DATA[character_hp_archtype].levelup_cost
		hp_gained_per_levelup = Globals.game_data.CHARACTER_STAT_HP_ARCHTYPE_DATA[character_hp_archtype].stat_gained_per_levelup
	
	
	# setup attack for the first time
	if character_attack_archtype != CHARACTER_ATTACK_ARCHTYPE.NONE:		
		base_attack_power = Globals.game_data.CHARACTER_STAT_ATTACK_ARCHTYPE_DATA[character_attack_archtype].init_base_attack
		attack_levelup_cost = Globals.game_data.CHARACTER_STAT_ATTACK_ARCHTYPE_DATA[character_attack_archtype].levelup_cost
		attack_gained_per_levelup = Globals.game_data.CHARACTER_STAT_ATTACK_ARCHTYPE_DATA[character_attack_archtype].stat_gained_per_levelup
		
	# multiply stats by a float. Useful to quickly level up enemies
	initial_movement_points *=	stat_multiplier
	#max_hp *=	stat_multiplier 
	base_attack_power *=	stat_multiplier 
	
	# set all temp stats to their base one
	movement_points = initial_movement_points
	hp=max_hp
	attack_power = base_attack_power
	
	#max_hp = 10
	#hp=max_hp
	
	set_abilities()	
	
	for type in Ability.ABILITY_TYPE.values():
		action_history_type_count[type]=0
		
	set_passives()
	
	# set movement points
	movement_points_changed()

# set the id of a character. done outside of character since it should be
func set_character_id():
	# if the character.id==-1 it means it wasn't set yet
	if id!=-1:
		return
	elif part_of_player_party:
		id = Globals.characters_created_counter
		Globals.characters_created_counter+=1
	else:
		id = Globals.number_of_characters_created_in_the_node
		Globals.number_of_characters_created_in_the_node+=1

func set_abilities():	
	for id in abilities_to_add_v2:		
		abilities_manager.add_ability_by_id(id)
		
	

# ------------ action order functions


# set an action order with size ACTION_ORDER_MAX_SIZE
# only the first x round would be used, where x in the number of combat rounds
func set_action_order_v3():
	var k = 0
	var round_num = 0
	while action_order_v2.size()!=ACTION_ORDER_MAX_SIZE:
		# TODO this is how you implement ability build
		# useful for the players, for enemies its simpler to use abilities right away
#		var a
#		if not ability_build.empty():
#			a = ability_build[k]
		var a = abilities_manager.get_all_abilities()[k]
		action_order_v2.append(Action.new(self, round_num, a, null))
		k +=1
		round_num +=1
		# fill the action order in a cyclic manner, so if we need 9 action and only 
		# 6 were defined, actions 6-9 will be identical to action 1-3
		if k==abilities_manager.get_all_abilities().size(): k=0 

# changes the action order in round combat_round_of_action to be the given ability
#func change_action_order(ability:Ability, combat_round_of_action:int):
#	action_order_v2[combat_round_of_action] = Action.new(self, combat_round_of_action, ability, null)
	

#func get_new_action(character,round_number,ability,item):
#	return Action.new(character,round_number,ability,item)


#func get_actions_from_action_order_by_round_number(n:int)->Ability:
#	for a in action_order_v2:		
#		if a.round_number==n: 
#			return a
#	return null

func get_action_from_action_order_by_ability(ability:Ability)->Ability:
	for a in action_order_v2:		
		if a.ability==ability: return a	
	return null

# removes and action from the turn order
# could lead to bugs if the action is called afterwards - for example if one removes action #1 and than in round 1 the the #1 action is called
# that is, the action numbers aren't fixed afterwards
#func remove_action_from_turn_order(round_number:int):
#	for i in range(action_order_v2.size()):
#		if action_order_v2[i].round_number==round_number:
#			action_order_v2.remove(i)

# remove item from turn order and inventory
#func remove_item_from_turn_order(item):
#	for a in action_order_v2:
#		if a.item==item:
#			a.item=null

# ------------ end action order functions

func set_passives():	
	for passive_id in passives_to_add_v2:
		passives_manager.add_passive(passive_id)

func set_gui():
	if !character_name.empty(): 
		$name.text = character_name
	$health_bar._ready()
	update_items_gui()
	
	emit_signal("ap_points_changed")
	emit_signal("health_changed", self.hp, self.temp_hp)
	_on_character_ap_points_changed()
	movement_points_changed()
	
	
func get_max_hp()->int:
	return max_hp

func update_gui_status_ailments():
	$status_ailments.text = "Status effects: \n"
	for s in status_effects.status_effects_dict.values():
		$status_ailments.text += s.gui_name + " - " + String(s.duration) + "\n"
	
	for b in Globals.combat_control.action_matrix.get_children():
		if b.character==self:
			b.show_major_status_effect()


func add_action_to_action_history(action):
	Globals.combat_control.action_history.append(action)
	

func do_turn_v3(combat_action:Character.Action):	
	var character_is_channeling = false #used to determine if the character should spend ap on the action
	
	if !is_alive():
		return
	
	if channeled_ability!=null:
		character_is_channeling = true
		if status_effects.is_status_active(Globals.STATUS_EFFECTS_ID.CHANNELING):
			#character is not done channeling
			pass
		else:
			# character is done channeling
			# add channeled ability to action history
			var hist = {character=self, round_number = Globals.combat_control.combat_round, ability=channeled_ability, item=null}
			add_action_to_action_history(hist)

			# do channeled ability
			channeled_ability.done_channeling = true
			channeled_ability.do_function()
			channeled_ability = null
			emit_signal("character_did_ability")
			
	else:		
		character_is_channeling = false # character isn't channeling
		add_action_to_action_history(combat_action) # add these actions to the action history
		
		# do the turn in three parts
		# 0 - do start of turn item actives
		# 1 - do the ability
		# 2 - do end of turn item actives		
				
		# ability at this point is considered as if it went of, though the character might not have been able to do it properly
		# stunned -> character did action, but it didn't do anything
		
		# do start of turn item actives
		if combat_action.item!=null:
			# do start of turn item actives
			do_item_action(combat_action.item, Globals.game_data.DO_ITEM_AT.TURN_START)
		
		# do the ability
		if combat_action.ability.charges<=0:
			emit_signal("character_notification_text", "Ability has no charges")				
		else:
			do_ability_action(combat_action.ability)
			Globals.combat_control.one_of_the_character_did_an_action_this_phase = true
		
		# do end of turn item actives
		if combat_action.item!=null:
			# do end of turn item actives
			do_item_action(combat_action.item, Globals.game_data.DO_ITEM_AT.TURN_END)

func do_turn_v4(combat_action_button):	
	var character_is_channeling = false #used to determine if the character should spend ap on the action
	
	if !is_alive():
		return
	
	if channeled_ability!=null:
		character_is_channeling = true
		if status_effects.is_status_active(Globals.STATUS_EFFECTS_ID.CHANNELING):
			#character is not done channeling
			pass
		else:
			# character is done channeling
			# add channeled ability to action history
			var hist = {character=self, round_number = Globals.combat_control.combat_round, ability=channeled_ability, item=null}
			add_action_to_action_history(hist)

			# do channeled ability
			channeled_ability.done_channeling = true
			channeled_ability.do_function()
			channeled_ability = null
			emit_signal("character_did_ability")
			
	else:		
		character_is_channeling = false # character isn't channeling		
		#add_action_to_action_history(combat_action) # add these actions to the action history #TODO fix this
		
		# do the turn in three parts
		# do start of turn item actives
		# do the ability
		# do end of turn item actives		
				
		# ability at this point is considered as if it went of, though the character might not have been able to do it properly
		# stunned -> character did action, but it didn't do anything
		
		# do start of turn item actives
		if combat_action_button.item!=null:
			# do start of turn item actives
			do_item_action(combat_action_button.item, Globals.game_data.DO_ITEM_AT.TURN_START)
		
		# do the ability
		if combat_action_button.combat_ability.charges<=0:
			emit_signal("character_notification_text", "Ability has no charges")				
		else:
			do_ability_action(combat_action_button.combat_ability)
			Globals.combat_control.one_of_the_character_did_an_action_this_phase = true
		
		# do end of turn item actives
		if combat_action_button.item!=null:
			# do end of turn item actives
			do_item_action(combat_action_button.item, Globals.game_data.DO_ITEM_AT.TURN_END)



# do active item action
func do_item_action(item, time_to_do_action):
	# check for item related debuffs
	# TODO decide how to handle action_history_type_count when it comes to items
	if !is_able_to_act():
			return # can't do the ability	
	item.do_item_active(time_to_do_action)

# do ability action
func do_ability_action(ability:Ability):
	# check for ability related debuffs
	if !is_able_to_act() or \
		(status_effects.is_status_active(Globals.STATUS_EFFECTS_ID.CANT_DEFEND) and ability.ability_type==Ability.ABILITY_TYPE.DEFENSIVE) or \
		(status_effects.is_status_active(Globals.STATUS_EFFECTS_ID.CANT_ATTACK) and ability.ability_type==Ability.ABILITY_TYPE.OFFENSIVE):
			return # can't do the ability	
	action_history_type_count[ability.ability_type] +=1
	ability.do_function()
	emit_signal("character_did_ability")


# get the action cost this round
# the cost is the AP cost of the ability, or 1 ap at minimum (to prevent wierd states where the game doesn't end)
# the cost is either the cost of the current ability, or the cost of doing something else
# if the character did_something_else, like channeling for example, then the cost is one
func get_ap_cost_v2(ability:Ability):
	var cost = ability.ap_cost
	if status_effects.is_status_active(Globals.STATUS_EFFECTS_ID.SLOWED): cost+=1
	return cost

func is_alive():
	return hp>0

# is the character stunned, challening, etc'
func is_able_to_act():
	# if not stunned or channeling
	if !is_alive() or status_effects.is_status_active(Globals.STATUS_EFFECTS_ID.STUNNED) or \
		status_effects.is_status_active(Globals.STATUS_EFFECTS_ID.CHANNELING): 
		return false
	return true
	

# this function is called when the character rests
# it heals hp, removes debuffs, and so on
func rest():	
	hp = max_hp
	temp_hp = 0
	action_history_type_count = {}	
	status_effects.status_effects_dict = {}
	# reset abilities after rest. does a full reset, including charges
	abilities_manager.reset_abilities(true)	

# get amount of damage this character is gonna do to the attacked.
# check all status ailments, damage multiplier, etc' and return the modified damage amount
func do_damage(attacked:Character, damage:int, damage_type:= Globals.game_data.DAMAGE_TYPE.PHYSICAL):
	var damage_multiplier :float= 1
	if !attacked.is_alive(): return
	if status_effects.is_status_active(Globals.STATUS_EFFECTS_ID.EMPOWERED): damage_multiplier +=1
	
	damage = do_attack_passives(attacked, damage)
		
	damage *= damage_multiplier
	if damage<=0: damage=0	
	attacked.take_damage(self,damage, damage_type)	
	
# check for passive of the attackers
func do_attack_passives(attacked:Character, damage):
	# handle ON_ATTACK passives
	# ON_ATTACK passives only apply when this character has the passive			
	for p_id in passives_manager.get_all_passives_id_based_on_activation_time(Passive.DO_PASSIVE_AT.ON_ATTACK):
		if passives_manager.has_passive_and_enabled(p_id):
			var p = passives_manager.get_passive(p_id)
			if p.id == Passive.PASSIVES_ID.STUN_EVERY_THIRD_ATTACK:
				p.STUN_EVERY_THIRD_ATTACK(attacked)
				
	# handle ON_TEAM_ATTACK passives
	# ON_TEAM_ATTACK passives apply when anyone on the team has the passive				
	for p_id in passives_manager.get_all_passives_id_based_on_activation_time(Passive.DO_PASSIVE_AT.ON_TEAM_ATTACK):
		for c in Globals.all_characters.get_allies(team):						
			if c.passives_manager.has_passive_and_enabled(p_id):
				var p = c.passives_manager.get_passive(p_id)
				if p.id == Passive.PASSIVES_ID.MY_TEAM_DOES_DOUBLE_DAMAGE_TO_STUNNED:
					damage = p.MY_TEAM_DOES_DOUBLE_DAMAGE_TO_STUNNED(attacked, damage)
					break # this prevents applying the same passive twice on different team members

	return damage

func take_damage(attacker:Character, damage:int, damage_type:= Globals.game_data.DAMAGE_TYPE.PHYSICAL):
	# stun_attackers status effect
	if status_effects.is_status_active(Globals.STATUS_EFFECTS_ID.STUN_ATTACKERS):
		attacker.status_effects.add_status_effect(Globals.STATUS_EFFECTS_ID.STUNNED, 2)
	
	# DAMAGE_IMMUNE status effect
	if status_effects.is_status_active(Globals.STATUS_EFFECTS_ID.DAMAGE_IMMUNE):
		return
			
	# calculate damage multipliers
	var dmg_multiplier = 1	
	
	if damage_type==Globals.game_data.DAMAGE_TYPE.PHYSICAL:
		if status_effects.is_status_active(Globals.STATUS_EFFECTS_ID.WEAK_DEFENSE): dmg_multiplier -=0.25
		if status_effects.is_status_active(Globals.STATUS_EFFECTS_ID.STANDARD_DEFENSE): dmg_multiplier -=0.5
	if status_effects.is_status_active(Globals.STATUS_EFFECTS_ID.VULNERABLE): dmg_multiplier +=1
	if passives_manager.has_passive_and_enabled(Passive.PASSIVES_ID.TAKE_LESS_DAMAGE_FROM_TANKIER_ENEMIES):
		# reduce damage from tanker enemies
		if get_total_hp() < attacker.get_total_hp():
			dmg_multiplier -= passives_manager.get_passive(Passive.PASSIVES_ID.TAKE_LESS_DAMAGE_FROM_TANKIER_ENEMIES).get_level() * 0.1

	
	damage *= dmg_multiplier
	
	# this part does damage resistance / armor
	#damage -= damage_reduction   #    <--flat damage redcution
	# damage reduction is percentage based
	if damage_reduction>=100: damage=0
	else:
		damage= damage*((100-damage_reduction)/100)
	
	damage = int(damage) # damage must be int to avoid bugs
	if(damage<=0): 
		pass
	elif(self.temp_hp>=damage): self.temp_hp-=damage
	else:
		var t = damage
		t-=temp_hp
		temp_hp = 0
		hp -= t
		if hp<0: hp=0
	
	var lifesteal_heal = damage * attacker.lifesteal
	if lifesteal_heal>0: attacker.heal(attacker,lifesteal_heal)
	
	emit_signal("health_changed", self.hp, self.temp_hp)
	emit_signal("character_took_damage", damage)
	if !is_alive():
		emit_signal("character_died")
	

# character was pushed by the pushed_by character in the push_direction, by push_amount
# the function does nothing right now but later on I can put here extra condition on what 
# happens when the character is pushed
func pushed(pushed_by:Character, push_direction:int, push_amount:int):
	if push_amount==0: return
	while push_amount>0:
		Globals.combat_control.action_matrix.push_character(self, push_direction)
		push_amount-=1
	

func heal(healer:Character, heal_amount:int):	
	if(!is_alive()): return
	assert(heal_amount>=0)
	
	if status_effects.is_status_active(Globals.STATUS_EFFECTS_ID.HEALING_DAMAGES):
		take_damage(healer,heal_amount)
		return
	
	# can't heal more than max hp	
	if get_total_hp()+heal_amount>max_hp:
		heal_amount = max_hp - get_total_hp()
		temp_hp = max_hp - get_total_hp()
	else:
		temp_hp+= heal_amount

	emit_signal("health_changed", self.hp,self.temp_hp)	
	emit_signal("character_healed", heal_amount)

#-------- ability and item active per slot 


func add_ability_with_item_active_to_slot(item_slot:int,ability_to_connect_to:Ability,item_with_active):
	# the next lines ensure that the player won't be able to do attach more than one item active to the same item. 
	# Could be a viable idea to allow that, depending on design
	if ability_item_active_pairs[0] != null and ability_item_active_pairs[0].ability==ability_to_connect_to:
		 ability_item_active_pairs[0] = null
	if ability_item_active_pairs[1] != null and ability_item_active_pairs[1].ability==ability_to_connect_to:
		 ability_item_active_pairs[1] = null
	# remove the item from the action_order	
	for a in action_order_v2:
		if a["item"]==item_with_active:
			a["item"]=null
				
	ability_item_active_pairs[item_slot] = {ability=ability_to_connect_to, item=item_with_active}
	get_action_from_action_order_by_ability(ability_to_connect_to)["item"] = item_with_active
	# TODO change how item actives work
#	if Globals.overworld.is_in_combat: 
#		update_item_actives_in_action_matrix()
	
# get the ability paired to an active item in slot
func get_ability_with_active_item_in_slot(item_slot_number:int):
	if ability_item_active_pairs[item_slot_number] == null: return null
	return ability_item_active_pairs[item_slot_number]

#-------- end ability and item active per slot 


func is_ally()->bool:
	if team == Globals.TEAMS.PLAYER:
		return true
	return false


# reset all stats, status ailments, passive and abilities that shouldn't persist from fight to fight
# for example - reset the temporary hp to zero
func combat_started_reset_character():
	reset_character()
	abilities_manager.reset_abilities()	
	passives_manager.reset_passives()
	status_effects.remove_all_status_effects()	
	
	set_gui()
	emit_signal("status_ailments_changed")


func reset_character():	
	temp_hp=0
	fight_start_hp = hp
	damage_reduction = 0
	lifesteal = 0	
	ap = start_ap
	attack_power = base_attack_power
	attack_range = initial_attack_range
	movement_points = initial_movement_points
	
	# initialize action history
	action_history_type_count = {}
	for type in Ability.ABILITY_TYPE.values():
		action_history_type_count[type]=0	
			
	channeled_ability = null
	selected_button = null	

func _print_to_console():
	print("team:", self.team)
	print("hp:", self.hp)	
	
func get_total_hp():
	return hp+temp_hp

func update_items_gui():
	var i1 = items_manager.get_item_in_slot(0)
	var i2 = items_manager.get_item_in_slot(1)
	if(i1==null): $item_slot_1.text = ""
	else: $item_slot_1.text = i1.gui_name
	if(i2==null): $item_slot_2.text = ""
	else: $item_slot_2.text = i2.gui_name	

# show it's the character's turn
func show_current_turn_indicator():
	for c in Globals.all_characters.get_all_characters():
		c._hide_current_turn_indicator()

	# show this turn indicator
	if is_alive(): $current_turn_indicator.show()
	

func _hide_current_turn_indicator():
	$current_turn_indicator.hide()	

func show_target_indicator():
	target_indicator.visible = true

func hide_target_indicator():
	target_indicator.visible = false

func _on_passives_passive_changed():
	$passives_text.text = "passives: \n"
	for p in passives_manager.get_children():
		$passives_text.text += p.p_name + "\n"

func _on_character_ap_points_changed():
	$ap_text.text = "AP: " + String(ap)

func _on_character_did_ability():	
	if team==Globals.TEAMS.PLAYER:
		animationPlayer.play("did ability ally")
	elif team==Globals.TEAMS.ENEMY:
		animationPlayer.play("did ability enemy")

func _on_character_took_damage_do_animation():
	animationPlayer.play("damage taken")

func _on_character_took_damage(damage):
	$damage_taken.text = String(damage)
	$damage_taken.set("custom_colors/default_color",Color.red)
	_on_character_took_damage_do_animation()	


func _on_character_character_healed(heal_amount):
	$damage_taken.text = String(heal_amount)	
	$damage_taken.set("custom_colors/default_color",Color.green)
	_on_character_took_damage_do_animation()

# update the charges of the item in the action matrix. This is only a gui change, the actual charges are changed elsewhere
func _on_character_ability_charges_changed(ability):
	for b in Globals.combat_control.action_matrix.get_children():
		if b.combat_ability == ability:
			b.update_charges_indicator()

func _on_character_character_notification_text(text:String):
	$notification.text = text
	animationPlayer.play("notification message")

# update the buttons in the action matrix with the character active items
func update_item_actives_in_action_matrix()->void:
	var pair_a = get_ability_with_active_item_in_slot(0)
	var pair_b = get_ability_with_active_item_in_slot(1)	
	
	# remove all items
	for button in Globals.combat_control.action_matrix.get_children():
		button.add_item_to_action(null)
	
	# add items
	for button in Globals.combat_control.action_matrix.get_children():
		var item = null
		if pair_a!= null and button.ability == pair_a.ability:
			item = pair_a.item
		elif pair_b!= null and button.ability == pair_b.ability:
			item = pair_b.item
		button.add_item_to_action(item)


# the character died signal was sent
func _on_character_died_signal():	
	Globals.combat_control.action_matrix.update_action_buttons_movement_buttons()
		
func movement_points_changed():
	movement_text.text = "Movement: " + String(movement_points)

# Used for saving the node. returns a dict of the node's features to be saved. 
func save()->Dictionary:
	var save_dict = {
		"filename" : get_filename(),
		"parent" : get_parent().get_path(),
		"rect_position_x": rect_position.x,
		"rect_position_y": rect_position.y,
		"character_name" : character_name,
		"team" : team,
		"part_of_player_party" : part_of_player_party,
		"id" : id,
		"max_hp" : max_hp,
		"hp" : hp,
		"base_attack_power" : base_attack_power,
		"attack_power" : attack_power,
		"damage_reduction" : damage_reduction,
		"lifesteal" : lifesteal,
		"movement_points" : movement_points,
		"initial_attack_range" : initial_attack_range,
		"total_xp" : total_xp,
		"used_xp" : used_xp,
		"character_hp_archtype" : character_hp_archtype,
		"character_speed_archtype" : character_speed_archtype,		
		"_run_first_time_setup" : _run_first_time_setup,		
	}
	return save_dict
