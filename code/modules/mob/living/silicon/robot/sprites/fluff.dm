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
	whitelist_charname = "RUSS"

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
	whitelist_charname = "RUSS"

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
	whitelist_charname = "RUSS"

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
	whitelist_charname = "RUSS"

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
	whitelist_charname = "RUSS"

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
	whitelist_charname = "RUSS"

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
	whitelist_charname = "RUSS"

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
	whitelist_charname = "B.A.U-Kingside"

/datum/robot_sprite/dogborg/security/fluff/jademanique/handle_extra_icon_updates(var/mob/living/silicon/robot/ourborg)
	if(istype(ourborg.module_active, /obj/item/weapon/gun/energy/laser/mounted))
		ourborg.add_overlay("[sprite_icon_state]-laser")
	if(istype(ourborg.module_active, /obj/item/weapon/gun/energy/taser/mounted/cyborg))
		ourborg.add_overlay("[sprite_icon_state]-taser")

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
	whitelist_charname = "Clea-Nor"
