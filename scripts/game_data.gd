extends Node

class_name GameData

# general

enum DAMAGE_TYPE {PHYSICAL, MAGICAL}

# --------------------- player characters

# the player starts with these characters	
const INITIAL_PARTY_RESOURCE_PATHS = [ #"res://scenes/characters/super_tanky_guy.tscn", 
										#"res://player_characters/anti_tank.tscn", 
										#"res://player_characters/manipulate_status_effects.tscn",
										"res://player_characters/singe_target_nuker.tscn", 
										"res://player_characters/stun_and_cc.tscn"] 
enum PLAYER_CHARACTER_IDS {GREEN_GUY, AP_GUY_BLUE, AP_GUY_RED, SUPER_TANKY_GUY, ANTI_TANK, MANIPULATE_STATUS_EFFECTS, SINGLE_TARGET_NUKER, STUN_AND_CC}
const PLAYER_IDS_TO_CHARACTER_RESOURCE_PATHS = {
	PLAYER_CHARACTER_IDS.GREEN_GUY : "res://scenes/characters/green_guy.tscn",
	PLAYER_CHARACTER_IDS.AP_GUY_BLUE : "res://scenes/characters/AP guy blue.tscn",
	PLAYER_CHARACTER_IDS.AP_GUY_RED : "res://scenes/characters/AP_guy_red.tscn", 
	PLAYER_CHARACTER_IDS.SUPER_TANKY_GUY : "res://scenes/characters/super_tanky_guy.tscn",
	PLAYER_CHARACTER_IDS.ANTI_TANK : "res://player_characters/anti_tank.tscn",
	PLAYER_CHARACTER_IDS.MANIPULATE_STATUS_EFFECTS : "res://player_characters/manipulate_status_effects.tscn",
	PLAYER_CHARACTER_IDS.SINGLE_TARGET_NUKER : "res://player_characters/singe_target_nuker.tscn",
	PLAYER_CHARACTER_IDS.STUN_AND_CC : "res://player_characters/stun_and_cc.tscn",	
	
}

# --------------------- character 

enum CHARACTER_STATS{base_attack, hp, ap,damage_reduction, max_hp, movement}
const CHARACTER_STATS_GUI_NAMES = {CHARACTER_STATS.base_attack:"attack", CHARACTER_STATS.hp:"hp", CHARACTER_STATS.ap:"ap", CHARACTER_STATS.max_hp:"max hp", CHARACTER_STATS.movement:"movement"}

enum SNEED{FEED,SEED,FORMERLY}


# this is the standard damage, abilities damage are based on it
const STANDARD_ATTACK_DAMAGE :int= 4

const STANDARD_DAMAGE_3_SPEED :int= STANDARD_ATTACK_DAMAGE
const STANDARD_DAMAGE_1_SPEED :int= int(STANDARD_DAMAGE_3_SPEED * 0.5)
const STANDARD_DAMAGE_2_SPEED :int= int(STANDARD_DAMAGE_3_SPEED * 0.75)
const STANDARD_DAMAGE_4_SPEED :int= int(STANDARD_DAMAGE_3_SPEED * 1.25)
const STANDARD_DAMAGE_5_SPEED :int= int(STANDARD_DAMAGE_3_SPEED * 1.5)

#used to balance hp pool
const FRAGILE_5_SPEED_HITS_TO_KILL := 3
const NORMAL_5_SPEED_HITS_TO_KILL := 4
const TANKY_5_SPEED_HITS_TO_KILL := 5


# hp gained per level is 10% of initial hp
const CHARACTER_STAT_HP_ARCHTYPE_DATA = {
	Character.CHARACTER_HP_ARCHTYPE.FRAGILE : {
		init_base_hp = FRAGILE_5_SPEED_HITS_TO_KILL * STANDARD_DAMAGE_5_SPEED,
		levelup_cost = 1,
		stat_gained_per_levelup = int(ceil(FRAGILE_5_SPEED_HITS_TO_KILL * STANDARD_DAMAGE_5_SPEED*0.1)),
	},
	Character.CHARACTER_HP_ARCHTYPE.NORMAL : {
		init_base_hp  = NORMAL_5_SPEED_HITS_TO_KILL * STANDARD_DAMAGE_5_SPEED,
		levelup_cost = 1,
		stat_gained_per_levelup = int(ceil(NORMAL_5_SPEED_HITS_TO_KILL * STANDARD_DAMAGE_5_SPEED*0.1)),
	},
	Character.CHARACTER_HP_ARCHTYPE.TANKY : {
		init_base_hp  = TANKY_5_SPEED_HITS_TO_KILL * STANDARD_DAMAGE_5_SPEED,
		levelup_cost = 1,
		stat_gained_per_levelup = int(ceil(TANKY_5_SPEED_HITS_TO_KILL * STANDARD_DAMAGE_5_SPEED*0.1)),
	},
}

# TODO change this if I want any difference in damage scaling. right now it's all the same
const CHARACTER_STAT_ATTACK_ARCHTYPE_DATA = {
	Character.CHARACTER_ATTACK_ARCHTYPE.WEAK : {
		init_base_attack = STANDARD_ATTACK_DAMAGE,
		levelup_cost = 3,
		stat_gained_per_levelup = 1,
	},
	Character.CHARACTER_ATTACK_ARCHTYPE.NORMAL : {
		init_base_attack = STANDARD_ATTACK_DAMAGE,
		levelup_cost = 3,
		stat_gained_per_levelup = 1,
	},
	Character.CHARACTER_ATTACK_ARCHTYPE.STRONG : {
		init_base_attack = STANDARD_ATTACK_DAMAGE,
		levelup_cost = 3,
		stat_gained_per_levelup = 1,
	},
}

const CHARACTER_STAT_SPEED_ARCHTYPE_DATA = { # VERY_SLOW, SLOW, NORMAL, FAST, VERY_FAST, NONE}
	Character.CHARACTER_SPEED_ARCHTYPE.VERY_SLOW : { 
		init_movement_speed = 0,
		levelup_cost = 5,
		stat_gained_per_levelup = 1,
	},
	Character.CHARACTER_SPEED_ARCHTYPE.SLOW : {
		init_movement_speed = 0,
		levelup_cost = 4,
		stat_gained_per_levelup = 1,
	},	
	Character.CHARACTER_SPEED_ARCHTYPE.NORMAL : {
		init_movement_speed = 1,
		levelup_cost = 3,
		stat_gained_per_levelup = 1,
	},
	Character.CHARACTER_SPEED_ARCHTYPE.FAST : {
		init_movement_speed = 2,
		levelup_cost = 2,
		stat_gained_per_levelup = 1,
	},
	Character.CHARACTER_SPEED_ARCHTYPE.VERY_FAST : {
		init_movement_speed = 3,
		levelup_cost = 1,
	},
}

# --------------------- items

enum ITEMS_ID {SHIELD, DAGGER,HEALING_CUP}
enum DO_ITEM_AT {NO_ACTIVE, TURN_START, TURN_END}

const ALL_ITEMS_DATA = [
	{
		id = ITEMS_ID.SHIELD, 
		gui_name = "Shield",
		passive_stats = {CHARACTER_STATS.damage_reduction:10},
		icon_path = "res://assets/item icons/fantasy shield.png",
		active = null,
		
	},
	{
		id = ITEMS_ID.DAGGER, 
		gui_name = "Dagger",
		passive_stats = {CHARACTER_STATS.base_attack:2},
		icon_path = "res://assets/item icons/fantasy dagger.png",
		active = {
			do_item_at = DO_ITEM_AT.TURN_END,
			charges = NAN,
		}
	},
	{
		id = ITEMS_ID.HEALING_CUP, 
		gui_name = "Healing Cup", 
		passive_stats = {CHARACTER_STATS.max_hp:50},
		icon_path = "res://assets/item icons/fantasy potion.png",
		active = {
			do_item_at = DO_ITEM_AT.TURN_START,
			charges = 3,
		}		
	}
]

static func get_item_data(item_id):
	for l in ALL_ITEMS_DATA:
		if l["id"]==item_id:
			return l



