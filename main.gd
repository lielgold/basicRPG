extends Control

const main_game_resource = preload("res://main_game.tscn")
var main_game

# Called when the node enters the scene tree for the first time.
func _ready():
	Globals.main = self
	
	var main_game = main_game_resource.instance()
	add_child(main_game)
	main_game.owner=self
	
	self.main_game = main_game


# create a save folder in the given path
func get_save_game_v3(save_path:String, save_name:=""):
	if save_name.empty(): save_name = save_path
	_save_meta_data(save_path, save_name)
	_save_globals(save_path + "globals.tscn")
	
	# save main_game
	var packed_scene = PackedScene.new()
	packed_scene.pack(Globals.main_game)
	var error = ResourceSaver.save(save_path + "/main_game_v2.tscn", packed_scene)	
	if error: push_error("saving failed")
	
	_save_overworld(save_path + "overworld_savegame_v2.savegame")

	# save characters
	var i:=0
	var character_save_file_count = Globals.player_party.get_child_count()
	var char_file_paths = []
	for c in Globals.player_party.get_children():
		packed_scene.pack(c)
		ResourceSaver.save(save_path + "character" + String(i)+ "_savegame_v2.tscn", packed_scene)		
		i+=1
	
	# save nodes
	_save_nodes(save_path + "nodes_savegame_v2.savegame")
	
	# save events
	_save_events(save_path + "events_savegame_v2.savegame")



# loads the game in the given directory. return true if there was an error.
func load_game_v3(save_directory_path)->bool:	
	# get character files' paths
	var char_file_paths = []
	var dir = Directory.new()
	if dir.open(save_directory_path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":			
			if file_name.begins_with("character"):
				char_file_paths.append(file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to load the game.")
		return true
		
	
	# free game information
	#Globals.main_game.queue_free()
	# bugfix:
	# queue_free takes too long to remove the data, which means there two overworld objects at the same time
	# this causes get_node to fail when using the old paths, as they refer to the soon to be freed overworld
	# free cleans it immidietly. Hopefully it doesn't introduce new and unexpected bugs	
	# you can go back to queue_free and make it work by fixing _load_events to not use get_node
	Globals.main_game.free() 
	
	# start loading game
	_load_globals(save_directory_path + "globals.tscn")
	
	# Load the PackedScene resource
	var loaded_scene = load(save_directory_path + "main_game_v2.tscn")	
	var my_scene = loaded_scene.instance()
	Globals.main_game = my_scene
	add_child(my_scene)
	my_scene.owner = self	
	
	for c in Globals.main_game.player_party.get_children():
		Globals.main_game.player_party.remove_child(c)
		c.queue_free()		
	
	for p in char_file_paths:
		var loaded_scene2 = load(save_directory_path + p)
		var character = loaded_scene2.instance()
		Globals.main_game.player_party.add_child(character)
	
	# load overworld
	_load_overworld(save_directory_path + "overworld_savegame_v2.savegame")
	
	# load nodes
	_load_nodes(save_directory_path + "nodes_savegame_v2.savegame")
	
	_load_events(save_directory_path + "events_savegame_v2.savegame")
	
	# need to update node gui after loading events as those impact the visuals
	for node in Globals.overworld.get_all_nodes():
		node.update_node_gui()
	
	Globals.main_game._ready()	
	return false

func get_date_as_string()->String:
	var date_as_string :="" 
	var date_dict := Time.get_datetime_dict_from_system()	
	var time_dict := Time.get_time_dict_from_system()
	date_as_string = String(date_dict.day)+"."+String(date_dict.month)+"."+String(date_dict.year) \
		+" - "+ String(time_dict.second) + "." + String(time_dict.minute) +"." + String(time_dict.hour)
	return date_as_string

# save meta data about the save (save name, date, etc')
func _save_meta_data(save_path:String, save_name:String):
	save_path = save_path + "meta_data.savegame"
	
	var save_date:=get_date_as_string()		
	
	var save_game = File.new()
	save_game.open(save_path, File.WRITE)
	var node_data = {"name_of_the_save":save_name, "date_of_the_save":save_date}
		
	# Store the save dictionary as a new line in the save file.
	save_game.store_line(to_json(node_data))
	save_game.close()    

# get the meta data of the given save
# return an array in the form of {"name_of_the_save":save_name, "date_of_the_save":save_date}
func get_save_meta_data(save_path:String):
	save_path = save_path + "/meta_data.savegame"
	var save_game = File.new()
	if not save_game.file_exists(save_path):
		return # Error! We don't have a save to load.

	# load data	
	save_game.open(save_path, File.READ)
	var meta_data = parse_json(save_game.get_line())	
	return meta_data

# this updates the save name in the meta data
# used only to display a save name for the user, in practice the real "save name" is the name of the save folder
func save_name_changed(save_directory_path:String, new_name:String):
	# create the data to save
	var meta_data = get_save_meta_data(save_directory_path)
	meta_data.name_of_the_save = new_name
	var save_game_path = save_directory_path + "/meta_data.savegame"
	
	var save_game = File.new()
	save_game.open(save_game_path, File.WRITE)	
		
	# Store the save dictionary as a new line in the save file.
	save_game.store_line(to_json(meta_data))
	save_game.close()
	
	

func _save_globals(globals_save_path):
	var save_game = File.new()
	save_game.open(globals_save_path, File.WRITE)
	var node_data = Globals.save()
		
	# Store the save dictionary as a new line in the save file.
	save_game.store_line(to_json(node_data))
	save_game.close()    

func _load_globals(globals_save_path):
	var save_game = File.new()
	if not save_game.file_exists(globals_save_path):
		return # Error! We don't have a save to load.

	# load data	
	save_game.open(globals_save_path, File.READ)
	var globals_data = parse_json(save_game.get_line())	
	for i in globals_data.keys():
		Globals.set(i, globals_data[i])

func _save_overworld(path:String):
	var save_game = File.new()
	save_game.open(path, File.WRITE)
	
	var data = Globals.overworld.save()	
	save_game.store_line(to_json(data))
	save_game.close()    


func _load_overworld(path:String):	
	var save_game = File.new()
	if not save_game.file_exists(path):
		return # Error! We don't have a save to load.

	# Load the file line by line and process that dictionary to restore
	# the object it represents.
	save_game.open(path, File.READ)

	while save_game.get_position() < save_game.get_len():
		var overworld_data = parse_json(save_game.get_line())

		if overworld_data==null:
			continue
					
		var overworld_node = Globals.overworld
		overworld_node.current_map = get_node(overworld_data["current_map_path"] )
	
	Globals.overworld.switch_map(Globals.overworld.current_map.get_path())
	save_game.close()	

func _save_nodes(path:String):
	var save_game = File.new()
	save_game.open(path, File.WRITE)
	
	var all_worldmap_nodes = Globals.overworld.get_all_nodes()	
	
	for node in all_worldmap_nodes:
		# Call the node's save function.
		var node_data = node.call("save")
		
		# Store the save dictionary as a new line in the save file.
		save_game.store_line(to_json(node_data))
	save_game.close()    

func _load_nodes(path:String):
	
	var save_game = File.new()
	if not save_game.file_exists(path):
		return # Error! We don't have a save to load.

	# Load the file line by line and process that dictionary to restore
	# the object it represents.
	save_game.open(path, File.READ)

	while save_game.get_position() < save_game.get_len():
		var node_data = parse_json(save_game.get_line())

		if node_data==null:
			continue
						
		var ow_node = Globals.overworld.get_node_by_name(node_data["map_name"], node_data["name"])
				
		if node_data.has("pos_x"):
			ow_node.position = Vector2(node_data["pos_x"], node_data["pos_y"])
		elif node_data.has("rect_position_x"):
			ow_node.rect_position = Vector2(node_data["rect_position_x"], node_data["rect_position_y"])

		
		if node_data.has("active_events_list_index"):
			ow_node.active_events_list = ow_node.event_lists.get_child(node_data["active_events_list_index"])
		
		# Now we set the remaining variables.
		for i in node_data.keys():
			if i == "filename" or i == "parent" or i == "pos_x" or i == "pos_y" or i=="active_events_list_index":
				continue
				
			ow_node.set(i, node_data[i])

	save_game.close()	
	
func _save_events(path:String):
	var save_game = File.new()
	save_game.open(path, File.WRITE)
	
	var all_worldmap_nodes = Globals.overworld.get_all_nodes()	
	for n in all_worldmap_nodes:
		if n.get_class_name()=="MapNode":
			for event in n._get_all_events():
				var event_data:Dictionary = event.save()
				save_game.store_line(to_json(event_data))
	save_game.close()

func _load_events(path:String):
	
	var save_game = File.new()
	if not save_game.file_exists(path):
		return # Error! We don't have a save to load.

	# Load the file line by line and process that dictionary to restore
	# the object it represents.
	save_game.open(path, File.READ)

	while save_game.get_position() < save_game.get_len():
		var event_data = parse_json(save_game.get_line())

		if event_data==null:
			continue
		
		var a = event_data["path"]
		var event_to_load = get_node(event_data["path"])
		
#		if event_to_load.get_class_name()=="MapEventChangeMap":
			

#		if node_data["call_scene_resource_path"].empty()==false:
#			ow_node.call_scene.resource_path = node_data["call_scene_resource_path"]
#
#		for node_name in node_data["reachable_from_me_node_names"]:			
#			ow_node.reachable_from_me.append(Globals.overworld.get_node_by_name(node_name[0], node_name[1]))

		# Now we set the remaining variables.
		for i in event_data.keys():
			if i == "filename" or i == "parent" or i == "pos_x" or i == "pos_y":
				continue

			event_to_load.set(i, event_data[i])


	save_game.close()	
