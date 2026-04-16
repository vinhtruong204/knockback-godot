class_name WeaponHoldHandler extends Node2D

@export var player_input: PlayerInput

@onready var current_weapon_node: Node2D = $Primary
@export var current_weapon_type: SwitchWeaponHandler.WeaponType = SwitchWeaponHandler.WeaponType.PRIMARY:
	set(value):
		# Hide older weapon
		current_weapon_node.hide()

		# Set new weapon type
		current_weapon_type = value

		# Change to new weapon node
		match value:
			SwitchWeaponHandler.WeaponType.PRIMARY:
				current_weapon_node = $Primary
			SwitchWeaponHandler.WeaponType.SECONDARY:
				current_weapon_node = $Secondary
			SwitchWeaponHandler.WeaponType.MELEE:
				current_weapon_node = $Melee

		# Show new weapon
		current_weapon_node.show()

func _ready() -> void:
	if not is_multiplayer_authority(): return
	
	player_input.switch_weapon.connect(_on_switch_weapon)

func _on_switch_weapon(weapon_type: SwitchWeaponHandler.WeaponType) -> void:
	self.current_weapon_type = weapon_type


func set_weapon_textures(weapon_images: Dictionary) -> void:
	for slot_type in weapon_images:
		var image_name: String = weapon_images[slot_type]
		if image_name == "":
			continue
		var tex = load("res://assets/game/weapon/static/%s" % image_name)
		if not tex:
			continue
		match slot_type:
			Enums.SlotType.PRIMARY:
				$Primary.get_child(0).texture = tex
			Enums.SlotType.SECONDARY:
				$Secondary.get_child(0).texture = tex
			Enums.SlotType.MELEE:
				$Melee.get_child(0).texture = tex