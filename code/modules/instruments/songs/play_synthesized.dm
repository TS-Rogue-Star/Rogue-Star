/**
 * Compiles our lines into "chords" with numbers. This makes there have to be a bit of lag at the beginning of the song, but repeats will not have to parse it again, and overall playback won't be impacted by as much lag.
 */
/datum/song/proc/compile_synthesized()
	if(!length(src.lines))
		return
	var/list/lines = src.lines //cache for hyepr speed!
	compiled_chords = list()
	var/list/octaves = list(3, 3, 3, 3, 3, 3, 3)
	var/list/accents = list("n", "n", "n", "n", "n", "n", "n")
	for(var/line in lines)
		var/list/chords = splittext(lowertext(line), ",")
		for(var/chord in chords)
			var/list/compiled_chord = list()
			var/tempodiv = 1
			var/list/notes_tempodiv = splittext(chord, "/")
			var/len = length(notes_tempodiv)
			if(len >= 2)
				tempodiv = text2num(notes_tempodiv[2])
			if(len) //some dunkass is going to do ,,,, to make 3 rests instead of ,/1 because there's no standardization so let's be prepared for that.
				var/list/notes = splittext(notes_tempodiv[1], "-")
				for(var/note in notes)
					if(length(note) == 0)
						continue
					// 1-7, A-G
					var/key = text2ascii(note) - 96
					if((key < 1) || (key > 7))
						continue
					for(var/i in 2 to length(note))
						var/oct_acc = copytext(note, i, i + 1)
						var/num = text2num(oct_acc)
						if(!num) //it's an accidental
							accents[key] = oct_acc //if they misspelled it/fucked up that's on them lmao, no safety checks.
						else //octave
							octaves[key] = clamp(num, octave_min, octave_max)
					compiled_chord += clamp((note_offset_lookup[key] + octaves[key] * 12 + accent_lookup[accents[key]]), key_min, key_max)
			compiled_chord += tempodiv //this goes last
			if(length(compiled_chord))
				compiled_chords[++compiled_chords.len] = compiled_chord

// RS Add Start: Advanced synth (Lira, March 2026)

/datum/song/proc/get_synth_playback_instruments()
	if(!using_instrument)
		return list()
	return list(using_instrument)

/datum/song/proc/get_synth_playback_layer_key(datum/instrument/instrument_override = null)
	var/datum/instrument/active_instrument = instrument_override || using_instrument
	if(active_instrument)
		return REF(active_instrument)
	return "__default__"

/datum/song/proc/register_held_synth_channel(channel_text, datum/instrument/instrument_override = null)
	if(!channel_text)
		return FALSE
	held_synth_channels_by_layer[get_synth_playback_layer_key(instrument_override)] = channel_text
	return TRUE

/datum/song/proc/synth_channel_is_held(channel_text)
	if(!full_sustain_held_note || !channel_text || !length(held_synth_channels_by_layer))
		return FALSE
	for(var/layer_key in held_synth_channels_by_layer)
		if(held_synth_channels_by_layer[layer_key] == channel_text)
			return TRUE
	return FALSE

/datum/song/proc/unregister_held_synth_channel(channel_text)
	if(!channel_text || !length(held_synth_channels_by_layer))
		return FALSE
	. = FALSE
	for(var/layer_key in held_synth_channels_by_layer.Copy())
		if(held_synth_channels_by_layer[layer_key] != channel_text)
			continue
		held_synth_channels_by_layer -= layer_key
		. = TRUE

/datum/song/proc/get_synth_channel_volume_multiplier(channel_text)
	var/list/channel_data = channel_playback_data[channel_text]
	if(islist(channel_data) && isnum(channel_data["volume_multiplier"]))
		return channel_data["volume_multiplier"]
	return using_instrument?.volume_multiplier || 1

/datum/song/proc/get_synth_channel_actual_volume(channel_text, current_volume)
	return (current_volume * 0.01) * volume * get_synth_channel_volume_multiplier(channel_text)

// RS Add End

/**
 * Plays a specific numerical key from our instrument to anyone who can hear us.
 * Does a hearing check if enough time has passed.
 */
// RS Edit: Browser-based instrument audio (Lira, March 2026)
/datum/song/proc/register_synth_channel_state(key, datum/instrument/instrument_override = null)
	if(can_noteshift)
		key = clamp(key + note_shift, key_min, key_max)
	if(note_filter_enabled) //RS Add: Note range filtering (Lira, August 2025)
		if(key < note_filter_min || key > note_filter_max)
			return null
	var/datum/instrument/active_instrument = instrument_override || using_instrument
	var/datum/instrument_key/K = active_instrument?.samples[num2text(key)] //See how fucking easy it is to make a number text? You don't need a complicated 9 line proc!
	if(!K?.sample)
		return null
	//Should probably add channel limiters here at some point but I don't care right now.
	var/channel = pop_channel()
	if(isnull(channel))
		return null
	var/channel_text = num2text(channel)
	channels_playing[channel_text] = 100
	channel_playback_data[channel_text] = list(
		"sample" = K.sample,
		"frequency" = K.frequency,
		"volume_multiplier" = active_instrument?.volume_multiplier || 1
	)
	register_held_synth_channel(channel_text, active_instrument)
	return list(
		"channel" = channel,
		"sample" = K.sample,
		"frequency" = K.frequency,
		"volume" = src.volume * (active_instrument?.volume_multiplier || 1)
	)

// RS Add: Browser-based instrument audio (Lira, March 2026)
/datum/song/proc/synth_should_track_browser_fallback_state(list/targets)
	if(!islist(targets) || !length(targets))
		return FALSE
	for(var/mob/M as anything in targets)
		if(browser_handles_listener(M))
			return TRUE
	return FALSE

// RS Edit: Browser-based instrument audio (Lira, March 2026)
/datum/song/proc/playkey_synth(key, mob/user, list/targets_override, datum/instrument/instrument_override = null) //RS Edit: Add override list (Lira, August 2025)
	if(!islist(targets_override) && ((world.time - MUSICIAN_HEARCHECK_MINDELAY) > last_hearcheck))
		do_hearcheck()
	var/list/channel_state = register_synth_channel_state(key, instrument_override)
	if(!islist(channel_state))
		return FALSE
	. = TRUE
	var/sound/copy = sound(channel_state["sample"])
	var/volume = channel_state["volume"]
	copy.frequency = channel_state["frequency"]
	copy.volume = volume
	var/channel = channel_state["channel"]
	var/turf/source = get_turf(parent)
	var/list/targets = islist(targets_override) ? targets_override : hearing_mobs //RS Add: Adds override (Lira, August 2025)
	for(var/mob/M as anything in targets) //RS Edit: Use targets instead of hearing_mobs (Lira, August 2025)
		if(!M)
			hearing_mobs -= M
			continue
		/* Maybe someday
		if(user && HAS_TRAIT(user, TRAIT_MUSICIAN) && isliving(M))
			var/mob/living/L = M
			L.apply_status_effect(STATUS_EFFECT_GOOD_MUSIC)
		*/
		// Jeez
		if(browser_handles_listener(M))
			continue
		browser_preserved_note_listeners -= M
		if(!(M in synth_fallback_listeners))
			synth_fallback_listeners += M
		M.playsound_local(
			turf_source = source,
			soundin = null,
			vol = volume,
			vary = FALSE,
			frequency = channel_state["frequency"],
			falloff = null,
			is_global = null,
			channel = channel,
			pressure_affected = null,
			S = copy,
			preference = /datum/client_preference/instrument_toggle,
			volume_channel = VOLUME_CHANNEL_INSTRUMENTS)
		// Could do environment and echo later but not for now

// RS Add: Browser-based instrument audio (Lira, March 2026)
/datum/song/proc/start_active_synth_channel(mob/M, channel_text, current_volume)
	if(!M || !using_instrument)
		return FALSE
	var/list/channel_data = channel_playback_data[channel_text]
	if(!islist(channel_data))
		return FALSE
	var/sample = channel_data["sample"]
	if(!sample)
		return FALSE
	var/frequency = channel_data["frequency"]
	var/actual_volume = get_synth_channel_actual_volume(channel_text, current_volume)
	if(actual_volume <= 0)
		return FALSE
	var/sound/copy = sound(sample)
	copy.frequency = frequency
	copy.volume = actual_volume
	M.playsound_local(
		turf_source = get_turf(parent),
		soundin = null,
		vol = actual_volume,
		vary = FALSE,
		frequency = frequency,
		falloff = null,
		is_global = null,
		channel = text2num(channel_text),
		pressure_affected = null,
		S = copy,
		preference = /datum/client_preference/instrument_toggle,
		volume_channel = VOLUME_CHANNEL_INSTRUMENTS)
	return TRUE

/**
 * Stops all sounds we are "responsible" for. Only works in synthesized mode.
 */
// RS Edit: Browser-based instrument audio (Lira, March 2026)
/datum/song/proc/terminate_all_sounds(clear_channels = TRUE, list/targets_override = null)
	var/list/targets = islist(targets_override) ? targets_override : hearing_mobs
	for(var/mob/M as anything in targets)
		terminate_sound_mob(M)
		synth_fallback_listeners -= M
	if(clear_channels)
		channels_playing.len = 0
		channels_idle.len = 0
		channel_playback_data.Cut()
		held_synth_channels_by_layer.Cut()
		synth_fallback_listeners.Cut()
		SSinstruments.current_instrument_channels -= using_sound_channels
		using_sound_channels = 0
		SSsounds.free_datum_channels(src)

/**
 * Stops all sounds we are responsible for in a given person. Only works in synthesized mode.
 */
// RS Edit: Browser-based instrument audio (Lira, March 2026)
/datum/song/proc/terminate_sound_mob(mob/M)
	if(!M)
		return
	for(var/channel in channels_playing)
		M.stop_sound_channel(text2num(channel))

/**
 * Pops a channel we have reserved so we don't have to release and re-request them from SSsounds every time we play a note. This is faster.
 */
/datum/song/proc/pop_channel()
	if(length(channels_idle)) //just pop one off of here if we have one available
		. = text2num(channels_idle[1])
		channels_idle.Cut(1,2)
		return
	if(using_sound_channels >= get_max_sound_channels()) // RS Edit: Advanced synth (Lira, March 2026)
		return
	. = SSinstruments.reserve_instrument_channel(src)
	if(!isnull(.))
		using_sound_channels++

/**
 * Decays our channels and updates their volumes to mobs who can hear us.
 *
 * Arguments:
 * * wait_ds - the deciseconds we should decay by. This is to compensate for any lag, as otherwise songs would get pretty nasty during high time dilation.
 */
// RS Edit: Browser-based instrument audio (Lira, March 2026)
/datum/song/proc/process_decay(wait_ds)
	if(!length(channels_playing))
		channel_playback_data.Cut()
		held_synth_channels_by_layer.Cut()
		synth_fallback_listeners.Cut()
		return
	var/list/current_targets = get_browser_listener_targets()
	var/list/fallback_targets = get_note_fallback_targets(current_targets)
	var/list/stopped_targets = list()
	for(var/mob/M as anything in current_targets)
		if(M in fallback_targets)
			continue
		stopped_targets += M
	if(length(stopped_targets))
		terminate_all_sounds(FALSE, stopped_targets)
	var/list/new_fallback_targets = list()
	var/list/active_fallback_targets = fallback_targets.Copy()
	for(var/mob/M as anything in fallback_targets)
		if(!M)
			hearing_mobs -= M
			continue
		if(M in browser_preserved_note_listeners)
			active_fallback_targets -= M
			continue
		if(M in synth_fallback_listeners)
			continue
		new_fallback_targets += M
	if(length(new_fallback_targets))
		for(var/channel in channels_playing)
			var/current_volume = channels_playing[channel]
			for(var/mob/M as anything in new_fallback_targets)
				start_active_synth_channel(M, channel, current_volume)
		for(var/mob/M as anything in new_fallback_targets)
			if(!(M in synth_fallback_listeners))
				synth_fallback_listeners += M
	var/linear_dropoff = cached_linear_dropoff * wait_ds
	var/exponential_dropoff = cached_exponential_dropoff ** wait_ds
	for(var/channel in channels_playing)
		if(synth_channel_is_held(channel))
			continue
		var/current_volume = channels_playing[channel]
		switch(sustain_mode)
			if(SUSTAIN_LINEAR)
				current_volume -= linear_dropoff
			if(SUSTAIN_EXPONENTIAL)
				current_volume /= exponential_dropoff
		channels_playing[channel] = current_volume
		var/dead = current_volume <= sustain_dropoff_volume
		var/channelnumber = text2num(channel)
		if(dead)
			channels_playing -= channel
			channel_playback_data -= channel
			unregister_held_synth_channel(channel)
			channels_idle += channel
			for(var/mob/M in active_fallback_targets)
				if(!M)
					hearing_mobs -= M
					continue
				M.stop_sound_channel(channelnumber)
		else
			for(var/mob/M in active_fallback_targets)
				if(!M)
					hearing_mobs -= M
					continue
				M.set_sound_channel_volume(channelnumber, get_synth_channel_actual_volume(channel, current_volume))
	if(!length(channels_playing))
		channel_playback_data.Cut()
		held_synth_channels_by_layer.Cut()
		synth_fallback_listeners.Cut()
