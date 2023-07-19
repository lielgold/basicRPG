extends Control

onready var end_game_info = $"end game info"
								


func activate(who_won:int):
	self.visible = true	

	if who_won==Globals.WHO_WON.PLAYER:
		end_game_info.text = "You won!"
				   
	elif who_won==Globals.WHO_WON.TIE:
		end_game_info.text = "You should try again, the enemies will not heal until you rest."
	elif who_won==Globals.WHO_WON.NOT_OVER_YET:
		end_game_info.text = "You should try again, the enemies will not heal until you rest."
	else:
		end_game_info.text = "You lost \nYou should try again, the enemies will not heal until you rest."
		
