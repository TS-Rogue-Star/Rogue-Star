/***
	Vox Specific
				***/

/*** 'Hair' ***/
/datum/sprite_accessory/hair/vox
	name = "Long Vox braid"
	icon_state = "vox_longbraid"
	species_allowed = list(SPECIES_VOX)
	sorting_group = MARKINGS_VOX

/datum/sprite_accessory/hair/vox/braid_short
	name = "Short Vox Braid"
	icon_state = "vox_shortbraid"

/datum/sprite_accessory/hair/vox/quills_short
	name = "Short Vox Quills"
	icon_state = "vox_shortquills"

/datum/sprite_accessory/hair/vox/quills_kingly
	name = "Kingly Vox Quills"
	icon_state = "vox_kingly"

/datum/sprite_accessory/hair/vox/quills_mohawk
	name = "Quill Mohawk"
	icon_state = "vox_mohawk"


/***	Markings	***/
/datum/sprite_accessory/marking/vox
	name = "Vox Beak"
	icon = 'icons/mob/human_races/markings_vox.dmi'
	icon_state = "vox_beak"
	species_allowed = list(SPECIES_VOX)
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_VOX

/datum/sprite_accessory/marking/vox/voxtalons
	name = "Vox scales"
	icon_state = "vox_talons"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_R_ARM,BP_L_ARM,BP_R_HAND,BP_L_HAND,BP_R_LEG,BP_L_LEG,BP_R_FOOT,BP_L_FOOT)

/datum/sprite_accessory/marking/vox/voxclaws
	name = "Vox Claws"
	icon_state = "Voxclaws"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_L_FOOT,BP_R_FOOT,BP_L_HAND,BP_R_HAND)

/datum/sprite_accessory/marking/vox/vox_alt
	name = "Vox Alternate"
	icon_state = "bay_vox"
	body_parts = list(BP_L_FOOT,BP_R_FOOT,BP_L_LEG,BP_R_LEG,BP_L_ARM,BP_R_ARM,BP_L_HAND,BP_R_HAND,BP_TORSO,BP_GROIN,BP_HEAD)

/datum/sprite_accessory/marking/vox/vox_alt_eyes
	name = "Alternate Vox Eyes"
	icon_state = "bay_vox_eyes"
	body_parts = list(BP_HEAD)

/datum/sprite_accessory/marking/vox/voxscales
	name = "Alternate Vox scales"
	icon_state = "Voxscales"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_R_ARM,BP_L_ARM,BP_R_HAND,BP_L_HAND,BP_R_LEG,BP_L_LEG,BP_R_FOOT,BP_L_FOOT)
