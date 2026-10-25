///////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star September 2026: Character Designer - Misc Settings //
///////////////////////////////////////////////////////////////////////////////////////
/datum/category_item/player_setup_item/vore/misc
	name = "Misc Settings"
	sort_order = 9
	show_in_character_setup = FALSE // RS Add: Character Designer - Misc Settings (Lira, September 2026)

/datum/category_item/player_setup_item/vore/misc/load_character(var/savefile/S)
	S["show_in_directory"]		>> pref.show_in_directory
	S["directory_tag"]			>> pref.directory_tag
	S["directory_erptag"]			>> pref.directory_erptag
	S["directory_ad"]			>> pref.directory_ad
	S["sensorpref"]				>> pref.sensorpref
	S["capture_crystal"]		>> pref.capture_crystal
	S["auto_backup_implant"]	>> pref.auto_backup_implant

/datum/category_item/player_setup_item/vore/misc/save_character(var/savefile/S)
	S["show_in_directory"]		<< pref.show_in_directory
	S["directory_tag"]			<< pref.directory_tag
	S["directory_erptag"]			<< pref.directory_erptag
	S["directory_ad"]			<< pref.directory_ad
	S["sensorpref"]				<< pref.sensorpref
	S["capture_crystal"]		<< pref.capture_crystal
	S["auto_backup_implant"]	<< pref.auto_backup_implant

/datum/category_item/player_setup_item/vore/misc/copy_to_mob(var/mob/living/carbon/human/character)
	if(pref.sensorpref > 5 || pref.sensorpref < 1)
		pref.sensorpref = 5
	character.sensorpref = pref.sensorpref
	character.capture_crystal = pref.capture_crystal

/datum/category_item/player_setup_item/vore/misc/sanitize_character()
	pref.show_in_directory		= sanitize_integer(pref.show_in_directory, 0, 1, initial(pref.show_in_directory))
	pref.directory_tag			= sanitize_inlist(pref.directory_tag, GLOB.char_directory_tags, initial(pref.directory_tag))
	pref.directory_erptag			= sanitize_inlist(pref.directory_erptag, GLOB.char_directory_erptags, initial(pref.directory_erptag))
	pref.sensorpref				= sanitize_integer(pref.sensorpref, 1, sensorpreflist.len, initial(pref.sensorpref))
	pref.capture_crystal		= sanitize_integer(pref.capture_crystal, 0, 1, initial(pref.capture_crystal))
	pref.auto_backup_implant		= sanitize_integer(pref.auto_backup_implant, 0, 1, initial(pref.auto_backup_implant))

// RS Edit: Character Designer - Misc Settings (Lira, September 2026)
/datum/category_item/player_setup_item/vore/misc/content(var/mob/user)
	return ""

// RS Edit: Character Designer - Misc Settings (Lira, September 2026)
/datum/category_item/player_setup_item/vore/misc/OnTopic(var/href, var/list/href_list, var/mob/user)
	return ..()
