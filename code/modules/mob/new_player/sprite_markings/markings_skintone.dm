
//skin styles - WIP
//going to have to re-integrate this with surgery
//let the icon_state hold an icon preview for now

/datum/sprite_accessory/skin
	icon = 'icons/mob/human_races/r_human.dmi'
	sorting_group = MARKINGS_SKINTONE

/datum/sprite_accessory/skin/human
	name = "Default human skin"
	icon_state = "default"

/datum/sprite_accessory/skin/human_tatt01
	name = "Tatt01 human skin"
	icon_state = "tatt1"

/datum/sprite_accessory/skin/tajaran
	name = "Default tajaran skin"
	icon_state = "default"
	icon = 'icons/mob/human_races/r_tajaran.dmi'

/datum/sprite_accessory/skin/unathi
	name = "Default Unathi skin"
	icon_state = "default"
	icon = 'icons/mob/human_races/r_lizard.dmi'

/datum/sprite_accessory/skin/skrell
	name = "Default skrell skin"
	icon_state = "default"
	icon = 'icons/mob/human_races/r_skrell.dmi'

/datum/sprite_accessory/marking/vr_spirit_lights
	name = "Ward - Spirit FBP Lights"
	icon = 'icons/mob/human_races/markings_vr.dmi'
	icon_state = "lights"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_L_LEG,BP_R_LEG,BP_L_ARM,BP_R_ARM,BP_L_HAND,BP_R_HAND,BP_TORSO,BP_HEAD)
	sorting_group = MARKINGS_SKINTONE

/datum/sprite_accessory/marking/vr_spirit_lights_body
	name = "Ward - Spirit FBP Lights (body)"
	icon = 'icons/mob/human_races/markings_vr.dmi'
	icon_state = "lights"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_L_LEG,BP_R_LEG,BP_L_ARM,BP_R_ARM,BP_L_HAND,BP_R_HAND,BP_TORSO)
	sorting_group = MARKINGS_SKINTONE

/datum/sprite_accessory/marking/vr_spirit_lights_head
	name = "Ward - Spirit FBP Lights (head)"
	icon = 'icons/mob/human_races/markings_vr.dmi'
	icon_state = "lights"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_SKINTONE

/datum/sprite_accessory/marking/vr_spirit_panels
	name = "Ward - Spirit FBP Panels"
	icon = 'icons/mob/human_races/markings_vr.dmi'
	icon_state = "panels"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_L_FOOT,BP_R_FOOT,BP_L_LEG,BP_R_LEG,BP_L_ARM,BP_R_ARM,BP_L_HAND,BP_R_HAND,BP_GROIN,BP_TORSO,BP_HEAD)
	sorting_group = MARKINGS_SKINTONE

/datum/sprite_accessory/marking/vr_spirit_panels_body
	name = "Ward - Spirit FBP Panels (body)"
	icon_state = "panels"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_L_FOOT,BP_R_FOOT,BP_L_LEG,BP_R_LEG,BP_L_ARM,BP_R_ARM,BP_L_HAND,BP_R_HAND,BP_GROIN,BP_TORSO)
	sorting_group = MARKINGS_SKINTONE

/datum/sprite_accessory/marking/vr_spirit_panels_head
	name = "Ward - Spirit FBP Panels (head)"
	icon_state = "panels"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_SKINTONE

/datum/sprite_accessory/marking/vr_body_tone
	name = "Body toning (for emergency contrast loss)"
	icon = 'icons/mob/human_races/markings_vr.dmi'
	icon_state = "btone"
	body_parts = list(BP_L_FOOT,BP_R_FOOT,BP_L_LEG,BP_R_LEG,BP_L_ARM,BP_R_ARM,BP_L_HAND,BP_R_HAND,BP_GROIN,BP_TORSO)
	sorting_group = MARKINGS_SKINTONE

/datum/sprite_accessory/marking/vr_gloss
	name = "Full body gloss"
	icon = 'icons/mob/human_races/markings_vr.dmi'
	icon_state = "gloss"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_L_FOOT,BP_R_FOOT,BP_L_LEG,BP_R_LEG,BP_L_ARM,BP_R_ARM,BP_L_HAND,BP_R_HAND,BP_GROIN,BP_TORSO,BP_HEAD)
	sorting_group = MARKINGS_SKINTONE

/datum/sprite_accessory/marking/vr_eboop_panels
	name = "Eggnerd FBP panels"
	icon = 'icons/mob/human_races/markings_vr.dmi'
	icon_state = "eboop"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_L_FOOT,BP_R_FOOT,BP_L_LEG,BP_R_LEG,BP_L_ARM,BP_R_ARM,BP_L_HAND,BP_R_HAND,BP_GROIN,BP_TORSO,BP_HEAD)
	sorting_group = MARKINGS_SKINTONE