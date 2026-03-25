/////////////////////////////////////////////////////////////////////////////////
//Created by Lira for Rogue Star March 2026 for browser-based instrument audio //
/////////////////////////////////////////////////////////////////////////////////
#define BROWSER_INSTRUMENT_DECAY_NONE 0
#define BROWSER_INSTRUMENT_DECAY_LINEAR 1
#define BROWSER_INSTRUMENT_DECAY_EXPONENTIAL 2

/proc/instrument_audio_sample_alias(sample_path)
	var/path_text = "[sample_path]"
	var/dot = findlasttext(path_text, ".")
	var/ext = dot ? copytext(path_text, dot) : ".ogg"
	return "instrument_[md5(path_text)][ext]"

/datum/song/proc/browser_song_id()
	return REF(src)

/datum/song/proc/can_use_browser_audio()
	return !!(using_instrument?.supports_browser_audio() && length(compiled_chords))

/datum/song/proc/get_browser_master_volume_multiplier()
	if(legacy)
		return using_instrument?.volume_multiplier || 1
	var/list/synth_instruments = get_synth_playback_instruments()
	var/master_multiplier = 0
	for(var/datum/instrument/I as anything in synth_instruments)
		if(I)
			master_multiplier = max(master_multiplier, I.volume_multiplier || 1)
	if(master_multiplier > 0)
		return master_multiplier
	return using_instrument?.volume_multiplier || 1

/datum/song/proc/browser_handles_listener(mob/M)
	return !!M?.client?.instrument_audio?.song_uses_browser(src)

/datum/song/proc/browser_listener_blocks_legacy_fallback(mob/M)
	if(browser_handles_listener(M))
		return TRUE
	if(!legacy || !M?.client || !get_browser_active_listener_mob(M.client))
		return FALSE
	var/datum/instrument_audio_manager/manager = M.client.instrument_audio
	if(!manager?.browser_listener_supported(src, M))
		return FALSE
	return manager.song_is_priming(src)

/datum/song/proc/listener_needs_note_fallback(mob/M)
	if(get_browser_listener_gain(M) <= 0)
		return FALSE
	if(legacy)
		return !browser_listener_blocks_legacy_fallback(M)
	return !browser_handles_listener(M)

/datum/song/proc/get_note_fallback_targets(list/targets_override = null)
	var/list/targets = islist(targets_override) ? targets_override : hearing_mobs
	if(!islist(targets) || !length(targets))
		return list()
	var/list/fallback_targets = list()
	for(var/mob/M as anything in targets)
		if(!M)
			if(!islist(targets_override))
				hearing_mobs -= M
			continue
		if(listener_needs_note_fallback(M))
			fallback_targets += M
	return fallback_targets

/datum/song/proc/get_browser_initial_event_time_ds()
	return get_browser_timeline_offset_ds() + get_instrument_time_step()

/datum/song/proc/get_browser_active_listener_mob(client/C)
	if(!C)
		return null
	var/mob/active_mob = browser_active_listeners[C]
	var/mob/current_mob = C.mob
	if(active_mob && active_mob != current_mob)
		unregister_browser_listener_tracking(active_mob)
		if(current_mob)
			browser_active_listeners[C] = current_mob
		else
			browser_active_listeners -= C
		active_mob = current_mob
	return active_mob

/datum/song/proc/configure_browser_full_timeline()
	browser_timeline_start_chord_index = 1
	browser_timeline_repeats_after_start = repeat
	browser_timeline_initial_time_ds = get_browser_initial_event_time_ds()
	browser_listener_launch_time = browser_playback_start_time

/datum/song/proc/get_browser_upcoming_rebuild_state()
	if(!playing || !length(compiled_chords))
		return null
	var/datum/song/progression_song = src
	if(band_is_follower())
		progression_song = band_leader
		if(!progression_song?.playing || !length(progression_song.compiled_chords))
			return null
	var/list/active_state = progression_song.band_get_active_chord_state()
	if(!islist(active_state))
		return null
	var/next_chord_index = clamp(progression_song.current_chord, 1, length(compiled_chords))
	var/next_start_time = active_state["end_time"]
	if(band_is_follower())
		next_start_time += get_browser_timeline_offset_ds()
	return list(
		"start_chord" = next_chord_index,
		"repeats_after_start" = max(0, progression_song.repeats_left),
		"next_start_time" = next_start_time
	)

/datum/song/proc/schedule_browser_listener_resync(resume_time)
	if(!isnum(resume_time))
		resume_time = browser_listener_launch_time
	var/resume_delay = resume_time - world.time
	if(resume_delay > 0)
		addtimer(CALLBACK(src, PROC_REF(resume_browser_listener_sync)), resume_delay)

/datum/song/proc/resume_browser_listener_sync()
	if(!playing)
		return FALSE
	do_hearcheck()
	sync_all_browser_listeners()
	return TRUE

/datum/song/proc/configure_browser_rebuild_from_upcoming_chord()
	var/list/rebuild_state = get_browser_upcoming_rebuild_state()
	if(!islist(rebuild_state))
		return FALSE
	var/next_start_time = rebuild_state["next_start_time"]
	browser_timeline_start_chord_index = rebuild_state["start_chord"]
	browser_timeline_repeats_after_start = rebuild_state["repeats_after_start"]
	browser_timeline_initial_time_ds = get_browser_initial_event_time_ds()
	browser_playback_start_time = next_start_time - browser_timeline_initial_time_ds
	browser_listener_launch_time = next_start_time
	schedule_browser_listener_resync(next_start_time)
	return TRUE

/datum/song/proc/get_browser_timeline_offset_ds()
	if(band_is_follower())
		return max(0, round(band_delay_ds, get_instrument_time_step()))
	return 0

/datum/song/proc/get_browser_loop_duration_ds()
	if(!length(compiled_chords))
		return 0
	var/time_step = get_instrument_time_step()
	var/loop_duration_ds = 0
	for(var/list/chord as anything in compiled_chords)
		if(!length(chord))
			continue
		loop_duration_ds += tempodiv_to_delay(chord[length(chord)]) * time_step
	return loop_duration_ds

/datum/song/proc/get_browser_completed_loops()
	if(!playing || repeat <= 0)
		return 0
	return clamp(repeat - get_repeats_left(), 0, repeat)

/datum/song/proc/browser_should_defer_listener_starts()
	if(browser_resync_suspended)
		return TRUE
	if(band_is_follower())
		return !!(band_leader?.playing && (band_leader.band_browser_resync_pending || band_leader.browser_resync_suspended))
	if(band_is_leader())
		return band_browser_resync_pending
	return FALSE

/datum/song/proc/browser_legacy_cutover_waiting_for_boundary()
	if(!legacy || !playing)
		return FALSE
	var/list/rebuild_state = get_browser_upcoming_rebuild_state()
	if(!islist(rebuild_state))
		return FALSE
	var/next_start_time = rebuild_state["next_start_time"]
	return isnum(next_start_time) && next_start_time > world.time

/datum/song/proc/get_browser_rebuild_elapsed_ds()
	return max(0, world.time - browser_playback_start_time)

/datum/song/proc/get_browser_full_timeline_elapsed_ds()
	if(!playing || !length(compiled_chords))
		return get_browser_rebuild_elapsed_ds()
	var/datum/song/progression_song = src
	if(band_is_follower())
		progression_song = band_leader
		if(!progression_song?.playing || !length(progression_song.compiled_chords))
			return get_browser_rebuild_elapsed_ds()
	if(!progression_song.band_active_chord_index)
		return get_browser_rebuild_elapsed_ds()
	var/time_step = get_instrument_time_step()
	var/elapsed_ds = get_browser_initial_event_time_ds()
	elapsed_ds += get_browser_completed_loops() * get_browser_loop_duration_ds()
	var/next_chord_index = clamp(progression_song.current_chord, 1, length(compiled_chords))
	for(var/i in 1 to (next_chord_index - 1))
		var/list/chord = compiled_chords[i]
		if(!length(chord))
			continue
		elapsed_ds += tempodiv_to_delay(chord[length(chord)]) * time_step
	return elapsed_ds

/datum/song/proc/reanchor_browser_playback()
	if(!playing)
		return FALSE
	browser_playback_start_time = world.time - get_browser_full_timeline_elapsed_ds()
	browser_listener_launch_time = browser_playback_start_time
	return TRUE

/datum/song/proc/rebuild_browser_timeline_for_active_playback()
	if(!playing)
		return FALSE
	if(!configure_browser_rebuild_from_upcoming_chord())
		configure_browser_full_timeline()
		reanchor_browser_playback()
	queue_browser_timeline_build()
	return TRUE

/datum/song/proc/begin_playback(mob/user, playback_start_time = world.time)
	if(!can_begin_playback())
		return FALSE
	playing = TRUE
	playback_generation++
	browser_resync_suspended = FALSE
	browser_preserved_note_listeners.Cut()
	browser_playback_start_time = playback_start_time
	repeats_left = repeat
	configure_browser_full_timeline()
	queue_browser_timeline_build()
	updateDialog(user)
	do_hearcheck()
	SEND_SIGNAL(parent, COMSIG_SONG_START)
	elapsed_delay = 0
	delay_by = 0
	current_chord = 1
	band_active_chord_index = 0
	band_active_chord_started_at = 0
	band_active_chord_duration_ds = 0
	user_playing = user
	last_note_fx_time = world.time - note_fx_interval_ds
	update_browser_source_tracking()
	sync_all_browser_listeners()
	START_PROCESSING(SSinstruments, src)
	return TRUE

/datum/song/proc/get_browser_registered_listeners()
	var/list/listeners = browser_tracked_listeners.Copy()
	for(var/client/C as anything in browser_active_listeners.Copy())
		var/mob/M = get_browser_active_listener_mob(C)
		if(!M || (M in listeners))
			continue
		listeners += M
	return listeners

/datum/song/proc/drop_browser_registered_listeners()
	for(var/mob/M as anything in get_browser_registered_listeners())
		browser_stop_listener(M, TRUE, TRUE)

/datum/song/proc/queue_browser_timeline_build()
	drop_browser_registered_listeners()
	browser_timeline_json = null
	browser_timeline_key = null
	browser_sample_manifest.Cut()
	browser_timeline_duration_ds = 0
	browser_timeline_building = FALSE
	browser_timeline_build_serial++
	if(!playing || !can_use_browser_audio())
		return FALSE
	browser_timeline_building = TRUE
	INVOKE_ASYNC(src, PROC_REF(build_browser_timeline_async), browser_timeline_build_serial)
	return TRUE

/datum/song/proc/build_browser_timeline_async(build_serial)
	set waitfor = FALSE
	var/list/build_result = prepare_browser_timeline()
	if(build_serial != browser_timeline_build_serial)
		return
	browser_timeline_building = FALSE
	if(!playing || !can_use_browser_audio() || !islist(build_result))
		browser_timeline_json = null
		browser_timeline_key = null
		browser_sample_manifest.Cut()
		browser_timeline_duration_ds = 0
		if(browser_should_defer_listener_starts())
			return
		sync_all_browser_listeners()
		return
	browser_sample_manifest = build_result["sample_manifest"]
	browser_timeline_duration_ds = build_result["duration_ds"]
	browser_timeline_json = build_result["timeline_json"]
	browser_timeline_key = build_result["timeline_key"]
	if(browser_should_defer_listener_starts())
		do_hearcheck()
		sync_all_browser_listeners()
		return
	do_hearcheck()
	sync_all_browser_listeners()

/datum/song/proc/prepare_browser_timeline()
	var/list/sample_manifest = list()
	if(!can_use_browser_audio())
		return null
	var/list/build_result = legacy ? build_browser_timeline_legacy(sample_manifest) : build_browser_timeline_synth(sample_manifest)
	if(!islist(build_result))
		return null
	var/list/events = build_result["events"]
	if(!length(events))
		return null
	build_result["sample_manifest"] = sample_manifest
	build_result["timeline_json"] = json_encode(list("events" = events))
	build_result["timeline_key"] = md5(build_result["timeline_json"])
	return build_result

/datum/song/proc/build_browser_chord_schedule()
	var/list/schedule = list()
	if(!length(compiled_chords))
		return schedule
	var/time_step = get_instrument_time_step()
	var/current_time = browser_timeline_initial_time_ds
	if(current_time <= 0)
		current_time = get_browser_initial_event_time_ds()
	var/start_index = clamp(browser_timeline_start_chord_index, 1, length(compiled_chords))
	for(var/i in start_index to length(compiled_chords))
		var/list/chord = compiled_chords[i]
		CHECK_TICK
		schedule += list(list("time_ds" = current_time, "chord" = chord))
		current_time += tempodiv_to_delay(chord[length(chord)]) * time_step
	for(var/loop_index = 1, loop_index <= max(0, browser_timeline_repeats_after_start), loop_index++)
		for(var/list/chord as anything in compiled_chords)
			CHECK_TICK
			schedule += list(list("time_ds" = current_time, "chord" = chord))
			current_time += tempodiv_to_delay(chord[length(chord)]) * time_step
	return schedule

/datum/song/proc/build_browser_timeline_legacy(list/sample_manifest)
	var/list/schedule = build_browser_chord_schedule()
	var/list/events = list()
	var/duration_ds = 0
	for(var/list/entry as anything in schedule)
		CHECK_TICK
		var/start_ds = entry["time_ds"]
		var/list/chord = entry["chord"]
		for(var/i in 1 to (length(chord) - 1))
			CHECK_TICK
			var/list/note_data = chord[i]
			var/sample_path = browser_legacy_note_path(note_data[1], note_data[2], note_data[3])
			if(!sample_path)
				continue
			duration_ds = max(duration_ds, start_ds + rustg_sound_length(sample_path))
			var/alias = instrument_audio_sample_alias(sample_path)
			sample_manifest[alias] = sample_path
			events += list(list(
				"s" = alias,
				"t" = round(start_ds / 10, 0.001),
				"r" = 1
			))
	return list(
		"events" = events,
		"duration_ds" = duration_ds
	)

/datum/song/proc/browser_legacy_note_path(note, acc as text, oct)
	var/list/note_state = resolve_legacy_note(note, acc, oct)
	if(!islist(note_state))
		return null
	if(note_filter_enabled)
		var/numeric_key = note_state["key"]
		if(numeric_key < note_filter_min || numeric_key > note_filter_max)
			return null
	note = note_state["note"]
	acc = note_state["acc"]
	oct = note_state["oct"]
	var/sample_path = "sound/instruments/[cached_legacy_dir]/[ascii2text(note + 64)][acc][oct].[cached_legacy_ext]"
	if(!fexists(sample_path))
		return null
	return sample_path

/datum/song/proc/build_browser_timeline_synth(list/sample_manifest)
	var/list/schedule = build_browser_chord_schedule()
	var/list/synth_instruments = get_synth_playback_instruments()
	if(!length(synth_instruments))
		return null
	var/list/all_events = list()
	var/time_step = get_instrument_time_step()
	var/song_stop_ds = max(time_step, get_browser_timeline_offset_ds() + time_step)
	var/list/held_events_by_layer = list()
	for(var/list/entry as anything in schedule)
		CHECK_TICK
		var/start_ds = entry["time_ds"]
		var/list/chord = entry["chord"]
		var/chord_duration_ds = tempodiv_to_delay(chord[length(chord)]) * time_step
		song_stop_ds = max(song_stop_ds, start_ds + chord_duration_ds)
		for(var/i in 1 to (length(chord) - 1))
			for(var/datum/instrument/I as anything in synth_instruments)
				CHECK_TICK
				var/list/note_data = browser_resolve_synth_note(chord[i], I)
				if(!note_data)
					continue
				var/layer_key = get_synth_playback_layer_key(I)
				var/list/held_event = held_events_by_layer[layer_key]
				if(full_sustain_held_note && held_event)
					browser_begin_decay(held_event, start_ds)
				var/alias = instrument_audio_sample_alias(note_data["sample"])
				sample_manifest[alias] = note_data["sample"]
				var/list/event = list(
					"_sample" = alias,
					"_start_ds" = start_ds,
					"_rate" = note_data["rate"],
					"_volume" = note_data["volume_multiplier"]
				)
				all_events += list(event)
				if(full_sustain_held_note)
					held_events_by_layer[layer_key] = event
				else
					browser_begin_decay(event, start_ds)
	if(!length(all_events))
		return null

	for(var/list/event as anything in all_events)
		CHECK_TICK
		browser_finalize_synth_event(event, song_stop_ds)

	return list(
		"events" = browser_export_synth_events(all_events),
		"duration_ds" = song_stop_ds
	)

/datum/song/proc/browser_resolve_synth_note(key, datum/instrument/instrument_override = null)
	if(can_noteshift)
		key = clamp(key + note_shift, key_min, key_max)
	if(note_filter_enabled && (key < note_filter_min || key > note_filter_max))
		return null
	var/datum/instrument/active_instrument = instrument_override || using_instrument
	var/datum/instrument_key/K = active_instrument?.samples[num2text(key)]
	if(!K?.sample)
		return null
	return list(
		"sample" = "[K.sample]",
		"rate" = K.frequency || 1,
		"volume_multiplier" = get_browser_synth_event_volume_multiplier(active_instrument)
	)

/datum/song/proc/get_browser_synth_event_volume_multiplier(datum/instrument/instrument_override = null)
	var/datum/instrument/active_instrument = instrument_override || using_instrument
	var/event_multiplier = active_instrument?.volume_multiplier || 1
	var/master_multiplier = get_browser_master_volume_multiplier()
	if(master_multiplier <= 0)
		return event_multiplier
	return event_multiplier / master_multiplier

/datum/song/proc/browser_begin_decay(list/event, start_ds)
	if(isnull(event["_decay_ds"]))
		event["_decay_ds"] = start_ds
		event["_mode"] = (sustain_mode == SUSTAIN_LINEAR) ? BROWSER_INSTRUMENT_DECAY_LINEAR : BROWSER_INSTRUMENT_DECAY_EXPONENTIAL

/datum/song/proc/browser_finalize_synth_event(list/event, song_stop_ds)
	if(!islist(event))
		return
	var/threshold = sustain_dropoff_volume / 100
	var/linear_drop_per_ds = cached_linear_dropoff / 100
	var/decay_ds = event["_decay_ds"]
	if(!isnum(decay_ds) || decay_ds >= song_stop_ds)
		event["_stop_ds"] = song_stop_ds
		event["_end_gain"] = 1
		return
	if(event["_mode"] == BROWSER_INSTRUMENT_DECAY_LINEAR)
		if(linear_drop_per_ds <= 0)
			event["_stop_ds"] = song_stop_ds
			event["_end_gain"] = 1
			return
		var/time_to_dead = max(0, (1 - threshold) / linear_drop_per_ds)
		var/dead_ds = decay_ds + time_to_dead
		if(dead_ds <= song_stop_ds)
			event["_stop_ds"] = dead_ds
			event["_end_gain"] = clamp(threshold, 0, 1)
			return
		event["_stop_ds"] = song_stop_ds
		event["_end_gain"] = clamp(max(0, 1 - (linear_drop_per_ds * (song_stop_ds - decay_ds))), 0, 1)
		return
	if(threshold > 0)
		var/time_to_dead_exp = log(1 / threshold) / log(cached_exponential_dropoff)
		var/dead_ds_exp = decay_ds + max(0, time_to_dead_exp)
		if(dead_ds_exp <= song_stop_ds)
			event["_stop_ds"] = dead_ds_exp
			event["_end_gain"] = clamp(threshold, 0, 1)
			return
	event["_stop_ds"] = song_stop_ds
	event["_end_gain"] = clamp(1 / (cached_exponential_dropoff ** max(0, song_stop_ds - decay_ds)), 0.0001, 1)

/datum/song/proc/browser_export_synth_events(list/all_events)
	var/list/exported = list()
	for(var/list/event as anything in all_events)
		CHECK_TICK
		var/list/export_event = list(
			"s" = event["_sample"],
			"t" = round(event["_start_ds"] / 10, 0.001),
			"r" = round(event["_rate"], 0.0001),
			"e" = round(event["_stop_ds"] / 10, 0.001)
		)
		var/event_volume = event["_volume"]
		var/decay_ds = event["_decay_ds"]
		var/end_gain = event["_end_gain"]
		if(isnum(event_volume) && abs(event_volume - 1) > 0.0001)
			export_event["v"] = round(max(0, event_volume), 0.0001)
		if(isnum(decay_ds) && decay_ds < event["_stop_ds"] && isnum(end_gain) && end_gain < 0.9999)
			export_event["d"] = round(decay_ds / 10, 0.001)
			export_event["m"] = event["_mode"]
			export_event["g"] = round(max(0.0001, end_gain), 0.0001)
		exported += list(export_event)
	return exported

/datum/song/proc/get_browser_listener_targets()
	var/list/targets = hearing_mobs?.Copy() || list()
	if(band_is_leader())
		for(var/datum/song/S as anything in band_followers)
			if(!S?.band_ready_for(src))
				continue
			targets |= S.hearing_mobs
		return targets
	if(band_is_follower() && band_leader?.playing && band_ready_for(band_leader))
		targets |= band_leader.hearing_mobs
	return targets

/datum/song/proc/add_browser_source_targets(list/sources, datum/song/S)
	if(!islist(sources) || !istype(S) || QDELETED(S) || QDELETED(S.parent))
		return
	if(ismovable(S.parent))
		sources |= S.parent
	var/mob/holder = S.get_holder()
	if(holder && holder != S.parent)
		sources |= holder

/datum/song/proc/get_browser_source_targets()
	var/list/sources = list()
	add_browser_source_targets(sources, src)
	if(band_is_leader())
		for(var/datum/song/S as anything in band_followers)
			if(!S?.band_ready_for(src))
				continue
			add_browser_source_targets(sources, S)
		return sources
	if(band_is_follower() && band_leader?.playing && band_ready_for(band_leader))
		add_browser_source_targets(sources, band_leader)
	return sources

/datum/song/proc/browser_listener_in_local_range(mob/M)
	if(!M)
		return FALSE
	var/turf/source = get_turf(parent)
	var/turf/target = get_turf(M)
	if(!source || !target || source.z != target.z)
		return FALSE
	var/list/in_range = get_mobs_and_objs_in_view_fast(source, instrument_range, remote_ghosts = FALSE)
	return !!(M in in_range["mobs"])

/datum/song/proc/browser_listener_in_targets(mob/M, list/listener_targets = null)
	if(!M)
		return FALSE
	if(islist(listener_targets))
		return !!(M in listener_targets)
	if(browser_listener_in_local_range(M))
		return TRUE
	if(band_is_leader())
		for(var/datum/song/S as anything in band_followers)
			if(!S?.band_ready_for(src))
				continue
			if(S.browser_listener_in_local_range(M))
				return TRUE
		return FALSE
	if(band_is_follower() && band_leader?.playing && band_ready_for(band_leader))
		return band_leader.browser_listener_in_local_range(M)
	return FALSE

/datum/song/proc/get_browser_listener_gain(mob/M)
	if(!M?.client || M.ear_deaf > 0)
		return 0
	if(!M.client.is_preference_enabled(/datum/client_preference/instrument_toggle))
		return 0
	var/turf/source = get_turf(parent)
	var/turf/target = get_turf(M)
	if(!source || !target || source.z != target.z)
		return 0
	var/adjusted_volume = volume * get_browser_master_volume_multiplier()
	adjusted_volume *= M.client.get_preference_volume_channel(VOLUME_CHANNEL_INSTRUMENTS)
	adjusted_volume *= M.client.get_preference_volume_channel(VOLUME_CHANNEL_MASTER)
	adjusted_volume -= max(get_dist(target, source) - world.view, 0) * 2
	if(adjusted_volume <= 0)
		return 0
	var/pressure_factor = 1
	var/distance = get_dist(target, source)
	var/datum/gas_mixture/hearer_env = target.return_air()
	var/datum/gas_mixture/source_env = source.return_air()
	if(hearer_env && source_env)
		var/pressure = min(hearer_env.return_pressure(), source_env.return_pressure())
		if(pressure < ONE_ATMOSPHERE)
			pressure_factor = max((pressure - SOUND_MINIMUM_PRESSURE) / (ONE_ATMOSPHERE - SOUND_MINIMUM_PRESSURE), 0)
	else
		pressure_factor = 0
	if(distance <= 1)
		pressure_factor = max(pressure_factor, 0.15)
	adjusted_volume *= pressure_factor
	if(adjusted_volume <= 0)
		return 0
	return clamp(adjusted_volume / 100, 0, 1)

/datum/song/proc/get_browser_listener_position(mob/M)
	var/list/position = list(
		"x" = 0,
		"z" = 0
	)
	if(!M)
		return position
	var/turf/source = get_turf(parent)
	var/turf/target = get_turf(M)
	if(!source || !target || source.z != target.z)
		return position
	position["x"] = source.x - target.x
	position["z"] = source.y - target.y
	return position

/datum/song/proc/prime_browser_listener(mob/M, datum/instrument_audio_manager/manager, list/listener_targets = null)
	if(!M?.client || !manager?.browser_listener_supported(src, M) || !browser_timeline_json)
		return FALSE
	if(!browser_listener_in_targets(M, listener_targets))
		return FALSE
	if(get_browser_listener_gain(M) <= 0)
		return FALSE
	register_browser_listener_tracking(M)
	manager.stop_song(src)
	browser_active_listeners -= M.client
	return manager.prime_song(src)

/datum/song/proc/sync_browser_listener(mob/M, list/listener_targets = null)
	var/client/C = M?.client
	if(!C)
		return FALSE
	var/mob/active_mob = get_browser_active_listener_mob(C)
	if(active_mob && active_mob != M)
		M = active_mob
	if(!browser_listener_in_targets(M, listener_targets))
		browser_stop_listener(M)
		return FALSE
	var/datum/instrument_audio_manager/manager = C.instrument_audio
	if(browser_resync_suspended)
		prime_browser_listener(M, manager, listener_targets)
		return FALSE
	if(!manager?.browser_listener_supported(src, M) || !browser_timeline_json)
		browser_stop_listener(M)
		return FALSE
	var/gain = get_browser_listener_gain(M)
	if(gain <= 0)
		browser_stop_listener(M)
		return FALSE
	var/listener_launch_time = max(browser_playback_start_time, browser_listener_launch_time)
	if(world.time < listener_launch_time)
		prime_browser_listener(M, manager, listener_targets)
		return FALSE
	var/elapsed_seconds = max(0, (world.time - browser_playback_start_time) / 10)
	if(browser_timeline_duration_ds && elapsed_seconds > ((browser_timeline_duration_ds / 10) + 0.05))
		browser_stop_listener(M)
		return FALSE
	register_browser_listener_tracking(M)
	var/list/position = get_browser_listener_position(M)
	var/pan_x = position["x"]
	var/pan_z = position["z"]
	var/had_listener_record = !!active_mob
	if(had_listener_record && manager.song_uses_browser(src))
		browser_active_listeners[C] = M
		browser_preserved_note_listeners -= M
		manager.update_song_gain(src, gain, pan_x, pan_z)
	else
		if(browser_should_defer_listener_starts())
			prime_browser_listener(M, manager, listener_targets)
			return FALSE
		if(browser_legacy_cutover_waiting_for_boundary())
			prime_browser_listener(M, manager, listener_targets)
			return FALSE
		if(manager.start_song(src, elapsed_seconds, gain, pan_x, pan_z))
			terminate_sound_mob(M)
			browser_preserved_note_listeners -= M
			browser_active_listeners[C] = M
		else if(!had_listener_record)
			browser_active_listeners -= C
	return TRUE

/datum/song/proc/sync_all_browser_listeners()
	if(!browser_timeline_json)
		clear_browser_tracking()
		return
	var/list/listener_targets = get_browser_listener_targets()
	var/list/sync_targets = listener_targets.Copy()
	for(var/client/C as anything in browser_active_listeners.Copy())
		var/mob/M = get_browser_active_listener_mob(C)
		if(!M || (M in sync_targets))
			continue
		sync_targets += M
	for(var/mob/M as anything in sync_targets)
		sync_browser_listener(M, listener_targets)

/datum/song/proc/browser_stop_listener(mob/M, drop_song = FALSE, preserve_active_notes = FALSE)
	if(!M?.client)
		unregister_browser_listener_tracking(M)
		browser_preserved_note_listeners -= M
		return
	var/client/C = M.client
	var/mob/active_mob = get_browser_active_listener_mob(C)
	if(active_mob && active_mob != M)
		return
	var/datum/instrument_audio_manager/manager = C.instrument_audio
	if(!active_mob)
		browser_preserved_note_listeners -= M
		if(manager?.song_has_state(src))
			manager.drop_song(src, preserve_active_notes)
		return
	if(drop_song)
		manager?.drop_song(src, preserve_active_notes)
	else
		manager?.stop_song(src, preserve_active_notes)
	if(preserve_active_notes)
		if(!(active_mob in browser_preserved_note_listeners))
			browser_preserved_note_listeners += active_mob
	else
		browser_preserved_note_listeners -= active_mob
	browser_active_listeners -= C

/datum/song/proc/clear_browser_listener_client(client/C)
	if(!C)
		return FALSE
	var/mob/active_mob = browser_active_listeners[C]
	var/mob/current_mob = C.mob
	var/cleared = !!active_mob
	if(current_mob in browser_tracked_listeners)
		cleared = TRUE
	browser_active_listeners -= C
	if(active_mob)
		browser_preserved_note_listeners -= active_mob
		unregister_browser_listener_tracking(active_mob)
	if(current_mob && current_mob != active_mob)
		browser_preserved_note_listeners -= current_mob
		unregister_browser_listener_tracking(current_mob)
	return cleared

/datum/song/proc/stop_browser_audio(preserve_active_notes = FALSE)
	for(var/mob/M as anything in get_browser_registered_listeners())
		browser_stop_listener(M, TRUE, preserve_active_notes)
	clear_browser_tracking()

/datum/song/proc/browser_hearcheck_update(list/old, list/exited)
	if(!browser_timeline_json)
		clear_browser_tracking()
		return
	update_browser_source_tracking()
	var/list/listener_targets = get_browser_listener_targets()
	for(var/mob/M as anything in exited)
		if(M in listener_targets)
			continue
		browser_stop_listener(M)
		unregister_browser_listener_tracking(M)
	var/list/sync_targets = listener_targets.Copy()
	for(var/client/C as anything in browser_active_listeners.Copy())
		var/mob/M = get_browser_active_listener_mob(C)
		if(!M || (M in sync_targets))
			continue
		sync_targets += M
	for(var/mob/M as anything in sync_targets)
		sync_browser_listener(M, listener_targets)

/datum/song/proc/update_browser_source_tracking()
	var/list/new_sources = get_browser_source_targets()
	for(var/atom/movable/source as anything in browser_tracked_sources.Copy())
		if(!(source in new_sources))
			UnregisterSignal(source, COMSIG_MOVABLE_MOVED)
			browser_tracked_sources -= source
	for(var/atom/movable/source as anything in new_sources)
		if(!(source in browser_tracked_sources))
			RegisterSignal(source, COMSIG_MOVABLE_MOVED, PROC_REF(on_browser_source_moved), TRUE)
			browser_tracked_sources += source

/datum/song/proc/register_browser_listener_tracking(mob/M)
	if(!M || (M in browser_tracked_listeners))
		return
	RegisterSignal(M, COMSIG_MOVABLE_MOVED, PROC_REF(on_browser_listener_moved), TRUE)
	browser_tracked_listeners += M

/datum/song/proc/unregister_browser_listener_tracking(mob/M)
	if(!M || !(M in browser_tracked_listeners))
		return
	UnregisterSignal(M, COMSIG_MOVABLE_MOVED)
	browser_tracked_listeners -= M

/datum/song/proc/clear_browser_tracking()
	for(var/mob/M as anything in browser_tracked_listeners.Copy())
		UnregisterSignal(M, COMSIG_MOVABLE_MOVED)
	browser_tracked_listeners.Cut()
	for(var/atom/movable/source as anything in browser_tracked_sources.Copy())
		UnregisterSignal(source, COMSIG_MOVABLE_MOVED)
	browser_tracked_sources.Cut()
	browser_active_listeners.Cut()

/datum/song/proc/on_browser_source_moved(atom/movable/source, atom/old_loc, direction, forced, movetime)
	SIGNAL_HANDLER
	if(!playing)
		return
	if(browser_resync_suspended)
		do_hearcheck()
		return
	do_hearcheck()
	sync_all_browser_listeners()

/datum/song/proc/on_browser_listener_moved(atom/movable/source, atom/old_loc, direction, forced, movetime)
	SIGNAL_HANDLER
	if(!playing)
		return
	var/mob/M = source
	var/turf/source_turf = get_turf(parent)
	var/turf/listener_turf = get_turf(M)
	if(!istype(M))
		return
	if(browser_resync_suspended)
		do_hearcheck()
		return
	if(!source_turf || !listener_turf || !browser_listener_in_targets(M))
		browser_stop_listener(M)
		return
	sync_browser_listener(M)

#undef BROWSER_INSTRUMENT_DECAY_NONE
#undef BROWSER_INSTRUMENT_DECAY_LINEAR
#undef BROWSER_INSTRUMENT_DECAY_EXPONENTIAL
