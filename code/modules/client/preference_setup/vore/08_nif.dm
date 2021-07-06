//Pretty small file, mostly just for storage.

// No longer used! Stubbed for conversion process.
/datum/preferences
	var/legacy_nif_type
	var/legacy_nif_dura
	var/legacy_nif_savedata

// Definition of the stuff for NIFs
/datum/category_item/player_setup_item/vore/nif
	name = "NIF Data"
	sort_order = 8

/datum/category_item/player_setup_item/vore/nif/load_character(var/savefile/S)
	S["nif_path"]		>> legacy_nif_type
	S["nif_durability"]	>> legacy_nif_dura
	S["nif_savedata"]	>> legacy_nif_savedata

/datum/category_item/player_setup_item/vore/nif/save_character(var/savefile/S)
	S["nif_path"]		<< legacy_nif_type
	S["nif_durability"]	<< legacy_nif_dura
	S["nif_savedata"]	<< legacy_nif_savedata

/datum/category_item/player_setup_item/vore/nif/content(var/mob/user)
	. += "<b>NIF:</b> [ispath(pref.client.pref_vr.nif_type) ? "Present" : "None"]"
