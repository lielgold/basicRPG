extends Control



onready var save_name = $save_name
onready var save_date = $save_date
onready var delete_button = $delete_button
onready var load_button = $load_button
onready var save_button = $save_button


var save_game_menu = null
var save_game_directory := ""

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func initialize(save_game_menu, save_game_directory:String):
	save_name = $save_name
	save_date = $save_date
	delete_button = $delete_button
	load_button = $load_button
	save_button = $save_button
	
	self.save_game_menu = save_game_menu
	self.save_game_directory = save_game_directory
	
	var dir = Directory.new()
	if dir.open(save_game_directory):
		save_name.text = save_game_directory		
	else:
		push_error("An error occurred when trying to access the save directory in the save widget.")
		return 1
	
	delete_button.connect("pressed",save_game_menu,"delete_save",[save_game_directory])
	load_button.connect("pressed",save_game_menu,"load_save",[save_game_directory])
	save_button.connect("pressed",save_game_menu,"overwrite_save",[save_game_directory, self])
		
	var meta_data = Globals.main.get_save_meta_data(Globals.SAVE_GAME_DIRECTORIES + save_game_directory)
	save_name.text = meta_data.name_of_the_save
	save_date.text = meta_data.date_of_the_save
	

# update the save name
func change_save_name(new_name=""):	
	Globals.main.save_name_changed(Globals.SAVE_GAME_DIRECTORIES + save_game_directory,save_name.text)
