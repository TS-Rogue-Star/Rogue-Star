/datum/sprite_accessory/marking/ch
	icon = 'icons/mob/human_races/markings_ch.dmi'

/datum/sprite_accessory/marking/ch/orca_head
	name = "Orca Head"
	icon_state = "orca"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_HEAD)
	species_allowed = list(SPECIES_AKULA)
	sorting_group = MARKINGS_HEAD //RS add

/datum/sprite_accessory/marking/ch/orca_body
	name = "Orca Body (female)"
	icon_state = "orca"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_TORSO,BP_GROIN)
	sorting_group = MARKINGS_BODY //RS add
	species_allowed = list(SPECIES_AKULA)

/datum/sprite_accessory/marking/ch/orca_legs
	name = "Orca Legs"
	icon_state = "orca"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_L_LEG,BP_R_LEG)
	sorting_group = MARKINGS_LIMBS //RS add
	species_allowed = list(SPECIES_AKULA)

/datum/sprite_accessory/marking/ch/orca_arms
	name = "Orca Arms"
	icon_state = "orca"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_L_ARM,BP_R_ARM)
	sorting_group = MARKINGS_LIMBS //RS add
	species_allowed = list(SPECIES_AKULA)

/datum/sprite_accessory/marking/ch/zangoose_belly
	name = "Mongoose Cat Belly Marking"
	icon_state = "test"
	body_parts = list(BP_TORSO)
	sorting_group = MARKINGS_BODY //RS add
	species_allowed = list(SPECIES_HUMAN, SPECIES_UNATHI, SPECIES_TAJ, SPECIES_NEVREAN, SPECIES_AKULA, SPECIES_ZORREN_HIGH, SPECIES_VULPKANIN, SPECIES_XENOCHIMERA, SPECIES_XENOHYBRID, SPECIES_VASILISSAN, SPECIES_RAPALA, SPECIES_PROTEAN, SPECIES_ALRAUNE) //This lets all races use the default hairstyles.

/datum/sprite_accessory/marking/ch/head_paint_front
	name = "Head Paint Front"
	icon_state = "paintfront"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD //RS add

/datum/sprite_accessory/marking/ch/head_paint_back
	name = "Head Paint"
	icon_state = "paint"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD //RS add

/datum/sprite_accessory/marking/ch/athena_lights
	name = "Hephaestus - Athena lights"
	icon_state = "athena"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_L_LEG,BP_R_LEG,BP_L_ARM,BP_R_ARM,BP_TORSO,BP_HEAD)
	sorting_group = MARKINGS_BODY //RS add

/datum/sprite_accessory/marking/ch/athena_panels
	name = "Hephaestus - Athena FBP Panels"
	icon_state = "athena_p"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_L_FOOT,BP_R_FOOT,BP_L_LEG,BP_R_LEG,BP_L_ARM,BP_R_ARM,BP_L_HAND,BP_R_HAND,BP_GROIN,BP_TORSO,BP_HEAD)
	sorting_group = MARKINGS_BODY //RS add

/datum/sprite_accessory/marking/ch/athena_panels_body
	name = "Hephaestus - Athena FBP Panels (body)"
	icon_state = "athena_p"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_L_FOOT,BP_R_FOOT,BP_L_LEG,BP_R_LEG,BP_L_ARM,BP_R_ARM,BP_L_HAND,BP_R_HAND,BP_GROIN,BP_TORSO)
	sorting_group = MARKINGS_BODY //RS add

/datum/sprite_accessory/marking/ch/athena_panels_head
	name = "Hephaestus - Athena FBP Panels (head)"
	icon_state = "athena_p"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD //RS add

/datum/sprite_accessory/marking/ch/rook_lights
	name = "Bishop - Rook lights"
	icon_state = "rook-l"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_L_FOOT,BP_R_FOOT,BP_L_LEG,BP_R_LEG,BP_L_ARM,BP_R_ARM,BP_L_HAND,BP_R_HAND,BP_GROIN,BP_TORSO,BP_HEAD)
	sorting_group = MARKINGS_BODY //RS add

/datum/sprite_accessory/marking/ch/rook_lights_body
	name = "Bishop - Rook lights (body)"
	icon_state = "rook-l"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_L_FOOT,BP_R_FOOT,BP_L_LEG,BP_R_LEG,BP_L_ARM,BP_R_ARM,BP_L_HAND,BP_R_HAND,BP_GROIN,BP_TORSO)
	sorting_group = MARKINGS_BODY //RS add

/datum/sprite_accessory/marking/ch/rook_lights_head
	name = "Bishop - Rook lights (head)"
	icon_state = "rook-l"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD //RS add

/datum/sprite_accessory/marking/ch/grointojaw
	name = "Groin to mouth marking"
	icon_state = "grointojaw"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_TORSO, BP_HEAD, BP_GROIN)
	sorting_group = MARKINGS_BODY //RS add

/datum/sprite_accessory/marking/ch/vale_eyes
	name = "VALE Eyes"
	icon_state = "vale_eyes"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD //RS add

/datum/sprite_accessory/marking/ch/vale_belly
	name = "VALE Belly"
	icon_state = "vale_belly"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_TORSO, BP_GROIN)
	sorting_group = MARKINGS_BODY //RS add

/datum/sprite_accessory/marking/ch/vale_back
	name = "VALE Back"
	icon_state = "vale_back"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_TORSO)
	sorting_group = MARKINGS_BODY //RS add

/datum/sprite_accessory/marking/ch/vulp_skull
	name = "Vulp Skullface"
	icon_state = "vulpskull"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD //RS add

/datum/sprite_accessory/marking/ch/voxbeak2
	name = "Vox Beak (Normal)"
	icon_state = "vox_beak"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD //RS add

/datum/sprite_accessory/marking/ch/voxtalons
	name = "Vox Talons"
	icon_state = "vox_talons"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_R_ARM,BP_L_ARM,BP_R_HAND,BP_L_HAND,BP_R_LEG,BP_L_LEG,BP_R_FOOT,BP_L_FOOT)
	sorting_group = MARKINGS_LIMBS //RS add

/datum/sprite_accessory/marking/ch/protogen_snout
	name = "Protogen Snout"
	icon_state = "protogen_snout"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD //RS add

/datum/sprite_accessory/marking/ch/hshark_snout
	name = "HShark Snout"
	icon_state = "hshark_snout"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD //RS add

/datum/sprite_accessory/marking/ch/hshark_head
	name = "HShark Head"
	icon_state = "hshark"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD //RS add

/datum/sprite_accessory/marking/ch/ram_horns
	name = "Ram Horns"
	icon_state = "ram_horns"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD //RS add

/datum/sprite_accessory/marking/ch/neckfluff
	name = "Neck Fluff"
	icon_state = "neckfluff"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD //RS add

/datum/sprite_accessory/marking/ch/husky_chest
	name = "Husky Chest"
	icon_state = "husky"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_TORSO, BP_GROIN)
	sorting_group = MARKINGS_BODY //RS add

/datum/sprite_accessory/marking/ch/fox_head
	name = "Fox Head"
	icon_state = "fox"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD //RS add

/datum/sprite_accessory/marking/ch/fox_chest
	name = "Fox Chest"
	icon_state = "fox"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_TORSO, BP_GROIN)
	sorting_group = MARKINGS_BODY //RS add

/datum/sprite_accessory/marking/ch/fox_hsocks
	name = "Fox Hand Socks"
	icon_state = "fox"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_R_ARM, BP_R_HAND, BP_L_ARM, BP_L_HAND)
	sorting_group = MARKINGS_LIMBS //RS add

/datum/sprite_accessory/marking/ch/fox_lsocks
	name = "Fox Leg Socks"
	icon_state = "fox"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_R_LEG,BP_R_FOOT,BP_L_LEG,BP_L_FOOT)
	digitigrade_acceptance = MARKING_ALL_LEGS
	sorting_group = MARKINGS_LIMBS //RS add

/datum/sprite_accessory/marking/ch/tiger_head
	name = "Tiger Head"
	icon_state = "tiger"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD //RS add

/datum/sprite_accessory/marking/ch/tiger_chest
	name = "Tiger Chest"
	icon_state = "tiger"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_TORSO, BP_GROIN)
	sorting_group = MARKINGS_BODY //RS add

/datum/sprite_accessory/marking/ch/tiger_arms
	name = "Tiger Arms"
	icon_state = "tiger"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_R_ARM, BP_R_HAND, BP_L_ARM, BP_L_HAND)
	sorting_group = MARKINGS_LIMBS //RS add

/datum/sprite_accessory/marking/ch/tiger_legs
	name = "Tiger Legs"
	icon_state = "tiger"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_R_LEG,BP_R_FOOT,BP_L_LEG,BP_L_FOOT)
	digitigrade_acceptance = MARKING_ALL_LEGS
	sorting_group = MARKINGS_LIMBS //RS add

/datum/sprite_accessory/marking/ch/gradient_arms
	name = "Gradient Arms"
	icon_state = "gradient"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_R_ARM, BP_R_HAND, BP_L_ARM, BP_L_HAND)
	sorting_group = MARKINGS_LIMBS //RS add

/datum/sprite_accessory/marking/ch/gradient_legs
	name = "Gradient Legs"
	icon_state = "gradient"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_R_LEG,BP_R_FOOT,BP_L_LEG,BP_L_FOOT)
	digitigrade_acceptance = MARKING_ALL_LEGS
	sorting_group = MARKINGS_LIMBS //RS add

/datum/sprite_accessory/marking/ch/hawk_talons
	name = "Hawk Talons (Legs)"
	icon_state = "hawktalon"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_R_LEG,BP_R_FOOT,BP_L_LEG,BP_L_FOOT)
	digitigrade_acceptance = MARKING_ALL_LEGS
	sorting_group = MARKINGS_LIMBS //RS add

/datum/sprite_accessory/marking/ch/deer_hooves
	name = "Deer Hooves"
	icon_state = "deerhoof"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_R_FOOT, BP_L_FOOT)
	digitigrade_acceptance = MARKING_ALL_LEGS
	sorting_group = MARKINGS_LIMBS //RS add

/datum/sprite_accessory/marking/ch/frills_simple
	name = "Frills (Simple)"
	icon_state = "frills_simple"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD //RS add

/datum/sprite_accessory/marking/ch/frills_short
	name = "Frills (Short)"
	icon_state = "frills_short"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD //RS add

/datum/sprite_accessory/marking/ch/frills_aquatic
	name = "Frills (Aquatic)"
	icon_state = "frills_aqua"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD //RS add

/datum/sprite_accessory/marking/ch/guilmonhead
	name = "Guilmon Head"
	icon_state = "guilmon_head"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD //RS add

/datum/sprite_accessory/marking/ch/guilmonchest
	name = "Guilmon Chest"
	icon_state = "guilmon_chest"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_TORSO)
	sorting_group = MARKINGS_BODY //RS add

/datum/sprite_accessory/marking/ch/guilmonchestmarking
	name = "Guilmon Chest Markings"
	icon_state = "guilmon_marking"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_TORSO)
	sorting_group = MARKINGS_BODY //RS add

/datum/sprite_accessory/marking/ch/guilmonarms
	name = "Guilmon Arms"
	icon_state = "guilmon"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_R_ARM,BP_L_ARM,BP_R_HAND,BP_L_HAND)
	sorting_group = MARKINGS_LIMBS //RS add

/datum/sprite_accessory/marking/ch/guilmonlegs
	name = "Guilmon Legs"
	icon_state = "guilmon"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_R_LEG,BP_R_FOOT,BP_L_LEG,BP_L_FOOT)
	digitigrade_acceptance = MARKING_ALL_LEGS
	sorting_group = MARKINGS_LIMBS //RS add

/datum/sprite_accessory/tail/special/orca_tail
	name = "Orca Tail"
	desc = ""
	icon_state = "sharktail_s"
	extra_overlay = "orca_tail"
	do_colouration = 1
	color_blend_mode = ICON_MULTIPLY
	species_allowed = list(SPECIES_AKULA)
	sorting_group = MARKINGS_LIMBS //RS add

/datum/sprite_accessory/marking/ch/teshari_large_eyes_het
	name = "Teshari large eyes (Heterochromia)"
	icon_state = "teshlarge_eyes_het"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_TESHARI //RS add

// Nightstalker Body Markings
/datum/sprite_accessory/marking/ch/desert_nightstalker
	name = "Nightstalker Scales (Desert Coloration)"
	icon_state = "nightstalker_desert"
	body_parts = list(BP_R_ARM,BP_L_ARM,BP_R_HAND,BP_L_HAND,BP_R_LEG,BP_L_LEG,BP_R_FOOT,BP_L_FOOT,BP_TORSO,BP_GROIN) // Fullbody markings, save head
	do_colouration = 0// Don't color, these are pre-colored markings
	sorting_group = MARKINGS_BODY //RS add

/datum/sprite_accessory/marking/ch/desert_nightstalker_head
	name = "Nightstalker Head (Desert Coloration)"
	icon_state = "nightstalker_desert"
	body_parts = list(BP_HEAD)
	do_colouration = 0 // Don't color, these are pre-colored markings
	sorting_group = MARKINGS_HEAD //RS add

/datum/sprite_accessory/marking/ch/nightstalker_head_center
	name = "Nightstalker Head, Tricolor (Center)"
	icon_state = "nightstalker_1"
	body_parts = list(BP_HEAD)
	color_blend_mode = ICON_MULTIPLY
	sorting_group = MARKINGS_HEAD //RS add

/datum/sprite_accessory/marking/ch/nightstalker_head_left
	name = "Nightstalker Head, Tricolor (Left)"
	icon_state = "nightstalker_2"
	body_parts = list(BP_HEAD)
	color_blend_mode = ICON_MULTIPLY
	sorting_group = MARKINGS_HEAD //RS add

/datum/sprite_accessory/marking/ch/nightstalker_head_right
	name = "Nightstalker Head, Tricolor (Right)"
	icon_state = "nightstalker_3"
	body_parts = list(BP_HEAD)
	color_blend_mode = ICON_MULTIPLY
	sorting_group = MARKINGS_HEAD //RS add

/datum/sprite_accessory/marking/ch/diamondback_nightstalker_outer
	name = "Nightstalker Scales, Outer"
	icon_state = "nightstalker_1"
	body_parts = list(BP_R_ARM,BP_L_ARM,BP_R_HAND,BP_L_HAND,BP_R_LEG,BP_L_LEG,BP_R_FOOT,BP_L_FOOT,BP_TORSO,BP_GROIN) // Fullbody markings, save head
	color_blend_mode = ICON_MULTIPLY
	sorting_group = MARKINGS_BODY //RS add

/datum/sprite_accessory/marking/ch/diamondback_nightstalker_inner
	name = "Nightstalker Scales, Inner"
	icon_state = "nightstalker_2"
	body_parts = list(BP_R_ARM,BP_L_ARM,BP_R_LEG,BP_L_LEG,BP_TORSO,BP_GROIN) // Fullbody markings, save head
	color_blend_mode = ICON_MULTIPLY
	sorting_group = MARKINGS_BODY //RS add

/datum/sprite_accessory/marking/ch/outer_spots
	name = "Spots, Outer"
	icon_state = "spots_extremities"
	body_parts = list(BP_R_ARM,BP_L_ARM,BP_R_LEG,BP_L_LEG,BP_R_FOOT,BP_L_FOOT)
	color_blend_mode = ICON_MULTIPLY
	sorting_group = MARKINGS_LIMBS //RS add

//Hellscout panel markings
/datum/sprite_accessory/marking/ch/hellscout_panels_body
	name = "Erebus - Hellscout FBP Panels (upper body)"
	icon_state = "hellscout_p"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_L_ARM,BP_R_ARM,BP_L_HAND,BP_R_HAND,BP_TORSO)
	sorting_group = MARKINGS_BODY //RS add

/datum/sprite_accessory/marking/digi/hellscout_panels_legs
	name = "Erebus - Hellscout FBP Panels (legs)"
	icon_state = "hellscout_p"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_L_FOOT,BP_R_FOOT,BP_L_LEG,BP_R_LEG)
	sorting_group = MARKINGS_LIMBS //RS add

/datum/sprite_accessory/marking/ch/hellscout_panels_head
	name = "Erebus - Hellscout FBP Panels (head)"
	icon_state = "hellscout_p"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD //RS add

//Hellscout abdomen markings
/datum/sprite_accessory/marking/digi/hellscout_abdomen
	name = "Erebus - Hellscout FBP Abdomen (Digitigrade)"
	icon_state = "hellscout_r"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_L_LEG,BP_R_LEG,BP_GROIN,BP_TORSO)
	sorting_group = MARKINGS_BODY //RS add

/datum/sprite_accessory/marking/ch/hellscout_abdomen_p
	name = "Erebus - Hellscout FBP Abdomen (Plantigrade)"
	icon_state = "hellscout_r"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_GROIN,BP_TORSO)
	sorting_group = MARKINGS_BODY //RS add

/datum/sprite_accessory/marking/ch/spectre_panels
	name = "RACS Spectre FBP Panels"
	icon_state = "spectre"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_L_FOOT,BP_R_FOOT,BP_L_LEG,BP_R_LEG,BP_L_ARM,BP_R_ARM,BP_L_HAND,BP_R_HAND,BP_GROIN,BP_TORSO,BP_HEAD)
	sorting_group = MARKINGS_BODY //RS add

/datum/sprite_accessory/marking/ch/spectre_panels_body
	name = "RACS Spectre FBP Panels (body)"
	icon_state = "spectre"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_L_FOOT,BP_R_FOOT,BP_L_LEG,BP_R_LEG,BP_L_ARM,BP_R_ARM,BP_L_HAND,BP_R_HAND,BP_GROIN,BP_TORSO)
	sorting_group = MARKINGS_BODY //RS add

/datum/sprite_accessory/marking/ch/spectre_panels_head
	name = "RACS Spectre FBP Panels (head)"
	icon_state = "spectre"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD //RS add

/datum/sprite_accessory/marking/ch/spectre_eyes
	name = "RACS Spectre FBP Eyes"
	icon_state = "spectre_eyes"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD //RS add

/datum/sprite_accessory/marking/ch/organs_gi
	name = "Internal Organs - Digestive"
	icon_state = "organs_gastro"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_TORSO,BP_GROIN)
	sorting_group = MARKINGS_BODY //RS add

/datum/sprite_accessory/marking/ch/organs_cv
	name = "Internal Organs - Heart,Lungs"
	icon_state = "organs_cardio" //Look I know cardio doesn't include the lungs but I don't care that's what I'm calling it
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_TORSO)
	sorting_group = MARKINGS_BODY //RS add

/datum/sprite_accessory/marking/ch/organs_ribs
	name = "Internal Organs - Ribcage"
	icon_state = "organs_ribs"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_TORSO)
	sorting_group = MARKINGS_BODY //RS add

/datum/sprite_accessory/marking/ch/chestfluff_big
	name = "Chest Fluff, Big"
	icon_state = "chestfluff_big"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_TORSO)
	sorting_group = MARKINGS_BODY //RS add

/datum/sprite_accessory/marking/ch/softbelly
	name = "Belly Fur, Soft"
	icon_state = "softbelly"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_TORSO, BP_GROIN)
	sorting_group = MARKINGS_BODY //RS add

/datum/sprite_accessory/marking/ch/softbelly_navel
	name = "Belly Fur, Soft With Navel"
	icon_state = "softbelly_navel"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_TORSO, BP_GROIN)
	sorting_group = MARKINGS_BODY //RS add

/datum/sprite_accessory/marking/ch/softbelly_fem
	name = "Belly Fur, Soft (Female)"
	icon_state = "softbelly_fem"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_TORSO, BP_GROIN)
	sorting_group = MARKINGS_BODY //RS add

/datum/sprite_accessory/marking/ch/softbelly_fem_navel
	name = "Belly Fur, Soft With Navel (Female)"
	icon_state = "softbelly_fem_navel"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_TORSO, BP_GROIN)
	sorting_group = MARKINGS_BODY //RS add

/datum/sprite_accessory/marking/ch/chitinbelly
	name = "Chitinous Scutes"
	icon_state = "chitin_belly"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_TORSO, BP_GROIN)
	sorting_group = MARKINGS_BODY //RS add

/datum/sprite_accessory/marking/ch/chitinbelly_fem
	name = "Chitinous Scutes (Female)"
	icon_state = "chitinbelly_fem"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_TORSO, BP_GROIN)
	sorting_group = MARKINGS_BODY //RS add

/datum/sprite_accessory/marking/ch/extraeyes
	name = "Extra Eyes"
	icon_state = "extra_eyes"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD //RS add

/datum/sprite_accessory/marking/ch/anthrovirus_ra
	name = "Anthro Virus (Right Arm)"
	icon_state = "anthrovirus"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_R_ARM,BP_R_HAND)
	sorting_group = MARKINGS_LIMBS //RS add
	hide_body_parts = list(BP_R_ARM,BP_R_HAND)

/datum/sprite_accessory/marking/ch/anthrovirus_la
	name = "Anthro Virus (Left Arm)"
	icon_state = "anthrovirus"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_L_ARM,BP_L_HAND)
	sorting_group = MARKINGS_LIMBS //RS add
	hide_body_parts = list(BP_L_ARM,BP_L_HAND)

/datum/sprite_accessory/marking/ch/anthrovirus_rl
	name = "Anthro Virus (Right Leg)"
	icon_state = "anthrovirus"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_R_LEG)
	sorting_group = MARKINGS_LIMBS //RS add
	hide_body_parts = list(BP_R_LEG)

/datum/sprite_accessory/marking/ch/anthrovirus_ll
	name = "Anthro Virus (Left Leg)"
	icon_state = "anthrovirus"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_L_LEG)
	sorting_group = MARKINGS_LIMBS //RS add
	hide_body_parts = list(BP_L_LEG)

/datum/sprite_accessory/marking/ch/anthrovirus_rf
	name = "Anthro Virus (Right Foot)"
	icon_state = "anthrovirus"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_R_FOOT)
	sorting_group = MARKINGS_LIMBS //RS add
	hide_body_parts = list(BP_R_FOOT)

/datum/sprite_accessory/marking/ch/anthrovirus_lf
	name = "Anthro Virus (Left Foot)"
	icon_state = "anthrovirus"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_L_FOOT)
	sorting_group = MARKINGS_LIMBS //RS add
	hide_body_parts = list(BP_L_FOOT)

/datum/sprite_accessory/marking/ch/anthrovirus_t
	name = "Anthro Virus (Torso)"
	icon_state = "anthrovirus"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_TORSO,BP_GROIN)
	hide_body_parts = list(BP_TORSO,BP_GROIN)
	sorting_group = MARKINGS_BODY //RS add

/datum/sprite_accessory/marking/ch/anthrovirus_h
	name = "Anthro Virus (Head)"
	icon_state = "anthrovirus"
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD //RS add
	color_blend_mode = ICON_MULTIPLY
	hide_body_parts	= list(BP_HEAD)

/datum/sprite_accessory/marking/ch/virus_ra
	name = "Bacteriophage (Right Arm)"
	icon_state = "virus"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_R_ARM,BP_R_HAND)
	sorting_group = MARKINGS_LIMBS //RS add
	hide_body_parts = list(BP_R_ARM,BP_R_HAND)

/datum/sprite_accessory/marking/ch/virus_la
	name = "Bacteriophage (Left Arm)"
	icon_state = "virus"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_L_ARM,BP_L_HAND)
	sorting_group = MARKINGS_LIMBS //RS add
	hide_body_parts = list(BP_L_ARM,BP_L_HAND)

/datum/sprite_accessory/marking/ch/virus_rl
	name = "Bacteriophage (Right Leg)"
	icon_state = "virus"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_R_LEG,BP_R_FOOT)
	sorting_group = MARKINGS_LIMBS //RS add
	hide_body_parts = list(BP_R_LEG,BP_R_FOOT)

/datum/sprite_accessory/marking/ch/virus_ll
	name = "Bacteriophage (Left Leg)"
	icon_state = "virus"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_L_LEG,BP_L_FOOT)
	sorting_group = MARKINGS_LIMBS //RS add
	hide_body_parts = list(BP_L_LEG,BP_L_FOOT)

/datum/sprite_accessory/marking/ch/virus_t
	name = "Bacteriophage (Torso)"
	icon_state = "virus"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_TORSO,BP_GROIN)
	hide_body_parts = list(BP_TORSO,BP_GROIN)
	sorting_group = MARKINGS_BODY //RS add

/datum/sprite_accessory/marking/ch/virus_g
	name = "Bacteriophage (Groin)"
	icon_state = "virusgroin" //this is separate so that the groin region can be hidden by the torso.
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_GROIN)
	sorting_group = MARKINGS_BODY //RS add
	//hide_body_parts = list(BP_GROIN) this IS pretty low, even for the groin body part.

/datum/sprite_accessory/marking/ch/virus_h
	name = "Bacteriophage (Head)"
	icon_state = "virus"
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD //RS add
	color_blend_mode = ICON_MULTIPLY
	hide_body_parts	= list(BP_HEAD)

/datum/sprite_accessory/marking/ch/tyranid
	name = "Tyranid Bodytype (Use with Armor)"
	icon_state = "tyranid"
	color_blend_mode = ICON_MULTIPLY
	hide_body_parts = list(BP_L_FOOT,BP_R_FOOT,BP_L_LEG,BP_R_LEG,BP_L_ARM,BP_R_ARM,BP_L_HAND,BP_R_HAND,BP_GROIN,BP_TORSO,BP_HEAD)
	body_parts = list(BP_L_FOOT,BP_R_FOOT,BP_L_LEG,BP_R_LEG,BP_L_ARM,BP_R_ARM,BP_L_HAND,BP_R_HAND,BP_GROIN,BP_TORSO,BP_HEAD)
	sorting_group = MARKINGS_BODY //RS add

/datum/sprite_accessory/marking/ch/tyranid_armor
	name = "Tyranid Bodytype (Armor)"
	icon_state = "tyranidarmor"
	color_blend_mode = ICON_MULTIPLY
	hide_body_parts = list(BP_L_FOOT,BP_R_FOOT,BP_L_LEG,BP_R_LEG,BP_L_ARM,BP_R_ARM,BP_L_HAND,BP_R_HAND,BP_GROIN,BP_TORSO,BP_HEAD)
	body_parts = list(BP_L_FOOT,BP_R_FOOT,BP_L_LEG,BP_R_LEG,BP_L_ARM,BP_R_ARM,BP_L_HAND,BP_R_HAND,BP_GROIN,BP_TORSO,BP_HEAD)
	sorting_group = MARKINGS_BODY //RS add

/datum/sprite_accessory/marking/ch/tyranid_head
	name = "Tyranid Head (Use with Armor)"
	icon_state = "tyranid"
	color_blend_mode = ICON_MULTIPLY
	hide_body_parts = list(BP_HEAD)
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD //RS add

/datum/sprite_accessory/marking/ch/tyranid_head_armor
	name = "Tyranid Head (Armor)"
	icon_state = "tyranidarmor"
	color_blend_mode = ICON_MULTIPLY
	hide_body_parts = list(BP_HEAD)
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD //RS add

/datum/sprite_accessory/marking/ch/tyranid_legs
	name = "Tyranid Legs (Use with Armor)"
	icon_state = "tyranid"
	color_blend_mode = ICON_MULTIPLY
	hide_body_parts = list(BP_L_FOOT,BP_R_FOOT,BP_L_LEG,BP_R_LEG)
	sorting_group = MARKINGS_LIMBS //RS add
	body_parts = list(BP_L_FOOT,BP_R_FOOT,BP_L_LEG,BP_R_LEG,BP_GROIN)

/datum/sprite_accessory/marking/ch/tyranid_legs_armor
	name = "Tyranid Legs (Armor)"
	icon_state = "tyranidarmor"
	color_blend_mode = ICON_MULTIPLY
	hide_body_parts = list(BP_L_FOOT,BP_R_FOOT,BP_L_LEG,BP_R_LEG)
	sorting_group = MARKINGS_LIMBS //RS add
	body_parts = list(BP_L_FOOT,BP_R_FOOT,BP_L_LEG,BP_R_LEG,BP_GROIN)

/datum/sprite_accessory/marking/ch/sect_drone
	name = "Sect Drone Bodytype"
	icon_state = "sectdrone"
	color_blend_mode = ICON_MULTIPLY
	hide_body_parts = list(BP_L_FOOT,BP_R_FOOT,BP_L_LEG,BP_R_LEG,BP_L_ARM,BP_R_ARM,BP_L_HAND,BP_R_HAND,BP_GROIN,BP_TORSO,BP_HEAD)
	body_parts = list(BP_L_FOOT,BP_R_FOOT,BP_L_LEG,BP_R_LEG,BP_L_ARM,BP_R_ARM,BP_L_HAND,BP_R_HAND,BP_GROIN,BP_TORSO,BP_HEAD)
	sorting_group = MARKINGS_BODY //RS add

/datum/sprite_accessory/marking/ch/sect_drone_eyes
	name = "Sect Drone Eyes"
	icon_state = "sectdrone_eyes"
	color_blend_mode = ICON_MULTIPLY
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD //RS add

/datum/sprite_accessory/marking/ch/thickneck
	name = "Thick Neck"
	icon_state = "thickneck"
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD //RS add
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/marking/ch/thickerneck
	name = "Thicker Neck"
	icon_state = "thickerneck"
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD //RS add
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/marking/ch/thickthroat
	name = "Thick Throat"
	icon_state = "thickthroat"
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD //RS add
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/marking/ch/fangs2
	name = "Forward Fangs"
	icon_state = "fangs2"
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD //RS add
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/marking/ch/fangs3
	name = "Further Forward Fangs"
	icon_state = "fangs3"
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD //RS add
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/marking/ch/normeyes
	name = "Normal Eyes"
	icon_state = "normeyes"
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD //RS add
	color_blend_mode = ICON_MULTIPLY

/datum/sprite_accessory/marking/ch/bignostrils
	name = "Big Nostrils"
	icon_state = "bignostrils"
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD //RS add
	color_blend_mode = ICON_MULTIPLY

//Probably shouldnt port these
/datum/sprite_accessory/marking/ch/breasts
	name = "Breasts"
	icon_state = "breasts"
	body_parts = list(BP_TORSO)
	color_blend_mode = ICON_MULTIPLY
	sorting_group = MARKINGS_BODY //RS add

/datum/sprite_accessory/marking/ch/breasts/smooth
	name = "Smooth Breasts"
	icon_state = "breasts_smooth"

/datum/sprite_accessory/marking/ch/breasts/reptile
	name = "Reptile Breasts"
	icon_state = "breasts_reptile"

/// NEW XENOMORPH SPRITE_ACCESSORIES - Basesprites borrowed from Citadel and tidied up by Makkinindorn, should blend a bit more nicely. ///

/datum/sprite_accessory/marking/ch/xenomorph // This is just here to create an easy-to-follow typepath.
	icon = 'icons/mob/human_races/markings_ch.dmi'
	color_blend_mode = ICON_MULTIPLY
	species_allowed = list(SPECIES_HUMAN, SPECIES_UNATHI, SPECIES_TAJ, SPECIES_NEVREAN, SPECIES_AKULA, SPECIES_ZORREN_HIGH, SPECIES_VULPKANIN, SPECIES_XENOCHIMERA, SPECIES_XENOHYBRID, SPECIES_VASILISSAN, SPECIES_RAPALA, SPECIES_PROTEAN, SPECIES_ALRAUNE) // Anyone can use these.

// LIMBS //

/datum/sprite_accessory/marking/ch/xenomorph/xeno_r_arm
	name = "Xenomorph right arm"
	icon_state = "xeno"
	body_parts = list(BP_R_ARM)
	sorting_group = MARKINGS_LIMBS //RS add

/datum/sprite_accessory/marking/ch/xenomorph/xeno_l_arm
	name = "Xenomorph left arm"
	icon_state = "xeno"
	body_parts = list(BP_L_ARM)
	sorting_group = MARKINGS_LIMBS //RS add

/datum/sprite_accessory/marking/ch/xenomorph/xeno_r_leg
	name = "Xenomorph right leg"
	icon_state = "xeno"
	body_parts = list(BP_R_LEG)
	sorting_group = MARKINGS_LIMBS //RS add

/datum/sprite_accessory/marking/ch/xenomorph/xeno_l_leg
	name = "Xenomorph left leg"
	icon_state = "xeno"
	body_parts = list(BP_L_LEG)
	sorting_group = MARKINGS_LIMBS //RS add

/datum/sprite_accessory/marking/ch/xenomorph/xeno_r_hand
	name = "Xenomorph right hand"
	icon_state = "xeno"
	body_parts = list(BP_R_HAND)
	sorting_group = MARKINGS_LIMBS //RS add

/datum/sprite_accessory/marking/ch/xenomorph/xeno_l_hand
	name = "Xenomorph left hand"
	icon_state = "xeno"
	body_parts = list(BP_L_HAND)
	sorting_group = MARKINGS_LIMBS //RS add

// DIGI LEGS //

/datum/sprite_accessory/marking/ch/xenomorph/digi_r_leg
	name = "Xenomorph right leg (digitigrade)"
	icon = 'icons/mob/human_races/markings_digi.dmi'
	icon_state = "xeno_digi"
	digitigrade_acceptance = MARKING_DIGITIGRADE_ONLY
	body_parts = list(BP_R_LEG, BP_R_FOOT)
	sorting_group = MARKINGS_LIMBS //RS add

/datum/sprite_accessory/marking/ch/xenomorph/digi_r_leg_hidden
	name = "Xenomorph right leg (digitigrade, hide)"
	icon = 'icons/mob/human_races/markings_digi.dmi'
	icon_state = "xeno_digi"
	digitigrade_acceptance = MARKING_DIGITIGRADE_ONLY
	body_parts = list(BP_R_LEG, BP_R_FOOT)
	hide_body_parts = list(BP_R_LEG, BP_R_FOOT)
	sorting_group = MARKINGS_LIMBS //RS add

/datum/sprite_accessory/marking/ch/xenomorph/digi_l_leg
	name = "Xenomorph left leg (digitigrade)"
	icon = 'icons/mob/human_races/markings_digi.dmi'
	icon_state = "xeno_digi"
	digitigrade_acceptance = MARKING_DIGITIGRADE_ONLY
	body_parts = list(BP_L_LEG, BP_L_FOOT)
	sorting_group = MARKINGS_LIMBS //RS add

/datum/sprite_accessory/marking/ch/xenomorph/digi_l_leg_hidden
	name = "Xenomorph left leg (digitigrade, hide)"
	icon = 'icons/mob/human_races/markings_digi.dmi'
	icon_state = "xeno_digi"
	digitigrade_acceptance = MARKING_DIGITIGRADE_ONLY
	body_parts = list(BP_L_LEG, BP_L_FOOT)
	hide_body_parts = list(BP_L_LEG, BP_L_FOOT)
	sorting_group = MARKINGS_LIMBS //RS add


// TORSOS //

/datum/sprite_accessory/marking/ch/xenomorph/xeno_chest_m
	name = "Xenomorph chest (male)"
	icon_state = "xeno"
	body_parts = list(BP_TORSO)
	sorting_group = MARKINGS_BODY //RS add

/datum/sprite_accessory/marking/ch/xenomorph/xeno_chest_f
	name = "Xenomorph chest (female)"
	icon_state = "xeno_f"
	body_parts = list(BP_TORSO)
	sorting_group = MARKINGS_BODY //RS add

// HEADS //

/datum/sprite_accessory/marking/ch/xenomorph/xeno_headcrest_standard
	name = "Xenomorph headcrest (drone)"
	icon_state = "xeno_drone"
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD //RS add
	hide_body_parts = list(BP_HEAD)

/datum/sprite_accessory/marking/ch/xenomorph/xeno_headcrest_royal
	name = "Xenomorph headcrest (royal)"
	icon_state = "xeno_royal"
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD //RS add
	hide_body_parts = list(BP_HEAD)

/datum/sprite_accessory/marking/ch/xenomorph/xeno_headcrest_warrior
	name = "Xenomorph headcrest (warrior)"
	icon_state = "xeno_warrior"
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD //RS add
	hide_body_parts = list(BP_HEAD)

/datum/sprite_accessory/marking/ch/xenomorph/xeno_headcrest_hollywood
	name = "Xenomorph headcrest (hollywood)"
	icon_state = "xeno_hollywood"
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD //RS add
	hide_body_parts = list(BP_HEAD)

/datum/sprite_accessory/marking/ch/xenomorph/xeno_headcrest_queen
	name = "Xenomorph headcrest (queen)"
	icon_state = "xeno_queen"
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD //RS add
	hide_body_parts = list(BP_HEAD)

/datum/sprite_accessory/marking/ch/xenomorph/xeno_headcrest_queen_striped
	name = "Xenomorph headcrest (queen, striped)"
	icon_state = "xeno_queen_striped"
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD //RS add
	hide_body_parts = list(BP_HEAD)

// TEETH //

/datum/sprite_accessory/marking/ch/xenomorph/xeno_teeth
	name = "Xenomorph teeth (standard)"
	icon_state = "xeno_teeth"
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD //RS add

/datum/sprite_accessory/marking/ch/xenomorph/xeno_teeth_queen
	name = "Xenomorph teeth (queen)"
	icon_state = "xeno_teeth_queen"
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD //RS add

// WHISKIES //

/datum/sprite_accessory/marking/ch/mole_whiskers
	name = "mole whiskers"
	icon_state = "molewhiskers"
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD //RS add
	color_blend_mode = ICON_MULTIPLY

// SNOOT //

/datum/sprite_accessory/marking/ch/vulp_lips
	name = "face, vulp (Lips)"
	icon_state = "vulp_lips"
	body_parts = list(BP_HEAD)
	sorting_group = MARKINGS_HEAD //RS add
	color_blend_mode = ICON_MULTIPLY
