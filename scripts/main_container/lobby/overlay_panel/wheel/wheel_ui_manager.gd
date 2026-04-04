class_name WheelUIManager extends Panel

func _open_gold_wheel():
	$Control/WheelContainer/GoldWheel.show()
	$Control/WheelContainer/DiamondWheel.hide()

func _open_diamond_wheel():
	$Control/WheelContainer/DiamondWheel.show()
	$Control/WheelContainer/GoldWheel.hide()
