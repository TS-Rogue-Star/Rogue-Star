/datum/preferences
	var/biological_gender = MALE
	var/identifying_gender = MALE

/datum/preferences/proc/set_biological_gender(var/gender)
	biological_gender = gender
	identifying_gender = gender

/datum/category_item/player_setup_item/general/basic
	name = "Basic"
	sort_order = 1

/datum/category_item/player_setup_item/general/basic/load_character(var/savefile/S)
	S["real_name"]				>> pref.real_name
	S["nickname"]				>> pref.nickname
	S["name_color"]				>> pref.name_color // RS Add: Name colors (Lira, February 2026)
	S["name_is_always_random"]	>> pref.be_random_name
	S["gender"]					>> pref.biological_gender
	S["id_gender"]				>> pref.identifying_gender
	S["age"]					>> pref.age
	S["bday_month"]				>> pref.bday_month
	S["bday_day"]				>> pref.bday_day
	S["last_bday_note"]			>> pref.last_birthday_notification
	S["bday_announce"]			>> pref.bday_announce
	S["spawnpoint"]				>> pref.spawnpoint
	S["OOC_Notes"]				>> pref.metadata
	S["OOC_Notes_Likes"]		>> pref.metadata_likes
	S["OOC_Notes_Disikes"]		>> pref.metadata_dislikes
	S["screamsound"]			>> pref.screamsound		//RS ADD

/datum/category_item/player_setup_item/general/basic/save_character(var/savefile/S)
	S["real_name"]				<< pref.real_name
	S["nickname"]				<< pref.nickname
	S["name_color"]				<< pref.name_color // RS Add: Name colors (Lira, February 2026)
	S["name_is_always_random"]	<< pref.be_random_name
	S["gender"]					<< pref.biological_gender
	S["id_gender"]				<< pref.identifying_gender
	S["age"]					<< pref.age
	S["bday_month"]				<< pref.bday_month
	S["bday_day"]				<< pref.bday_day
	S["last_bday_note"]			<< pref.last_birthday_notification
	S["bday_announce"]			<< pref.bday_announce
	S["spawnpoint"]				<< pref.spawnpoint
	S["OOC_Notes"]				<< pref.metadata
	S["OOC_Notes_Likes"]		<< pref.metadata_likes
	S["OOC_Notes_Disikes"]		<< pref.metadata_dislikes
	S["screamsound"]			<< pref.screamsound		//RS ADD

/datum/category_item/player_setup_item/general/basic/sanitize_character()
	pref.age                = sanitize_integer(pref.age, get_min_age(), get_max_age(), initial(pref.age))
	pref.bday_month			= sanitize_integer(pref.bday_month, 0, 12, initial(pref.bday_month))
	pref.bday_day			= sanitize_integer(pref.bday_day, 0, 31, initial(pref.bday_day))
	pref.last_birthday_notification = sanitize_integer(pref.last_birthday_notification, 0, 9999, initial(pref.last_birthday_notification))
	pref.biological_gender  = sanitize_inlist(pref.biological_gender, get_genders(), pick(get_genders()))
	pref.identifying_gender = (pref.identifying_gender in all_genders_define_list) ? pref.identifying_gender : pref.biological_gender
	pref.real_name		= sanitize_name(pref.real_name, pref.species, is_FBP())
	if(!pref.real_name)
		pref.real_name      = random_name(pref.identifying_gender, pref.species)
	pref.nickname		= sanitize_name(pref.nickname)
	pref.name_color		= sanitize_chat_name_color(pref.name_color, null) // RS Add: Name colors (Lira, February 2026)
	pref.spawnpoint         = sanitize_inlist(pref.spawnpoint, spawntypes, initial(pref.spawnpoint))
	pref.be_random_name     = sanitize_integer(pref.be_random_name, 0, 1, initial(pref.be_random_name))

// Moved from /datum/preferences/proc/copy_to()
/datum/category_item/player_setup_item/general/basic/copy_to_mob(var/mob/living/carbon/human/character)
	if(config.humans_need_surnames)
		var/firstspace = findtext(pref.real_name, " ")
		var/name_length = length(pref.real_name)
		if(!firstspace)	//we need a surname
			pref.real_name += " [pick(last_names)]"
		else if(firstspace == name_length)
			pref.real_name += "[pick(last_names)]"

	character.real_name = pref.real_name
	character.name = character.real_name
	if(character.dna)
		character.dna.real_name = character.real_name

	character.nickname = pref.nickname
	character.name_color = sanitize_chat_name_color(pref.name_color, null) // RS Add: Name colors (Lira, February 2026)

	character.gender = pref.biological_gender
	character.identifying_gender = pref.identifying_gender
	character.age = pref.age
	character.bday_month = pref.bday_month
	character.bday_day = pref.bday_day

// RS Edit: Character Designer - Identity Tab (Lira, September 2026)
/datum/category_item/player_setup_item/general/basic/content()
	. = "<b>Spawn Point</b>: <a href='?src=\ref[src];spawnpoint=1'>[pref.spawnpoint]</a>"

// RS Edit: Character Designer - Identity Tab (Lira, September 2026)
/datum/category_item/player_setup_item/general/basic/OnTopic(var/href,var/list/href_list, var/mob/user)
	if(href_list["spawnpoint"])
		var/list/spawnkeys = list()
		for(var/spawntype in spawntypes)
			spawnkeys += spawntype
		var/choice = tgui_input_list(user, "Where would you like to spawn when late-joining?", "Late-Join Choice", spawnkeys)
		if(!choice || !spawntypes[choice] || !CanUseTopic(user))
			return TOPIC_NOACTION
		pref.spawnpoint = choice
		return TOPIC_REFRESH
	return ..()

/datum/category_item/player_setup_item/general/basic/proc/get_genders()
	var/datum/species/S
	if(pref.species)
		S = GLOB.all_species[pref.species]
	else
		S = GLOB.all_species[SPECIES_HUMAN]
	var/list/possible_genders = S.genders
	if(!pref.organ_data || pref.organ_data[BP_TORSO] != "cyborg")
		return possible_genders
	possible_genders = possible_genders.Copy()
	possible_genders |= NEUTER
	return possible_genders
