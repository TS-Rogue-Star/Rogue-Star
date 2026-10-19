////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2026: Character Designer - Expression //
////////////////////////////////////////////////////////////////////////////////////

/proc/character_designer_voice_choices()
	return list(
		"beep-boop",
		"goon speak 1",
		"goon speak 2",
		"goon speak 3",
		"goon speak 4",
		"goon speak blub",
		"goon speak bottalk",
		"goon speak buwoo",
		"goon speak cow",
		"goon speak lizard",
		"goon speak pug",
		"goon speak pugg",
		"goon speak roach",
		"goon speak skelly",
		"yip",
		"yap",
		"yipyap"
	)

/proc/character_designer_voice_sounds(voice_sound)
	switch(voice_sound)
		if("beep-boop")
			return talk_sound
		if("goon speak 1")
			return goon_speak_one_sound
		if("goon speak 2")
			return goon_speak_two_sound
		if("goon speak 3")
			return goon_speak_three_sound
		if("goon speak 4")
			return goon_speak_four_sound
		if("goon speak blub")
			return goon_speak_blub_sound
		if("goon speak bottalk")
			return goon_speak_bottalk_sound
		if("goon speak buwoo")
			return goon_speak_buwoo_sound
		if("goon speak cow")
			return goon_speak_cow_sound
		if("goon speak lizard")
			return goon_speak_lizard_sound
		if("goon speak pug")
			return goon_speak_pug_sound
		if("goon speak pugg")
			return goon_speak_pugg_sound
		if("goon speak roach")
			return goon_speak_roach_sound
		if("goon speak skelly")
			return goon_speak_skelly_sound
		if("yip")
			return talk_yip
		if("yap")
			return talk_yap
		if("yipyap")
			return talk_yipyap

/proc/character_designer_voice_asset_name(sound_file)
	return "designer-voice-[replacetext("[sound_file]", "/", "-")]"

/datum/asset/simple/character_designer_voices/register()
	for(var/voice_id in character_designer_voice_choices())
		for(var/sound_file in character_designer_voice_sounds(voice_id))
			assets[character_designer_voice_asset_name(sound_file)] = sound_file
	return ..()

/datum/tgui_module/custom_marking_designer/proc/build_expression_voices()
	var/list/voices = list()
	for(var/voice_id in character_designer_voice_choices())
		var/list/samples = list()
		for(var/sound_file in character_designer_voice_sounds(voice_id))
			samples += character_designer_voice_asset_name(sound_file)
		var/sample_rate = 44100
		if(voice_id in list("beep-boop", "goon speak pug"))
			sample_rate = 48000
		else if(voice_id == "goon speak cow")
			sample_rate = 96000
		voices += list(list("id" = voice_id, "samples" = samples, "sample_rate" = sample_rate))
	return voices

/datum/tgui_module/custom_marking_designer/proc/append_basic_expression_payload(list/payload)
	if(!prefs || !islist(payload))
		return
	payload["voice_freq"] = prefs.voice_freq
	payload["voice_sound"] = prefs.voice_sound
	payload["autohiss"] = prefs.autohiss
	for(var/key in list("custom_say", "custom_whisper", "custom_ask", "custom_exclaim"))
		payload[key] = html_decode(prefs.vars[key])
	payload["custom_heat"] = islist(prefs.custom_heat) ? prefs.custom_heat.Copy() : list()
	payload["custom_cold"] = islist(prefs.custom_cold) ? prefs.custom_cold.Copy() : list()

/datum/tgui_module/custom_marking_designer/proc/validate_basic_expression_settings(list/params)
	if(!prefs || !islist(params))
		return null
	var/list/values = list()
	if("voice_freq" in params)
		var/frequency = params["voice_freq"]
		if(istext(frequency))
			frequency = text2num(frequency)
		if(!isnum(frequency) || frequency != round(frequency) || (frequency != 0 && (frequency < 15000 || frequency > 70000)))
			return null
		values["voice_freq"] = frequency
	if("voice_sound" in params)
		if(!istext(params["voice_sound"]) || !(params["voice_sound"] in character_designer_voice_choices()))
			return null
		values["voice_sound"] = params["voice_sound"]
	if("autohiss" in params)
		if(!istext(params["autohiss"]) || !(params["autohiss"] in list("Full", "Basic", "Off")))
			return null
		values["autohiss"] = params["autohiss"]
	for(var/key in list("custom_say", "custom_whisper", "custom_ask", "custom_exclaim"))
		if(!(key in params))
			continue
		var/value = params[key]
		if(!isnull(value) && (!istext(value) || length_char(value) > 12))
			return null
		values[key] = length(value) ? sanitize(value, 0) : null
	for(var/key in list("custom_heat", "custom_cold"))
		if(!(key in params))
			continue
		var/list/messages = params[key]
		if(!islist(messages) || messages.len > 10)
			return null
		var/list/clean_messages = list()
		for(var/message in messages)
			if(!istext(message) || !isnull(messages[message]) || length_char(message) < 3 || length_char(message) > 160)
				return null
			clean_messages += readd_quotes(sanitize(message, 0, 0, 0, 0))
		values[key] = clean_messages
	return values

/datum/tgui_module/custom_marking_designer/proc/apply_basic_expression_settings(list/values)
	for(var/key in values)
		prefs.vars[key] = values[key]
