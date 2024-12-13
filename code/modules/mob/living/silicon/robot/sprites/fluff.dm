#define CUSTOM_BORGSPRITE(x) "Custom - " + (x)

// All whitelisted cyborg sprites go here.

// A

/datum/robot_sprite/dogborg/security/fluff/argonne
	name = CUSTOM_BORGSPRITE("RUSS")

	sprite_icon = 'icons/mob/robot/fluff_wide.dmi'

	has_eye_light_sprites = TRUE
	has_vore_belly_sprites = TRUE
	has_rest_sprites = TRUE
	rest_sprite_options = list("Default", "Sit", "Bellyup")
	has_dead_sprite = TRUE
	has_dead_sprite_overlay = TRUE
	pixel_x = -16

	sprite_icon_state = "argonne-russ-sec"

	is_whitelisted = TRUE
	whitelist_ckey = "argonne"

/datum/robot_sprite/dogborg/crisis/fluff/argonne
	name = CUSTOM_BORGSPRITE("RUSS")

	sprite_icon = 'icons/mob/robot/fluff_wide.dmi'

	has_eye_light_sprites = TRUE
	has_vore_belly_sprites = TRUE
	has_rest_sprites = TRUE
	rest_sprite_options = list("Default", "Sit", "Bellyup")
	has_dead_sprite = TRUE
	has_dead_sprite_overlay = TRUE
	pixel_x = -16

	sprite_icon_state = "argonne-russ-crisis"

	is_whitelisted = TRUE
	whitelist_ckey = "argonne"

/datum/robot_sprite/dogborg/surgical/fluff/argonne
	name = CUSTOM_BORGSPRITE("RUSS")

	sprite_icon = 'icons/mob/robot/fluff_wide.dmi'

	has_eye_light_sprites = TRUE
	has_vore_belly_sprites = TRUE
	has_rest_sprites = TRUE
	rest_sprite_options = list("Default", "Sit", "Bellyup")
	has_dead_sprite = TRUE
	has_dead_sprite_overlay = TRUE
	pixel_x = -16

	sprite_icon_state = "argonne-russ-surg"

	is_whitelisted = TRUE
	whitelist_ckey = "argonne"

/datum/robot_sprite/dogborg/engineering/fluff/argonne
	name = CUSTOM_BORGSPRITE("RUSS")

	sprite_icon = 'icons/mob/robot/fluff_wide.dmi'

	has_eye_light_sprites = TRUE
	has_vore_belly_sprites = TRUE
	has_rest_sprites = TRUE
	rest_sprite_options = list("Default", "Sit", "Bellyup")
	has_dead_sprite = TRUE
	has_dead_sprite_overlay = TRUE
	pixel_x = -16

	sprite_icon_state = "argonne-russ-eng"

	is_whitelisted = TRUE
	whitelist_ckey = "argonne"

/datum/robot_sprite/dogborg/science/fluff/argonne
	name = CUSTOM_BORGSPRITE("RUSS")

	sprite_icon = 'icons/mob/robot/fluff_wide.dmi'

	has_eye_light_sprites = TRUE
	has_vore_belly_sprites = TRUE
	has_rest_sprites = TRUE
	rest_sprite_options = list("Default", "Sit", "Bellyup")
	has_dead_sprite = TRUE
	has_dead_sprite_overlay = TRUE
	pixel_x = -16

	sprite_icon_state = "argonne-russ-sci"

	is_whitelisted = TRUE
	whitelist_ckey = "argonne"

/datum/robot_sprite/dogborg/mining/fluff/argonne
	name = CUSTOM_BORGSPRITE("RUSS")

	sprite_icon = 'icons/mob/robot/fluff_wide.dmi'

	has_eye_light_sprites = TRUE
	has_vore_belly_sprites = TRUE
	has_rest_sprites = TRUE
	rest_sprite_options = list("Default", "Sit", "Bellyup")
	has_dead_sprite = TRUE
	has_dead_sprite_overlay = TRUE
	pixel_x = -16

	sprite_icon_state = "argonne-russ-mine"

	is_whitelisted = TRUE
	whitelist_ckey = "argonne"

/datum/robot_sprite/dogborg/service/fluff/argonne
	name = CUSTOM_BORGSPRITE("RUSS")

	sprite_icon = 'icons/mob/robot/fluff_wide.dmi'

	has_eye_light_sprites = TRUE
	has_vore_belly_sprites = TRUE
	has_rest_sprites = TRUE
	rest_sprite_options = list("Default", "Sit", "Bellyup")
	has_dead_sprite = TRUE
	has_dead_sprite_overlay = TRUE
	pixel_x = -16

	sprite_icon_state = "argonne-russ-serv"

	is_whitelisted = TRUE
	whitelist_ckey = "argonne"

// F

/datum/robot_sprite/security/fluff/foopwotch
	name = CUSTOM_BORGSPRITE("NDF") //For: GAEL

	sprite_icon = 'icons/mob/robot/fluff.dmi'
	sprite_icon_state = "foopwotch-ndfsec"

	has_eye_light_sprites = TRUE
	has_vore_belly_sprites = TRUE
	has_custom_open_sprites = TRUE
	has_dead_sprite = TRUE
	has_dead_sprite_overlay = FALSE
	sprite_flags = ROBOT_HAS_LASER_SPRITE | ROBOT_HAS_TASER_SPRITE

	is_whitelisted = TRUE
	whitelist_ckey = "foopwotch"

/datum/robot_sprite/combat/fluff/foopwotch
	name = CUSTOM_BORGSPRITE("NDF") //For: GAEL

	sprite_icon = 'icons/mob/robot/fluff.dmi'
	sprite_icon_state = "foopwotch-ndfcmb"

	has_eye_light_sprites = TRUE
	has_vore_belly_sprites = TRUE
	has_custom_open_sprites = TRUE
	has_dead_sprite = TRUE
	has_dead_sprite_overlay = FALSE
	sprite_flags = ROBOT_HAS_SHIELD_SPRITE | ROBOT_HAS_SPEED_SPRITE | ROBOT_HAS_LASER_SPRITE //RS EDIT

	is_whitelisted = TRUE
	whitelist_ckey = "foopwotch"

//RS Edit Note: The above still exists as it has two special icon_states: Dagger & Disabler. While I could add extra flags to _sprite_datum.dm, this is such an edge case it gets to keep existing.
/datum/robot_sprite/combat/fluff/foopwotch/handle_extra_icon_updates(var/mob/living/silicon/robot/ourborg)

	..()
	if(ourborg.has_active_type(/obj/item/weapon/combat_borgblade)) //RS Edit
		ourborg.add_overlay("[sprite_icon_state]-dagger")
	if(ourborg.has_active_type(/obj/item/weapon/gun/energy/robotic/disabler)) //RS Edit
		ourborg.add_overlay("[sprite_icon_state]-disabler")

// J

/datum/robot_sprite/dogborg/security/fluff/jademanique
	name = CUSTOM_BORGSPRITE("B.A.U-Kingside")

	sprite_icon = 'icons/mob/robot/fluff_wide.dmi'
	sprite_icon_state = "jademanique-kingside"
	sprite_hud_icon_state = "security"

	has_eye_light_sprites = TRUE
	has_vore_belly_sprites = TRUE
	has_rest_sprites = TRUE
	rest_sprite_options = list("Default", "Sit", "Bellyup")
	has_dead_sprite = TRUE
	has_dead_sprite_overlay = TRUE
	pixel_x = -16

	is_whitelisted = TRUE
	whitelist_ckey = "jademanique"

// L

/datum/robot_sprite/dogborg/engineering/fluff/lunarfleet
	name = CUSTOM_BORGSPRITE("Clea-Nor")

	sprite_icon = 'icons/mob/robot/fluff_wide.dmi'
	sprite_icon_state = "lunarfleet-cleanor"

	has_eye_light_sprites = TRUE
	has_vore_belly_sprites = TRUE
	has_rest_sprites = TRUE
	rest_sprite_options = list("Default", "Sit", "Bellyup")
	has_dead_sprite = TRUE
	has_dead_sprite_overlay = TRUE
	pixel_x = -16

	is_whitelisted = TRUE
	whitelist_ckey = "lunarfleet"
