// This file contains an example of an engineering borg that contains multistomach capability.
//In this folder as well, you will find a .dmi that contains

// EXAMPLES are written next to each line

/*
/datum/robot_sprite/dogborg/engineering/EXAMPLE
	name = "EXAMPLE"
	sprite_icon_state = "engi"
	sprite_hud_icon_state = "engi"
	has_eye_sprites = TRUE //engi-eyes
	has_eye_light_sprites = TRUE //engi-lights
	has_sleeper_light_indicator = FALSE //We have multibelly! No sleeper lights!
	has_vore_belly_resting_sprites = TRUE //engi-belly-1-bellyup & engi-belly-2-bellyup
	sprite_icon = 'code/game/Rogue Star/cyborgs/example/example.dmi'
	rest_sprite_options = list("Default", "Bellyup", "Sit") //engi-rest, engi-bellyup, engi-sit (in that order)

	/////////////////////////////////////////////////////////////////
	/// The "belly_capacity_list" is how many states you want each belly AND what bellies we have!
	/// This also communicates what stomach sprites we have!
	/// You can have AS MANY AS YOU WANT.
	/// In order:
	/// Belly: engi-belly-1 & engi-belly-2
	/// Throat: engi-throat-1 & engi-throat-2
	/// Tail:  engi-tail-1 & engi-tail-2
	/// Etc Etc
	belly_capacity_list = list("belly" = 2, "throat" = 2, "tail"  = 2)
	/////////////////////////////////////////////////////////////////

/obj/item/weapon/robot_module/robot/engineering/EXAMPLE
	name = "engineering EXAMPLE robot module"

/obj/item/weapon/robot_module/robot/engineering/EXAMPLE/create_equipment(var/mob/living/silicon/robot/robot)
	..()
	robot.vore_capacity = 1 //Leave this be. Unimportant.
	robot.vore_capacity_ex = list("belly" = 2, "throat" = 2, "tail" = 2) //Copy & paste the list you have for the 'belly_capacity_list' here!
/*
