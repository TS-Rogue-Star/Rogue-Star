///////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star September 2026: Character Designer - Misc Settings //
///////////////////////////////////////////////////////////////////////////////////////
// Define a place to save in character setup
/datum/preferences
	var/resleeve_lock = 0	// Whether movs should have OOC reslieving protection. Default false.
	var/resleeve_scan = 1	// Whether mob should start with a pre-spawn body scan.  Default true.
	var/synth_cookie = FALSE	// Whether mod can be printed as a snack. requires body scan. Default false.

// Definition of the stuff for Sizing
/datum/category_item/player_setup_item/vore/resleeve
	name = "Resleeving"
	sort_order = 4
	show_in_character_setup = FALSE // RS Add: Character Designer - Misc Settings (Lira, September 2026)

/datum/category_item/player_setup_item/vore/resleeve/load_character(var/savefile/S)
	S["resleeve_lock"]		>> pref.resleeve_lock
	S["resleeve_scan"]		>> pref.resleeve_scan
	S["synth_cookie"]		>> pref.synth_cookie


/datum/category_item/player_setup_item/vore/resleeve/save_character(var/savefile/S)
	S["resleeve_lock"]		<< pref.resleeve_lock
	S["resleeve_scan"]		<< pref.resleeve_scan
	S["synth_cookie"]		<< pref.synth_cookie

/datum/category_item/player_setup_item/vore/resleeve/sanitize_character()
	pref.resleeve_lock		= sanitize_integer(pref.resleeve_lock, 0, 1, initial(pref.resleeve_lock))
	pref.resleeve_scan		= sanitize_integer(pref.resleeve_scan, 0, 1, initial(pref.resleeve_scan))
	pref.synth_cookie		= sanitize_integer(pref.synth_cookie, 0, 1, initial(pref.synth_cookie))

/datum/category_item/player_setup_item/vore/resleeve/copy_to_mob(var/mob/living/carbon/human/character)
	if(character && !istype(character,/mob/living/carbon/human/dummy))
		spawn(5 SECONDS)
			if(QDELETED(character) || QDELETED(pref))
				return // They might have been deleted during the wait
			if(pref.resleeve_scan)
				var/datum/transhuman/body_record/BR = new()
				BR.init_from_mob(character, pref.resleeve_scan, pref.resleeve_lock, pref.synth_cookie)
			if(pref.resleeve_lock)
				character.resleeve_lock = character.ckey
			character.original_player = character.ckey

// RS Edit: Character Designer - Misc Settings (Lira, September 2026)
/datum/category_item/player_setup_item/vore/resleeve/content(var/mob/user)
	return ""

// RS Edit: Character Designer - Misc Settings (Lira, September 2026)
/datum/category_item/player_setup_item/vore/resleeve/OnTopic(var/href, var/list/href_list, var/mob/user)
	return ..()
