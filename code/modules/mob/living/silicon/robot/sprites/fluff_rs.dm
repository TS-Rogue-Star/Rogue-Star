/datum/robot_sprite/dogborg/service/fluff/aurum
	name = CUSTOM_BORGSPRITE("Aurum The Synth")

	sprite_icon = 'icons/mob/robot/fluff_wide_rs.dmi'
	sprite_icon_state = "googlyfox-aurum-serv"

	has_eye_light_sprites = TRUE
	has_vore_belly_sprites = TRUE
	has_rest_sprites = TRUE
	rest_sprite_options = list("Default", "Sit", "Bellyup")
	has_dead_sprite = TRUE
	has_dead_sprite_overlay = TRUE
	has_vore_belly_resting_sprites = TRUE
	belly_capacity_list = list("sleeper" = 1, "belly" = 2, "throat" = 1)
	pixel_x = -16

	is_whitelisted = TRUE
	whitelist_ckey = "googlyfox"
