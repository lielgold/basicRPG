extends Node

class_name Passive

# MY_TEAM_DOES_DOUBLE_DAMAGE_TO_STUNNED - if an ally has this passive you do double damage to stunned
enum PASSIVES_ID{GAIN_DAMAGE_REDUCTION, MY_TEAM_DOES_DOUBLE_DAMAGE_TO_STUNNED,STUN_EVERY_THIRD_ATTACK,STANDARD_ATTACK_DOES_SPLASH_DAMAGE,STANDARD_ATTACKS_HIT_ALL_ENEMIES_IN_RANGE,STANDARD_ATTACKS_REDUCE_ENEMY_ATTACK_POWER, 
	DO_EXTRA_DAMAGE_TO_TANKIER_ENEMIES, TAKE_LESS_DAMAGE_FROM_TANKIER_ENEMIES,GAIN_ATTACK_POWER_EVERY_ROUND} 
enum DO_PASSIVE_AT{START_OF_ROUND, ON_ATTACK, ON_TEAM_ATTACK,NONE}

const PASSIVES_INITIALIZATION_TABLE = [
	[PASSIVES_ID.GAIN_DAMAGE_REDUCTION,"gain damage reduction", DO_PASSIVE_AT.START_OF_ROUND],
	[PASSIVES_ID.MY_TEAM_DOES_DOUBLE_DAMAGE_TO_STUNNED,"my team does double damage to stunned", DO_PASSIVE_AT.ON_TEAM_ATTACK],
	[PASSIVES_ID.STUN_EVERY_THIRD_ATTACK,"stun every third attack", DO_PASSIVE_AT.ON_ATTACK],
	[PASSIVES_ID.STANDARD_ATTACK_DOES_SPLASH_DAMAGE,"standard attack does splash damage", DO_PASSIVE_AT.ON_ATTACK],
	[PASSIVES_ID.STANDARD_ATTACKS_HIT_ALL_ENEMIES_IN_RANGE,"standard attacks hit all enemies in range", DO_PASSIVE_AT.ON_ATTACK],
	[PASSIVES_ID.STANDARD_ATTACKS_REDUCE_ENEMY_ATTACK_POWER,"standard attacks reduce enemy attack power", DO_PASSIVE_AT.ON_ATTACK],
	[PASSIVES_ID.DO_EXTRA_DAMAGE_TO_TANKIER_ENEMIES,"do extra damage to tankier enemies", DO_PASSIVE_AT.ON_ATTACK], # regular attacks do extra damage per level
	[PASSIVES_ID.TAKE_LESS_DAMAGE_FROM_TANKIER_ENEMIES,"take less damage from tankier enemies", DO_PASSIVE_AT.ON_ATTACK], # take less damage from characters with more total hp
	[PASSIVES_ID.GAIN_ATTACK_POWER_EVERY_ROUND,"gain attack power every round", DO_PASSIVE_AT.START_OF_ROUND],
]

onready var character = get_parent().get_parent()

export (PASSIVES_ID) var id
var p_name:String
export var is_enabled:bool
export (DO_PASSIVE_AT) var when_to_do_passive
export var hit_counter =0
export var level:=1

func initialize(passive_id:int, passive_is_enabled = true, initial_level :=1):
	assert(passive_id in PASSIVES_ID.values())
	var l = get_passive_data_from_passive_initialization_table(passive_id)
	self.id = l[0]
	self.p_name = l[1]
	self.when_to_do_passive = l[2]
	self.is_enabled = passive_is_enabled
	self.level = initial_level

# give passive id, get the data on the passive from the initialization table
func get_passive_data_from_passive_initialization_table(passive_id):
	for l in PASSIVES_INITIALIZATION_TABLE:
		if l[0]==passive_id:
			return l

func reset_passive():
	is_enabled = true
	hit_counter = 0

func get_level():
	return level

func add_damage_reduction():
	assert(id==PASSIVES_ID.GAIN_DAMAGE_REDUCTION)
	character.damage_reduction+=3	
	
func MY_TEAM_DOES_DOUBLE_DAMAGE_TO_STUNNED(attacked, damage):
	assert(id==PASSIVES_ID.MY_TEAM_DOES_DOUBLE_DAMAGE_TO_STUNNED)

	if attacked.status_effects.is_status_active(Globals.STATUS_EFFECTS_ID.STUNNED):
		damage*=2
	return damage
	
func STUN_EVERY_THIRD_ATTACK(attacked):
	assert(id==PASSIVES_ID.STUN_EVERY_THIRD_ATTACK)
	hit_counter +=1
	if(hit_counter==3):
		hit_counter = 0
		attacked.status_effects.add_status_effect(Globals.STATUS_EFFECTS_ID.STUNNED,2)

# TODO when leveling this should go from every 3 round to 1, or something like that
func gain_attack_power_every_round():
	character.attack_power +=1

# Called when the node enters the scene tree for the first time.
func _ready():
	character = get_parent().character
	add_to_group("save_me",true)

# Used for saving the node. returns a dict of the node's features to be saved. 
func save()->Dictionary:
	var save_dict = {
		"filename" : get_filename(),
		"parent" : get_parent().get_path(),
		"id" : id,
		"p_name" : p_name,
		"is_enabled" : is_enabled,
		"when_to_do_passive" : when_to_do_passive,
		"hit_counter" : hit_counter,
	}
	return save_dict
