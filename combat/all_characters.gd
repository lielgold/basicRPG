extends Control

onready var allies = $allies
onready var enemies = $enemies

func add_new_character(character:Character):
	if character.team==Globals.TEAMS.PLAYER: 
		$allies.add_child(character)
	else: 
		$enemies.add_child(character)

func remove_character(character:Character)->void:
	character.get_parent().remove_child(character)
	character.set_owner(null)

# return true if there are no allies
func is_allies_empty()->bool:
	if get_allies(Globals.TEAMS.PLAYER).empty(): return true
	return false

func remove_all_enemies()->void:
	for n in $enemies.get_children():
		$enemies.remove_child(n)
		n.queue_free()

# get all characters
func get_all_characters()->Array:	
	var a = $allies.get_children()
	a.append_array($enemies.get_children())			
	return a

func get_all_living_characters()->Array:
	var all = get_all_characters()
	var output = []
	for c in all:
		if c.is_alive():
			output.append(c)
	return output

# get allies of team
func get_allies(team)->Array:
	if(team==Globals.TEAMS.PLAYER): return $allies.get_children()
	else: return $enemies.get_children()	

# get enemies of team	
func get_enemies(team, living_only:=false)->Array:
	var output =[]
	if(team==Globals.TEAMS.PLAYER): output = $enemies.get_children()
	else: output = $allies.get_children()
	
	# remove dead characters
	var output2 = []
	if living_only:
		for c in output:
			if c.is_alive():
				output2.append(c)
		return output2
	else: return output


#get closest living enemy
func get_closest_living_enemy(team):
	var enemies = get_enemies(team)
	if(team==Globals.TEAMS.ENEMY): enemies.invert()
	for e in enemies:
		if e.is_alive():
			return e
			
#get the living enemy in the last row
func get_furthest_living_enemy(team):
	var enemies = get_enemies(team)
	if(team==Globals.TEAMS.PLAYER): enemies.invert()
	for e in enemies:
		if e.is_alive():
			return e			
			
		

# move character one place forward or backwards, based on the forward argument. 
# doesn't do anything if character is already in front.
# this shouldn't be used as a move ability, there's no check here for buffs or debuffs
# it's only to move the character in the GUI after using an ability
func move_character(character:Character, forward=true):
	var direction = 1
	if(!forward): direction=-1
	
	for a in get_all_characters():
		if a==character:
			if(character.team==Globals.TEAMS.PLAYER):
				$allies.move_child(a,a.get_index()+direction)
			else:
				$enemies.move_child(a,a.get_index()-direction)
	
# return true if the character is living and in front (closest to the enemies)
func is_character_in_front(character:Character):
	if(get_closest_living_enemy(Globals.TEAMS.PLAYER) ==character or get_closest_living_enemy(Globals.TEAMS.ENEMY)==character): return true
	return false
	
func is_character_in_back_row(character:Character):
	if(get_furthest_living_enemy(Globals.TEAMS.PLAYER) ==character or get_furthest_living_enemy(Globals.TEAMS.ENEMY)==character): return true
	return false	
	

# Called when the node enters the scene tree for the first time.
func _ready():
	Globals.all_characters = self
