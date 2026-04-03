class_name WheelUIManager extends Panel

func _open_gold_wheel():
	$Control/WheelContainer/GoldWheel.visible = true
	$Control/WheelContainer/DiamondWheel.visible = false

func _open_diamond_wheel():
	$Control/WheelContainer/DiamondWheel.visible = true
	$Control/WheelContainer/GoldWheel.visible = false
