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

	is_whitelisted = TRUE
	whitelist_ckey = "foopwotch"

/datum/robot_sprite/security/fluff/foopwotch/handle_extra_icon_updates(var/mob/living/silicon/robot/ourborg)
	if(istype(ourborg.module_active, /obj/item/weapon/gun/energy/laser/mounted))
		ourborg.add_overlay("[sprite_icon_state]-laser")
	if(istype(ourborg.module_active, /obj/item/weapon/gun/energy/taser/mounted/cyborg))
		ourborg.add_overlay("[sprite_icon_state]-taser")

/datum/robot_sprite/combat/fluff/foopwotch
	name = CUSTOM_BORGSPRITE("NDF") //For: GAEL

	sprite_icon = 'icons/mob/robot/fluff.dmi'
	sprite_icon_state = "foopwotch-ndfcmb"

	has_eye_light_sprites = TRUE
	has_vore_belly_sprites = TRUE
	has_custom_open_sprites = TRUE
	has_dead_sprite = TRUE
	has_dead_sprite_overlay = FALSE
	has_speed_sprite = TRUE
	has_shield_sprite = TRUE

	is_whitelisted = TRUE
	whitelist_ckey = "foopwotch"

/datum/robot_sprite/combat/fluff/foopwotch/handle_extra_icon_updates(var/mob/living/silicon/robot/ourborg)

	..()
	if(istype(ourborg.module_active, /obj/item/weapon/gun/energy/laser/mounted) || istype(ourborg.module_active, /obj/item/weapon/gun/energy/lasercannon/mounted))
		ourborg.add_overlay("[sprite_icon_state]-laser")
	if(istype(ourborg.module_active, /obj/item/weapon/combat_borgblade))
		ourborg.add_overlay("[sprite_icon_state]-dagger")
	if(istype(ourborg.module_active, /obj/item/weapon/gun/energy/taser/mounted/cyborg/ertgun))
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
