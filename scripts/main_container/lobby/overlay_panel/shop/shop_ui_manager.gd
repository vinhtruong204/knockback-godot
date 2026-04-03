class_name ShopUIManager extends Panel

var _tab_map = {
	"RecommendedBtn": "Recommend",
	"DailyDiscountBtn": "Daily Discount",
	"WeaponBtn": "Weapon",
	"ItemBtn": "Item",
	"CharacterBtn": "Character"
}

func _ready() -> void:
	$HBoxContainer/RecommendedBtn.pressed.connect(func():
		show_tab(_tab_map[$HBoxContainer/RecommendedBtn.name])
		)
	
	$HBoxContainer/DailyDiscountBtn.pressed.connect(func():
		show_tab(_tab_map[$HBoxContainer/DailyDiscountBtn.name])
		)
	
	$HBoxContainer/WeaponBtn.pressed.connect(func():
		show_tab(_tab_map[$HBoxContainer/WeaponBtn.name])
		)
		
	$HBoxContainer/ItemBtn.pressed.connect(func():
		show_tab(_tab_map[$HBoxContainer/ItemBtn.name])
		)
	
	$HBoxContainer/CharacterBtn.pressed.connect(func():
		show_tab(_tab_map[$HBoxContainer/CharacterBtn.name])
		)
	

func show_tab(tab_name: String):
	for child in $ItemsContainer.get_children():
		child.visible = false
	
	$ItemsContainer.get_node(tab_name).visible = true
