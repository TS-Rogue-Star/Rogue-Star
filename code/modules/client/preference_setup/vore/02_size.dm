/////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star September 2026: Character Designer - Size and Weight //
/////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star September 2026: Character Designer - Expression ///////
/////////////////////////////////////////////////////////////////////////////////////////

// Body weight limits on a character.
#define WEIGHT_MIN 70
#define WEIGHT_MAX 500
#define WEIGHT_CHANGE_MIN 0
#define WEIGHT_CHANGE_MAX 100
#define MAX_VOICE_FREQ 70000
#define MIN_VOICE_FREQ 15000

// Define a place to save in character setup
/datum/preferences
	var/size_multiplier = RESIZE_NORMAL
	// Body weight stuff.
	var/weight_vr = 137		// bodyweight of character (pounds, because I'm not doing the math again -Spades)
	var/weight_gain = 100	// Weight gain rate.
	var/weight_loss = 50	// Weight loss rate.
	var/fuzzy = 0			// Preference toggle for sharp/fuzzy icon. Default sharp.
	var/offset_override = TRUE
	var/voice_freq = 0
	var/voice_sound = "beep-boop"
	var/custom_speech_bubble = "default"

// Definition of the stuff for Sizing
/datum/category_item/player_setup_item/vore/size
	name = "Size"
	sort_order = 2

/datum/category_item/player_setup_item/vore/size/load_character(var/savefile/S)
	S["size_multiplier"]	>> pref.size_multiplier
	S["weight_vr"]			>> pref.weight_vr
	S["weight_gain"]		>> pref.weight_gain
	S["weight_loss"]		>> pref.weight_loss
	S["fuzzy"]				>> pref.fuzzy
	S["offset_override"]	>> pref.offset_override
	S["voice_freq"]			>> pref.voice_freq
	S["voice_sound"]		>> pref.voice_sound
	S["custom_speech_bubble"]		>> pref.custom_speech_bubble

/datum/category_item/player_setup_item/vore/size/save_character(var/savefile/S)
	S["size_multiplier"]	<< pref.size_multiplier
	S["weight_vr"]			<< pref.weight_vr
	S["weight_gain"]		<< pref.weight_gain
	S["weight_loss"]		<< pref.weight_loss
	S["fuzzy"]				<< pref.fuzzy
	S["offset_override"]	<< pref.offset_override
	S["voice_freq"]			<< pref.voice_freq
	S["voice_sound"]		<< pref.voice_sound
	S["custom_speech_bubble"]		<< pref.custom_speech_bubble

/datum/category_item/player_setup_item/vore/size/sanitize_character()
	pref.weight_vr			= sanitize_integer(pref.weight_vr, WEIGHT_MIN, WEIGHT_MAX, initial(pref.weight_vr))
	pref.weight_gain		= sanitize_integer(pref.weight_gain, WEIGHT_CHANGE_MIN, WEIGHT_CHANGE_MAX, initial(pref.weight_gain))
	pref.weight_loss		= sanitize_integer(pref.weight_loss, WEIGHT_CHANGE_MIN, WEIGHT_CHANGE_MAX, initial(pref.weight_loss))
	pref.fuzzy				= sanitize_integer(pref.fuzzy, 0, 1, initial(pref.fuzzy))
	pref.offset_override	= sanitize_integer(pref.offset_override, 0, 1, initial(pref.offset_override))
	if(pref.voice_freq != 0)
		pref.voice_freq			= sanitize_integer(pref.voice_freq, MIN_VOICE_FREQ, MAX_VOICE_FREQ, initial(pref.fuzzy))
	if(pref.size_multiplier == null || pref.size_multiplier < RESIZE_TINY || pref.size_multiplier > RESIZE_HUGE)
		pref.size_multiplier = initial(pref.size_multiplier)
	if(!(pref.custom_speech_bubble in selectable_speech_bubbles))
		pref.custom_speech_bubble = "default"

/datum/category_item/player_setup_item/vore/size/copy_to_mob(var/mob/living/carbon/human/character)
	character.weight			= pref.weight_vr
	character.weight_gain		= pref.weight_gain
	character.weight_loss		= pref.weight_loss
	character.fuzzy				= pref.fuzzy
	character.offset_override	= pref.offset_override
	character.voice_freq		= pref.voice_freq
	character.resize(pref.size_multiplier, animate = FALSE, ignore_prefs = TRUE)
	if(!pref.voice_sound)
		character.voice_sounds_list = talk_sound
	else
		switch(pref.voice_sound)
			if("beep-boop")
				character.voice_sounds_list = talk_sound
			if("goon speak 1")
				character.voice_sounds_list = goon_speak_one_sound
			if("goon speak 2")
				character.voice_sounds_list = goon_speak_two_sound
			if("goon speak 3")
				character.voice_sounds_list = goon_speak_three_sound
			if("goon speak 4")
				character.voice_sounds_list = goon_speak_four_sound
			if("goon speak blub")
				character.voice_sounds_list = goon_speak_blub_sound
			if("goon speak bottalk")
				character.voice_sounds_list = goon_speak_bottalk_sound
			if("goon speak buwoo")
				character.voice_sounds_list = goon_speak_buwoo_sound
			if("goon speak cow")
				character.voice_sounds_list = goon_speak_cow_sound
			if("goon speak lizard")
				character.voice_sounds_list = goon_speak_lizard_sound
			if("goon speak pug")
				character.voice_sounds_list = goon_speak_pug_sound
			if("goon speak pugg")
				character.voice_sounds_list = goon_speak_pugg_sound
			if("goon speak roach")
				character.voice_sounds_list = goon_speak_roach_sound
			if("goon speak skelly")
				character.voice_sounds_list = goon_speak_skelly_sound
			//RS ADD START
			if("yip")
				character.voice_sounds_list = talk_yip
			if("yap")
				character.voice_sounds_list = talk_yap
			if("yipyap")
				character.voice_sounds_list = talk_yipyap
			//RS ADD END
	character.custom_speech_bubble = pref.custom_speech_bubble

// RS Edit: Character Designer - Size and Weight (Lira, September 2026)
/datum/category_item/player_setup_item/vore/size/content(var/mob/user)
	return ""

// RS Edit: Character Designer - Size and Weight (Lira, September 2026)
/datum/category_item/player_setup_item/vore/size/OnTopic(var/href, var/list/href_list, var/mob/user)
	return ..();
