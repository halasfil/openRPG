extends CharacterBody2D

const SPEED = 100
const DODGE_BOOST_TIME = .1
const DODGE_COOLDOWN = .5
const DODGE_SPEED_BOOST = 6
const ATTACK_TIME = .45
const ATTACK_COOLDOWN = .5

const UP = "back"
const DOWN = "front"
const RIGHT = "right"
const LEFT = "left"

@onready
var ANIMATION = $AnimationPlayer
@onready
var SKIN = $Body
@onready
var WEAPON = $Weapon
@onready
var SHIELD = $Shield
@onready
var POINTER_MARKER = $PointerMarker
@onready
var BOW_MARKER = $BowMarker
@onready
var BOW = $BowMarker/Bow
@onready
var DODGE_DUST = preload("res://scenes/DodgeDust.tscn")

var direction_facing = DOWN
var duringAction = false
var vector = Vector2.ZERO
var speedBoost = 1 
var canDodge = true
var weaponEquipped = true
var shieldEquipped = true
var rangedEquipped = true

func _ready():
	BOW.visible = false
	checkIfShouldShowWeaponAndShield()

func _physics_process(_delta):
	aim()
	if !duringAction:
		player_input()

func aim():
	POINTER_MARKER.look_at(get_global_mouse_position())

func player_input():
	if (Input.is_action_just_pressed("attack_ranged") && rangedEquipped == true):
		attack(true)
	elif (Input.is_action_pressed("attack_melee") && weaponEquipped == true):
		attack(false)
	elif Input.is_action_just_pressed("dodge"):
		dodge()
	elif Input.is_action_pressed("ui_left"):
		walk(true, LEFT)
	elif Input.is_action_pressed("ui_right"):
		walk(true, RIGHT)
	elif Input.is_action_pressed("ui_up"):
		walk(true, UP)
	elif Input.is_action_pressed("ui_down"):
		walk(true, DOWN)
	elif Input.is_action_just_pressed("1"):
		change_skin(1)
	elif Input.is_action_just_pressed("2"):
		change_skin(2)
	elif Input.is_action_just_pressed("3"):
		change_weapon(1)
	elif Input.is_action_just_pressed("4"):
		change_weapon(2)
	else:
		play_walking_or_idle_animation(false)
		velocity.x = 0
		velocity.y = 0

func calculateWalkingVector():
	vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	vector = vector.normalized()

func walk(playWalkingAnimation, directionFacing):
	calculateWalkingVector()
	direction_facing = directionFacing
	velocity = vector * SPEED * speedBoost
	if playWalkingAnimation != null:
		play_walking_or_idle_animation(playWalkingAnimation)

func dodge():
	if canDodge && isMovingPlayer():
		canDodge = false
		speedBoost = DODGE_SPEED_BOOST
		play_dodge_animaiton()
		spawn_dodge_dust()
		await get_tree().create_timer(DODGE_BOOST_TIME).timeout
		speedBoost = 1
		await get_tree().create_timer(DODGE_COOLDOWN).timeout
		canDodge = true

func isMovingPlayer():
	return (velocity.x != 0 || velocity.y != 0)

func spawn_dodge_dust():
	var dust = DODGE_DUST.instantiate()
	dust.emitting = true
	dust.global_position = Vector2(global_position.x, global_position.y + 16)
	get_parent().add_child(dust)

func attack(ranged):
	duringAction = true
	direction_facing = getDirectionAim()
	if ranged:
		play_ranged_animation()
		await get_tree().create_timer(ATTACK_TIME).timeout
	elif (weaponEquipped == true):
		play_melee_animation()
		await get_tree().create_timer(ATTACK_TIME).timeout
	duringAction = false

func hideWeaponAndShield():
	WEAPON.visible = false
	SHIELD.visible = false

func checkIfShouldShowWeaponAndShield():
	if weaponEquipped == true:
		WEAPON.visible = true
	else:
		WEAPON.visible = false
	if shieldEquipped == true:
		SHIELD.visible = true
	else:
		SHIELD.visible = false

func play_melee_animation():
	var attackType = RandomNumberGenerator.new().randi_range(0, 1)
	if direction_facing == RIGHT:
		SKIN.flip_h = false
		WEAPON.flip_h = false
		SHIELD.flip_h = false
		if attackType == 1:
			ANIMATION.play("attack_side")
		else:
			ANIMATION.play("attack_side_2")
	elif direction_facing == LEFT:
		SKIN.flip_h = true
		WEAPON.flip_h = true
		SHIELD.flip_h = true
		if attackType == 1:
			ANIMATION.play("attack_side")
		else:
			ANIMATION.play("attack_side_2")
	elif direction_facing == UP:
		if attackType == 1:
			ANIMATION.play("attack_back")
		else:
			ANIMATION.play("attack_back_2")
	elif direction_facing == DOWN:
		if attackType == 1:
			ANIMATION.play("attack_front")
		else:
			ANIMATION.play("attack_front_2")

func play_ranged_animation():
	BOW.z_index = 10
	hideWeaponAndShield()
	BOW_MARKER.rotation = get_angle_to(get_global_mouse_position())
	BOW.visible=true
	if direction_facing == RIGHT:
		SKIN.flip_h = false
		ANIMATION.play("bow_side")
	elif direction_facing == LEFT:
		SKIN.flip_h = true
		ANIMATION.play("bow_side")
	elif direction_facing == UP:
		BOW.z_index = -1
		ANIMATION.play("bow_back")
	elif direction_facing == DOWN:
		ANIMATION.play("bow_front")
	await get_tree().create_timer(ATTACK_COOLDOWN).timeout
	BOW.visible = false
	checkIfShouldShowWeaponAndShield()

func play_dodge_animaiton():
	if direction_facing == RIGHT:
		SKIN.flip_h = false
		ANIMATION.play("dodge_side")
	elif direction_facing == LEFT:
		SKIN.flip_h = true
		ANIMATION.play("dodge_side")
	elif direction_facing == UP:
		ANIMATION.play("dodge_back")
	elif direction_facing == DOWN:
		ANIMATION.play("dodge_front")

func getDirectionAim():
	var angle = get_angle_to(get_global_mouse_position());
	if (angle > -0.75 && angle < 0.75):
		return RIGHT;
	elif (angle > 0.75 && angle < 2.25):
		return DOWN;
	elif (angle > 2.25 || angle < -2.25):
		return LEFT;
	elif (angle > -2.25 && angle < -0.75):
		return UP;

func change_weapon(id):
	if id == 1:
		if (weaponEquipped == false):
			weaponEquipped = true
			WEAPON.texture = load("res://assets/player/father/weapons/melee/sword_1.png")
		else:
			weaponEquipped = false
	elif id == 2:
		if (shieldEquipped == false):
			shieldEquipped = true
			SHIELD.texture = load("res://assets/player/father/shield/shield_1.png")
		else:
			shieldEquipped = false	
	elif id == 3:
			BOW.texture = load("res://assets/player/father/weapons/ranged/bow_1.png")
	checkIfShouldShowWeaponAndShield()

func change_skin(change):
	if change == 1:
		SKIN.texture = load("res://assets/player/father/skins/father_no_equip.png")
	elif change == 2:
		SKIN.texture = load("res://assets/player/father/skins/father_cloth_1.png")

func play_walking_or_idle_animation(movement):
	if direction_facing == RIGHT:
		SKIN.flip_h = false
		WEAPON.flip_h = false
		SHIELD.flip_h = false
		if movement:
			ANIMATION.play("walk_side")
		else:
			ANIMATION.play("idle_side")
	elif direction_facing == LEFT:
		SKIN.flip_h = true
		WEAPON.flip_h = true
		SHIELD.flip_h = true
		if movement:
			ANIMATION.play("walk_side")
		else:
			ANIMATION.play("idle_side")
	elif direction_facing == DOWN:
		if movement:
			ANIMATION.play("walk_front")
		else:
			ANIMATION.play("idle_front")
	elif direction_facing == UP:
		if movement:
			ANIMATION.play("walk_back")
		else:
			ANIMATION.play("idle_back")
	move_and_slide()
