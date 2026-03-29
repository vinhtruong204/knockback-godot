class_name SwitchWeaponHandler extends Control

enum WeaponType { PRIMARY, SECONDARY, MELEE }

#region Signal
signal weapon_switched(weapon: SwitchWeaponHandler.WeaponType)
#endregion

@onready var current_weapon_button: Button = $CurrentWeaponBtn

#region Panel
@onready var select_weapon_panel: Panel = $SelectWeaponPanel
var _is_select_weapon_panel_visible: bool = false

@onready var primary_button: Button = $SelectWeaponPanel/VBoxContainer/PrimaryBtn
@onready var secondary_button: Button = $SelectWeaponPanel/VBoxContainer/SecondaryBtn
@onready var melee_button: Button = $SelectWeaponPanel/VBoxContainer/MeleeBtn
#endregion

func _ready() -> void:
	current_weapon_button.pressed.connect(_on_current_weapon_button_pressed)

	primary_button.pressed.connect(_on_weapon_button_pressed.bind(primary_button))
	secondary_button.pressed.connect(_on_weapon_button_pressed.bind(secondary_button))
	melee_button.pressed.connect(_on_weapon_button_pressed.bind(melee_button))

func _on_current_weapon_button_pressed() -> void:
	if _is_select_weapon_panel_visible:
		select_weapon_panel.hide()
		_is_select_weapon_panel_visible = false
	else:
		select_weapon_panel.show()
		_is_select_weapon_panel_visible = true


func _on_weapon_button_pressed(next_weapon: Button) -> void:
	# Hide panel
	select_weapon_panel.hide()
	_is_select_weapon_panel_visible = false
	
	# Update current weapon button
	if current_weapon_button.icon != next_weapon.icon:
		current_weapon_button.icon = next_weapon.icon
		current_weapon_button.text = next_weapon.text
		
		var weapon_type: WeaponType
		match next_weapon:
			primary_button: weapon_type = WeaponType.PRIMARY
			secondary_button: weapon_type = WeaponType.SECONDARY
			melee_button: weapon_type = WeaponType.MELEE
			
		weapon_switched.emit(weapon_type)