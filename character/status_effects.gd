

enum STATUS_EFFECTS_ID{STANDARD_DEFENSE,STUNNED,CHANNELING, EMPOWERED, VULNERABLE,CANT_DEFEND,CANT_ATTACK,STUN_ATTACKERS, SLOWED, HEALING_DAMAGES, 
	DAMAGE_IMMUNE, WEAK_DEFENSE}
enum STATUS_EFFECTS_TYPE{BUFF, DEBUFF, OTHER}
const STATUS_EFFECTS_DATA = [
	{id=STATUS_EFFECTS_ID.WEAK_DEFENSE, gui_name="25% defense", type=STATUS_EFFECTS_TYPE.BUFF, icon_texture_resource_path = "res://assets/status_effects_icons/defense.png"}, 
	{id=STATUS_EFFECTS_ID.STANDARD_DEFENSE, gui_name="50% defense", type=STATUS_EFFECTS_TYPE.BUFF, icon_texture_resource_path = "res://assets/status_effects_icons/defense.png"}, 
	{id=STATUS_EFFECTS_ID.STUNNED, gui_name = "stunned", type=STATUS_EFFECTS_TYPE.DEBUFF, icon_texture_resource_path = "res://assets/status_effects_icons/stunned.png"},
	{id=STATUS_EFFECTS_ID.CHANNELING, gui_name="channeling", type=STATUS_EFFECTS_TYPE.OTHER, icon_texture_resource_path = "res://assets/status_effects_icons/stunned.png"}, 
	{id=STATUS_EFFECTS_ID.EMPOWERED, gui_name="empowered", type=STATUS_EFFECTS_TYPE.BUFF, icon_texture_resource_path = "res://assets/status_effects_icons/stunned.png"},
	{id=STATUS_EFFECTS_ID.VULNERABLE, gui_name="vulnerable", type=STATUS_EFFECTS_TYPE.DEBUFF, icon_texture_resource_path = "res://assets/status_effects_icons/stunned.png"}, 
	{id=STATUS_EFFECTS_ID.CANT_DEFEND, gui_name="can't defend", type=STATUS_EFFECTS_TYPE.DEBUFF, icon_texture_resource_path = "res://assets/status_effects_icons/stunned.png"},
	{id=STATUS_EFFECTS_ID.CANT_ATTACK, gui_name="can't attack", type=STATUS_EFFECTS_TYPE.DEBUFF, icon_texture_resource_path = "res://assets/status_effects_icons/stunned.png"}, 
	{id=STATUS_EFFECTS_ID.STUN_ATTACKERS, gui_name="stun attackers", type=STATUS_EFFECTS_TYPE.BUFF, icon_texture_resource_path = "res://assets/status_effects_icons/stunned.png"}, 
	{id=STATUS_EFFECTS_ID.SLOWED, gui_name="slowed", type=STATUS_EFFECTS_TYPE.DEBUFF, icon_texture_resource_path = "res://assets/status_effects_icons/stunned.png"}, 
	{id=STATUS_EFFECTS_ID.HEALING_DAMAGES, gui_name="healing damages", type=STATUS_EFFECTS_TYPE.DEBUFF, icon_texture_resource_path = "res://assets/status_effects_icons/stunned.png"},
	{id=STATUS_EFFECTS_ID.DAMAGE_IMMUNE, gui_name="Immune to damage", type=STATUS_EFFECTS_TYPE.BUFF, icon_texture_resource_path = "res://assets/status_effects_icons/stunned.png"},
]

class StatusEffect:
	var id:int
	var duration:int
	var type:int #buff, debuff, other
	var gui_name:String
	var icon_texture_resource_path:String

	func _init(status_id:int,duration:int, data):
		self.id = status_id
		self.duration = duration	
		self.type = data.type
		self.gui_name = data.gui_name
		self.icon_texture_resource_path = data.icon_texture_resource_path

var status_effects_dict = {}

var character

func _init(character):
	self.character = character

func get_status_effects_data(id:int):
	for l in STATUS_EFFECTS_DATA:
		if l.id==id:
			return l

func add_status_effect(status_id:int, status_duration:int):
	var data = get_status_effects_data(status_id)
	
	if status_effects_dict.has(status_id): 
		status_effects_dict[status_id].duration += status_duration
		# these lines prevent stacking status effects
#		if status_effects_dict[status_id].duration < status_duration:
#			status_effects_dict[status_id].duration = status_duration
	else:		
		status_effects_dict[status_id] = StatusEffect.new(status_id, status_duration, data)
	character.emit_signal("status_ailments_changed")

# redyce the duration of the status effect by the specified duration
func reduce_status_effect(status_id:int, duration:int):
	if status_effects_dict.has(status_id):
		status_effects_dict[status_id].duration -= duration
		if status_effects_dict[status_id].duration <=0:
			status_effects_dict.erase(status_id)
	character.emit_signal("status_ailments_changed")	

func increase_status_effect(status_id:int, duration:int):
	if status_effects_dict.has(status_id):
		status_effects_dict[status_id].duration += duration
	character.emit_signal("status_ailments_changed")		

func remove_status_effect(status_id:int):
	if status_effects_dict.has(status_id):
		status_effects_dict.erase(status_id)
	character.emit_signal("status_ailments_changed")			

# reduce the duration of all status effects
# type - optional argument, reduce duration only of this type. leave NAN to effect all of them
func reduce_all_status_effects_by_duration(duration:int, status_effect_type:int=NAN):
	for status in status_effects_dict.values():		
		if is_nan(status_effect_type) or status.type==status_effect_type:
			reduce_status_effect(status.id,duration)

# return the remaining duration of the status. return 0 if it's inactive or was never placed
func get_status_duration(status_id):	
	if status_effects_dict.has(status_id):
		return status_effects_dict[status_id].duration
	return 0

# return true if the status is active
func is_status_active(status_id):
	for status in status_effects_dict.values():		
		if status.id==status_id and status.duration>0: return true
	return false
	
func remove_all_status_effects():
	status_effects_dict = {}

# remove all negative status effects from the character
# remove_negative_status_effects - if false, removes buffs instead
func remove_all_negative_status_effects(remove_negative_status_effects:=true):
	for stat_id in STATUS_EFFECTS_ID.keys():
		if status_effects_dict.has(stat_id):
			if (remove_negative_status_effects and status_effects_dict[stat_id].type == STATUS_EFFECTS_TYPE.DEBUFF) \
				or (!remove_negative_status_effects and status_effects_dict[stat_id].type == STATUS_EFFECTS_TYPE.BUFF):
				status_effects_dict.erase(stat_id)


func remove_all_positive_status_effects():
	remove_all_negative_status_effects(false)

