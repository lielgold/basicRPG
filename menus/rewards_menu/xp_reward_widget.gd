extends Control


onready var player_icon = $player_icon
onready var player_xp = $player_xp

var character:Character
var xp_character_got:int

# Called when the node enters the scene tree for the first time.
func _ready():
	player_icon = $player_icon
	player_xp = $player_xp	
	
	
func initialize(character:Character, xp:int):
	player_icon = $player_icon
	player_xp = $player_xp	
	
	self.character = character
	xp_character_got = xp
	
	
	player_xp.text = character.character_name + " - XP: " + String(xp)	
	player_icon.texture = load(character.portrait.resource_path)

