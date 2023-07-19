extends Node

class_name Ability

# -------------------------- abilities

# define ability price
const ABILITY_CHARGES_USAGE_PER_COMBAT = 3 # this should reflect the number of phases, the more phases, the more usage
const ENCOUNTERS_BEFORE_A_CHARACTER_RUNS_OUT_OF_CHARGES = 6

const CHARGES_AMOUNT_VERY_CHEAP :int= ENCOUNTERS_BEFORE_A_CHARACTER_RUNS_OUT_OF_CHARGES * 2
const CHARGES_AMOUNT_CHEAP :int= int(ENCOUNTERS_BEFORE_A_CHARACTER_RUNS_OUT_OF_CHARGES * float(1.5))
const CHARGES_AMOUNT_NORMAL :int= ENCOUNTERS_BEFORE_A_CHARACTER_RUNS_OUT_OF_CHARGES
const CHARGES_AMOUNT_EXPENSIVE :int= int(ENCOUNTERS_BEFORE_A_CHARACTER_RUNS_OUT_OF_CHARGES * (float(1)/3))
const CHARGES_AMOUNT_VERY_EXPENSIVE :int= int(ENCOUNTERS_BEFORE_A_CHARACTER_RUNS_OUT_OF_CHARGES * (float(1)/3))


# -------------------------- end abilities

const CHARGES_NOT_USED = -1000 # used as a magic number to mean that the ability has no charges. NAN causes issues.

enum ABILITY_TYPE{OTHER, DEFENSIVE, OFFENSIVE, MOVEMENT}
enum TARGETING_TYPE{NONE, SELF, CLOSEST_ENEMY, FURTHEST_ENEMY, ALL_ALLIES, ALL_ENEMIES, EVERYONE, LOWEST_HP_ENEMY, SLOWEST_ENEMY, FIRST_LEFT_ENEMY, FIRST_RIGHT_ENEMY, RIGHT_ENEMY_COLUMN, LEFT_ENEMY_COLUMN, FIRST_RIGHT_CHARACTER_IN_SAME_ROW, FIRST_LEFT_CHARACTER_IN_SAME_ROW
	RIGHT_COLUMN,LEFT_COLUMN, CHARACTERS_ON_BOTH_SIDES, FASTEST_ENEMY}
enum ABILITIES_ID{DO_NOTHING, REGULAR_DEFENSE,STRONG_DEFENSE,REGULAR_ATTACK,REGULAR_RANGED_ATTACK,STUN_ATTACK,REMOVE_PERCENTAGE_HP_ALL_ENEMIES,
	KILL_IF_LESS_THAN_PERCENTAGE_MAX_HP,DAMAGE_ALL_ENEMIES_HEAL_ALL_ALLIES,REMOVE_ALL_TEMP_HP_FROM_ALL_ENEMIES,
	DISABLE_ENEMY_DEFENSIVE_ACTIONS,STUN_SLOWEST_ENEMY,ATTACKERS_GET_STUNNED,
	DISABLE_ENEMY_OFFENSIVE_ACTIONS,ATTACK_AND_DEFEND,LIFESTEAL_ATTACK,REMOVE_ENEMY_CHARGES,BURN_THIS_ACTION_TO_GET_AP,SLOW_ALL_ENEMIES,HEAL_ACCORDING_TO_USED_CHARGES,
	MAKE_HEALING_DAMAGES_AND_ATTACK,ATTACK_BASED_ON_NUMBER_OF_ENEMY_DEFENSIVE_ABILITIES_DONE,STRONG_RANGED_ATTACK,HEAL_TO_PREVIOUS_PHASE_HP,REDO_LAST_ENEMY_ACTION,DO_DAMAGE_BASED_ON_ENEMY_AP,
	DO_ALL_ONE_SPEED_ACTIONS_IN_A_ROW,STUN_ALL_ENEMIES_IN_ATTACK_RANGE,ATTACK_LOWEST_HP_ENEMY,MAKE_BOTH_YOU_AND_THE_CLOSEST_ENEMY_VULNERABLE_THEN_ATTACK_IT, DAMAGE_ENEMY_BASED_ON_TANKY_ALLY,
	KILL_IF_LESS_THAN_PERCENTAGE_MAX_HP_V2, VERY_WEAK_LINE_ATTACK, REMOVE_DEBUFFS_FROM_SELF, INCREASE_DEBUFF_DURATION, COPY_BUFF, GAIN_MOVEMENT_POINTS,
	DAMAGE_BASE_ON_NUMBER_OF_STATUS_EFFECTS, STRONG_SINGLE_TARGET_NUKE, SINGLE_TARGET_NUKE_THAT_HEALS, SINGLE_TARGET_NUKE_THAT_PUSHES,
	MAKE_CLOSEST_CHARACTER_AND_SELF_INVUNERABLE_AND_STUNNED, DEFENSE_COSTS_CHARGES_AND_HEALS,SHORT_STUN_COLUMN,LONG_STUN_ENEMY_AND_SELF,
	CHANGE_DIRECTION_OF_CHARACTER, CHANGE_DIRECTION_OF_CHARACTERS_ON_BOTH_SIDES_AND_BECOME_DAMAGE_IMMUNE, WEAK_DEFENSE, STUN_FASTEST_ENEMY}

# list used for initilizing abilitiesm contains all data about the abilities
# must be updated when adding new abilities
# charges is NAN for abilities that don't use charges
const ABILITY_DATA = [
	{ability_id=ABILITIES_ID.DO_NOTHING, default_gui_name="do nothing", ability_type = ABILITY_TYPE.OTHER, ap_cost=1, speed = 1,charges = 9999, targeting = TARGETING_TYPE.SELF},
	{ability_id=ABILITIES_ID.REGULAR_DEFENSE, default_gui_name="Defend", ability_type = ABILITY_TYPE.DEFENSIVE, ap_cost=2, speed = 2,charges = CHARGES_AMOUNT_VERY_CHEAP, targeting = TARGETING_TYPE.SELF},
	{ability_id=ABILITIES_ID.WEAK_DEFENSE, default_gui_name="Weak defense.", ability_type = ABILITY_TYPE.DEFENSIVE, ap_cost=2, speed = 3,charges = CHARGES_AMOUNT_VERY_CHEAP, targeting = TARGETING_TYPE.SELF},	
	{ability_id=ABILITIES_ID.STRONG_DEFENSE, default_gui_name="Strong defense.", ability_type = ABILITY_TYPE.DEFENSIVE, ap_cost=3, speed = 3,charges = CHARGES_AMOUNT_EXPENSIVE, targeting = TARGETING_TYPE.SELF},
	{ability_id=ABILITIES_ID.REGULAR_ATTACK, default_gui_name="Attack enemy.", ability_type = ABILITY_TYPE.OFFENSIVE, ap_cost=2, speed = 2,charges = CHARGES_AMOUNT_VERY_CHEAP, targeting = TARGETING_TYPE.FIRST_RIGHT_ENEMY},
	{ability_id=ABILITIES_ID.REGULAR_RANGED_ATTACK, default_gui_name="Ranged attack", ability_type = ABILITY_TYPE.OFFENSIVE, ap_cost=2, speed = 2,charges = CHARGES_AMOUNT_VERY_CHEAP, targeting = TARGETING_TYPE.FIRST_RIGHT_ENEMY},		
	{ability_id=ABILITIES_ID.STUN_ATTACK, default_gui_name="Stun the target.", ability_type = ABILITY_TYPE.OFFENSIVE, ap_cost=2, speed = 2,charges = CHARGES_AMOUNT_NORMAL, targeting = TARGETING_TYPE.FIRST_RIGHT_ENEMY},
	{ability_id=ABILITIES_ID.REMOVE_PERCENTAGE_HP_ALL_ENEMIES, default_gui_name="Remove a percentage of hp from all enemies", ability_type = ABILITY_TYPE.OFFENSIVE, ap_cost=4, speed = 4, charges = CHARGES_AMOUNT_EXPENSIVE, targeting = TARGETING_TYPE.ALL_ENEMIES},
	{ability_id=ABILITIES_ID.KILL_IF_LESS_THAN_PERCENTAGE_MAX_HP, default_gui_name="kill target if it has less than 20% max hp", ability_type = ABILITY_TYPE.OFFENSIVE, ap_cost=4, speed = 4, charges = CHARGES_AMOUNT_VERY_EXPENSIVE, targeting = TARGETING_TYPE.FIRST_RIGHT_ENEMY},
	{ability_id=ABILITIES_ID.DAMAGE_ALL_ENEMIES_HEAL_ALL_ALLIES, default_gui_name="Damage all enemies in range, heal all allies.", ability_type = ABILITY_TYPE.OFFENSIVE, ap_cost=5, speed = 5,charges = CHARGES_AMOUNT_EXPENSIVE, targeting = TARGETING_TYPE.EVERYONE},
	# {ability_id=ABILITIES_ID.MOVE_TO_CLOSEST_ENEMY_DOUBLE_DAMAGE_TAKEN_AND_RECEIVED, default_gui_name="move to closest enemy double damage taken and received", ability_type = ABILITY_TYPE.movement, ap_cost=3, charges = NAN, targeting = TARGETING_TYPE.SELF},
	{ability_id=ABILITIES_ID.REMOVE_ALL_TEMP_HP_FROM_ALL_ENEMIES, default_gui_name="Remove all temp hp from all enemies.", ability_type = ABILITY_TYPE.OFFENSIVE, ap_cost=4, speed = 4,charges = CHARGES_AMOUNT_VERY_EXPENSIVE, targeting = TARGETING_TYPE.ALL_ENEMIES}, 
	#{ability_id=ABILITIES_ID.PULL_FURTHEST_ENEMY_TO_CLOSEST_ALLY_AND_MAKE_IT_VULNERABLE, default_gui_name="pull enemy backline to front and make it vulnerable", ability_type = ABILITY_TYPE.offensive, ap_cost=5, charges = NAN, targeting = TARGETING_TYPE.FURTHEST_ENEMY},
	# {ability_id=ABILITIES_ID.MOVE_AWAY_FROM_CLOSEST_ENEMY, default_gui_name="move away from closest enemy", ability_type = ABILITY_TYPE.movement, ap_cost=1, charges = NAN, targeting = TARGETING_TYPE.SELF},
	{ability_id=ABILITIES_ID.DISABLE_ENEMY_DEFENSIVE_ACTIONS, default_gui_name="Disable enemy defensive actions", ability_type = ABILITY_TYPE.OFFENSIVE, ap_cost=3, speed = 3, charges = CHARGES_AMOUNT_NORMAL, targeting = TARGETING_TYPE.FIRST_RIGHT_ENEMY},
	{ability_id=ABILITIES_ID.STUN_SLOWEST_ENEMY, default_gui_name="Stun slowest enemy", ability_type = ABILITY_TYPE.OFFENSIVE, ap_cost=3, speed = 3, charges = CHARGES_AMOUNT_NORMAL, targeting = TARGETING_TYPE.SLOWEST_ENEMY},
	{ability_id=ABILITIES_ID.ATTACKERS_GET_STUNNED, default_gui_name="Attackers get stunned.", ability_type = ABILITY_TYPE.OTHER, ap_cost=4, speed = 4, charges = CHARGES_AMOUNT_EXPENSIVE, targeting = TARGETING_TYPE.SELF},
	{ability_id=ABILITIES_ID.DISABLE_ENEMY_OFFENSIVE_ACTIONS, default_gui_name="Disable enemy offensive actions.", ability_type = ABILITY_TYPE.OFFENSIVE, ap_cost=3, speed = 3, charges = CHARGES_AMOUNT_EXPENSIVE, targeting = TARGETING_TYPE.FIRST_RIGHT_ENEMY},		
	{ability_id=ABILITIES_ID.ATTACK_AND_DEFEND, default_gui_name="Attack enemy and defend self.", ability_type = ABILITY_TYPE.OFFENSIVE, ap_cost=3, speed = 3, charges = CHARGES_AMOUNT_NORMAL, targeting = TARGETING_TYPE.FIRST_RIGHT_ENEMY},
	{ability_id=ABILITIES_ID.LIFESTEAL_ATTACK, default_gui_name="Lifesteal attack.", ability_type = ABILITY_TYPE.OFFENSIVE, ap_cost=3, speed = 3, charges = CHARGES_AMOUNT_NORMAL, targeting = TARGETING_TYPE.FIRST_RIGHT_ENEMY},
	# {ability_id=ABILITIES_ID.MOVE_TO_CLOSEST_ENEMY, default_gui_name="move to closest enemy", ability_type = ABILITY_TYPE.movement, ap_cost=1, charges = NAN, targeting = TARGETING_TYPE.SELF},
	{ability_id=ABILITIES_ID.REMOVE_ENEMY_CHARGES, default_gui_name="Remove enemy ap.", ability_type = ABILITY_TYPE.OFFENSIVE, ap_cost=3, speed = 3, charges = CHARGES_AMOUNT_VERY_EXPENSIVE, targeting = TARGETING_TYPE.FIRST_RIGHT_CHARACTER_IN_SAME_ROW},
	{ability_id=ABILITIES_ID.BURN_THIS_ACTION_TO_GET_AP, default_gui_name="Burn this action to get AP", ability_type = ABILITY_TYPE.OTHER, ap_cost=1, speed = 1, charges = CHARGES_AMOUNT_VERY_EXPENSIVE, targeting = TARGETING_TYPE.SELF},
	{ability_id=ABILITIES_ID.SLOW_ALL_ENEMIES, default_gui_name="Slow all enemies.", ability_type = ABILITY_TYPE.OFFENSIVE, ap_cost=5, charges = CHARGES_AMOUNT_NORMAL, speed = 2, targeting = TARGETING_TYPE.ALL_ENEMIES},
	{ability_id=ABILITIES_ID.HEAL_ACCORDING_TO_USED_CHARGES, default_gui_name="Heal according to missing charges.", ability_type = ABILITY_TYPE.DEFENSIVE, ap_cost=3, speed = 4, charges = CHARGES_AMOUNT_EXPENSIVE, targeting = TARGETING_TYPE.SELF},
	{ability_id=ABILITIES_ID.MAKE_HEALING_DAMAGES_AND_ATTACK, default_gui_name="Turn healing to damage, and attack enemy.", ability_type = ABILITY_TYPE.OFFENSIVE, ap_cost=5, speed = 5, charges = CHARGES_AMOUNT_VERY_EXPENSIVE, targeting = TARGETING_TYPE.FIRST_LEFT_ENEMY},
	{ability_id=ABILITIES_ID.ATTACK_BASED_ON_NUMBER_OF_ENEMY_DEFENSIVE_ABILITIES_DONE, default_gui_name="Attack based on number of enemy defensive abilities done", ability_type = ABILITY_TYPE.OFFENSIVE, ap_cost=4, speed = 4, charges = CHARGES_AMOUNT_NORMAL, targeting = TARGETING_TYPE.FIRST_LEFT_ENEMY},
	{ability_id=ABILITIES_ID.STRONG_RANGED_ATTACK, default_gui_name="Strong ranged attack.", ability_type = ABILITY_TYPE.OFFENSIVE, ap_cost=3, speed = 3, charges = CHARGES_AMOUNT_CHEAP, targeting = TARGETING_TYPE.FIRST_RIGHT_ENEMY},
	{ability_id=ABILITIES_ID.HEAL_TO_PREVIOUS_PHASE_HP, default_gui_name="Heal to the hp in the phase hp.", ability_type = ABILITY_TYPE.DEFENSIVE, ap_cost=4, speed = 4, charges = CHARGES_AMOUNT_EXPENSIVE, targeting = TARGETING_TYPE.SELF},
	{ability_id=ABILITIES_ID.REDO_LAST_ENEMY_ACTION, default_gui_name="Redo last enemy action.", ability_type = ABILITY_TYPE.DEFENSIVE, ap_cost=5, speed = 5, charges = CHARGES_AMOUNT_EXPENSIVE, targeting = TARGETING_TYPE.SELF},
	{ability_id=ABILITIES_ID.DO_DAMAGE_BASED_ON_ENEMY_AP, default_gui_name="Do damage based on enemy ap.", ability_type = ABILITY_TYPE.OFFENSIVE, ap_cost=4, speed = 4, charges = CHARGES_AMOUNT_EXPENSIVE, targeting = TARGETING_TYPE.FIRST_LEFT_ENEMY},
	{ability_id=ABILITIES_ID.DO_ALL_ONE_SPEED_ACTIONS_IN_A_ROW, default_gui_name="Do all one speed actions in a row.", ability_type = ABILITY_TYPE.OFFENSIVE, ap_cost=5, speed = 5, charges = CHARGES_AMOUNT_EXPENSIVE, targeting = TARGETING_TYPE.FIRST_LEFT_ENEMY},
	{ability_id=ABILITIES_ID.STUN_ALL_ENEMIES_IN_ATTACK_RANGE, default_gui_name="Stun all enemies in attack range.", ability_type = ABILITY_TYPE.OFFENSIVE, ap_cost=3, speed = 3, charges = CHARGES_AMOUNT_EXPENSIVE, targeting = TARGETING_TYPE.ALL_ENEMIES},
	{ability_id=ABILITIES_ID.ATTACK_LOWEST_HP_ENEMY, default_gui_name="Attack lowest hp enemy", ability_type = ABILITY_TYPE.OFFENSIVE, ap_cost=4, speed = 4, charges = CHARGES_AMOUNT_NORMAL, targeting = TARGETING_TYPE.LOWEST_HP_ENEMY},
	{ability_id=ABILITIES_ID.MAKE_BOTH_YOU_AND_THE_CLOSEST_ENEMY_VULNERABLE_THEN_ATTACK_IT, default_gui_name="Make self and closest enemy vulnerable, then attack it", ability_type = ABILITY_TYPE.OFFENSIVE, ap_cost=2, speed = 2, charges = CHARGES_AMOUNT_EXPENSIVE, targeting = TARGETING_TYPE.FIRST_RIGHT_ENEMY},
	{ability_id=ABILITIES_ID.DAMAGE_ENEMY_BASED_ON_TANKY_ALLY, default_gui_name="Damage enemy next based on the hp of its tanky ally", ability_type = ABILITY_TYPE.OFFENSIVE, ap_cost=2, speed = 3, charges = CHARGES_AMOUNT_EXPENSIVE, targeting = TARGETING_TYPE.FIRST_RIGHT_ENEMY},
	{ability_id=ABILITIES_ID.KILL_IF_LESS_THAN_PERCENTAGE_MAX_HP_V2, default_gui_name="Kill if less than 30% hp, then take the same amount of damage", ability_type = ABILITY_TYPE.OFFENSIVE, ap_cost=2, speed = 4, charges = CHARGES_AMOUNT_VERY_EXPENSIVE, targeting = TARGETING_TYPE.FIRST_RIGHT_ENEMY},
	{ability_id=ABILITIES_ID.VERY_WEAK_LINE_ATTACK, default_gui_name="Very weak line attack.", ability_type = ABILITY_TYPE.OFFENSIVE, ap_cost=2, speed = 2, charges = CHARGES_AMOUNT_NORMAL, targeting = TARGETING_TYPE.RIGHT_ENEMY_COLUMN},
	{ability_id=ABILITIES_ID.REMOVE_DEBUFFS_FROM_SELF, default_gui_name="Remove debuffs from self.", ability_type = ABILITY_TYPE.DEFENSIVE, ap_cost=2, speed = 1, charges = CHARGES_AMOUNT_EXPENSIVE, targeting = TARGETING_TYPE.SELF},
	{ability_id=ABILITIES_ID.INCREASE_DEBUFF_DURATION, default_gui_name="Increase debuff duration.", ability_type = ABILITY_TYPE.OFFENSIVE, ap_cost=4, speed = 1, charges = CHARGES_AMOUNT_EXPENSIVE, targeting = TARGETING_TYPE.FIRST_RIGHT_ENEMY},
	{ability_id=ABILITIES_ID.COPY_BUFF, default_gui_name="Copy buff from target.", ability_type = ABILITY_TYPE.OTHER, ap_cost=2, speed = 5, charges = CHARGES_AMOUNT_EXPENSIVE, targeting = TARGETING_TYPE.FIRST_RIGHT_CHARACTER_IN_SAME_ROW},
	{ability_id=ABILITIES_ID.GAIN_MOVEMENT_POINTS, default_gui_name="Gain movement points.", ability_type = ABILITY_TYPE.OTHER, ap_cost=2, speed = 5, charges = CHARGES_AMOUNT_VERY_CHEAP, targeting = TARGETING_TYPE.SELF},
	{ability_id=ABILITIES_ID.DAMAGE_BASE_ON_NUMBER_OF_STATUS_EFFECTS, default_gui_name="Damage base on the number of status effects number of self and enemies.", ability_type = ABILITY_TYPE.OFFENSIVE, ap_cost=2, speed = 4, charges = CHARGES_AMOUNT_NORMAL, targeting = TARGETING_TYPE.FIRST_RIGHT_CHARACTER_IN_SAME_ROW},
	{ability_id=ABILITIES_ID.STRONG_SINGLE_TARGET_NUKE, default_gui_name="Strong single target nuke.", ability_type = ABILITY_TYPE.OFFENSIVE, ap_cost=2, speed = 4, charges = CHARGES_AMOUNT_VERY_EXPENSIVE, targeting = TARGETING_TYPE.FIRST_RIGHT_CHARACTER_IN_SAME_ROW},
	{ability_id=ABILITIES_ID.SINGLE_TARGET_NUKE_THAT_HEALS, default_gui_name="Single target nuke that heals.", ability_type = ABILITY_TYPE.OFFENSIVE, ap_cost=2, speed = 4, charges = CHARGES_AMOUNT_EXPENSIVE, targeting = TARGETING_TYPE.FIRST_RIGHT_CHARACTER_IN_SAME_ROW},
	{ability_id=ABILITIES_ID.SINGLE_TARGET_NUKE_THAT_PUSHES, default_gui_name="Single target nuke that pushes.", ability_type = ABILITY_TYPE.OFFENSIVE, ap_cost=2, speed = 4, charges = CHARGES_AMOUNT_NORMAL, targeting = TARGETING_TYPE.FIRST_RIGHT_CHARACTER_IN_SAME_ROW},
	{ability_id=ABILITIES_ID.MAKE_CLOSEST_CHARACTER_AND_SELF_INVUNERABLE_AND_STUNNED, default_gui_name="closest character and myself get stunned, self invunerable", ability_type = ABILITY_TYPE.OFFENSIVE, ap_cost=2, speed = 4, charges = CHARGES_AMOUNT_NORMAL, targeting = TARGETING_TYPE.FIRST_RIGHT_CHARACTER_IN_SAME_ROW},
	{ability_id=ABILITIES_ID.DEFENSE_COSTS_CHARGES_AND_HEALS, default_gui_name="Defense costs charges and heals.", ability_type = ABILITY_TYPE.DEFENSIVE, ap_cost=2, speed = 4, charges = CHARGES_AMOUNT_CHEAP, targeting = TARGETING_TYPE.SELF},
	{ability_id=ABILITIES_ID.SHORT_STUN_COLUMN, default_gui_name="Stun a column for a short duration.", ability_type = ABILITY_TYPE.OFFENSIVE, ap_cost=2, speed = 1, charges = CHARGES_AMOUNT_EXPENSIVE, targeting = TARGETING_TYPE.RIGHT_COLUMN},
	{ability_id=ABILITIES_ID.LONG_STUN_ENEMY_AND_SELF, default_gui_name="Stun self and enemy.", ability_type = ABILITY_TYPE.OFFENSIVE, ap_cost=2, speed = 3, charges = CHARGES_AMOUNT_NORMAL, targeting = TARGETING_TYPE.FIRST_RIGHT_ENEMY},
	{ability_id=ABILITIES_ID.CHANGE_DIRECTION_OF_CHARACTER, default_gui_name="Change the ability direction of the target", ability_type = ABILITY_TYPE.OFFENSIVE, ap_cost=2, speed = 2, charges = CHARGES_AMOUNT_EXPENSIVE, targeting = TARGETING_TYPE.FIRST_RIGHT_CHARACTER_IN_SAME_ROW},
	{ability_id=ABILITIES_ID.CHANGE_DIRECTION_OF_CHARACTERS_ON_BOTH_SIDES_AND_BECOME_DAMAGE_IMMUNE, default_gui_name="Change the direction of characters on both sides and become immune to damage.", ability_type = ABILITY_TYPE.OFFENSIVE, ap_cost=2, speed = 2, charges = CHARGES_AMOUNT_VERY_EXPENSIVE, targeting = TARGETING_TYPE.CHARACTERS_ON_BOTH_SIDES},
	{ability_id=ABILITIES_ID.STUN_FASTEST_ENEMY, default_gui_name="Stun fastest enemy", ability_type = ABILITY_TYPE.OFFENSIVE, ap_cost=3, speed = 3, charges = CHARGES_AMOUNT_NORMAL, targeting = TARGETING_TYPE.SLOWEST_ENEMY},
	
]

onready var character = get_parent().get_parent()

export (ABILITIES_ID) var ability_id:int
export var gui_name:String
export (ABILITY_TYPE) var ability_type:int
export var ap_cost:int
export var speed:int
export var is_enabled:bool
export var initial_charges:int = CHARGES_NOT_USED
export var charges:int = CHARGES_NOT_USED
var hp_in_previous_phase:int
export (TARGETING_TYPE) var target_type
var done_channeling = false

func initialize(ability_id:int, gui_name:String="", is_enabled:bool=true):
	var data = get_ability_data_by_ability_id(ability_id)
	if data==null: push_error("ability id given couldn't be found: " + String(ability_id)) # can't technically happen after the id refactor 
	
	self.ability_id = ability_id
	if gui_name=="": self.gui_name = data.default_gui_name
	else: self.gui_name = gui_name
	self.ability_type = data.ability_type
	self.ap_cost = data.ap_cost
	self.speed = data.speed
	self.initial_charges = data.charges
	self.charges = data.charges
	self.target_type = data.targeting
	self.is_enabled = is_enabled

# full_reset - completely reset ability. reset charges back to full.
func reset_ability(full_reset:=false):
	var data = get_ability_data_by_ability_id(self.ability_id)	
	self.ap_cost = data.ap_cost
	self.target_type = data.targeting
	self.is_enabled = true
	self.hp_in_previous_phase = character.hp
	
	if full_reset: self.charges = data.charges
	
# return the data from ABILITY_DATA, or null if ability_id is not a valid id from ABILITIES_ID
func get_ability_data_by_ability_id(ability_id:int):
	for a in ABILITY_DATA:
		if a.ability_id==ability_id:
			return a
	return null	

# reduce the amount of charges of the ability
func reduce_charges(reduction_amount:int)->void:
	charges-=reduction_amount
	if charges <=0: charges=0

# do this ability's function
func do_function():
	if charges != CHARGES_NOT_USED:
		if charges<=0: return
		reduce_charges(1)		
		character.emit_signal("ability_charges_changed",self)
	#do ability function based on its ability_id
	match ability_id:
		ABILITIES_ID.DO_NOTHING: do_nothing()
		ABILITIES_ID.WEAK_DEFENSE: weak_defense()
		ABILITIES_ID.REGULAR_DEFENSE: regular_defense()
		ABILITIES_ID.STRONG_DEFENSE: strong_defense()
		ABILITIES_ID.REGULAR_ATTACK: regular_attack()
		ABILITIES_ID.REGULAR_RANGED_ATTACK: regular_ranged_attack()
		ABILITIES_ID.STUN_ATTACK: stun_attack()
		ABILITIES_ID.REMOVE_PERCENTAGE_HP_ALL_ENEMIES: remove_percentage_hp_all_enemies()
		ABILITIES_ID.KILL_IF_LESS_THAN_PERCENTAGE_MAX_HP: kill_if_less_than_percentage_max_hp()
		ABILITIES_ID.DAMAGE_ALL_ENEMIES_HEAL_ALL_ALLIES: damage_all_enemies_heal_all_allies()
		# ABILITIES_ID.MOVE_TO_CLOSEST_ENEMY_DOUBLE_DAMAGE_TAKEN_AND_RECEIVED: move_to_closest_enemy_double_damage_taken_and_received()
		ABILITIES_ID.REMOVE_ALL_TEMP_HP_FROM_ALL_ENEMIES: remove_all_temp_hp_from_all_enemies()
		# ABILITIES_ID.PULL_FURTHEST_ENEMY_TO_CLOSEST_ALLY_AND_MAKE_IT_VULNERABLE: pull_furthest_enemy_to_closest_ally_and_make_it_vulnerable()
		# ABILITIES_ID.MOVE_AWAY_FROM_CLOSEST_ENEMY: move_away_from_closest_enemy()
		ABILITIES_ID.DISABLE_ENEMY_DEFENSIVE_ACTIONS: disable_enemy_defensive_actions()
		ABILITIES_ID.STUN_SLOWEST_ENEMY: stun_slowest_enemy()
		ABILITIES_ID.ATTACKERS_GET_STUNNED: attackers_get_stunned()
		ABILITIES_ID.DISABLE_ENEMY_OFFENSIVE_ACTIONS: disable_enemy_offensive_actions()
		ABILITIES_ID.ATTACK_AND_DEFEND: attack_and_defend()
		ABILITIES_ID.LIFESTEAL_ATTACK: lifesteal_attack()
		# ABILITIES_ID.MOVE_TO_CLOSEST_ENEMY: move_to_closest_enemy()
		ABILITIES_ID.REMOVE_ENEMY_CHARGES: remove_enemy_charges()
		ABILITIES_ID.BURN_THIS_ACTION_TO_GET_AP: burn_this_action_to_get_AP()
		ABILITIES_ID.SLOW_ALL_ENEMIES: slow_all_enemies() 
		ABILITIES_ID.HEAL_ACCORDING_TO_USED_CHARGES: heal_according_to_used_charges()
		ABILITIES_ID.MAKE_HEALING_DAMAGES_AND_ATTACK: make_healing_damages_and_attack()
		ABILITIES_ID.ATTACK_BASED_ON_NUMBER_OF_ENEMY_DEFENSIVE_ABILITIES_DONE: attack_based_on_number_of_enemy_defensive_abilities_done()
		ABILITIES_ID.STRONG_RANGED_ATTACK: strong_ranged_attack()
		ABILITIES_ID.HEAL_TO_PREVIOUS_PHASE_HP: heal_to_previous_phase_hp()
		ABILITIES_ID.REDO_LAST_ENEMY_ACTION: redo_last_enemy_action()
		ABILITIES_ID.DO_DAMAGE_BASED_ON_ENEMY_AP: do_damage_based_on_enemy_ap()
		ABILITIES_ID.DO_ALL_ONE_SPEED_ACTIONS_IN_A_ROW: do_all_one_speed_actions_in_a_row()
		ABILITIES_ID.STUN_ALL_ENEMIES_IN_ATTACK_RANGE: stun_all_enemies_in_attack_range()
		ABILITIES_ID.ATTACK_LOWEST_HP_ENEMY: attack_lowest_hp_enemy()
		ABILITIES_ID.MAKE_BOTH_YOU_AND_THE_CLOSEST_ENEMY_VULNERABLE_THEN_ATTACK_IT: make_both_you_and_the_closest_enemy_vulnerable_then_attack_it()
		ABILITIES_ID.DAMAGE_ENEMY_BASED_ON_TANKY_ALLY: damage_enemy_based_on_tanky_ally()
		ABILITIES_ID.KILL_IF_LESS_THAN_PERCENTAGE_MAX_HP_V2: kill_if_less_than_percentage_max_hp_v2()
		ABILITIES_ID.VERY_WEAK_LINE_ATTACK: very_weak_line_attack()
		ABILITIES_ID.REMOVE_DEBUFFS_FROM_SELF: remove_debuffs_from_self()
		ABILITIES_ID.INCREASE_DEBUFF_DURATION: increase_debuff_duration()
		ABILITIES_ID.COPY_BUFF: copy_buff()
		ABILITIES_ID.GAIN_MOVEMENT_POINTS: gain_movement_points()
		ABILITIES_ID.DAMAGE_BASE_ON_NUMBER_OF_STATUS_EFFECTS: damage_base_on_number_of_status_effects()
		ABILITIES_ID.STRONG_SINGLE_TARGET_NUKE: strong_single_target_nuke()
		ABILITIES_ID.SINGLE_TARGET_NUKE_THAT_HEALS: single_target_nuke_that_heals()
		ABILITIES_ID.SINGLE_TARGET_NUKE_THAT_PUSHES: single_target_nuke_that_pushes()		
		ABILITIES_ID.MAKE_CLOSEST_CHARACTER_AND_SELF_INVUNERABLE_AND_STUNNED: make_closest_character_and_self_invunerable_and_stunned()		
		ABILITIES_ID.DEFENSE_COSTS_CHARGES_AND_HEALS: defense_costs_charges_and_heals()
		ABILITIES_ID.SHORT_STUN_COLUMN: short_stun_column()
		ABILITIES_ID.LONG_STUN_ENEMY_AND_SELF: long_stun_enemy_and_self()
		ABILITIES_ID.CHANGE_DIRECTION_OF_CHARACTER: change_direction_of_character()
		ABILITIES_ID.CHANGE_DIRECTION_OF_CHARACTERS_ON_BOTH_SIDES_AND_BECOME_DAMAGE_IMMUNE: change_direction_of_characters_on_both_sides_and_become_damage_immune()
		ABILITIES_ID.STUN_FASTEST_ENEMY_ENEMY: stun_fastest_enemy()
		
		
		
		
				
	
		_: push_error("couldn't find a proper do_function for ability " + gui_name + " using the given id: " + String(ability_id)) #underscore is the default in gdnative. Great job guys, really intuitive.

# do the character's ability
func do_nothing():
	pass


# regular defense on self
func regular_defense():
	for c in Globals.action_matrix.get_targets():
		c.status_effects.add_status_effect(Globals.STATUS_EFFECTS_ID.STANDARD_DEFENSE,2)

# weak defense on self
func weak_defense():
	for c in Globals.action_matrix.get_targets():
		c.status_effects.add_status_effect(Globals.STATUS_EFFECTS_ID.WEAK_DEFENSE,2)	

func channel_ability(ability, channel_duration:int):
		done_channeling = false
		character.status_effects.add_status_effect(Globals.STATUS_EFFECTS_ID.CHANNELING,channel_duration)		
		character.channeled_ability = ability

# channel for x turns, then def self for y
func strong_defense():
	if !done_channeling:
		channel_ability(self,3)
		return
	else:
		for c in Globals.action_matrix.get_targets():
			c.status_effects.add_status_effect(Globals.STATUS_EFFECTS_ID.STANDARD_DEFENSE,6)					


# regular attack on closest enemy
# target_character - use this Character instead of the normal one from get_targets. To be used when regular_attack is called from other abilities
# attack_strength_modifier - How strong the attack should be, as defined in game_data
# so if attack_strength_modifier == very weak attack, the attack should do 0.5 of standrad attack damage
func regular_attack(attack_strength_modifier:int=Globals.game_data.STANDARD_ATTACK_DAMAGE):	
	# check for special conditions that change targeting
	# put here passives or special conditions that change targeting. Example:
#	if character.passives_manager.has_passive_and_enabled(Passive.PASSIVES_ID.STANDARD_ATTACKS_HIT_ALL_ENEMIES_IN_RANGE):		
#		# get all targets in range
#		var t = self.target_type
#		self.target_type = TARGETING_TYPE.ALL_ENEMIES_IN_ATTACK_RANGE 
#		targets = get_targets()
#		self.target_type = t 
	for target in Globals.action_matrix.get_targets():
		_regular_attack(target, attack_strength_modifier)

	
	

# do a regular attack on govem target. to be called from other abilities
# target_character - use this Character instead of the normal one from get_targets. To be used when regular_attack is called from other abilities
# attack_strength_modifier - How strong the attack should be, as defined in game_data
# so if attack_strength_modifier == very weak attack, the attack should do 0.5 of standrad attack damage
func _regular_attack(target_character, attack_strength_modifier:int=Globals.game_data.STANDARD_ATTACK_DAMAGE):
	# decide the damage of the attack
	# if it's a weak attack the damage is gonna be halved, if it's strong it's gonna be 1.5, etc'
	var damage_mult = 1
	damage_mult *= float(attack_strength_modifier) / Globals.game_data.STANDARD_ATTACK_DAMAGE	
	
	# handle relevant passives
	var charater_damage :int= character.attack_power	
	if character.passives_manager.has_passive_and_enabled(Passive.PASSIVES_ID.DO_EXTRA_DAMAGE_TO_TANKIER_ENEMIES):
		if character.get_total_hp() < target_character.get_total_hp():
			charater_damage += character.passives_manager.get_passive(Passive.PASSIVES_ID.DO_EXTRA_DAMAGE_TO_TANKIER_ENEMIES).get_level() * 2
	
	# the damage is caluclated as total_damage * percentage_attack_strength (10 * 0.5 = 5 damage)
	charater_damage *= damage_mult
	
	if target_character==null:			
		push_error("enemy is null inside regular_attack. fix the bug.")
		target_character.hp +=1 # this should trigger the bug. I think it was fixed by now, so I'm not sure if still exists
	
	# if enemy is in range, attack it
	if Globals.combat_control.action_matrix.is_in_attack_range(character,target_character):
		character.do_damage(target_character, charater_damage, Globals.game_data.DAMAGE_TYPE.PHYSICAL)
		
		# do on hit effects
		# splash damage
		if character.passives_manager.has_passive_and_enabled(Passive.PASSIVES_ID.STANDARD_ATTACK_DOES_SPLASH_DAMAGE):
			for enemy_in_splash_range in Globals.combat_control.action_matrix.get_characters_in_range_of_character(target_character, 1, character.team, false,true):
				character.do_damage(enemy_in_splash_range, charater_damage*0.3, Globals.game_data.DAMAGE_TYPE.PHYSICAL)
		# do STANDARD_ATTACKS_REDUCE_ENEMY_ATTACK_POWER
		if character.passives_manager.has_passive_and_enabled(Passive.PASSIVES_ID.STANDARD_ATTACKS_REDUCE_ENEMY_ATTACK_POWER):
			target_character.attack_power -= 1
			if target_character.attack_power<0: target_character.attack_power=0

		
# regular attack on furthest  enemy
func regular_ranged_attack(damage_multiplier:float=1):	
	for enemy in Globals.action_matrix.get_targets():
		if enemy!=null and enemy.is_alive():
			character.do_damage(enemy, character.attack_power*damage_multiplier, Globals.game_data.DAMAGE_TYPE.PHYSICAL)

# does a strong ranged attack, but doesn't do anything if an enemy is nearby
func strong_ranged_attack():
	if Globals.combat_control.action_matrix.is_enemy_nearby(character): return
	regular_ranged_attack(1.5)
		
	
# stun closest enemy
func stun_attack():
	for enemy in Globals.action_matrix.get_targets():
		enemy.status_effects.add_status_effect(Globals.STATUS_EFFECTS_ID.STUNNED,3)

			
#removes % hp from all enemies
func remove_percentage_hp_all_enemies():
	for enemy in Globals.action_matrix.get_targets():
		var hp = enemy.max_hp*0.07
		character.do_damage(enemy, hp, Globals.game_data.DAMAGE_TYPE.MAGICAL)
			
#kill closest enemy if less than % hp
func kill_if_less_than_percentage_max_hp():
	for enemy in Globals.action_matrix.get_targets():
		if enemy.hp < enemy.max_hp*0.2:
			character.do_damage(enemy, enemy.hp, Globals.game_data.DAMAGE_TYPE.MAGICAL)
			

#damage all enemies, heal all allies
func damage_all_enemies_heal_all_allies():
	# damage all enemies
	for target in Globals.action_matrix.get_targets():
		if character.team==target.team:
			target.heal(character,Globals.game_data.STANDARD_DAMAGE_3_SPEED)
		else:			
			character.do_damage(target, Globals.game_data.STANDARD_DAMAGE_2_SPEED, Globals.game_data.DAMAGE_TYPE.MAGICAL)
			

# move to closest enemy, double damage this character takes and receives
# removed
#func move_to_closest_enemy_double_damage_taken_and_received():
#	move_to_closest_enemy()
#	character.status_effects.add_status_effect(Globals.STATUS_EFFECTS_ID.VULNERABLE,3)
#	character.status_effects.add_status_effect(Globals.STATUS_EFFECTS_ID.EMPOWERED,3)
	

# move this character to closest enemy
# removed
#func move_to_closest_enemy():
#	var enemy = Globals.combat_zone.get_closest_living_enemy(character)[0]
#	Globals.combat_zone.move_character_to_other_character(character, enemy)

# removed
#func move_away_from_closest_enemy():
#	var enemy = Globals.combat_zone.get_closest_living_enemy(character)[0]
#	Globals.combat_zone.move_character_away_from_other_character(character, enemy)


#remove all temp hp from all enemies
func remove_all_temp_hp_from_all_enemies():
	for e in Globals.action_matrix.get_targets():	
		character.do_damage(e, e.temp_hp, Globals.game_data.DAMAGE_TYPE.MAGICAL)
			

# forces a character to do an ability
# TODO fix this, right now the targeting doesn't take into account changes in the direction
# this was broken after moving targeting from Ability to the action matrix
func force_character_to_do_ability_v3(character_to_do_action, forced_ability:Ability)->void:		
	var ab:Ability = character_to_do_action.abilities_manager.add_ability_by_id(forced_ability.ability_id)
	ab.target_type = forced_ability.target_type
	character_to_do_action.do_ability_action(ab)
	character_to_do_action.abilities_manager.remove_last_ability()
	
# removed
#func pull_furthest_enemy_to_closest_ally_and_make_it_vulnerable():
#	for e in get_targets():		
#		force_character_to_do_ability_v2(e, ABILITIES_ID.MOVE_TO_CLOSEST_ENEMY)	
#		e.status_effects.add_status_effect(Globals.STATUS_EFFECTS_ID.VULNERABLE,2)		

# disable the defensive actions of the closest enemy
func disable_enemy_defensive_actions():
	for e in Globals.action_matrix.get_targets():
		e.status_effects.add_status_effect(Globals.STATUS_EFFECTS_ID.CANT_DEFEND,2)		

# stun slowest enemy
func stun_slowest_enemy():
	for enemy in Globals.action_matrix.get_targets():
		enemy.status_effects.add_status_effect(Globals.STATUS_EFFECTS_ID.STUNNED,2)

# stun fastest enemy
func stun_fastest_enemy():
	for enemy in Globals.action_matrix.get_targets():
		enemy.status_effects.add_status_effect(Globals.STATUS_EFFECTS_ID.STUNNED,2)
		
# the attackers of this characters get stunned
func attackers_get_stunned():
	character.status_effects.add_status_effect(Globals.STATUS_EFFECTS_ID.STUN_ATTACKERS,2)	
	
# disable the defensive actions of the closest enemy
func disable_enemy_offensive_actions():
	for enemy in Globals.action_matrix.get_targets():
		enemy.status_effects.add_status_effect(Globals.STATUS_EFFECTS_ID.CANT_ATTACK,2)			

# attack closest enemy, then defend self
func attack_and_defend():
	var cur_button = Globals.action_matrix.get_current_turn_button_v2()
	var t = cur_button.targeting_type	
	for target in Globals.action_matrix.get_targets():
		_regular_attack(target)
	cur_button.targeting_type = TARGETING_TYPE.SELF
	regular_defense()
	cur_button.targeting_type = t

# attack closest enemy with lifesteal
func lifesteal_attack():
	character.lifesteal +=0.25
	for target in Globals.action_matrix.get_targets():
		_regular_attack(target)
	character.lifesteal -=0.25

# remove ap from the closest enemy
func remove_enemy_charges():
	for target_action_button in Globals.action_matrix.get_targets(false):
		target_action_button.ability.reduce_charges(2)
		

# use this action to get +15 ap, then remove ability
func burn_this_action_to_get_AP():
	character.ap += 15
	character.emit_signal("ap_points_changed")
	
# slow all enemies
func slow_all_enemies():	
	for enemy in Globals.action_matrix.get_targets():		
		enemy.status_effects.add_status_effect(Globals.STATUS_EFFECTS_ID.SLOWED,3)

# heal self according to missing ap
func heal_according_to_used_charges():
	var charges_used = 0
	for ability in character.abilities_manager.get_all_abilities():
		if  ability.initial_charges > ability.charges:
			charges_used+= ability.initial_charges - ability.charges
		
	for c in Globals.action_matrix.get_targets():
		c.heal(character, int(charges_used*0.25))

# make closest enemy healing damage it, and then attack it
func make_healing_damages_and_attack():
	for enemy in Globals.action_matrix.get_targets():
		enemy.status_effects.add_status_effect(Globals.STATUS_EFFECTS_ID.HEALING_DAMAGES,2)		
		_regular_attack(enemy)

# attack closest enemy based on the number of defensive actions all enemies did
func attack_based_on_number_of_enemy_defensive_abilities_done():
	var defensive_actions_done = 0
	for enemy in Globals.all_characters.get_enemies(character.team):
		defensive_actions_done +=enemy.action_history_type_count[ABILITY_TYPE.DEFENSIVE]	
	
	for enemy in Globals.action_matrix.get_targets():
		character.do_damage(enemy, defensive_actions_done*Globals.game_data.STANDARD_ATTACK_DAMAGE*(1/3), Globals.game_data.DAMAGE_TYPE.MAGICAL)	

# heal self to the hp in the previous phase
func heal_to_previous_phase_hp():
	for c in Globals.action_matrix.get_targets():
		var total_hp_before_heal = c.get_total_hp()
		if self.hp_in_previous_phase > total_hp_before_heal:
			c.heal(character, self.hp_in_previous_phase-c.get_total_hp())
		self.hp_in_previous_phase = total_hp_before_heal

# redo last enemy action
# TODO this is broken, need to fix force_character_to_do_ability_v3
func redo_last_enemy_action():
	# find the last action performed by an enemy	
	var last_enemy_action_button = null
	var this_action_button = Globals.combat_control.action_matrix.get_current_turn_button_v2()
	
	for b in Globals.combat_control.action_matrix.get_children():
		if b==this_action_button: break
		elif b.character.part_of_player_party!=character.part_of_player_party:
			last_enemy_action_button=b
	if last_enemy_action_button==null:
		return
	
	force_character_to_do_ability_v3(character,last_enemy_action_button.combat_ability)

# do damage based on missing hp
# TODO - fix this or remove. probably remove.
func do_damage_based_on_enemy_ap():	
#	var total_enemy_ap = 0
#	var round_number = character.get_action_from_action_order_by_ability(self).round_number
#	for e in Globals.all_characters.get_enemies(character.team):
#		var action = e.get_actions_from_action_order_by_round_number(round_number)
#		total_enemy_ap +=action.ability.ap_cost
		
	push_error("you never tested this code. check if it works")
	var missing_charges := 0
	for b in Globals.combat_control.action_matrix.get_children():
		if character.part_of_player_party==b.character.part_of_player_party:
			missing_charges += b.action_ability.initial_charges - b.action_ability.charges

	character.attack_power+=missing_charges
	for target in Globals.action_matrix.get_targets():
		_regular_attack(target)
	character.attack_power-=missing_charges
		
# do all 1 ap actions in the matrix in a row
# TODO fix this, speed is now detemined in the action matrix and so there's probably a bug here
# TODO this is broken, need to fix force_character_to_do_ability_v3
func do_all_one_speed_actions_in_a_row():
	push_error("you never tested this code. check if it works")
	var one_ap_abilities = []
	for b in Globals.combat_control.action_matrix.get_children():
		if b.combat_action_speed==1:
			one_ap_abilities.append(b.combat_ability)

	var this_action_button = Globals.combat_control.action_matrix.get_current_turn_button_v2()
	for abil in one_ap_abilities:
		force_character_to_do_ability_v3(character, abil)
			
			
# stun all nearby 
# TODO add get_targets after I add ability range to everything
func stun_all_enemies_in_attack_range():
	var targets = Globals.action_matrix.get_targets()
	for target in targets:
		target.status_effects.add_status_effect(Globals.STATUS_EFFECTS_ID.STUNNED,1)
		

# attack lowest hp enemy
func attack_lowest_hp_enemy():
	var targets = Globals.action_matrix.get_targets()
	for target in targets:
		_regular_attack(target)	

# both this character and the closest enemy becaome vulnerable then attack it
func make_both_you_and_the_closest_enemy_vulnerable_then_attack_it():
	for target in Globals.action_matrix.get_targets():
		target.status_effects.add_status_effect(Globals.STATUS_EFFECTS_ID.VULNERABLE,2)
		character.status_effects.add_status_effect(Globals.STATUS_EFFECTS_ID.VULNERABLE,2)
		_regular_attack(target)

# damage enemy that's next to its tanky ally. The target is the tank, the damage is done to his ally.
func damage_enemy_based_on_tanky_ally():
	var targets = Globals.action_matrix.get_targets()
	for target in targets:
		if target.team==character.team: continue # prevent using allies as the tank
		var tank_index = Globals.combat_control.action_matrix.get_button_index(character, Globals.combat_control.combat_round)		
		for i in [-1,1]:
			var ally_of_tank = Globals.combat_control.action_matrix.get_character_in_index(tank_index-1, Globals.combat_control.combat_round)
			if ally_of_tank!=null and ally_of_tank.team==character.team:continue
			var hp_diff = (target.get_total_hp() - ally_of_tank.get_total_hp())*0.5
			character.do_damage(ally_of_tank, hp_diff, Globals.game_data.DAMAGE_TYPE.MAGICAL)
				
#kill closest enemy if less than % hp, then take the same amount of damage
func kill_if_less_than_percentage_max_hp_v2():
	for enemy in Globals.action_matrix.get_targets():
		if enemy.get_total_hp() < enemy.max_hp*0.3:
			var damage = enemy.get_total_hp()
			character.do_damage(enemy, damage, Globals.game_data.DAMAGE_TYPE.MAGICAL)
			character.do_damage(character, damage, Globals.game_data.DAMAGE_TYPE.MAGICAL)


# does a very regular attack against an enemy line
func very_weak_line_attack():
	for target in Globals.action_matrix.get_targets():
		_regular_attack(target, Globals.game_data.STANDARD_DAMAGE_1_SPEED)


# remove all debuffs from self
func remove_debuffs_from_self():
	character.status_effects.remove_all_negative_status_effects()

# increase debuff duration
func increase_debuff_duration():
	for target in Globals.action_matrix.get_targets():
		for status_effect in target.status_effects.status_effects_dict.values():
			if status_effect.type == target.status_effects.STATUS_EFFECTS_TYPE.DEBUFF:
				target.status_effects.increase_status_effect(status_effect.id, 3)
				break

# copy buff from any character
func copy_buff():
	for target in Globals.action_matrix.get_targets():
		for status_effect in target.status_effects.status_effects_dict.values():
			if status_effect.type == target.status_effects.STATUS_EFFECTS_TYPE.BUFF:
				character.status_effects.add_status_effect(status_effect.id, status_effect.duration)				
				break

# gain movement points
func gain_movement_points():
	for target in Globals.action_matrix.get_targets():
		target.movement_points +=4	


# do damage to enemy based on the number of status effect on self and the enemy
func damage_base_on_number_of_status_effects():
	var self_status_num = character.status_effects.status_effects_dict.values().size()
	for target in Globals.action_matrix.get_targets():
		var target_status_num = character.status_effects.status_effects_dict.values().size()
		var damage = self_status_num + target_status_num
		character.do_damage(target, damage, Globals.game_data.DAMAGE_TYPE.MAGICAL)

# single target nuke to a single unit
func strong_single_target_nuke():
	var damage = Globals.game_data.STANDARD_DAMAGE_5_SPEED
	for target in Globals.action_matrix.get_targets():
		character.do_damage(target, damage, Globals.game_data.DAMAGE_TYPE.MAGICAL)

# single target nuke that heals for the same amount
func single_target_nuke_that_heals():
	var damage = Globals.game_data.STANDARD_ATTACK_DAMAGE
	for target in Globals.action_matrix.get_targets():
		character.do_damage(target, damage, Globals.game_data.DAMAGE_TYPE.MAGICAL)
		character.heal(character, Globals.game_data.STANDARD_ATTACK_DAMAGE)
		
# single target nuke that pushes unit 3 times
func single_target_nuke_that_pushes():
	var damage :int= Globals.game_data.STANDARD_DAMAGE_1_SPEED
	var push_amount := 3
	for target in Globals.action_matrix.get_targets():
		character.do_damage(target, damage, Globals.game_data.DAMAGE_TYPE.MAGICAL)
		var direction = Globals.combat_control.action_matrix.get_direction_between_characters_in_same_row(character,target)
		target.pushed(character, direction, push_amount)

# make closest character and self become both stunned and invunerable
func make_closest_character_and_self_invunerable_and_stunned():	
	character.status_effects.add_status_effect(Globals.STATUS_EFFECTS_ID.STUNNED,2)
	character.status_effects.add_status_effect(Globals.STATUS_EFFECTS_ID.DAMAGE_IMMUNE,2)
	for target in Globals.action_matrix.get_targets():
		target.status_effects.add_status_effect(Globals.STATUS_EFFECTS_ID.STUNNED,2)
		target.status_effects.add_status_effect(Globals.STATUS_EFFECTS_ID.DAMAGE_IMMUNE,2)		

# strong defense that costs charges of the last used ability and heals
# does nothing if there are no available charges
func defense_costs_charges_and_heals():
	var last_used_ability = null
	
	# get last used ability
	var act
	for i in range(0,Globals.combat_control.action_history.size()-1):
		act = Globals.combat_control.action_history[i]	
		if act.character == character:
			last_used_ability = act.ability	
	
	if last_used_ability==null or last_used_ability.charges < 3:
		# do nothing the last ability doesn't have enough charges
		return
	else:
		# remove charges from the last used spell, defend and heal afterwards
		last_used_ability.charges -=3
		regular_defense()
		character.heal(character,Globals.game_data.STANDARD_DAMAGE_3_SPEED)	

# stun enemy column for one turn and gain armor
func short_stun_column():
	for target in Globals.action_matrix.get_targets():
		target.status_effects.add_status_effect(Globals.STATUS_EFFECTS_ID.STUNNED,1)	

# stun enemy and self for a long time
# TODO add reduce enemy armor after I add that system instead of the current one
func long_stun_enemy_and_self():	
	for target in Globals.action_matrix.get_targets():
		target.status_effects.add_status_effect(Globals.STATUS_EFFECTS_ID.STUNNED,3)
	# cool bug - you need to stun the enemies before you stun yourself, because get_targets 
	# returns [] when you're stunned, as you can't act.
	character.status_effects.add_status_effect(Globals.STATUS_EFFECTS_ID.STUNNED,2)

# change target's direction
# TODO after I change targeting to return action buttons instead of characters I need to change this 
# since the targeting type would be removed
func change_direction_of_character():	
	for target_action_button in Globals.action_matrix.get_targets(false):
		target_action_button.change_direction_of_ability()
		
# become damage immune and change direction of characters on both sides
# TODO after I change targeting to return action buttons instead of characters I need to change this 
# since the targeting type would be removed
func change_direction_of_characters_on_both_sides_and_become_damage_immune():	
	character.status_effects.add_status_effect(Globals.STATUS_EFFECTS_ID.DAMAGE_IMMUNE,1)
	for target_action_button in Globals.action_matrix.get_targets(false):
		target_action_button.change_direction_of_ability()
		
# do weak defense and gain movement points
func weak_defense_and_gain_movement_points():
	character.movement_points +=3
	weak_defense()



func _to_string():
	print(gui_name)
	

# Called when the node enters the scene tree for the first time.
func _ready():	
	character = get_parent().character
	#hp_in_previous_phase = character.hp
	add_to_group("save_me",true)

# Used for saving the node. returns a dict of the node's features to be saved. 
func save()->Dictionary:
	var save_dict = {
		"filename" : get_filename(),
		"parent" : get_parent().get_path(),
		"ability_id" : ability_id,
		"gui_name" : gui_name,
		"ability_type" : ability_type,
		"ap_cost" : ap_cost,
		"speed" : speed,
		"is_enabled" : is_enabled,
		"charges" : charges,
		"target_type" : target_type,
	}
	return save_dict
