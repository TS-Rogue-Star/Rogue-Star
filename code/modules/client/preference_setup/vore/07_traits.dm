#define ORGANICS	1
#define SYNTHETICS	2

//RS EDIT START - MOVED FROM _traits.dm
#define TRAIT_TYPE_NEGATIVE	-1
#define TRAIT_TYPE_NEUTRAL	0
#define TRAIT_TYPE_POSITIVE	1

#define TRAIT_VARCHANGE_LESS_BETTER		-1
#define TRAIT_VARCHANGE_ALWAYS_OVERRIDE	0
#define TRAIT_VARCHANGE_MORE_BETTER		1

#define TRAIT_PREF_TYPE_BOOLEAN 1
#define TRAIT_PREF_TYPE_COLOR 2
#define TRAIT_PREF_TYPE_STRING 3
#define TRAIT_PREF_TYPE_INT 4
#define TRAIT_PREF_TYPE_LIST 5

#define TRAIT_NO_VAREDIT_TARGET 0
#define TRAIT_VAREDIT_TARGET_SPECIES 1
#define TRAIT_VAREDIT_TARGET_MOB 2
//RS EDIT END

var/global/list/valid_bloodreagents = list("iron","copper","phoron","silver","gold","slimejelly")	//allowlist-based so people don't make their blood restored by alcohol or something really silly. use reagent IDs!

/datum/preferences
	var/custom_species	// Custom species name, can't be changed due to it having been used in savefiles already.
	var/custom_base		// What to base the custom species on
	var/blood_color = "#A10808"

	var/custom_say = null
	var/custom_whisper = null
	var/custom_ask = null
	var/custom_exclaim = null

	var/list/custom_heat = list()
	var/list/custom_cold = list()

	var/list/pos_traits	= list()	// What traits they've selected for their custom species
	var/list/neu_traits = list()
	var/list/neg_traits = list()

	var/traits_cheating = 0 //Varedit by admins allows saving new maximums on people who apply/etc
	var/starting_trait_points = 0
	var/max_traits = MAX_SPECIES_TRAITS
	var/dirty_synth = 0		//Are you a synth
	var/gross_meatbag = 0		//Where'd I leave my Voight-Kampff test kit?

	var/trait_injection_verb = "bites"	//RS ADD
	var/trait_injection_selected = "microcillin"	//RS ADD
	var/trait_injection_amount = 1	//RS ADD

/datum/preferences/proc/get_custom_bases_for_species(var/new_species)
	if (!new_species)
		new_species = species
	var/list/choices
	var/datum/species/spec = GLOB.all_species[new_species]
	if (spec.selects_bodytype == SELECTS_BODYTYPE_SHAPESHIFTER)
		choices = spec.get_valid_shapeshifter_forms()
		choices = choices.Copy()
	else if (spec.selects_bodytype == SELECTS_BODYTYPE_CUSTOM)
		choices = GLOB.custom_species_bases.Copy()
		if(new_species != SPECIES_CUSTOM)
			choices = (choices | new_species)
	return choices

// Definition of the stuff for Ears
/datum/category_item/player_setup_item/vore/traits
	name = "Traits"
	sort_order = 7

/datum/category_item/player_setup_item/vore/traits/load_character(var/savefile/S)
	S["custom_species"]	>> pref.custom_species
	S["custom_base"]	>> pref.custom_base
	S["pos_traits"]		>> pref.pos_traits
	S["neu_traits"]		>> pref.neu_traits
	S["neg_traits"]		>> pref.neg_traits
	S["blood_color"]	>> pref.blood_color
	S["blood_reagents"]		>> pref.blood_reagents

	S["traits_cheating"]	>> pref.traits_cheating
	S["max_traits"]		>> pref.max_traits
	S["trait_points"]	>> pref.starting_trait_points

	S["custom_say"]		>> pref.custom_say
	S["custom_whisper"]	>> pref.custom_whisper
	S["custom_ask"]		>> pref.custom_ask
	S["custom_exclaim"]	>> pref.custom_exclaim

	S["custom_heat"]	>> pref.custom_heat
	S["custom_cold"]	>> pref.custom_cold
	S["trait_injection_verb"] >> pref.trait_injection_verb	//RS ADD
	S["trait_injection_amount"] >> pref.trait_injection_amount //RS ADD
	S["trait_injection_selected"] >> pref.trait_injection_selected	//RS ADD

/datum/category_item/player_setup_item/vore/traits/save_character(var/savefile/S)
	S["custom_species"]	<< pref.custom_species
	S["custom_base"]	<< pref.custom_base
	S["pos_traits"]		<< pref.pos_traits
	S["neu_traits"]		<< pref.neu_traits
	S["neg_traits"]		<< pref.neg_traits
	S["blood_color"]	<< pref.blood_color
	S["blood_reagents"]		<< pref.blood_reagents

	S["traits_cheating"]	<< pref.traits_cheating
	S["max_traits"]		<< pref.max_traits
	S["trait_points"]	<< pref.starting_trait_points

	S["custom_say"]		<< pref.custom_say
	S["custom_whisper"]	<< pref.custom_whisper
	S["custom_ask"]		<< pref.custom_ask
	S["custom_exclaim"]	<< pref.custom_exclaim

	S["custom_heat"]	<< pref.custom_heat
	S["custom_cold"]	<< pref.custom_cold
	S["trait_injection_verb"] << pref.trait_injection_verb	//RS ADD
	S["trait_injection_amount"] << pref.trait_injection_amount //RS ADD
	S["trait_injection_selected"] << pref.trait_injection_selected	//RS ADD

/datum/category_item/player_setup_item/vore/traits/sanitize_character()
	if(!pref.pos_traits) pref.pos_traits = list()
	if(!pref.neu_traits) pref.neu_traits = list()
	if(!pref.neg_traits) pref.neg_traits = list()

	pref.blood_color = sanitize_hexcolor(pref.blood_color, default="#A10808")
	pref.blood_reagents	= sanitize_text(pref.blood_reagents, initial(pref.blood_reagents))

	if(!pref.traits_cheating)
		var/datum/species/S = GLOB.all_species[pref.species]
		if(S)
			pref.starting_trait_points = S.trait_points
		else
			pref.starting_trait_points = 0
		pref.max_traits = MAX_SPECIES_TRAITS

	if(pref.organ_data[O_BRAIN])	//Checking if we have a synth on our hands, boys.
		pref.dirty_synth = 1
		pref.gross_meatbag = 0
	else
		pref.gross_meatbag = 1
		pref.dirty_synth = 0

	// Clean up positive traits
	for(var/datum/trait/path as anything in pref.pos_traits)
		if(!(path in positive_traits_map[pref.species])) // RS EDIT
			pref.pos_traits -= path
			continue
		var/take_flags = initial(path.can_take)
		if((pref.dirty_synth && !(take_flags & SYNTHETICS)) || (pref.gross_meatbag && !(take_flags & ORGANICS)))
			pref.pos_traits -= path
	//Neutral traits
	for(var/datum/trait/path as anything in pref.neu_traits)
		if(!(path in neutral_traits_map[pref.species])) // RS EDIT
			pref.neu_traits -= path
			continue
		var/take_flags = initial(path.can_take)
		if((pref.dirty_synth && !(take_flags & SYNTHETICS)) || (pref.gross_meatbag && !(take_flags & ORGANICS)))
			pref.neu_traits -= path
	//Negative traits
	for(var/datum/trait/path as anything in pref.neg_traits)
		if(!(path in negative_traits_map[pref.species])) // RS EDIT
			pref.neg_traits -= path
			continue
		var/take_flags = initial(path.can_take)
		if((pref.dirty_synth && !(take_flags & SYNTHETICS)) || (pref.gross_meatbag && !(take_flags & ORGANICS)))
			pref.neg_traits -= path

	var/datum/species/selected_species = GLOB.all_species[pref.species]

	if(selected_species.selects_bodytype)
		if (!(pref.custom_base in pref.get_custom_bases_for_species()))
			pref.custom_base = SPECIES_HUMAN
		//otherwise, allowed!
	else if(!pref.custom_base || !(pref.custom_base in GLOB.custom_species_bases))
		pref.custom_base = SPECIES_HUMAN

	pref.custom_say = lowertext(trim(pref.custom_say))
	pref.custom_whisper = lowertext(trim(pref.custom_whisper))
	pref.custom_ask = lowertext(trim(pref.custom_ask))
	pref.custom_exclaim = lowertext(trim(pref.custom_exclaim))

	if (islist(pref.custom_heat)) //don't bother checking these for actual singular message length, they should already have been checked and it'd take too long every time it's sanitized
		if (length(pref.custom_heat) > 10)
			pref.custom_heat.Cut(11)
	else
		pref.custom_heat = list()
	if (islist(pref.custom_cold))
		if (length(pref.custom_cold) > 10)
			pref.custom_cold.Cut(11)
	else
		pref.custom_cold = list()

/datum/category_item/player_setup_item/vore/traits/copy_to_mob(var/mob/living/carbon/human/character)
	character.custom_species	= pref.custom_species
	character.custom_say		= lowertext(trim(pref.custom_say))
	character.custom_ask		= lowertext(trim(pref.custom_ask))
	character.custom_whisper	= lowertext(trim(pref.custom_whisper))
	character.custom_exclaim	= lowertext(trim(pref.custom_exclaim))
	character.custom_heat = pref.custom_heat
	character.custom_cold = pref.custom_cold


	if(character.isSynthetic())	//Checking if we have a synth on our hands, boys.
		pref.dirty_synth = 1
		pref.gross_meatbag = 0
	else
		pref.gross_meatbag = 1
		pref.dirty_synth = 0

	// RS Edit Start: Reduce unneeded processing for character preview (Lira, September 2025)
	var/datum/species/S = character.species
	var/datum/species/new_S = S
	var/rebuild_traits = TRUE
	var/signature = null
	if(character.preview_fast && pref.species == SPECIES_CUSTOM)
		signature = pref.get_custom_trait_signature()
		if(signature && character.preview_trait_signature == signature)
			rebuild_traits = FALSE
	if(rebuild_traits)
		new_S = S.produceCopy(pref.pos_traits + pref.neu_traits + pref.neg_traits, character, pref.custom_base)
		if(character.preview_fast)
			character.preview_trait_signature = signature
		for(var/datum/trait/T in new_S.traits)
			T.apply_pref(src)
	else if(character.preview_fast)
		character.preview_trait_signature = signature
	else
		character.preview_trait_signature = null
	// RS Edit End

	//Any additional non-trait settings can be applied here
	new_S.blood_color = pref.blood_color
	new_S.blood_reagents = pref.blood_reagents

	if(pref.species == SPECIES_CUSTOM)
		//Statistics for this would be nice
		var/english_traits = english_list(new_S.traits, and_text = ";", comma_text = ";")
		log_game("TRAITS [pref.client_ckey]/([character]) with: [english_traits]") //Terrible 'fake' key_name()... but they aren't in the same entity yet

/datum/category_item/player_setup_item/vore/traits/content(var/mob/user)
	. += "<b>Custom Say: </b>"
	. += "<a href='?src=\ref[src];custom_say=1'>Set Say Verb</a>"
	. += "(<a href='?src=\ref[src];reset_say=1'>Reset</A>)"
	. += "<br>"
	. += "<b>Custom Whisper: </b>"
	. += "<a href='?src=\ref[src];custom_whisper=1'>Set Whisper Verb</a>"
	. += "(<a href='?src=\ref[src];reset_whisper=1'>Reset</A>)"
	. += "<br>"
	. += "<b>Custom Ask: </b>"
	. += "<a href='?src=\ref[src];custom_ask=1'>Set Ask Verb</a>"
	. += "(<a href='?src=\ref[src];reset_ask=1'>Reset</A>)"
	. += "<br>"
	. += "<b>Custom Exclaim: </b>"
	. += "<a href='?src=\ref[src];custom_exclaim=1'>Set Exclaim Verb</a>"
	. += "(<a href='?src=\ref[src];reset_exclaim=1'>Reset</A>)"
	. += "<br>"
	. += "<b>Custom Heat Discomfort: </b>"
	. += "<a href='?src=\ref[src];custom_heat=1'>Set Heat Messages</a>"
	. += "(<a href='?src=\ref[src];reset_heat=1'>Reset</A>)"
	. += "<br>"
	. += "<b>Custom Cold Discomfort: </b>"
	. += "<a href='?src=\ref[src];custom_cold=1'>Set Cold Messages</a>"
	. += "(<a href='?src=\ref[src];reset_cold=1'>Reset</A>)"

/datum/category_item/player_setup_item/vore/traits/OnTopic(var/href,var/list/href_list, var/mob/user)
	if(!CanUseTopic(user))
		return TOPIC_NOACTION

	else if(href_list["custom_say"])
		var/say_choice = sanitize(tgui_input_text(usr, "This word or phrase will appear instead of 'says': [pref.real_name] says, \"Hi.\"", "Custom Say", pref.custom_say, 12), 12)
		if(say_choice)
			pref.custom_say = say_choice
		return TOPIC_REFRESH

	else if(href_list["custom_whisper"])
		var/whisper_choice = sanitize(tgui_input_text(usr, "This word or phrase will appear instead of 'whispers': [pref.real_name] whispers, \"Hi...\"", "Custom Whisper", pref.custom_whisper, 12), 12)
		if(whisper_choice)
			pref.custom_whisper = whisper_choice
		return TOPIC_REFRESH

	else if(href_list["custom_ask"])
		var/ask_choice = sanitize(tgui_input_text(usr, "This word or phrase will appear instead of 'asks': [pref.real_name] asks, \"Hi?\"", "Custom Ask", pref.custom_ask, 12), 12)
		if(ask_choice)
			pref.custom_ask = ask_choice
		return TOPIC_REFRESH

	else if(href_list["custom_exclaim"])
		var/exclaim_choice = sanitize(tgui_input_text(usr, "This word or phrase will appear instead of 'exclaims', 'shouts' or 'yells': [pref.real_name] exclaims, \"Hi!\"", "Custom Exclaim", pref.custom_exclaim, 12), 12)
		if(exclaim_choice)
			pref.custom_exclaim = exclaim_choice
		return TOPIC_REFRESH

	else if(href_list["custom_heat"])
		tgui_alert(user, "You are setting custom heat messages. These will overwrite your species' defaults. To return to defaults, click reset.")
		var/old_message = pref.custom_heat.Join("\n\n")
		var/new_message = sanitize(tgui_input_text(usr,"Use double enter between messages to enter a new one. Must be at least 3 characters long, 160 characters max and up to 10 messages are allowed.","Heat Discomfort messages",old_message, multiline= TRUE, prevent_enter = TRUE), MAX_MESSAGE_LEN,0,0,0)
		if(length(new_message) > 0)
			var/list/raw_list = splittext(new_message,"\n\n")
			if(raw_list.len > 10)
				raw_list.Cut(11)
			for(var/i = 1, i <= raw_list.len, i++)
				if(length(raw_list[i]) < 3 || length(raw_list[i]) > 160)
					raw_list.Cut(i,i)
				else
					raw_list[i] = readd_quotes(raw_list[i])
			ASSERT(raw_list.len <= 10)
			pref.custom_heat = raw_list
		return TOPIC_REFRESH

	else if(href_list["custom_cold"])
		tgui_alert(user, "You are setting custom cold messages. These will overwrite your species' defaults. To return to defaults, click reset.")
		var/old_message = pref.custom_heat.Join("\n\n")
		var/new_message = sanitize(tgui_input_text(usr,"Use double enter between messages to enter a new one. Must be at least 3 characters long, 160 characters max and up to 10 messages are allowed.","Cold Discomfort messages",old_message, multiline= TRUE, prevent_enter = TRUE), MAX_MESSAGE_LEN,0,0,0)
		if(length(new_message) > 0)
			var/list/raw_list = splittext(new_message,"\n\n")
			if(raw_list.len > 10)
				raw_list.Cut(11)
			for(var/i = 1, i <= raw_list.len, i++)
				if(length(raw_list[i]) < 3 || length(raw_list[i]) > 160)
					raw_list.Cut(i,i)
				else
					raw_list[i] = readd_quotes(raw_list[i])
			ASSERT(raw_list.len <= 10)
			pref.custom_cold = raw_list
		return TOPIC_REFRESH

	else if(href_list["reset_say"])
		var/say_choice = tgui_alert(usr, "Reset your Custom Say Verb?","Reset Verb",list("Yes","No"))
		if(say_choice == "Yes")
			pref.custom_say = null
		return TOPIC_REFRESH

	else if(href_list["reset_whisper"])
		var/whisper_choice = tgui_alert(usr, "Reset your Custom Whisper Verb?","Reset Verb",list("Yes","No"))
		if(whisper_choice == "Yes")
			pref.custom_whisper = null
		return TOPIC_REFRESH

	else if(href_list["reset_ask"])
		var/ask_choice = tgui_alert(usr, "Reset your Custom Ask Verb?","Reset Verb",list("Yes","No"))
		if(ask_choice == "Yes")
			pref.custom_ask = null
		return TOPIC_REFRESH

	else if(href_list["reset_exclaim"])
		var/exclaim_choice = tgui_alert(usr, "Reset your Custom Exclaim Verb?","Reset Verb",list("Yes","No"))
		if(exclaim_choice == "Yes")
			pref.custom_exclaim = null
		return TOPIC_REFRESH

	else if(href_list["reset_cold"])
		var/cold_choice = tgui_alert(usr, "Reset your Custom Cold Discomfort messages?", "Reset Discomfort",list("Yes","No"))
		if(cold_choice == "Yes")
			pref.custom_cold = list()
		return TOPIC_REFRESH

	else if(href_list["reset_heat"])
		var/heat_choice = tgui_alert(usr, "Reset your Custom Heat Discomfort messages?", "Reset Discomfort",list("Yes","No"))
		if(heat_choice == "Yes")
			pref.custom_heat = list()
		return TOPIC_REFRESH

	return ..()
