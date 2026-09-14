/datum/preferences
	var/list/all_underwear
	var/list/all_underwear_metadata

/datum/category_item/player_setup_item/general/equipment
	name = "Clothing"
	sort_order = 4
	show_in_character_setup = FALSE // RS Add: Character Designer - Equipment (Lira, September 2026)

/datum/category_item/player_setup_item/general/equipment/load_character(var/savefile/S)
	S["all_underwear"] >> pref.all_underwear
	S["all_underwear_metadata"] >> pref.all_underwear_metadata
	S["backbag"]	>> pref.backbag
	S["pdachoice"]	>> pref.pdachoice
	S["communicator_visibility"]	>> pref.communicator_visibility
	S["shoe_hater"] >> pref.shoe_hater	//RS ADD

/datum/category_item/player_setup_item/general/equipment/save_character(var/savefile/S)
	S["all_underwear"] << pref.all_underwear
	S["all_underwear_metadata"] << pref.all_underwear_metadata
	S["backbag"]	<< pref.backbag
	S["pdachoice"]	<< pref.pdachoice
	S["communicator_visibility"]	<< pref.communicator_visibility
	S["shoe_hater"] << pref.shoe_hater	//RS ADD

// Moved from /datum/preferences/proc/copy_to()
/datum/category_item/player_setup_item/general/equipment/copy_to_mob(var/mob/living/carbon/human/character)
	character.all_underwear.Cut()
	character.all_underwear_metadata.Cut()

	for(var/underwear_category_name in pref.all_underwear)
		var/datum/category_group/underwear/underwear_category = global_underwear.categories_by_name[underwear_category_name]
		if(underwear_category)
			var/underwear_item_name = pref.all_underwear[underwear_category_name]
			character.all_underwear[underwear_category_name] = underwear_category.items_by_name[underwear_item_name]
			if(pref.all_underwear_metadata[underwear_category_name])
				character.all_underwear_metadata[underwear_category_name] = pref.all_underwear_metadata[underwear_category_name]
		else
			pref.all_underwear -= underwear_category_name

	// TODO - Looks like this is duplicating the work of sanitize_character() if so, remove
	if(pref.backbag > backbaglist.len || pref.backbag < 1)
		pref.backbag = 2 //Same as above
	character.backbag = pref.backbag

	if(pref.pdachoice > 7 || pref.pdachoice < 1)
		pref.pdachoice = 1
	character.pdachoice = pref.pdachoice

/datum/category_item/player_setup_item/general/equipment/sanitize_character()
	if(!islist(pref.gear)) pref.gear = list()

	if(!istype(pref.all_underwear))
		pref.all_underwear = list()

		for(var/datum/category_group/underwear/WRC in global_underwear.categories)
			for(var/datum/category_item/underwear/WRI in WRC.items)
				if(WRI.is_default(pref.identifying_gender ? pref.identifying_gender : MALE))
					pref.all_underwear[WRC.name] = WRI.name
					break

	if(!istype(pref.all_underwear_metadata))
		pref.all_underwear_metadata = list()

	for(var/underwear_category in pref.all_underwear)
		var/datum/category_group/underwear/UWC = global_underwear.categories_by_name[underwear_category]
		if(!UWC)
			pref.all_underwear -= underwear_category
		else
			var/datum/category_item/underwear/UWI = UWC.items_by_name[pref.all_underwear[underwear_category]]
			if(!UWI)
				pref.all_underwear -= underwear_category

	for(var/underwear_metadata in pref.all_underwear_metadata)
		if(!(underwear_metadata in pref.all_underwear))
			pref.all_underwear_metadata -= underwear_metadata
	pref.backbag	= sanitize_integer(pref.backbag, 1, backbaglist.len, initial(pref.backbag))
	pref.pdachoice	= sanitize_integer(pref.pdachoice, 1, pdachoicelist.len, initial(pref.pdachoice))
