////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star September 2026: Character Designer - Expression //
////////////////////////////////////////////////////////////////////////////////////

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

// RS Edit: Character Designer - Expression (Lira, September 2026)
/datum/category_item/player_setup_item/vore/traits/content(var/mob/user)
	return ""
