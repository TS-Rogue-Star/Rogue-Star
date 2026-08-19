/datum/preferences
	var/extra_languages = 0
	var/preferred_language = "common" // VOREStation Edit: Allow selecting a preferred language

// RS Edit: Character Designer - Species and Prosthetics (Lira, August 2026)
/datum/preferences/proc/reconcile_languages_for_species()
	if(!islist(alternate_languages))
		testing("LANGSANI: Sanitizing languages on [client]'s character [real_name || "-name not yet loaded-"] because their character has no languages list")
		alternate_languages = list()
	if(!islist(language_custom_keys))
		language_custom_keys = list()
	if(!species)
		return FALSE

	var/datum/species/S = GLOB.all_species[species]
	if(!istype(S))
		testing("LANGSANI: Failed sani on [client]'s character [real_name || "-name not yet loaded-"] because their species ([species]) isn't in the global list")
		return FALSE

	if(alternate_languages.len > (S.num_alternate_languages + extra_languages))
		testing("LANGSANI: Truncated [client]'s character [real_name || "-name not yet loaded-"] language list because it was too long (len: [alternate_languages.len], allowed: [S.num_alternate_languages])")
		alternate_languages.len = (S.num_alternate_languages + extra_languages) // Truncate to allowed length

	for(var/language in alternate_languages)
		var/datum/language/L = GLOB.all_languages[language]
		if(!istype(L) || (L.flags & RESTRICTED) || (!(language in S.secondary_langs) && client && !is_lang_whitelisted(client, L)))
			testing("LANGSANI: Removed [L?.name || "lang not found"] from [client]'s character [real_name || "-name not yet loaded-"] because it failed allowed checks")
			alternate_languages -= language

	// VOREStation Edit Start
	if((!(preferred_language in alternate_languages) && preferred_language != LANGUAGE_GALCOM && preferred_language != S.language) || !preferred_language)
		preferred_language = S.language
	// VOREStation Edit End

	for(var/key in language_custom_keys)
		var/key_language = language_custom_keys[key]
		if(!key_language)
			language_custom_keys.Remove(key)
			continue
		if(!((key_language == S.language) || (key_language == S.default_language && S.default_language != S.language) || (key_language in alternate_languages)))
			language_custom_keys.Remove(key)

	return TRUE

/datum/category_item/player_setup_item/general/language
	name = "Language"
	sort_order = 2
	var/static/list/forbidden_prefixes = list(";", ":", ".", "!", "*", "^", "-")

/datum/category_item/player_setup_item/general/language/load_character(var/savefile/S)
	S["language"]			>> pref.alternate_languages
	S["extra_languages"]	>> pref.extra_languages
	if(islist(pref.alternate_languages))			// Because aparently it may not be?
		testing("LANGSANI: Loaded from [pref.client]'s character [pref.real_name || "-name not yet loaded-"] savefile: [english_list(pref.alternate_languages || list())]")
	S["language_prefixes"]	>> pref.language_prefixes
	//VORE Edit Begin
	S["preflang"]			>> pref.preferred_language
	//VORE Edit End
	S["language_custom_keys"]	>> pref.language_custom_keys

/datum/category_item/player_setup_item/general/language/save_character(var/savefile/S)
	S["language"]			<< pref.alternate_languages
	S["extra_languages"]	<< pref.extra_languages
	if(islist(pref.alternate_languages))			// Because aparently it may not be?
		testing("LANGSANI: Loaded from [pref.client]'s character [pref.real_name || "-name not yet loaded-"] savefile: [english_list(pref.alternate_languages || list())]")
	S["language_prefixes"]	<< pref.language_prefixes
	S["language_custom_keys"]	<< pref.language_custom_keys
	S["preflang"]			<< pref.preferred_language // VOREStation Edit

// RS Edit: Character Designer - Species and Prosthetics (Lira, August 2026)
/datum/category_item/player_setup_item/general/language/sanitize_character()
	pref.reconcile_languages_for_species()

	if(isnull(pref.language_prefixes) || !pref.language_prefixes.len)
		pref.language_prefixes = config.language_prefixes.Copy()
	for(var/prefix in pref.language_prefixes)
		if(prefix in forbidden_prefixes)
			pref.language_prefixes -= prefix

// RS Edit: Character Designer - Languages (Lira, August 2026)
/proc/character_language_custom_key_is_valid(value)
	return istext(value) && length(value) == 1 && contains_az09(value)

// RS Edit: Character Designer - Languages (Lira, August 2026)
/proc/character_language_prefix_is_valid(value)
	return istext(value) && length(value) == 1 && !contains_az09(value) && !(value in list(";", ":", ".", "!", "*", "^", "-"))
