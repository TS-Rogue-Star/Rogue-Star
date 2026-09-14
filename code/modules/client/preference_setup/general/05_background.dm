/datum/category_item/player_setup_item/general/background
	name = "Background"
	sort_order = 5
	show_in_character_setup = FALSE // RS Add: Character Designer - Identity Tab (Lira, September 2026)

/datum/category_item/player_setup_item/general/background/load_character(var/savefile/S)
	S["med_record"]				>> pref.med_record
	S["sec_record"]				>> pref.sec_record
	S["gen_record"]				>> pref.gen_record
	S["home_system"]			>> pref.home_system
	S["birthplace"]				>> pref.birthplace
	S["citizenship"]			>> pref.citizenship
	S["faction"]				>> pref.faction
	S["religion"]				>> pref.religion
	S["economic_status"]		>> pref.economic_status

/datum/category_item/player_setup_item/general/background/save_character(var/savefile/S)
	S["med_record"]				<< pref.med_record
	S["sec_record"]				<< pref.sec_record
	S["gen_record"]				<< pref.gen_record
	S["home_system"]			<< pref.home_system
	S["birthplace"]				<< pref.birthplace
	S["citizenship"]			<< pref.citizenship
	S["faction"]				<< pref.faction
	S["religion"]				<< pref.religion
	S["economic_status"]		<< pref.economic_status

/datum/category_item/player_setup_item/general/background/sanitize_character()
	if(!pref.home_system) pref.home_system = "Unset"
	if(!pref.birthplace)  pref.birthplace =  "Unset"
	if(!pref.citizenship) pref.citizenship = "None"
	if(!pref.faction)     pref.faction =     "None"
	if(!pref.religion)    pref.religion =    "None"

	pref.economic_status = sanitize_inlist(pref.economic_status, ECONOMIC_CLASS, initial(pref.economic_status))

// Moved from /datum/preferences/proc/copy_to()
/datum/category_item/player_setup_item/general/background/copy_to_mob(var/mob/living/carbon/human/character)
	character.med_record		= pref.med_record
	character.sec_record		= pref.sec_record
	character.gen_record		= pref.gen_record
	character.home_system		= pref.home_system
	character.birthplace		= pref.birthplace
	character.citizenship		= pref.citizenship
	character.personal_faction	= pref.faction
	character.religion			= pref.religion
