// Event/special borg sprites

// Lost

// Regular sprites

/datum/robot_sprite/lost
	module_type = "Lost"
	sprite_icon = 'icons/mob/robot/lost.dmi'

/datum/robot_sprite/lost/drone
	name = "AG Model"
	sprite_icon_state = "drone"
	sprite_flags = ROBOT_HAS_SHIELD_SPRITE //RS EDIT

// Wide/dogborg sprites

/datum/robot_sprite/dogborg/lost
	module_type = "Lost"
	sprite_icon = 'icons/mob/robot/lost_wide.dmi'

/datum/robot_sprite/dogborg/lost/do_equipment_glamour(var/obj/item/weapon/robot_module/module)
	if(!has_custom_equipment_sprites)
		return

	..()

	var/obj/item/weapon/shockpaddles/robot/SP = locate() in module.modules
	if(SP)
		SP.name = "paws of life"
		SP.desc = "Zappy paws. For fixing cardiac arrest."
		SP.icon = 'icons/mob/dogborg_vr.dmi'
		SP.icon_state = "defibpaddles0"
		SP.attack_verb = list("batted", "pawed", "bopped", "whapped")

	var/obj/item/device/dogborg/sleeper/lost/DL = locate() in module.modules
	if(DL)
		DL.icon_state = "sleeperlost"

	var/obj/item/weapon/dogborg/pounce/SA = locate() in module.modules
	if(SA)
		SA.name = "pounce"
		SA.icon_state = "pounce"

/datum/robot_sprite/dogborg/lost/stray
	name = "Stray"
	sprite_icon_state = "stray"


// Tall sprites

/datum/robot_sprite/dogborg/tall/lost
	module_type = "Lost"
	sprite_icon = 'icons/mob/robot/lost_large.dmi'
	sprite_hud_icon_state = "lost"

/datum/robot_sprite/dogborg/tall/lost/do_equipment_glamour(var/obj/item/weapon/robot_module/module)
	if(!has_custom_equipment_sprites)
		return

	..()

	var/obj/item/weapon/shockpaddles/robot/SP = locate() in module.modules
	if(SP)
		SP.name = "paws of life"
		SP.desc = "Zappy paws. For fixing cardiac arrest."
		SP.icon = 'icons/mob/dogborg_vr.dmi'
		SP.icon_state = "defibpaddles0"
		SP.attack_verb = list("batted", "pawed", "bopped", "whapped")

	var/obj/item/device/dogborg/sleeper/lost/DL = locate() in module.modules
	if(DL)
		DL.icon_state = "sleeperlost"

	var/obj/item/weapon/dogborg/pounce/SA = locate() in module.modules
	if(SA)
		SA.name = "pounce"
		SA.icon_state = "pounce"

/datum/robot_sprite/dogborg/tall/lost/raptor
	name = "Raptor V-4"
	sprite_icon_state = "raptor"
	sprite_flags = ROBOT_HAS_SHIELD_SPRITE | ROBOT_HAS_LASER_SPRITE //RS EDIT


// Gravekeeper

// Regular sprites

/datum/robot_sprite/gravekeeper
	module_type = "Gravekeeper"
	sprite_icon = 'icons/mob/robot/gravekeeper.dmi'
	sprite_hud_icon_state = "lost"

/datum/robot_sprite/gravekeeper/drone
	name = "AG Model"
	sprite_icon_state = "drone"
	sprite_flags = ROBOT_HAS_SHIELD_SPRITE //RS EDIT

/datum/robot_sprite/gravekeeper/sleek
	name = "WTOperator"
	sprite_icon_state = "sleek"
	sprite_flags = ROBOT_HAS_SHIELD_SPRITE //RS EDIT


// Tall sprites

/datum/robot_sprite/dogborg/tall/gravekeeper
	module_type = "Gravekeeper"
	sprite_icon = 'icons/mob/robot/gravekeeper_large.dmi'
	sprite_hud_icon_state = "lost"

/datum/robot_sprite/dogborg/tall/gravekeeper/do_equipment_glamour(var/obj/item/weapon/robot_module/module)
	if(!has_custom_equipment_sprites)
		return

	..()

	var/obj/item/device/dogborg/sleeper/compactor/generic/DCS = locate() in module.modules
	if(DCS)
		DCS.icon_state = "sleeperd"

/datum/robot_sprite/dogborg/tall/gravekeeper/raptor
	name = "Raptor V-4"
	sprite_icon_state = "raptor"
	sprite_flags = ROBOT_HAS_LASER_SPRITE | ROBOT_HAS_SHIELD_SPRITE //RS EDIT
