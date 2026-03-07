class_name LobbyUIManager extends Control

#region Overlay
func _open_player_profile():
	$OverlayContainer/PlayerProfile.visible = true

func _open_equipment():
	$OverlayContainer/Equipment.visible = true

func _open_leaderboard():
	$OverlayContainer/Leaderboard.visible = true

func _open_ranking():
	$OverlayContainer/Ranking.visible = true

func _open_normal():
	$OverlayContainer/Normal.visible = true
	
func _open_lan():
	$OverlayContainer/LAN.visible = true

func _open_shop():
	$OverlayContainer/Shop.visible = true

func _open_wheel():
	$OverlayContainer/Wheel.visible = true

func _open_task():
	$OverlayContainer/Task.visible = true
#endregion

#region Top overlay
func _open_purchase():
	$TopOverlay/Purchase.visible = true

func _open_settings():
	$TopOverlay/Settings.visible = true
#endregion
