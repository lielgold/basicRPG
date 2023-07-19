extends Control

const save_game_widget_resource = preload("res://menus/save_game_menu/save_game_widget.tscn")

onready var menu_panel = $menu_panel
onready var close_menu_button = $close_menu_button
onready var new_save_button = $new_save_button
onready var save_game_widget_container = $ScrollContainer/GridContainer/

# Called when the node enters the scene tree for the first time.
func _ready():
	menu_panel = $menu_panel
	close_menu_button = $close_menu_button
	new_save_button = $new_save_button
	save_game_widget_container = $ScrollContainer/GridContainer/
	
	close_menu_button.connect("pressed",self,"close_the_menu")
	new_save_button.connect("pressed",self,"create_new_save")
	
	update_saves_in_menu()
	
func _get_save_directories()->Array:
	var directores = []
	var dir = Directory.new()
	if dir.open(Globals.SAVE_GAME_DIRECTORIES) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				directores.append(file_name)
			file_name = dir.get_next()
	else:
		push_error("An error occurred when trying to access the save directory.")		
	return directores	

# update the save widgets in the menu
func update_saves_in_menu():	
	for widget in save_game_widget_container.get_children():
		widget.get_parent().remove_child(widget)
		widget.queue_free()
		
	var save_directories = _get_save_directories()
	for save_dir in save_directories:		
		var save_game_widget = save_game_widget_resource.instance()
		var error = save_game_widget.initialize(self, save_dir)
		if error: continue
		else: save_game_widget_container.add_child(save_game_widget)


# create a save folder with the specified name
func create_new_save(save_name:=""):
	# generate save name for the directory, uses the date by default
	var save_directory_name = Globals.main.get_date_as_string()
	
	# use the date of the save as the default name
	if save_name.empty(): save_name=save_directory_name
	
	# create the save file directory for the first time
	var dir = Directory.new()
	if dir.open(Globals.SAVE_GAME_DIRECTORIES)!=OK:
		dir.make_dir(Globals.SAVE_GAME_DIRECTORIES)
	dir.open(Globals.SAVE_GAME_DIRECTORIES)
	
	# save the game	
	save_directory_name = Globals.SAVE_GAME_DIRECTORIES + save_directory_name + "/"
	dir.make_dir(save_directory_name)
	var save_game_file = Globals.main.get_save_game_v3(save_directory_name,save_name)
	update_saves_in_menu()



func close_the_menu():
	hide()

# delete the save in the given argument
func delete_save(save_game_directory):
	var path = ProjectSettings.globalize_path(Globals.SAVE_GAME_DIRECTORIES + save_game_directory) 
	OS.move_to_trash(path)
	update_saves_in_menu()

# load the save in the given argument
func load_save(save_game_directory):
	var path = Globals.SAVE_GAME_DIRECTORIES + save_game_directory +"/"	
	var error = Globals.main.load_game_v3(path)

# overwrite save in given path
func overwrite_save(save_game_directory, save_widget):
	var position = save_widget.get_position_in_parent()
	
	var meta_data = Globals.main.get_save_meta_data(Globals.SAVE_GAME_DIRECTORIES + save_game_directory)
	var save_name = meta_data.name_of_the_save
	
	delete_save(save_game_directory)
	create_new_save(save_name)
	update_saves_in_menu()
	
	# put the save game in the save position
	var save_directories = _get_save_directories()
	for widget in save_game_widget_container.get_children():
		if widget.save_game_directory == save_game_directory:
			widget.get_parent().move_child(widget, position)
			break

func _input(event):
	#close the menu if clicked outside of it
	if (event is InputEventMouseButton) and event.pressed:
		var evLocal = make_input_local(event)
		if !Rect2(Vector2(0,0),self.rect_size).has_point(evLocal.position):
			close_the_menu()
