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

/datum/sprite_accessory

	var/icon			// the icon file the accessory is located in
	var/icon_state		// the icon_state of the accessory
	var/preview_state	// a custom preview state for whatever reason

	var/name = "ERROR - FIXME" // the preview name of the accessory
	var/desc

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
