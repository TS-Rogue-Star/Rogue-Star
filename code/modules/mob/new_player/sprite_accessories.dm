/*

	Hello and welcome to sprite_accessories: For sprite accessories, such as hair,
	facial hair, and possibly tattoos and stuff somewhere along the line. This file is
	intended to be friendly for people with little to no actual coding experience.
	The process of adding in new hairstyles has been made pain-free and easy to do.
	Enjoy! - Doohl


	Notice: This all gets automatically compiled in a list in dna2.dm, so you do not
	have to define any UI values for sprite accessories manually for hair and facial
	hair. Just add in new hair types and the game will naturally adapt.

	!!WARNING!!: changing existing hair information can be VERY hazardous to savefiles,
	to the point where you may completely corrupt a server's savefiles. Please refrain
	from doing this unless you absolutely know what you are doing, and have defined a
	conversion in savefile.dm
*/

#define MARKINGS_HEAD		0
#define MARKINGS_BODY		1
#define MARKINGS_LIMBS		2
#define MARKINGS_TATSCAR 	3
#define MARKINGS_TESHARI	4
#define MARKINGS_VOX		5
#define MARKINGS_SKINTONE	6

/datum/sprite_accessory

	var/icon			// the icon file the accessory is located in
	var/icon_state		// the icon_state of the accessory
	var/preview_state	// a custom preview state for whatever reason

	var/name = "ERROR - FIXME" // the preview name of the accessory

	// Determines if the accessory will be skipped or included in random hair generations
	var/gender = NEUTER

	// Restrict some styles to specific species. Set to null to perform no checking.
	var/list/species_allowed = list()
	//Should only restrict the ones that make NO SENSE on other species,
	//like Tajaran inner-ear coloring overlay stuff.

	// Whether or not the accessory can be affected by colouration
	var/do_colouration = TRUE

	var/color_blend_mode = ICON_MULTIPLY	// If checked.

	// Ckey of person allowed to use this, if defined.
	var/list/ckeys_allowed = null

	/// Should this sprite block emissives?
	var/em_block = FALSE

	var/list/hide_body_parts = list() //Uses organ tag defines. Bodyparts in this list do not have their icons rendered, allowing for more spriter freedom when doing taur/digitigrade stuff.

	var/sorting_group //For use in the Preference menu

/*
////////////////////////////
/  =--------------------=  /
/  ==  Body Markings   ==  /
/  =--------------------=  /
////////////////////////////
*/
/datum/sprite_accessory/marking
	icon = 'icons/mob/human_races/markings.dmi'
	color_blend_mode = ICON_ADD

	var/genetic = TRUE
	var/organ_override = FALSE
	var/body_parts = list() //A list of bodyparts this covers, in organ_tag defines
	//Reminder: BP_L_FOOT,BP_R_FOOT,BP_L_LEG,BP_R_LEG,BP_L_ARM,BP_R_ARM,BP_L_HAND,BP_R_HAND,BP_TORSO,BP_GROIN,BP_HEAD

	var/digitigrade_acceptance = MARKING_NONDIGI_ONLY
	var/digitigrade_icon = 'icons/mob/human_races/markings_digi.dmi'

//Heterochromia

/datum/sprite_accessory/marking/heterochromia
	name = "Heterochromia (right eye)"
	icon_state = "heterochromia"
	body_parts = list(BP_HEAD)

/datum/sprite_accessory/marking/vr_heterochromia_l
	name = "Heterochromia (left eye)"
	icon = 'icons/mob/human_races/markings_vr.dmi'
	icon_state = "heterochromia_l"
	body_parts = list(BP_HEAD)

//Cybernetic Augments, some species-limited due to sprite misalignment. /aug/ types are excluded from dna.

/datum/sprite_accessory/marking/aug
	name = "Augment (Backports, Back)"
	icon_state = "aug_backports"
	genetic = FALSE
	body_parts = list(BP_TORSO)
	species_allowed = list()			//Removing Polaris whitelits

/datum/sprite_accessory/marking/aug/diode
	name = "Augment (Backports Diode, Back)"
	icon_state = "aug_backportsdiode"

/datum/sprite_accessory/marking/aug/backportswide
	name = "Augment (Backports Wide, Back)"
	icon_state = "aug_backportswide"
	body_parts = list(BP_TORSO)

/datum/sprite_accessory/marking/aug/backportswide/diode
	name = "Augment (Backports Wide Diode, Back)"
	icon_state = "aug_backportswidediode"

/datum/sprite_accessory/marking/aug/headcase
	name = "Augment (Headcase, Head)"
	icon_state = "aug_headcase"
	body_parts = list(BP_HEAD)

/datum/sprite_accessory/marking/aug/headcase_light
	name = "Augment (Headcase Light, Head)"
	icon_state = "aug_headcaselight"
	body_parts = list(BP_HEAD)

/datum/sprite_accessory/marking/aug/headport
	name = "Augment (Headport, Head)"
	icon_state = "aug_headport"
	body_parts = list(BP_HEAD)

/datum/sprite_accessory/marking/aug/headport/diode
	name = "Augment (Headport Diode, Head)"
	icon_state = "aug_headplugdiode"

/datum/sprite_accessory/marking/aug/lowerjaw
	name = "Augment (Lower Jaw, Head)"
	icon_state = "aug_lowerjaw"
	body_parts = list(BP_HEAD)
	species_allowed = list()			//Removing Polaris whitelits

/datum/sprite_accessory/marking/aug/scalpports
	name = "Augment (Scalp Ports)"
	icon_state = "aug_scalpports"
	body_parts = list(BP_HEAD)

/datum/sprite_accessory/marking/aug/scalpports/vertex_left
	name = "Augment (Scalp Port, Vertex Left)"
	icon_state = "aug_vertexport_l"

/datum/sprite_accessory/marking/aug/scalpports/vertex_right
	name = "Augment (Scalp Port, Vertex Right)"
	icon_state = "aug_vertexport_r"

/datum/sprite_accessory/marking/aug/scalpports/occipital_left
	name = "Augment (Scalp Port, Occipital Left)"
	icon_state = "aug_occipitalport_l"

/datum/sprite_accessory/marking/aug/scalpports/occipital_right
	name = "Augment (Scalp Port, Occipital Right)"
	icon_state = "aug_occipitalport_r"

/datum/sprite_accessory/marking/aug/scalpportsdiode
	name = "Augment (Scalp Ports Diode)"
	icon_state = "aug_scalpportsdiode"
	body_parts = list(BP_HEAD)

/datum/sprite_accessory/marking/aug/scalpportsdiode/vertex_left
	name = "Augment (Scalp Port Diode, Vertex Left)"
	icon_state = "aug_vertexportdiode_l"

/datum/sprite_accessory/marking/aug/scalpportsdiode/vertex_right
	name = "Augment (Scalp Port Diode, Vertex Right)"
	icon_state = "aug_vertexportdiode_r"

/datum/sprite_accessory/marking/aug/scalpportsdiode/occipital_left
	name = "Augment (Scalp Port Diode, Occipital Left)"
	icon_state = "aug_occipitalportdiode_l"

/datum/sprite_accessory/marking/aug/scalpportsdiode/occipital_right
	name = "Augment (Scalp Port Diode, Occipital Right)"
	icon_state = "aug_occipitalportdiode_r"

/datum/sprite_accessory/marking/aug/backside_left
	name = "Augment (Backside Left, Head)"
	icon_state = "aug_backside_l"

/datum/sprite_accessory/marking/aug/backside_left/side_diode
	name = "Augment (Backside Left Diode, Head)"
	icon_state = "aug_sidediode_l"

/datum/sprite_accessory/marking/aug/backside_right
	name = "Augment (Backside Right, Head)"
	icon_state = "aug_backside_r"
	body_parts = list(BP_HEAD)

/datum/sprite_accessory/marking/aug/backside_right/side_diode
	name = "Augment (Backside Right Diode, Head)"
	icon_state = "aug_sidediode_r"

/datum/sprite_accessory/marking/aug/side_deunan_left
	name = "Augment (Deunan, Side Left)"
	icon_state = "aug_sidedeunan_l"
	body_parts = list(BP_HEAD)

/datum/sprite_accessory/marking/aug/side_deunan_right
	name = "Augment (Deunan, Side Right)"
	icon_state = "aug_sidedeunan_r"
	body_parts = list(BP_HEAD)

/datum/sprite_accessory/marking/aug/side_kuze_left
	name = "Augment (Kuze, Side Left)"
	icon_state = "aug_sidekuze_l"
	body_parts = list(BP_HEAD)

/datum/sprite_accessory/marking/aug/side_kuze_left/side_diode
	name = "Augment (Kuze Diode, Side Left)"
	icon_state = "aug_sidekuzediode_l"

/datum/sprite_accessory/marking/aug/side_kuze_right
	name = "Augment (Kuze, Side Right)"
	icon_state = "aug_sidekuze_r"
	body_parts = list(BP_HEAD)

/datum/sprite_accessory/marking/aug/side_kuze_right/side_diode
	name = "Augment (Kuze Diode, Side Right)"
	icon_state = "aug_sidekuzediode_r"

/datum/sprite_accessory/marking/aug/side_kinzie_left
	name = "Augment (Kinzie, Side Left)"
	icon_state = "aug_sidekinzie_l"
	body_parts = list(BP_HEAD)

/datum/sprite_accessory/marking/aug/side_kinzie_right
	name = "Augment (Kinzie, Side Right)"
	icon_state = "aug_sidekinzie_r"
	body_parts = list(BP_HEAD)

/datum/sprite_accessory/marking/aug/side_shelly_left
	name = "Augment (Shelly, Side Left)"
	icon_state = "aug_sideshelly_l"
	body_parts = list(BP_HEAD)

/datum/sprite_accessory/marking/aug/side_shelly_right
	name = "Augment (Shelly, Side Right)"
	icon_state = "aug_sideshelly_r"
	body_parts = list(BP_HEAD)

/datum/sprite_accessory/marking/aug/chestports
	name = "Augment (Chest Ports)"
	icon_state = "aug_chestports"
	body_parts = list(BP_TORSO)

/datum/sprite_accessory/marking/aug/chestports/teshari
	name = "Augment (Chest Ports)(Teshari)"
	icon_state = "aug_chestports_tesh"
	species_allowed = list(SPECIES_TESHARI)

/datum/sprite_accessory/marking/aug/abdomenports
	name = "Augment (Abdomen Ports)"
	icon_state = "aug_abdomenports"
	body_parts = list(BP_TORSO)

/datum/sprite_accessory/marking/aug/abdomenports/teshari
	name = "Augment (Abdomen Ports)(Teshari)"
	icon_state = "aug_abdomenports_tesh"
	body_parts = list(BP_GROIN)
	species_allowed = list(SPECIES_TESHARI)