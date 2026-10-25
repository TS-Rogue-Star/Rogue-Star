///////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star September 2026: Character Designer - Misc Settings //
///////////////////////////////////////////////////////////////////////////////////////
// Define a place to save in character setup
/datum/preferences
	var/vantag_volunteer = 0	// What state I want to be in, in terms of being affected by antags.
	var/vantag_preference = VANTAG_NONE	// Whether I'd like to volunteer to be an antag at some point.

// Definition of the stuff for Sizing
/datum/category_item/player_setup_item/vore/vantag
	name = "VS Events"
	sort_order = 6
	show_in_character_setup = FALSE // RS Add: Character Designer - Misc Settings (Lira, September 2026)

/datum/category_item/player_setup_item/vore/vantag/load_character(var/savefile/S)
	S["vantag_volunteer"]	>> pref.vantag_volunteer
	S["vantag_preference"]	>> pref.vantag_preference

/datum/category_item/player_setup_item/vore/vantag/save_character(var/savefile/S)
	S["vantag_volunteer"]	<< pref.vantag_volunteer
	S["vantag_preference"]	<< pref.vantag_preference

/datum/category_item/player_setup_item/vore/vantag/sanitize_character()
	pref.vantag_volunteer	= sanitize_integer(pref.vantag_volunteer, 0, 1, initial(pref.vantag_volunteer))
	pref.vantag_preference	= sanitize_inlist(pref.vantag_preference, vantag_choices_list, initial(pref.vantag_preference))

/datum/category_item/player_setup_item/vore/vantag/copy_to_mob(var/mob/living/carbon/human/character)
	if(character && !istype(character,/mob/living/carbon/human/dummy))
		character.vantag_pref = pref.vantag_preference
		BITSET(character.hud_updateflag, VANTAG_HUD)
