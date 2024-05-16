// Syndie borg sprites

/* none yet
/datum/robot_sprite/syndie
	module_type = list("Protector", "Mechanist", "Combat Medic")
	sprite_icon = 'icons/mob/robot/syndie.dmi'
	sprite_hud_icon_state = "malf"
*/

// Wide/dogborg sprites

/datum/robot_sprite/dogborg/syndie
	module_type = list("Protector", "Mechanist", "Combat Medic")
	sprite_icon = 'icons/mob/robot/syndie_wide.dmi'
	sprite_hud_icon_state = "malf"

/datum/robot_sprite/dogborg/syndie/do_equipment_glamour(var/obj/item/weapon/robot_module/module)
	if(!has_custom_equipment_sprites)
		return

	..()

	var/obj/item/weapon/dogborg/pounce/SA = locate() in module.modules
	if(SA)
		SA.name = "pounce"
		SA.icon_state = "pounce"

	var/obj/item/device/dogborg/sleeper/K9/syndie/SYB = locate() in module.modules
	if(SYB)
		SYB.icon_state = "sleepersyndiebrig"

	var/obj/item/device/dogborg/sleeper/compactor/syndie/SYC = locate() in module.modules
	if(SYC)
		SYC.icon_state = "sleepersyndieeng"

	var/obj/item/device/dogborg/sleeper/syndie/SYS = locate() in module.modules
	if(SYS)
		SYS.icon_state = "sleepersyndiemed"

	var/obj/item/weapon/shockpaddles/robot/combat/SYP = locate() in module.modules
	if(SYP)
		SYP.name = "paws of death"
		SYP.desc = "Zappy paws. For fixing cardiac arrest so your buddies can keep on fighting. Safeties disengaged for faster charging."
		SYP.icon = 'icons/mob/dogborg_vr.dmi'
		SYP.icon_state = "defibpaddles0"
		SYP.attack_verb = list("batted", "pawed", "bopped", "whapped")

	var/obj/item/weapon/shockpaddles/robot/jumper/SYJ = locate() in module.modules
	if(SYJ)
		SYJ.name = "jumper paws"
		SYJ.desc = "Zappy paws. For rebooting a full body prostetic."
		SYJ.icon = 'icons/mob/dogborg_vr.dmi'
		SYJ.icon_state = "defibpaddles0"
		SYJ.attack_verb = list("batted", "pawed", "bopped", "whapped")

/datum/robot_sprite/dogborg/syndie/borgi
	name = "Borgi"
	sprite_icon_state = "borgi"
	has_eye_sprites = FALSE
	has_eye_light_sprites = TRUE
	has_dead_sprite_overlay = FALSE

/datum/robot_sprite/dogborg/syndie/drake
	name = "Drake"
	sprite_icon_state = "drake"

// Tall sprites

/datum/robot_sprite/dogborg/tall/syndie
	module_type = list("Protector", "Mechanist", "Combat Medic")
	sprite_icon = 'icons/mob/robot/syndie_large.dmi'
	sprite_hud_icon_state = "malf"

/datum/robot_sprite/dogborg/tall/syndie/do_equipment_glamour(var/obj/item/weapon/robot_module/module)
	if(!has_custom_equipment_sprites)
		return

	..()

	var/obj/item/weapon/dogborg/pounce/SA = locate() in module.modules
	if(SA)
		SA.name = "pounce"
		SA.icon_state = "pounce"

	var/obj/item/device/dogborg/sleeper/K9/syndie/SYB = locate() in module.modules
	if(SYB)
		SYB.icon_state = "sleepersyndiebrig"

	var/obj/item/device/dogborg/sleeper/compactor/syndie/SYC = locate() in module.modules
	if(SYC)
		SYC.icon_state = "sleepersyndieeng"

	var/obj/item/device/dogborg/sleeper/syndie/SYS = locate() in module.modules
	if(SYS)
		SYS.icon_state = "sleepersyndiemed"

	var/obj/item/weapon/shockpaddles/robot/combat/SYP = locate() in module.modules
	if(SYP)
		SYP.name = "paws of death"
		SYP.desc = "Zappy paws. For fixing cardiac arrest so your buddies can keep on fighting. Safties disengaged for faster charging."
		SYP.icon = 'icons/mob/dogborg_vr.dmi'
		SYP.icon_state = "defibpaddles0"
		SYP.attack_verb = list("batted", "pawed", "bopped", "whapped")

	var/obj/item/weapon/shockpaddles/robot/jumper/SYJ = locate() in module.modules
	if(SYJ)
		SYJ.name = "jumper paws"
		SYJ.desc = "Zappy paws. For rebooting a full body prostetic."
		SYJ.icon = 'icons/mob/dogborg_vr.dmi'
		SYJ.icon_state = "defibpaddles0"
		SYJ.attack_verb = list("batted", "pawed", "bopped", "whapped")

/datum/robot_sprite/dogborg/tall/syndie/raptor
	name = "Raptor V-4"
	sprite_icon_state = "raptor"
	rest_sprite_options = list("Default", "Bellyup")

/datum/robot_sprite/dogborg/tall/syndie/meka
	name = "MEKA"
	sprite_icon_state = "meka"
	has_eye_light_sprites = TRUE
	has_custom_open_sprites = TRUE
	has_vore_belly_sprites = FALSE
	rest_sprite_options = list("Default", "Sit")

/datum/robot_sprite/dogborg/tall/syndie/newmeka
	name = "MEKA v2"
	sprite_icon_state = "newmeka"
	has_eye_light_sprites = TRUE
	has_custom_open_sprites = TRUE
	rest_sprite_options = list("Default", "Sit")

/datum/robot_sprite/dogborg/tall/syndie/mmeka
	name = "NIKO"
	sprite_icon_state = "mmeka"
	has_eye_light_sprites = TRUE
	has_custom_open_sprites = TRUE
	rest_sprite_options = list("Default", "Sit")

/datum/robot_sprite/dogborg/tall/syndie/fmeka
	name = "NIKA"
	sprite_icon_state = "fmeka"
	has_eye_light_sprites = TRUE
	has_custom_open_sprites = TRUE
	rest_sprite_options = list("Default", "Sit")

/datum/robot_sprite/dogborg/tall/syndie/k4t
	name = "K4T"
	sprite_icon_state = "k4t"
	has_eye_light_sprites = TRUE
	has_custom_open_sprites = TRUE
	has_vore_belly_sprites = FALSE
	rest_sprite_options = list("Default", "Bellyup")


// Protector

// Regular sprites

/datum/robot_sprite/protector
	module_type = "Protector"
	sprite_icon = 'icons/mob/robot/protector.dmi'
	sprite_hud_icon_state = "malf"

/datum/robot_sprite/protector/bloodhound
	name = "Cerberus"
	sprite_icon_state = "bloodhound"

/datum/robot_sprite/protector/treadhound
	name = "Cerberus-Treaded"
	sprite_icon_state = "treadhound"

/datum/robot_sprite/protector/squats
	name = "Ares"
	sprite_icon_state = "squats"

/datum/robot_sprite/protector/heavy
	name = "XI-ALP"
	sprite_icon_state = "heavy"

// Wide/dogborg sprites

/datum/robot_sprite/dogborg/syndie/protector
	module_type = "Protector"
	sprite_icon = 'icons/mob/robot/protector_wide.dmi'
	sprite_hud_icon_state = "malf"

/datum/robot_sprite/dogborg/syndie/protector/k9
	name = "K9"
	sprite_icon_state = "k9"
	has_eye_light_sprites = TRUE


// Mechanist

// Regular sprites

/datum/robot_sprite/mechanist
	module_type = "Mechanist"
	sprite_icon = 'icons/mob/robot/mechanist.dmi'
	sprite_hud_icon_state = "malf"

/datum/robot_sprite/mechanist/spider
	name = "XI-GUS"
	sprite_icon_state = "spider"

/datum/robot_sprite/mechanist/sleek
	name = "WTOperator"
	sprite_icon_state = "sleek"

// Wide/dogborg sprites

/datum/robot_sprite/dogborg/syndie/mechanist
	module_type = "Mechanist"
	sprite_icon = 'icons/mob/robot/mechanist_wide.dmi'
	sprite_hud_icon_state = "malf"

/datum/robot_sprite/dogborg/syndie/mechanist/pupdozer
	name = "Pupdozer"
	sprite_icon_state = "pupdozer"
	has_eye_light_sprites = TRUE
	rest_sprite_options = list("Default")

// Tall sprites

/datum/robot_sprite/dogborg/tall/mechanist
	module_type = "Mechanist"
	sprite_icon = 'icons/mob/robot/syndie_large.dmi'
	sprite_hud_icon_state = "malf"

/datum/robot_sprite/dogborg/tall/mechanist/syndimechraptor
	name = "Raptor V-4"
	sprite_icon_state = "syndimechraptor"
	has_eye_light_sprites = TRUE
	rest_sprite_options = list("Default", "Bellyup")

// Combat Medic

// Regular sprites

/datum/robot_sprite/combat_medic
	module_type = "Combat Medic"
	sprite_icon = 'icons/mob/robot/combat_medic.dmi'
	sprite_hud_icon_state = "malf"

/datum/robot_sprite/combat_medic/toiletbot
	name = "Telemachus"
	sprite_icon_state = "toiletbot"

// Wide/dogborg sprites

/datum/robot_sprite/dogborg/syndie/combat_medic
	module_type = "Combat Medic"
	sprite_icon = 'icons/mob/robot/combat_medic_wide.dmi'

	has_sleeper_light_indicator = FALSE

/* //RS REMOVAL
/datum/robot_sprite/dogborg/crisis/get_belly_overlay(var/mob/living/silicon/robot/ourborg)
	if(has_sleeper_light_indicator)
		if(ourborg.sleeper_state == 2 && !(ourborg.vore_selected?.silicon_belly_overlay_preference == "Vorebelly")) return "[sprite_icon_state]-sleeper_g"
		else return "[sprite_icon_state]-sleeper_r"
	else
		return ..()
*/

/datum/robot_sprite/dogborg/syndie/combat_medic/vale
	name = "Stray"
	sprite_icon_state = "vale"
	has_eye_light_sprites = TRUE
	has_sleeper_light_indicator = TRUE
