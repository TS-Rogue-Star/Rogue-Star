/// EXAMPLE.
/*
/datum/robot_sprite/dogborg/DEPARTMENT/catborg
	name = "Catborg - DEPARTMENTL"
	sprite_icon_state = "engi"
	sprite_hud_icon_state = "engi"
	has_eye_sprites = TRUE
	has_eye_light_sprites = TRUE
	has_sleeper_light_indicator = FALSE
	has_vore_belly_resting_sprites = TRUE
	sprite_icon = 'code/game/Rogue Star/catborgs/departmental/Catborg_engi.dmi'
	rest_sprite_options = list("Default", "Bellyup", "Sit")
	belly_capacity_list = list("belly" = 2, "throat" =2)
	module_type = list("Standard", "Engineering", "Surgeon", "Crisis", "Miner", "Janitor", "Service", "Clerical", "Security", "Research") //Select whichever ones they apply to.
	// list("Standard", "Engineering", "Surgeon", "Crisis", "Miner", "Janitor", "Service", "Clerical", "Security", "Research")

*/

/// Kitty Borgs

/// CARGO

/datum/robot_sprite/dogborg/mining/kittyborg
	name = "Kittyborg"
	sprite_icon_state = "cargo"
	sprite_hud_icon_state = "cargo"
	has_eye_sprites = TRUE
	has_eye_light_sprites = TRUE
	has_sleeper_light_indicator = FALSE
	has_vore_belly_resting_sprites = TRUE
	sprite_icon = 'code/game/Rogue Star/catborgs/departmental/kittyborg/kittyborg_cargo.dmi'
	rest_sprite_options = list("Default", "Bellyup", "Sit")
	belly_capacity_list = list("belly" = 2, "throat" =2)
	sprite_flags = ROBOT_HAS_SHIELD_SPRITE | ROBOT_HAS_GUN_SPRITE

/// Engineering
/datum/robot_sprite/dogborg/engineering/kittyborg
	name = "Kittyborg"
	sprite_icon_state = "engi"
	sprite_hud_icon_state = "engi"
	has_eye_sprites = TRUE
	has_eye_light_sprites = TRUE
	has_sleeper_light_indicator = FALSE
	has_vore_belly_resting_sprites = TRUE
	sprite_icon = 'code/game/Rogue Star/catborgs/departmental/kittyborg/kittyborg_engi.dmi'
	rest_sprite_options = list("Default", "Bellyup", "Sit")
	belly_capacity_list = list("belly" = 2)
	sprite_flags = ROBOT_HAS_SHIELD_SPRITE | ROBOT_HAS_GUN_SPRITE


/// Janitor
/datum/robot_sprite/dogborg/janitor/kittyborg
	name = "Kittyborg"
	sprite_icon_state = "jani"
	sprite_hud_icon_state = "jani"
	has_eye_sprites = TRUE
	has_eye_light_sprites = TRUE
	has_sleeper_light_indicator = FALSE
	has_vore_belly_resting_sprites = TRUE
	sprite_icon = 'code/game/Rogue Star/catborgs/departmental/kittyborg/kittyborg_jani.dmi'
	rest_sprite_options = list("Default", "Bellyup", "Sit")
	belly_capacity_list = list("belly" = 2)
	sprite_flags = ROBOT_HAS_SHIELD_SPRITE | ROBOT_HAS_GUN_SPRITE

/// Medical
/datum/robot_sprite/dogborg/crisis/kittyborg
	name = "Kittyborg"
	sprite_icon_state = "medicat"
	sprite_hud_icon_state = "medicat"
	has_eye_sprites = TRUE
	has_eye_light_sprites = TRUE
	has_sleeper_light_indicator = FALSE
	has_vore_belly_resting_sprites = TRUE
	sprite_icon = 'code/game/Rogue Star/catborgs/departmental/kittyborg/kittyborg_medicat.dmi'
	rest_sprite_options = list("Default", "Bellyup", "Sit")
	belly_capacity_list = list("belly" = 2)
	sprite_flags = ROBOT_HAS_SHIELD_SPRITE | ROBOT_HAS_GUN_SPRITE
	module_type = list("Surgeon", "Crisis")

/// Science
/datum/robot_sprite/dogborg/science/kittyborg
	name = "Kittyborg"
	sprite_icon_state = "sci"
	sprite_hud_icon_state = "sci"
	has_eye_sprites = TRUE
	has_eye_light_sprites = TRUE
	has_sleeper_light_indicator = FALSE
	has_vore_belly_resting_sprites = TRUE
	sprite_icon = 'code/game/Rogue Star/catborgs/departmental/kittyborg/kittyborg_sci.dmi'
	rest_sprite_options = list("Default", "Bellyup", "Sit")
	belly_capacity_list = list("belly" = 2)
	sprite_flags = ROBOT_HAS_SHIELD_SPRITE | ROBOT_HAS_GUN_SPRITE

/// Security
/datum/robot_sprite/dogborg/security/kittyborg
	name = "Kittyborg"
	sprite_icon_state = "sec"
	sprite_hud_icon_state = "sec"
	has_eye_sprites = TRUE
	has_eye_light_sprites = TRUE
	has_sleeper_light_indicator = FALSE
	has_vore_belly_resting_sprites = TRUE
	sprite_icon = 'code/game/Rogue Star/catborgs/departmental/kittyborg/kittyborg_sec.dmi'
	rest_sprite_options = list("Default", "Bellyup", "Sit")
	belly_capacity_list = list("belly" = 2)
	sprite_flags = ROBOT_HAS_SHIELD_SPRITE | ROBOT_HAS_GUN_SPRITE

/// Service
/datum/robot_sprite/dogborg/service/kittyborg
	name = "Kittyborg"
	sprite_icon_state = "service"
	sprite_hud_icon_state = "service"
	has_eye_sprites = TRUE
	has_eye_light_sprites = TRUE
	has_sleeper_light_indicator = FALSE
	has_vore_belly_resting_sprites = TRUE
	sprite_icon = 'code/game/Rogue Star/catborgs/departmental/kittyborg/kittyborg_service.dmi'
	rest_sprite_options = list("Default", "Bellyup", "Sit")
	belly_capacity_list = list("belly" = 2)
	sprite_flags = ROBOT_HAS_SHIELD_SPRITE | ROBOT_HAS_GUN_SPRITE
	module_type = list("Service", "Clerical")










/// CAT BORGS
/// ALL THE CAT BORG SPRITES BELOW HERE

/// Cargo
/datum/robot_sprite/dogborg/mining/catborg
	name = "Catborg"
	sprite_icon_state = "catgo"
	sprite_hud_icon_state = "catgo"
	has_eye_sprites = TRUE
	has_eye_light_sprites = TRUE
	has_sleeper_light_indicator = FALSE
	has_vore_belly_resting_sprites = TRUE
	sprite_icon = 'code/game/Rogue Star/catborgs/departmental/catborgs/catborg_cargo.dmi'
	rest_sprite_options = list("Default", "Bellyup", "Sit")
	belly_capacity_list = list("belly" = 2, "throat" =2)
	sprite_flags = ROBOT_HAS_SHIELD_SPRITE | ROBOT_HAS_DISABLER_SPRITE | ROBOT_HAS_TASER_SPRITE | ROBOT_HAS_LASER_SPRITE

/// Engineering
/datum/robot_sprite/dogborg/engineering/catborg
	name = "Catborg"
	sprite_icon_state = "engi"
	sprite_hud_icon_state = "engi"
	has_eye_sprites = TRUE
	has_eye_light_sprites = TRUE
	has_sleeper_light_indicator = FALSE
	has_vore_belly_resting_sprites = TRUE
	sprite_icon = 'code/game/Rogue Star/catborgs/departmental/catborgs/catborg_engineering.dmi'
	rest_sprite_options = list("Default", "Bellyup", "Sit")
	belly_capacity_list = list("belly" = 2, "throat" =2)
	sprite_flags = ROBOT_HAS_SHIELD_SPRITE | ROBOT_HAS_DISABLER_SPRITE | ROBOT_HAS_TASER_SPRITE | ROBOT_HAS_LASER_SPRITE

/// Crisis
/datum/robot_sprite/dogborg/crisis/catborg
	name = "Catborg"
	sprite_icon_state = "meowdical"
	sprite_hud_icon_state = "meowdical"
	has_eye_sprites = TRUE
	has_eye_light_sprites = TRUE
	has_sleeper_light_indicator = FALSE
	has_vore_belly_resting_sprites = TRUE
	sprite_icon = 'code/game/Rogue Star/catborgs/departmental/catborgs/catborg_medical.dmi'
	rest_sprite_options = list("Default", "Bellyup", "Sit")
	belly_capacity_list = list("belly" = 2, "throat" =2)
	sprite_flags = ROBOT_HAS_SHIELD_SPRITE | ROBOT_HAS_DISABLER_SPRITE | ROBOT_HAS_TASER_SPRITE | ROBOT_HAS_LASER_SPRITE
	module_type = list("Surgeon", "Crisis")

/// Science
/datum/robot_sprite/dogborg/science/catborg
	name = "Catborg"
	sprite_icon_state = "sci"
	sprite_hud_icon_state = "sci"
	has_eye_sprites = TRUE
	has_eye_light_sprites = TRUE
	has_sleeper_light_indicator = FALSE
	has_vore_belly_resting_sprites = TRUE
	sprite_icon = 'code/game/Rogue Star/catborgs/departmental/catborgs/catborg_science.dmi'
	rest_sprite_options = list("Default", "Bellyup", "Sit")
	belly_capacity_list = list("belly" = 2, "throat" =2)
	sprite_flags = ROBOT_HAS_SHIELD_SPRITE | ROBOT_HAS_DISABLER_SPRITE | ROBOT_HAS_TASER_SPRITE | ROBOT_HAS_LASER_SPRITE

/// Security
/datum/robot_sprite/dogborg/security/catborg
	name = "Catborg"
	sprite_icon_state = "sec"
	sprite_hud_icon_state = "sec"
	has_eye_sprites = TRUE
	has_eye_light_sprites = TRUE
	has_sleeper_light_indicator = FALSE
	has_vore_belly_resting_sprites = TRUE
	sprite_icon = 'code/game/Rogue Star/catborgs/departmental/catborgs/catborg_security.dmi'
	rest_sprite_options = list("Default", "Bellyup", "Sit")
	belly_capacity_list = list("belly" = 2, "throat" =2)
	sprite_flags = ROBOT_HAS_SHIELD_SPRITE | ROBOT_HAS_DISABLER_SPRITE | ROBOT_HAS_TASER_SPRITE | ROBOT_HAS_LASER_SPRITE

/// Service
/datum/robot_sprite/dogborg/service/catborg
	name = "Catborg"
	sprite_icon_state = "service"
	sprite_hud_icon_state = "service"
	has_eye_sprites = TRUE
	has_eye_light_sprites = TRUE
	has_sleeper_light_indicator = FALSE
	has_vore_belly_resting_sprites = TRUE
	has_robotdecal_sprites = TRUE
	sprite_icon = 'code/game/Rogue Star/catborgs/departmental/catborgs/catborg_service.dmi'
	rest_sprite_options = list("Default", "Bellyup", "Sit")
	belly_capacity_list = list("belly" = 2, "throat" =2)
	sprite_flags = ROBOT_HAS_SHIELD_SPRITE | ROBOT_HAS_DISABLER_SPRITE | ROBOT_HAS_TASER_SPRITE | ROBOT_HAS_LASER_SPRITE
	module_type = list("Service", "Clerical", "Janitor") //They get Janitor because no specific janitor sprite.

/// CUSTOM

/// Custom Catborg set up like a gryphon.
/// Technically - this is my character.
/// However, there's no birdborgs for people to be so why not open this up to everyone.
/// And besides, if I see some
/datum/robot_sprite/dogborg/catborg/diana
	name = "Gryphonborg"
	sprite_icon_state = "borb"
	sprite_hud_icon_state = "borb"
	sprite_icon = 'code/game/Rogue Star/catborgs/Custom/catborg_cameron.dmi'
	belly_capacity_list = list("belly" = 3, "throat" =2)
	rest_sprite_options = list("Default", "Bellyup", "Sit")
	has_eye_sprites = TRUE
	has_eye_light_sprites = TRUE
	has_sleeper_light_indicator = FALSE
	has_vore_belly_resting_sprites = TRUE
	has_robotdecal_sprites = TRUE
	is_whitelisted = FALSE //Putting this here as a declaration that it is NOT whitelisted.
	// whitelist_ckey = "cameron653" //The owner of the character.
	// There is only one version of this borg, so it gets all the departments.
	// Feel free to recolor it if you want to make it have specific sprites for specific departments.
	module_type = list("Standard", "Engineering", "Surgeon", "Crisis", "Miner", "Janitor", "Service", "Clerical", "Security", "Research")
	sprite_flags = ROBOT_HAS_SHIELD_SPRITE | ROBOT_HAS_DISABLER_SPRITE | ROBOT_HAS_TASER_SPRITE | ROBOT_HAS_LASER_SPRITE


/// Custom Catborg Matica
/datum/robot_sprite/dogborg/catborg/matica
	name = "Catborg - Matica"
	sprite_icon_state = "chonker"
	sprite_hud_icon_state = "chonker"
	sprite_icon = 'code/game/Rogue Star/catborgs/Custom/catborg_matica_custom.dmi'
	belly_capacity_list = list("belly" = 1, "throat" =2)
	rest_sprite_options = list("Default", "Bellyup", "Sit")
	has_eye_sprites = TRUE
	has_eye_light_sprites = TRUE
	has_sleeper_light_indicator = FALSE
	has_vore_belly_resting_sprites = TRUE
	is_whitelisted = TRUE
	whitelist_ckey = "somememeguy"
	module_type = list("Standard", "Engineering", "Surgeon", "Crisis", "Miner", "Janitor", "Service", "Clerical", "Security", "Research")
	sprite_flags = ROBOT_HAS_SHIELD_SPRITE | ROBOT_HAS_DISABLER_SPRITE | ROBOT_HAS_TASER_SPRITE | ROBOT_HAS_LASER_SPRITE

/* //This is just kept here as a reference.
var/global/list/departmental_robot_modules:
	module_type = list("Standard", "Engineering", "Surgeon", "Crisis", "Miner", "Janitor", "Service", "Clerical", "Security", "Research")
*/
