/***	Werewolf	***/
/datum/sprite_accessory/marking/vr_werewolf_nose
	name = "Werewolf nose"
	icon = 'icons/mob/species/werebeast/werebeast_markings.dmi'
	icon_state = "werewolf_nose"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_HEAD)
	species_allowed = list(SPECIES_WEREBEAST)
	sorting_group = MARKINGS_HEAD

/datum/sprite_accessory/marking/vr_werewolf_face
	name = "Werewolf face"
	icon = 'icons/mob/species/werebeast/werebeast_markings.dmi'
	icon_state = "werewolf"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_HEAD)
	species_allowed = list(SPECIES_WEREBEAST)
	sorting_group = MARKINGS_HEAD

/datum/sprite_accessory/marking/vr_werewolf_belly
	name = "Werewolf belly"
	icon = 'icons/mob/species/werebeast/werebeast_markings.dmi'
	icon_state = "werewolf"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_GROIN,BP_TORSO)
	species_allowed = list(SPECIES_WEREBEAST)
	sorting_group = MARKINGS_BODY

/datum/sprite_accessory/marking/vr_werewolf_socks
	name = "Werewolf socks"
	icon = 'icons/mob/species/werebeast/werebeast_markings.dmi'
	icon_state = "werewolf"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_L_FOOT,BP_R_FOOT,BP_L_LEG,BP_R_LEG,BP_L_ARM,BP_R_ARM,BP_L_HAND,BP_R_HAND)
	species_allowed = list(SPECIES_WEREBEAST)
	sorting_group = MARKINGS_BODY

/***	Shadekin	***/
/datum/sprite_accessory/marking/vr_shadekin_snoot
	name = "Shadekin Snoot"
	icon = 'icons/mob/human_races/markings_vr.dmi'
	icon_state = "shadekin-snoot"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_HEAD)
	species_allowed = list(SPECIES_SHADEKIN, SPECIES_SHADEKIN_CREW)
	sorting_group = MARKINGS_HEAD

/***	Sect drone	***/
/datum/sprite_accessory/marking/vr_sect_drone
	name = "Sect Drone Bodytype"
	icon = 'icons/mob/human_races/markings_vr.dmi'
	icon_state = "sectdrone"
	color_blend_mode = ICON_MULTIPLY
	hide_body_parts = list(BP_L_FOOT,BP_R_FOOT,BP_L_LEG,BP_R_LEG,BP_L_ARM,BP_R_ARM,BP_L_HAND,BP_R_HAND,BP_GROIN,BP_TORSO,BP_HEAD)
	body_parts = list(BP_L_FOOT,BP_R_FOOT,BP_L_LEG,BP_R_LEG,BP_L_ARM,BP_R_ARM,BP_L_HAND,BP_R_HAND,BP_GROIN,BP_TORSO,BP_HEAD)
	organ_override = TRUE
	sorting_group = MARKINGS_BODY

/datum/sprite_accessory/marking/vr_sect_drone_eyes
	name = "Sect Drone Eyes"
	icon = 'icons/mob/human_races/markings_vr.dmi'
	icon_state = "sectdrone_eyes"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD
