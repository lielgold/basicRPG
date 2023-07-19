extends HBoxContainer


export(GameData.CHARACTER_STATS) onready var stat


var character_menu
onready var increase = $increase
onready var decrease = $decrease
onready var stat_middle_button = $stat_middle_button

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func initialize(character_menu,stat):
	self.character_menu = character_menu
	self.stat = stat
	self.increase = $increase
	self.decrease = $decrease	
	self.stat_middle_button = $stat_middle_button	
	
	increase.connect("pressed",character_menu,"stat_levelup_widget_change",[self, stat, true])
	decrease.connect("pressed",character_menu,"stat_levelup_widget_change",[self, stat, false])
	
	stat_level_changed()

# update the gui of the middle button when the stat level changes
func stat_level_changed():		
	stat_middle_button.text = GameData.CHARACTER_STATS_GUI_NAMES[stat] + " - " + String(character_menu.character.get_stat_level(stat))
