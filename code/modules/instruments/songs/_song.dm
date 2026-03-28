#define MUSICIAN_HEARCHECK_MINDELAY 4
#define MUSIC_MAXLINES 1000
#define MUSIC_MAXLINECHARS 300
// RS Add Start: Midi support (Lira, March 2026)
#define INSTRUMENT_PLAYBACK_SOURCE_NOTES "notes"
#define INSTRUMENT_PLAYBACK_SOURCE_UPLOADED_MIDI "uploaded_midi"
#define INSTRUMENT_UPLOADED_MIDI_PRIMING_LEAD 1 SECOND
#define INSTRUMENT_UPLOADED_MIDI_READY_TIMEOUT 5 SECONDS
// RS Add End

/**
 * # Song datum
 *
 * These are the actual backend behind instruments.
 * They attach to an atom and provide the editor + playback functionality.
 */

////////////////////////////////////////////////////////////////////////////////////
//Updated by Lira for Rogue Star August 2025 to support forming synchronized bands//
////////////////////////////////////////////////////////////////////////////////////
//Updated by Lira for Rogue Star March 2026 for browser-based instrument audio//////
////////////////////////////////////////////////////////////////////////////////////

/datum/song
	/// Name of the song
	var/name = "Untitled"

	/// The atom we're attached to/playing from
	var/atom/parent

	/// Our song lines
	var/list/lines

	/// delay between notes in deciseconds
	var/tempo = 5

	/// How far we can be heard
	var/instrument_range = 15

	/// Are we currently playing?
	var/playing = FALSE

	/// Are we currently editing?
	var/editing = TRUE
	/// Is the help screen open?
	var/help = FALSE

	/// Repeats left
	var/repeat = 0
	/// RS Add: Browser-based instrument audio (Lira, March 2026)
	var/repeats_left = 0
	/// Maximum times we can repeat
	var/max_repeats = 10

	/// Our volume
	var/volume = 35
	/// Max volume
	var/max_volume = 75
	/// Min volume - This is so someone doesn't decide it's funny to set it to 0 and play invisible songs.
	var/min_volume = 1

	/// What instruments our built in picker can use. The picker won't show unless this is longer than one.
	var/list/allowed_instrument_ids = list("r3grand")

	// RS Add Start: Midi support (Lira, March 2026)
	var/playback_source = INSTRUMENT_PLAYBACK_SOURCE_NOTES
	var/uploaded_midi_name
	var/uploaded_midi_resource
	var/uploaded_midi_alias
	var/uploaded_midi_duration_ds = 0
	var/uploaded_midi_serial = 0
	var/uploaded_midi_ready_confirmed = FALSE
	var/uploaded_midi_waiting_for_initial_ready = FALSE
	// RS Add End

	//////////// Cached instrument variables /////////////
	/// Instrument we are currently using
	var/datum/instrument/using_instrument
	/// Cached legacy ext for legacy instruments
	var/cached_legacy_ext
	/// Cached legacy dir for legacy instruments
	var/cached_legacy_dir
	/// Cached list of samples, referenced directly from the instrument for synthesized instruments
	var/list/cached_samples
	/// Are we operating in legacy mode (so if the instrument is a legacy instrument)
	var/legacy = FALSE
	//////////////////////////////////////////////////////

	/////////////////// Playing variables ////////////////
	/**
	  * Build by compile_chords()
	  * Must be rebuilt on instrument switch.
	  * Compilation happens when we start playing and is cleared after we finish playing.
	  * Format: list of chord lists, with chordlists having (key1, key2, key3, tempodiv)
	  */
	var/list/compiled_chords
	/// Current section of a long chord we're on, so we don't need to make a billion chords, one for every unit ticklag.
	var/elapsed_delay
	/// Amount of delay to wait before playing the next chord
	var/delay_by
	/// Current chord we're on.
	var/current_chord
	/// Channel as text = current volume percentage but it's 0 to 100 instead of 0 to 1.
	var/list/channels_playing = list()
	/// List of channels that aren't being used, as text. This is to prevent unnecessary freeing and reallocations from SSsounds/SSinstruments.
	var/list/channels_idle = list()
	/// Person playing us
	var/mob/user_playing

	// RS Add Start: Browser-based instrument audio (Lira, March 2026)
	var/band_active_chord_index = 0
	var/band_active_chord_started_at = 0
	var/band_active_chord_duration_ds = 0
	var/list/channel_playback_data = list()
	var/list/synth_fallback_listeners = list()
	var/list/browser_preserved_note_listeners = list()
	var/playback_generation = 0
	// RS Add End

	//////////////////////////////////////////////////////

	/// Last world.time we checked for who can hear us
	var/last_hearcheck = 0
	/// The list of mobs that can hear us
	var/list/hearing_mobs

	// RS Add Start: Browser-based instrument audio (Lira, March 2026)
	var/browser_timeline_json
	var/browser_timeline_key
	var/browser_timeline_build_serial = 0
	var/browser_timeline_building = FALSE
	var/browser_timeline_uploaded_midi = FALSE
	var/list/browser_sample_manifest = list()
	var/browser_timeline_duration_ds = 0
	var/browser_playback_start_time = 0
	var/browser_listener_launch_time = 0
	var/browser_timeline_start_chord_index = 1
	var/browser_timeline_repeats_after_start = 0
	var/browser_timeline_initial_time_ds = 0
	var/list/browser_active_listeners = list()
	var/list/browser_tracked_listeners = list()
	var/list/browser_tracked_sources = list()
	var/browser_resync_suspended = FALSE
	// RS Add End

	/// If this is enabled, some things won't be strictly cleared when they usually are (liked compiled_chords on play stop)
	var/debug_mode = FALSE
	/// Max sound channels to occupy
	var/max_sound_channels = CHANNELS_PER_INSTRUMENT
	/// Current channels, so we can save a length() call.
	var/using_sound_channels = 0
	/// Last channel to play. text. || RS Edit: Advanced synth (Lira, March 2026)
	var/list/held_synth_channels_by_layer = list()
	/// Should we not decay our last played note?
	var/full_sustain_held_note = TRUE

	/////////////////////// DO NOT TOUCH THESE ///////////////////
	var/octave_min = INSTRUMENT_MIN_OCTAVE
	var/octave_max = INSTRUMENT_MAX_OCTAVE
	var/key_min = INSTRUMENT_MIN_KEY
	var/key_max = INSTRUMENT_MAX_KEY
	var/static/list/note_offset_lookup = list(9, 11, 0, 2, 4, 5, 7)
	var/static/list/accent_lookup = list("b" = -1, "s" = 1, "#" = 1, "n" = 0)
	//////////////////////////////////////////////////////////////

	///////////// !!FUN!! - Only works in synthesized mode! /////////////////
	/// Note numbers to shift.
	var/note_shift = 0
	var/note_shift_min = -100
	var/note_shift_max = 100
	var/can_noteshift = TRUE
	/// The kind of sustain we're using
	var/sustain_mode = SUSTAIN_LINEAR
	/// When a note is considered dead if it is below this in volume
	var/sustain_dropoff_volume = 0
	/// Total duration of linear sustain for 100 volume note to get to SUSTAIN_DROPOFF
	var/sustain_linear_duration = 5
	/// Exponential sustain dropoff rate per decisecond
	var/sustain_exponential_dropoff = 1.4
	////////// DO NOT DIRECTLY SET THESE!
	/// Do not directly set, use update_sustain()
	var/cached_linear_dropoff = 10
	/// Do not directly set, use update_sustain()
	var/cached_exponential_dropoff = 1.045
	/////////////////////////////////////////////////////////////////////////

	//RS Add: Visual cue (Lira, August 2025)
	/// Last world.time we spawned a floating note visual
	var/last_note_fx_time = 0
	/// Interval in deciseconds between note visuals
	var/note_fx_interval_ds = 20

	//RS Add: Band sync (Lira, August 2025)
	/// If following, points to the leader's song datum
	var/datum/song/band_leader
	/// If leader, list of follower song datums
	var/list/datum/song/band_followers
	/// Optional override for sync radius (tiles); defaults to BAND_SYNC_RANGE
	var/band_range = BAND_SYNC_RANGE
	/// Optional per-instrument sync delay in deciseconds (applied when following in a band)
	var/band_delay_ds = 0
	/// If enabled, follower auto-starts and auto-resumes with the leader
	var/band_autoplay = TRUE
	/// Set true when the user manually clicked Stop; prevents auto-resume until they Play again
	var/band_paused_manually = FALSE
	/// Suppresses autoplay retries after a failed follower start until readiness/config changes (Lira, March 2026)
	var/band_autoplay_start_failed = FALSE
	/// Browser-based instrument audio (Lira, March 2026)
	var/band_browser_resync_pending = FALSE

	//RS Add: Note range filter (Lira, August 2025)
	/// Enable/disable note range filter per performer
	var/note_filter_enabled = FALSE
	/// Inclusive lower bound (0-127)
	var/note_filter_min = INSTRUMENT_MIN_KEY
	/// Inclusive upper bound (0-127)
	var/note_filter_max = INSTRUMENT_MAX_KEY

/datum/song/New(atom/parent, list/instrument_ids, new_range)
	SSinstruments.on_song_new(src)
	lines = list()
	tempo = sanitize_tempo(tempo)
	src.parent = parent
	if(instrument_ids)
		allowed_instrument_ids = islist(instrument_ids)? instrument_ids : list(instrument_ids)
	if(length(allowed_instrument_ids))
		set_instrument(allowed_instrument_ids[1])
	hearing_mobs = list()
	volume = clamp(volume, min_volume, max_volume)
	update_sustain()
	if(new_range)
		instrument_range = new_range
	band_followers = list() //RS Edit: Initialize band followers (Lira, August 2025)

/datum/song/Destroy()
	stop_playing()
	SSinstruments.on_song_del(src)
	lines = null
	if(using_instrument)
		using_instrument.songs_using -= src
		using_instrument = null
	allowed_instrument_ids = null
	parent = null
	band_followers = null //RS Edit: Destory the followers (Lira, August 2025)
	band_leader = null //RS Edit: Destory the followers (Lira, August 2025)
	return ..()

// RS Add: Advanced synth (Lira, March 2026)
/datum/song/proc/handle_destroyed_instrument(datum/instrument/I)
	if(I && (using_instrument == I))
		set_instrument(null)

// RS Add: Advanced synth (Lira, March 2026)
/datum/song/proc/get_max_sound_channels()
	return max_sound_channels

/**
 * Checks and stores which mobs can hear us. Terminates sounds for mobs that leave our range.
 */
// RS Edit: Track browser-backed listener enter and exit state during hearchecks (Lira, March 2026)
/datum/song/proc/do_hearcheck()
	last_hearcheck = world.time
	var/list/old = hearing_mobs.Copy()
	for(var/mob/M as anything in old)
		if(!M)
			old -= M
	hearing_mobs.len = 0
	var/turf/source = get_turf(parent)
	var/list/in_range = get_mobs_and_objs_in_view_fast(source, instrument_range, remote_ghosts = FALSE)
	for(var/mob/M in in_range["mobs"])
		if(!M)
			continue
		hearing_mobs[M] = get_dist(M, source)
	var/list/exited = old - hearing_mobs
	for(var/mob/M as anything in exited)
		if(!M)
			continue
		terminate_sound_mob(M)
		synth_fallback_listeners -= M
		browser_preserved_note_listeners -= M
	browser_hearcheck_update(old, exited)

/**
 * Sets our instrument, caching anything necessary for faster accessing. Accepts an ID, typepath, or instantiated instrument datum.
 */
// RS Edit: Browser-based instrument audio (Lira, March 2026)
/datum/song/proc/set_instrument(datum/instrument/I)
	terminate_all_sounds()
	var/old_legacy
	if(using_instrument)
		using_instrument.songs_using -= src
		old_legacy = (using_instrument.instrument_flags & INSTRUMENT_LEGACY)
	using_instrument = null
	cached_samples = null
	cached_legacy_ext = null
	cached_legacy_dir = null
	legacy = null
	if(istext(I) || ispath(I))
		I = SSinstruments.instrument_data[I]
	if(istype(I))
		using_instrument = I
		I.songs_using += src
		var/instrument_legacy = (I.instrument_flags & INSTRUMENT_LEGACY)
		if(instrument_legacy)
			cached_legacy_ext = I.legacy_instrument_ext
			cached_legacy_dir = I.legacy_instrument_path
			legacy = TRUE
		else
			cached_samples = I.samples
			legacy = FALSE
		if(isnull(old_legacy) || (old_legacy != instrument_legacy))
			if(playing)
				compile_chords()
	clear_band_autoplay_start_failure()
	if(playing)
		refresh_browser_playback(TRUE)

/**
 * Attempts to start playing our song.
 */
// RS Edit: Browser-based instrument audio (Lira, March 2026)
/datum/song/proc/start_playing(mob/user)
	if(playing)
		return
	if(!using_instrument?.ready())
		to_chat(user, "<span class='warning'>An error has occurred with [src]. Please reset the instrument.</span>")
		return
	if(band_is_follower() && !(band_leader?.playing))
		to_chat(user, "<span class='warning'>Band leader is not currently playing; no active song to sync.</span>")
		return
	var/datum/song/active_uploaded_midi_source = get_active_uploaded_midi_source_song()
	if(active_uploaded_midi_source)
		if(!uploaded_midi_uses_selected_instrument())
			if(active_uploaded_midi_source == src)
				to_chat(user, "<span class='warning'>Uploaded MIDI currently only works with browser-playable synth instruments.</span>")
			else
				to_chat(user, "<span class='warning'>Your current instrument cannot play the band leader's uploaded MIDI.</span>")
			return
		if(active_uploaded_midi_source == src)
			if(!user?.client?.instrument_audio?.supports_browser_audio())
				to_chat(user, "<span class='warning'>Uploaded MIDI playback requires browser audio support on your client.</span>")
				return
			if(!user.client.is_preference_enabled(/datum/client_preference/instrument_toggle))
				to_chat(user, "<span class='warning'>Enable instrument audio in your client preferences before playing uploaded MIDI.</span>")
				return
		band_paused_manually = FALSE
		clear_band_autoplay_start_failure()
		var/playback_start_time = world.time
		if(active_uploaded_midi_source == src && should_delay_uploaded_midi_playback_for_listeners(user))
			playback_start_time += INSTRUMENT_UPLOADED_MIDI_PRIMING_LEAD
		if(band_is_follower() && band_leader?.playing)
			playback_start_time = band_leader.browser_playback_start_time || world.time
		if(!begin_playback(user, playback_start_time))
			return
		if(debug_mode)
			report_playback_debug(user)
		if(active_uploaded_midi_source == src)
			log_uploaded_midi_action(user, "played", uploaded_midi_name)
		if(band_is_leader())
			band_start_followers(user)
		else if(band_is_follower() && band_leader?.playing)
			request_band_browser_resync()
		return
	band_paused_manually = FALSE //RS Add: User explicitly started playback; clear any manual pause state
	clear_band_autoplay_start_failure()
	if(band_is_follower() && band_leader?.playing) //RS Add: If we're a band follower and the leader is currently playing, mirror the leader's lines and tempo so chord indices align (Lira, August 2025)
		lines = band_leader.lines?.Copy() || list()
		tempo = band_leader.tempo
		repeat = band_leader.repeat
	compile_chords()
	if(!length(compiled_chords))
		to_chat(user, "<span class='warning'>Song is empty.</span>")
		return
	var/playback_start_time = world.time
	if(band_is_follower() && band_leader?.playing)
		playback_start_time = band_leader.browser_playback_start_time || world.time
	if(!begin_playback(user, playback_start_time))
		return
	if(debug_mode)
		report_playback_debug(user)

	//RS Add Start: Band playing (Lira, August 2025)
	//If we're a band leader with selected followers, start them now
	if(band_is_leader())
		band_start_followers(user)
	//If we just started as a follower while leader is mid-song, immediately sync by playing the leader's current chord so we "catch up".
	else if(band_is_follower() && band_leader?.playing)
		band_sync_join_current_chord(band_leader)
		request_band_browser_resync()
	//RS Add End

/**
 * Stops playing, terminating all sounds if in synthesized mode. Clears hearing_mobs.
 */
// RS Edit: Browser-based instrument audio (Lira, March 2026)
/datum/song/proc/stop_playing(keep_band = FALSE) //RS Edit: End band by default (Lira, August 2025)
	if(!playing)
		return
	playing = FALSE
	if(!debug_mode)
		compiled_chords = null
	STOP_PROCESSING(SSinstruments, src)
	SEND_SIGNAL(parent, COMSIG_SONG_END)
	terminate_all_sounds(TRUE)
	stop_browser_audio(legacy)
	browser_preserved_note_listeners.Cut()
	hearing_mobs.len = 0
	user_playing = null
	repeats_left = 0
	uploaded_midi_ready_confirmed = FALSE
	uploaded_midi_waiting_for_initial_ready = FALSE
	browser_timeline_build_serial++
	browser_timeline_building = FALSE
	browser_timeline_uploaded_midi = FALSE
	browser_playback_start_time = 0
	browser_listener_launch_time = 0
	browser_timeline_duration_ds = 0
	browser_timeline_start_chord_index = 1
	browser_timeline_repeats_after_start = 0
	browser_timeline_initial_time_ds = 0
	band_active_chord_index = 0
	band_active_chord_started_at = 0
	band_active_chord_duration_ds = 0
	band_browser_resync_pending = FALSE
	browser_resync_suspended = FALSE
	browser_timeline_json = null
	browser_timeline_key = null
	browser_sample_manifest.Cut()
	//RS Add Start: Band stop playing (Lira, August 2025)
	if(band_leader == src)
		if(using_uploaded_midi_playback() && !keep_band)
			band_finish_uploaded_midi_followers_after_leader_stop()
		else
			band_stop_followers_playback()
	if(!keep_band && band_is_follower())
		band_leave()
	//RS Add End

// RS Add: Browser-based instrument audio (Lira, March 2026)
/datum/song/proc/reset_active_playback_cursor(playback_start_time = world.time)
	if(!playing)
		return FALSE
	playback_generation++
	elapsed_delay = 0
	delay_by = 0
	current_chord = length(compiled_chords) ? 1 : 0
	repeats_left = repeat
	band_active_chord_index = 0
	band_active_chord_started_at = 0
	band_active_chord_duration_ds = 0
	uploaded_midi_waiting_for_initial_ready = FALSE
	browser_playback_start_time = playback_start_time
	browser_listener_launch_time = playback_start_time
	browser_preserved_note_listeners.Cut()
	return TRUE

// RS Add: Browser-based instrument audio (Lira, March 2026)
/datum/song/proc/restart_active_playback(playback_start_time = world.time)
	if(!playing)
		return FALSE
	terminate_all_sounds(TRUE, get_browser_listener_targets())
	stop_browser_audio()
	return reset_active_playback_cursor(playback_start_time)

// RS Add: Midi support (Lira, March 2026)
/datum/song/proc/refresh_uploaded_midi_listener_sync()
	if(!playing || !get_active_uploaded_midi_source_song())
		return FALSE
	var/listener_targets_changed = FALSE
	if(band_is_leader())
		for(var/datum/song/S as anything in band_followers.Copy())
			if(QDELETED(S) || QDELETED(S.parent))
				band_followers -= S
				continue
			if(!S.band_ready_for(src))
				continue
			if((world.time - MUSICIAN_HEARCHECK_MINDELAY) > S.last_hearcheck)
				S.do_hearcheck()
				listener_targets_changed = TRUE
	if((world.time - MUSICIAN_HEARCHECK_MINDELAY) > last_hearcheck)
		do_hearcheck()
		listener_targets_changed = TRUE
	if(listener_targets_changed)
		sync_all_browser_listeners()
	return listener_targets_changed

/**
 * Processes our song.
 */
// RS Edit: Browser-based instrument audio (Lira, March 2026)
/datum/song/proc/process_song(wait)
	if(playing) //RS Add: Visual cue when playing (Lira, August 2025)
		//Throttle to once every note_fx_interval_ds deciseconds
		if(world.time - last_note_fx_time >= note_fx_interval_ds)
			var/atom/anchor = get_holder() || parent
			if(anchor)
				//Show a musical note above the performer/instrument to viewers in instrument range
//				var/note = pick("♪", "♫")	//RS EDIT START
//				anchor.runechat_message(note, instrument_range, FALSE, list("musicnote", "black_outline"))
				new /obj/particle_emitter/music(get_turf(anchor))	//RS EDIT END
			last_note_fx_time = world.time

	var/datum/song/active_uploaded_midi_source = get_active_uploaded_midi_source_song()
	if(active_uploaded_midi_source)
		if(!uploaded_midi_uses_selected_instrument())
			stop_playing(TRUE)
			return
		if(should_stop_playing(user_playing))
			stop_playing(active_uploaded_midi_source != src)
			return
		refresh_uploaded_midi_listener_sync()
		if(uploaded_midi_ready_timed_out())
			stop_playing(TRUE)
			return
		if(browser_timeline_duration_ds > 0 && browser_playback_start_time > 0 && world.time >= (browser_playback_start_time + browser_timeline_duration_ds))
			stop_playing(active_uploaded_midi_source != src)
			return
		if(active_uploaded_midi_source != src)
			return
		if(using_uploaded_midi_playback() && band_is_leader())
			band_manage_uploaded_midi_followers()
		return

	if(band_is_follower()) //RS Add: Followers don't advance their own chord progression; leader drives playback (Lira, August 2025)
		return

	if(!length(compiled_chords) || should_stop_playing(user_playing))
		stop_playing()
		return
	var/list/chord = compiled_chords[current_chord]
	if(++elapsed_delay >= delay_by)
		var/chord_duration = tempodiv_to_delay(chord[length(chord)])
		var/chord_duration_ds = chord_duration * get_instrument_time_step()
		var/browser_resync_resume_delay = 0
		//RS Add Start: Band logic (Lira, August 2025)
		var/list/targets_override
		if(band_is_leader())
			//Build a union of hearing mobs from leader and ready followers
			if((world.time - MUSICIAN_HEARCHECK_MINDELAY) > last_hearcheck)
				do_hearcheck()
			targets_override = hearing_mobs.Copy()
			for(var/datum/song/S as anything in band_followers)
				if(!S.band_ready_for(src))
					continue
				if((world.time - MUSICIAN_HEARCHECK_MINDELAY) > S.last_hearcheck)
					S.do_hearcheck()
				targets_override |= S.hearing_mobs
			if(band_browser_resync_pending)
				browser_resync_resume_delay = chord_duration_ds + band_prepare_browser_resync()
				band_browser_resync_pending = FALSE
		play_chord(chord, targets_override)
		band_active_chord_index = current_chord
		band_active_chord_started_at = world.time
		band_active_chord_duration_ds = chord_duration_ds
		//Broadcast this chord to followers (if any)
		if(band_is_leader())
			band_broadcast_play(current_chord)
		if(browser_resync_resume_delay)
			addtimer(CALLBACK(src, PROC_REF(band_finish_browser_resync)), max(get_instrument_time_step(), browser_resync_resume_delay))
		//RS Add End
		elapsed_delay = 0
		delay_by = chord_duration
		current_chord++
		if(current_chord > length(compiled_chords))
			if(repeats_left)
				repeats_left--
				current_chord = 1
				return
			else
				stop_playing()
				return

// RS Add: Base timing on SSinstruments cadence to decouple tempo from FPS (Lira, November 2025)
/datum/song/proc/get_instrument_time_step()
	return SSinstruments?.wait || world.tick_lag

/**
 * Converts a tempodiv to ticks to elapse before playing the next chord, taking into account our tempo.
 */
/datum/song/proc/tempodiv_to_delay(tempodiv)
	if(!tempodiv)
		tempodiv = 1 // no division by 0. some song converters tend to use 0 for when it wants to have no div, for whatever reason.
	// RS Edit Start: Remove FPS dependency (Lira, November 2025)
	var/time_step = get_instrument_time_step()
	return max(1, round((tempo/tempodiv) / time_step, 1))
	// RS Edit End

/**
 * Compiles chords.
 */
// RS Edit: Browser-based instrument audio (Lira, March 2026)
/datum/song/proc/compile_chords()
	compiled_chords = null
	legacy ? compile_legacy() : compile_synthesized()

/**
 * Plays a chord.
 */
// RS Edit: Browser-based instrument audio (Lira, March 2026)
/datum/song/proc/play_chord(list/chord, list/targets_override) //RS Edit: Adds band override (Lira, August 2025)
	if(!islist(targets_override) && ((world.time - MUSICIAN_HEARCHECK_MINDELAY) > last_hearcheck))
		do_hearcheck()
	if(legacy && browser_timeline_json)
		sync_all_browser_listeners()
	var/list/current_targets = islist(targets_override) ? targets_override : hearing_mobs
	var/list/fallback_targets = get_note_fallback_targets(targets_override)
	var/list/synth_instruments = legacy ? null : get_synth_playback_instruments()
	if(!length(fallback_targets))
		if(!legacy && length(channels_playing))
			terminate_all_sounds(FALSE, islist(targets_override) ? targets_override : get_browser_listener_targets())
		if(!legacy && length(synth_instruments) && synth_should_track_browser_fallback_state(current_targets))
			for(var/i in 1 to (length(chord) - 1))
				for(var/datum/instrument/I as anything in synth_instruments)
					register_synth_channel_state(chord[i], I)
		return
	// last value is timing information
	for(var/i in 1 to (length(chord) - 1))
		if(legacy)
			playkey_legacy(chord[i][1], chord[i][2], chord[i][3], user_playing, fallback_targets) //RS Edit: Adds band override (Lira, August 2025)
			continue
		for(var/datum/instrument/I as anything in synth_instruments)
			playkey_synth(chord[i], user_playing, fallback_targets, I) //RS Edit: Adds band override (Lira, August 2025)

/**
 * Checks if we should halt playback.
 */
/datum/song/proc/should_stop_playing(mob/user)
	return QDELETED(parent) || !using_instrument || !playing

/**
 * Sanitizes tempo to a value that makes sense and fits the current instrument processing interval.
 */
/datum/song/proc/sanitize_tempo(new_tempo)
	new_tempo = abs(new_tempo)
	// RS Edit Start: Remove FPS dependency (Lira, November 2025)
	var/time_step = get_instrument_time_step()
	return clamp(round(new_tempo, time_step), time_step, 5 SECONDS)
	// RS Edit End

/**
 * Gets our beats per minute based on our tempo.
 */
/datum/song/proc/get_bpm()
	return 600 / tempo

// RS Add: Browser-based instrument audio (Lira, March 2026)
/datum/song/proc/get_repeats_left()
	if(band_is_follower() && band_leader?.playing)
		return band_leader.get_repeats_left()
	return repeats_left

/**
 * Sets our tempo from a beats-per-minute, sanitizing it to a valid number first.
 */
 // RS Edit: Browser-based instrument audio (Lira, March 2026)
/datum/song/proc/set_bpm(bpm)
	tempo = sanitize_tempo(600 / bpm)
	refresh_browser_playback(TRUE)

// RS Add: Browser-based instrument audio (Lira, March 2026)
/datum/song/proc/refresh_browser_playback(rebuild_timeline = FALSE, restart_playback = FALSE)
	if(!playing)
		return
	var/datum/song/active_uploaded_midi_source = get_active_uploaded_midi_source_song()
	if(rebuild_timeline)
		if(active_uploaded_midi_source)
			if(!uploaded_midi_uses_selected_instrument())
				stop_playing(TRUE)
				return
			reset_uploaded_midi_ready_timeout()
			var/coordinate_band_resync = band_is_leader() || band_is_follower()
			if(coordinate_band_resync)
				request_band_browser_resync()
			queue_browser_timeline_build()
			if(coordinate_band_resync)
				return
			do_hearcheck()
			sync_all_browser_listeners()
			return
		request_band_browser_resync()
		if(restart_playback)
			restart_active_playback()
		if(band_is_leader())
			band_sync_followers_for_timeline_rebuild(restart_playback)
		rebuild_browser_timeline_for_active_playback()
	do_hearcheck()
	sync_all_browser_listeners()

// RS Add: Midi support (Lira, March 2026)
/datum/song/proc/uploaded_midi_listener_supported(mob/M)
	var/datum/instrument_audio_manager/manager = M?.client?.instrument_audio
	if(!manager?.supports_browser_audio())
		return FALSE
	if(manager.owner?.mob != M)
		return FALSE
	if(!uploaded_midi_uses_selected_instrument())
		return FALSE
	if(M.ear_deaf > 0)
		return FALSE
	return M.client.is_preference_enabled(/datum/client_preference/instrument_toggle)

// RS Add: Midi support (Lira, March 2026)
/datum/song/proc/uploaded_midi_browser_ready()
	if(browser_timeline_building || !browser_timeline_json)
		return FALSE
	var/list/listener_targets = get_browser_listener_targets()
	var/current_launch_time = max(browser_playback_start_time, browser_listener_launch_time)
	for(var/mob/M as anything in listener_targets)
		var/datum/instrument_audio_manager/manager = M?.client?.instrument_audio
		if(!manager?.song_is_primed(src))
			continue
		if(!manager.browser_listener_supported(src, M))
			continue
		if(get_browser_listener_gain(M) <= 0)
			continue
		uploaded_midi_ready_confirmed = TRUE
		if(uploaded_midi_waiting_for_initial_ready && world.time < current_launch_time)
			uploaded_midi_waiting_for_initial_ready = FALSE
		return TRUE
	return FALSE

// RS Add: Midi support (Lira, March 2026)
/datum/song/proc/uploaded_midi_browser_priming()
	if(browser_timeline_building || !browser_timeline_json)
		return FALSE
	var/list/listener_targets = get_browser_listener_targets()
	for(var/mob/M as anything in listener_targets)
		var/datum/instrument_audio_manager/manager = M?.client?.instrument_audio
		if(!manager?.song_is_priming(src))
			continue
		if(!manager.browser_listener_supported(src, M))
			continue
		if(get_browser_listener_gain(M) <= 0)
			continue
		return TRUE
	return FALSE

// RS Add: Midi support (Lira, March 2026)
/datum/song/proc/reset_uploaded_midi_ready_timeout(anchor_time = world.time)
	if(!playing || !get_active_uploaded_midi_source_song())
		return FALSE
	if(!isnum(anchor_time))
		anchor_time = world.time
	uploaded_midi_ready_confirmed = FALSE
	browser_listener_launch_time = max(browser_playback_start_time, anchor_time)
	return TRUE

// RS Add: Midi support (Lira, March 2026)
/datum/song/proc/uploaded_midi_ready_timed_out()
	var/ready_timeout_anchor = browser_listener_launch_time || browser_playback_start_time
	if(ready_timeout_anchor <= 0)
		return FALSE
	if(browser_timeline_building)
		return FALSE
	if(uploaded_midi_ready_confirmed)
		return FALSE
	if(uploaded_midi_browser_ready())
		return FALSE
	if(uploaded_midi_browser_priming())
		return FALSE
	return world.time >= (ready_timeout_anchor + INSTRUMENT_UPLOADED_MIDI_READY_TIMEOUT)

// RS Add: Midi support (Lira, March 2026)
/datum/song/proc/should_delay_uploaded_midi_playback_for_listeners(mob/user)
	if(!using_uploaded_midi_playback())
		return FALSE
	if(uploaded_midi_listener_supported(user))
		return TRUE
	var/list/checked_clients = list()
	if(user?.client)
		checked_clients += user.client
	var/list/songs_to_check = list(src)
	if(band_is_leader())
		for(var/datum/song/S as anything in band_followers)
			if(!S?.band_autoplay || !S.band_ready_for(src) || !S.can_begin_playback())
				continue
			songs_to_check += S
	for(var/datum/song/S as anything in songs_to_check)
		var/turf/source = get_turf(S.parent)
		if(!source)
			continue
		var/list/in_range = get_mobs_and_objs_in_view_fast(source, S.instrument_range, remote_ghosts = FALSE)
		for(var/mob/M in in_range["mobs"])
			var/client/C = M?.client
			if(!C || (C in checked_clients))
				continue
			checked_clients += C
			if(S.uploaded_midi_listener_supported(M))
				return TRUE
	return FALSE

// RS Add: Browser-based instrument audio (Lira, March 2026)
/datum/song/proc/report_playback_debug(mob/user)
	if(!user?.client)
		return
	var/message
	if(selected_uploaded_midi_source())
		if(browser_handles_listener(user))
			message = "uploaded MIDI browser playback active on your client"
		else if(browser_timeline_building)
			message = "uploaded MIDI timeline building in the background"
		else if(browser_timeline_json)
			if(user.client.instrument_audio?.song_is_priming(src))
				message = "uploaded MIDI priming on your client; playback will start once the file and samples finish loading"
			else
				message = "uploaded MIDI prepared, but your client is not using it yet"
		else if(has_uploaded_midi())
			message = "uploaded MIDI is loaded, but browser playback is not ready on your client"
		else
			message = "no uploaded MIDI is currently loaded"
	else if(browser_handles_listener(user))
		message = "browser-backed playback active on your client"
	else if(browser_timeline_building)
		message = "browser timeline building in the background; your client is using legacy fallback until ready"
	else if(browser_timeline_json)
		if(user.client.instrument_audio?.song_is_priming(src))
			message = "browser timeline prepared and priming on your client; legacy fallback will be used until samples finish loading"
		else
			message = "browser timeline prepared, but your client is currently using legacy fallback"
	else if(using_instrument?.supports_browser_audio())
		message = "legacy fallback active; browser timeline was not prepared"
	else
		message = "legacy note-by-note fallback only"
	to_chat(user, span_notice("Instrument debug: [message]."))

/**
 * Updates the window for our users. Override down the line.
 */
/datum/song/proc/updateDialog(mob/user)
	interact(user)

/datum/song/process(wait)
	if(!playing)
		return PROCESS_KILL
	// it's expected this ticks at every instrument subsystem interval. if it lags, do not attempt to catch up.
	// RS Edit Start: Remove FPS dependency (Lira, November 2025)
	process_song(wait)
	process_decay(wait)
	// RS Edit End

/**
 * Updates our cached linear/exponential falloff stuff, saving calculations down the line.
 */
/datum/song/proc/update_sustain()
	// Exponential is easy
	cached_exponential_dropoff = sustain_exponential_dropoff
	// Linear, not so much, since it's a target duration from 100 volume rather than an exponential rate.
	var/target_duration = sustain_linear_duration
	var/volume_diff = max(0, 100 - sustain_dropoff_volume)
	var/volume_decrease_per_decisecond = volume_diff / target_duration
	cached_linear_dropoff = volume_decrease_per_decisecond

/**
 * Setter for setting output volume.
 */
/datum/song/proc/set_volume(volume)
	src.volume = clamp(volume, max(0, min_volume), min(100, max_volume))
	update_sustain()
	refresh_browser_playback() // RS Add: Browser-based instrument audio (Lira, March 2026)
	updateDialog()

/**
 * Setter for setting how low the volume has to get before a note is considered "dead" and dropped
 */
/datum/song/proc/set_dropoff_volume(volume)
	sustain_dropoff_volume = clamp(volume, INSTRUMENT_MIN_SUSTAIN_DROPOFF, 100)
	update_sustain()
	refresh_browser_playback(TRUE) // RS Add: Browser-based instrument audio (Lira, March 2026)
	updateDialog()

/**
 * Setter for setting exponential falloff factor.
 */
/datum/song/proc/set_exponential_drop_rate(drop)
	sustain_exponential_dropoff = clamp(drop, INSTRUMENT_EXP_FALLOFF_MIN, INSTRUMENT_EXP_FALLOFF_MAX)
	update_sustain()
	refresh_browser_playback(TRUE) // RS Add: Browser-based instrument audio (Lira, March 2026)
	updateDialog()

/**
 * Setter for setting linear falloff duration.
 */
/datum/song/proc/set_linear_falloff_duration(duration)
	sustain_linear_duration = clamp(duration, 0.1, INSTRUMENT_MAX_TOTAL_SUSTAIN)
	update_sustain()
	refresh_browser_playback(TRUE) // RS Add: Browser-based instrument audio (Lira, March 2026)
	updateDialog()

/datum/song/vv_edit_var(var_name, var_value)
	. = ..()
	if(.)
		switch(var_name)
			if(NAMEOF(src, volume))
				set_volume(var_value)
			if(NAMEOF(src, sustain_dropoff_volume))
				set_dropoff_volume(var_value)
			if(NAMEOF(src, sustain_exponential_dropoff))
				set_exponential_drop_rate(var_value)
			if(NAMEOF(src, sustain_linear_duration))
				set_linear_falloff_duration(var_value)

// subtype for handheld instruments, like violin
/datum/song/handheld

/datum/song/handheld/updateDialog(mob/user)
	parent.interact(user || usr)

// RS Add: Advanced synth (Lira, March 2026)
/datum/song/proc/can_begin_playback()
	return !!using_instrument?.ready()

// RS Add: Midi support (Lira, March 2026)
/datum/song/proc/selected_uploaded_midi_source()
	return playback_source == INSTRUMENT_PLAYBACK_SOURCE_UPLOADED_MIDI

// RS Add: Midi support (Lira, March 2026)
/datum/song/proc/selected_uploaded_browser_source()
	return selected_uploaded_midi_source()

// RS Add: Midi support (Lira, March 2026)
/datum/song/proc/has_uploaded_midi()
	return !!(uploaded_midi_name && uploaded_midi_resource && uploaded_midi_alias)

// RS Add: Midi support (Lira, March 2026)
/datum/song/proc/using_uploaded_midi_playback()
	return selected_uploaded_midi_source() && has_uploaded_midi()

// RS Add: Midi support (Lira, March 2026)
/datum/song/proc/get_active_uploaded_midi_source_song()
	if(band_is_follower() && band_leader)
		if(band_leader.playing && band_leader.using_uploaded_midi_playback())
			return band_leader
		if(playing && browser_timeline_uploaded_midi)
			return band_leader
		return null
	if(using_uploaded_midi_playback())
		return src
	return null

// RS Add: Midi support (Lira, March 2026)
/datum/song/proc/uploaded_midi_uses_selected_instrument()
	return !!(using_instrument && !legacy && using_instrument.supports_browser_audio())

// RS Add: Midi support (Lira, March 2026)
/datum/song/proc/can_manage_uploaded_midi(mob/user)
	if(!user?.client?.instrument_audio?.supports_browser_audio())
		return FALSE
	if(!user.client.is_preference_enabled(/datum/client_preference/instrument_toggle))
		return FALSE
	return uploaded_midi_uses_selected_instrument()

// RS Add: Midi support (Lira, March 2026)
/datum/song/proc/get_uploaded_midi_duration_seconds()
	if(uploaded_midi_duration_ds <= 0)
		return null
	return round(uploaded_midi_duration_ds / 10, 0.1)

// RS Add: Midi support (Lira, March 2026)
/datum/song/proc/get_audio_log_context()
	var/turf/T = get_turf(parent)
	if(!T)
		return "[parent] (unknown location)"
	return "[parent] at [T.x],[T.y],[T.z]"

// RS Add: Midi support (Lira, March 2026)
/datum/song/proc/log_uploaded_midi_action(mob/user, action, file_name)
	if(!action || !file_name)
		return
	var/user_text = user ? "[key_name(user)]" : "Unknown user"
	log_game("[user_text] [action] instrument MIDI '[file_name]' on [get_audio_log_context()].")

// RS Add: Midi support (Lira, March 2026)
/datum/song/proc/set_playback_source(new_source)
	if(new_source != INSTRUMENT_PLAYBACK_SOURCE_UPLOADED_MIDI)
		new_source = INSTRUMENT_PLAYBACK_SOURCE_NOTES
	else if(!has_uploaded_midi())
		return FALSE
	if(playback_source == new_source)
		return FALSE
	if(new_source == INSTRUMENT_PLAYBACK_SOURCE_NOTES)
		var/datum/song/active_uploaded_midi_source = get_active_uploaded_midi_source_song()
		if(active_uploaded_midi_source && active_uploaded_midi_source != src && band_is_follower())
			band_paused_manually = TRUE
	if(playing)
		stop_playing(TRUE)
	playback_source = new_source
	return TRUE

// RS Add: Midi support (Lira, March 2026)
/datum/song/proc/reset_browser_payload_state()
	browser_timeline_build_serial++
	browser_timeline_building = FALSE
	browser_timeline_uploaded_midi = FALSE
	browser_timeline_json = null
	browser_timeline_key = null
	browser_timeline_duration_ds = 0
	browser_sample_manifest.Cut()

// RS Add: Midi support (Lira, March 2026)
/datum/song/proc/upload_midi(uploaded_file, mob/user)
	if(!uploaded_file)
		return FALSE
	var/upload_name = "[uploaded_file]"
	var/lower_name = lowertext(upload_name)
	var/dot = findlasttext(lower_name, ".")
	var/ext = dot ? copytext(lower_name, dot) : ""
	if(ext != ".mid" && ext != ".midi")
		to_chat(user, "<span class='warning'>Only .mid and .midi uploads are supported for browser playback.</span>")
		return FALSE
	var/had_upload = has_uploaded_midi()
	var/old_name = uploaded_midi_name
	var/old_alias = uploaded_midi_alias
	var/using_uploaded_timeline = old_alias && browser_sample_manifest[old_alias]
	var/upload_hash = md5("[REF(src)]#[uploaded_midi_serial + 1]#[upload_name]")
	if(playing)
		stop_playing(TRUE)
	else if(using_uploaded_timeline)
		reset_browser_payload_state()
	uploaded_midi_serial++
	uploaded_midi_name = upload_name
	uploaded_midi_resource = uploaded_file
	uploaded_midi_alias = "instrument_upload_[upload_hash][ext]"
	uploaded_midi_duration_ds = 0
	playback_source = INSTRUMENT_PLAYBACK_SOURCE_UPLOADED_MIDI
	if(had_upload)
		log_game("[key_name(user)] replaced instrument MIDI '[old_name]' with '[upload_name]' on [get_audio_log_context()].")
	else
		log_uploaded_midi_action(user, "uploaded", upload_name)
	return TRUE

// RS Add: Midi support (Lira, March 2026)
/datum/song/proc/clear_uploaded_midi(mob/user, action = "cleared")
	var/had_upload = has_uploaded_midi()
	var/old_name = uploaded_midi_name
	var/old_alias = uploaded_midi_alias
	var/using_uploaded_timeline = old_alias && browser_sample_manifest[old_alias]
	if(playing && selected_uploaded_midi_source())
		stop_playing(TRUE)
	if(using_uploaded_timeline)
		reset_browser_payload_state()
	uploaded_midi_name = null
	uploaded_midi_resource = null
	uploaded_midi_alias = null
	uploaded_midi_duration_ds = 0
	if(selected_uploaded_midi_source())
		playback_source = INSTRUMENT_PLAYBACK_SOURCE_NOTES
	if(had_upload && action)
		log_uploaded_midi_action(user, action, old_name)
	return had_upload

// RS Add: Advanced synth (Lira, March 2026)
/datum/song/proc/clear_band_autoplay_start_failure()
	band_autoplay_start_failed = FALSE

/datum/song/handheld/should_stop_playing(mob/user)
	. = ..()
	if(.)
		return TRUE
	var/obj/item/instrument/I = parent
	return I.should_stop_playing(user)

// subtype for stationary structures, like pianos
/datum/song/stationary

/datum/song/stationary/updateDialog(mob/user)
	parent.interact(user || usr)

/datum/song/stationary/should_stop_playing(mob/user)
	. = ..()
	if(.)
		return TRUE
	var/obj/structure/musician/M = parent
	return M.should_stop_playing(user)

//RS Add Start: Band sync support procs (Lira, August 2025) || Browser-based instrument audio (Lira, March 2026)

//Returns the mob holding this instrument if handheld, or null otherwise
/datum/song/proc/get_holder()
	if(istype(parent, /obj/item))
		var/obj/item/I = parent
		if(ismob(I.loc))
			return I.loc
	return null

//Holder name if available
/datum/song/proc/get_holder_name()
	var/mob/M = get_holder()
	return M ? M.name : "(unheld)"

/datum/song/proc/get_autoplay_user(mob/fallback_user = null)
	var/mob/holder = get_holder()
	return holder || fallback_user

//Returns TRUE if follower is held and within range of the given leader
/datum/song/proc/band_ready_for(datum/song/leader)
	if(!leader || QDELETED(leader) || QDELETED(leader.parent) || QDELETED(parent))
		return FALSE
	var/mob/holder = get_holder()
	if(!holder)
		return FALSE
	var/turf/lt = get_turf(leader.parent)
	var/turf/ft = get_turf(parent)
	if(!lt || !ft)
		return FALSE
	if(get_dist(lt, ft) > leader.band_range)
		return FALSE
	if(leader.using_uploaded_midi_playback() && !uploaded_midi_uses_selected_instrument())
		return FALSE
	return TRUE

/datum/song/proc/get_band_readiness_status(datum/song/leader)
	if(!leader || QDELETED(leader) || QDELETED(leader.parent) || QDELETED(parent))
		return "Not ready"
	var/mob/holder = get_holder()
	if(!holder)
		return "Not ready (unheld)"
	var/turf/lt = get_turf(leader.parent)
	var/turf/ft = get_turf(parent)
	if(!lt || !ft || (get_dist(lt, ft) > leader.band_range))
		return "Not ready (out of range)"
	if(leader.using_uploaded_midi_playback() && !uploaded_midi_uses_selected_instrument())
		return "Not ready (incompatible instrument)"
	return "Ready"

/datum/song/proc/band_get_active_chord_state()
	if(!playing || !length(compiled_chords) || !band_active_chord_index || band_active_chord_duration_ds <= 0)
		return null
	if(band_active_chord_index < 1 || band_active_chord_index > length(compiled_chords))
		return null
	var/chord_end_time = band_active_chord_started_at + band_active_chord_duration_ds
	if(world.time >= chord_end_time)
		return null
	return list(
		"chord_index" = band_active_chord_index,
		"start_time" = band_active_chord_started_at,
		"end_time" = chord_end_time
	)

/datum/song/proc/band_sync_join_current_chord(datum/song/leader)
	if(!playing || !band_ready_for(leader))
		return FALSE
	if((world.time - MUSICIAN_HEARCHECK_MINDELAY) > leader.last_hearcheck)
		leader.do_hearcheck()
	if((world.time - MUSICIAN_HEARCHECK_MINDELAY) > last_hearcheck)
		do_hearcheck()
	current_chord = clamp(leader.current_chord, 1, length(compiled_chords))
	var/list/chord_state = leader.band_get_active_chord_state()
	if(!islist(chord_state))
		return FALSE
	var/ch_idx = clamp(chord_state["chord_index"], 1, length(compiled_chords))
	if(ch_idx > length(compiled_chords))
		return FALSE
	var/band_delay = max(0, round(band_delay_ds, get_instrument_time_step()))
	var/follower_start_time = chord_state["start_time"] + band_delay
	var/list/f_chord = compiled_chords[ch_idx]
	var/list/targets = leader.hearing_mobs?.Copy() || list()
	targets |= hearing_mobs
	var/start_delay = max(0, follower_start_time - world.time)
	var/current_playback_generation = playback_generation
	if(start_delay)
		var/list/targets_snapshot = targets.Copy()
		addtimer(CALLBACK(src, PROC_REF(play_chord_if_playing), f_chord, targets_snapshot, current_playback_generation), start_delay)
	else
		play_chord_if_playing(f_chord, targets, current_playback_generation)
	return TRUE

/datum/song/proc/request_band_browser_resync()
	if(!playing)
		return FALSE
	if(band_is_follower())
		if(band_leader?.playing)
			band_leader.band_browser_resync_pending = TRUE
			return TRUE
		return FALSE
	if(!band_is_leader())
		return FALSE
	band_browser_resync_pending = TRUE
	return TRUE

/datum/song/proc/browser_stop_active_listeners_for_resync()
	browser_resync_suspended = TRUE
	for(var/client/C as anything in browser_active_listeners.Copy())
		var/mob/M = get_browser_active_listener_mob(C)
		if(!M)
			continue
		browser_stop_listener(M, FALSE, TRUE)

/datum/song/proc/band_prepare_browser_resync()
	var/max_delay = 0
	if(playing)
		browser_stop_active_listeners_for_resync()
	for(var/datum/song/S as anything in band_followers)
		if(!S?.playing || !S.band_ready_for(src))
			continue
		S.browser_stop_active_listeners_for_resync()
		max_delay = max(max_delay, max(0, round(S.band_delay_ds, get_instrument_time_step())))
	return max_delay

/datum/song/proc/band_finish_browser_resync()
	if(!playing || !band_is_leader())
		return FALSE
	if(browser_timeline_building)
		addtimer(CALLBACK(src, PROC_REF(band_finish_browser_resync)), get_instrument_time_step())
		return FALSE
	for(var/datum/song/S as anything in band_followers)
		if(!S?.playing || !S.band_ready_for(src))
			continue
		if(S.browser_timeline_building)
			addtimer(CALLBACK(src, PROC_REF(band_finish_browser_resync)), get_instrument_time_step())
			return FALSE
	browser_resync_suspended = FALSE
	do_hearcheck()
	sync_all_browser_listeners()
	for(var/datum/song/S as anything in band_followers)
		if(!S?.playing)
			continue
		S.browser_resync_suspended = FALSE
		if(!S.band_ready_for(src))
			continue
		S.do_hearcheck()
		S.sync_all_browser_listeners()
	return TRUE

//Enable and set inclusive note range filter (0-127 keys)
/datum/song/proc/set_note_filter_bounds(low, high)
	low = clamp(round(low), INSTRUMENT_MIN_KEY, INSTRUMENT_MAX_KEY)
	high = clamp(round(high), INSTRUMENT_MIN_KEY, INSTRUMENT_MAX_KEY)
	if(high < low)
		var/tmp = low
		low = high
		high = tmp
	note_filter_min = low
	note_filter_max = high
	note_filter_enabled = TRUE
	refresh_browser_playback(TRUE)
	updateDialog()

//Disable note range filter
/datum/song/proc/clear_note_filter()
	note_filter_enabled = FALSE
	refresh_browser_playback(TRUE)
	updateDialog()

 //Plays a chord only if we are still playing
/datum/song/proc/play_chord_if_playing(list/chord, list/targets_override, expected_playback_generation = null)
	if(!playing)
		return
	if(!isnull(expected_playback_generation) && expected_playback_generation != playback_generation)
		return
	play_chord(chord, targets_override)

//Are we currently leading a band?
/datum/song/proc/band_is_leader()
	return band_leader == src && length(band_followers)

//Are we currently following a band?
/datum/song/proc/band_is_follower()
	return band_leader && band_leader != src

//Create band: set self as leader and ensure followers list exists
/datum/song/proc/band_create()
	band_leader = src
	if(!islist(band_followers))
		band_followers = list()


//Invite nearby held instruments to join our band
/datum/song/proc/band_invite_nearby(mob/requester)
    if(band_leader != src)
        band_create()
    var/turf/src_turf = get_turf(parent)
    var/mob/holder
    var/req_name
    var/instr_name
    var/msg
    var/ans
    for(var/datum/song/S as anything in SSinstruments.songs)
        if(S == src)
            continue
        if(QDELETED(S) || QDELETED(S.parent))
            continue
        if(S.band_leader || S.band_is_follower())
            continue
        var/turf/other = get_turf(S.parent)
        if(!other || get_dist(src_turf, other) > band_range)
            continue
        holder = S.get_holder()
        if(!holder || !holder.client)
            continue
        req_name = requester ? requester.name : "Someone"
        instr_name = (S.parent && S.parent.name) ? S.parent.name : "instrument"
        msg = "[req_name] wants to sync your [instr_name] with their band. Accept?"
        ans = tgui_alert(holder, msg, "Band Invite", list("Accept", "Decline"))
        if(ans == "Accept")
            S.band_join(src)
            to_chat(holder, "<span class='notice'>You joined [requester?.name]'s band.</span>")
            to_chat(requester, "<span class='notice'>[holder.name] joined your band.</span>")

/datum/song/proc/band_manage_uploaded_midi_followers()
	if(!band_is_leader() || !using_uploaded_midi_playback())
		return FALSE
	var/leader_listener_sync_needed = band_browser_resync_pending
	var/resync_followers = band_browser_resync_pending
	for(var/datum/song/S as anything in band_followers.Copy())
		if(QDELETED(S) || QDELETED(S.parent))
			band_followers -= S
			continue
		if(!S.band_ready_for(src))
			if(S.playing)
				S.stop_playing(TRUE)
				leader_listener_sync_needed = TRUE
			S.band_paused_manually = FALSE
			S.clear_band_autoplay_start_failure()
			continue
		if(!S.playing && S.band_autoplay && !S.band_paused_manually && !S.band_autoplay_start_failed)
			if(!S.begin_playback(S.get_autoplay_user(user_playing), browser_playback_start_time))
				S.band_autoplay_start_failed = TRUE
				continue
			leader_listener_sync_needed = TRUE
			resync_followers = TRUE
	if((leader_listener_sync_needed || resync_followers) && uploaded_midi_band_resync_waiting_on_builds())
		band_browser_resync_pending = TRUE
		return TRUE
	if(leader_listener_sync_needed || resync_followers)
		band_browser_resync_pending = FALSE
	var/list/resync_targets
	var/resync_time = 0
	if(resync_followers)
		resync_targets = list()
		for(var/datum/song/S as anything in band_followers)
			if(!S?.playing || !S.band_ready_for(src))
				continue
			resync_targets += S
	if(leader_listener_sync_needed || length(resync_targets))
		if(!islist(resync_targets))
			resync_targets = list()
		resync_time = world.time + get_instrument_time_step()
		relaunch_browser_listeners(resync_time)
	if(length(resync_targets))
		if(!resync_time)
			resync_time = world.time + get_instrument_time_step()
		for(var/datum/song/S as anything in resync_targets)
			S.relaunch_browser_listeners(resync_time)
	return TRUE

/datum/song/proc/uploaded_midi_band_resync_waiting_on_builds()
	if(browser_timeline_building)
		return TRUE
	for(var/datum/song/S as anything in band_followers)
		if(!S?.playing || !S.band_ready_for(src))
			continue
		if(S.browser_timeline_building)
			return TRUE
	return FALSE

/datum/song/proc/relaunch_browser_listeners(resume_time = null)
	if(!playing || !browser_timeline_json)
		return FALSE
	if(!isnum(resume_time))
		resume_time = world.time + get_instrument_time_step()
	resume_time = max(world.time + get_instrument_time_step(), resume_time)
	browser_stop_active_listeners_for_resync()
	browser_listener_launch_time = max(browser_playback_start_time, resume_time)
	browser_resync_suspended = FALSE
	do_hearcheck()
	sync_all_browser_listeners()
	if(browser_listener_launch_time > world.time)
		schedule_browser_listener_resync(browser_listener_launch_time)
	return TRUE

//Start all collected followers: copy song state and start their processing
/datum/song/proc/band_start_followers(mob/user)
	if(!band_is_leader())
		return
	var/leader_using_uploaded_midi = using_uploaded_midi_playback()
	for(var/datum/song/S as anything in band_followers.Copy())
		if(QDELETED(S) || QDELETED(S.parent))
			band_followers -= S
			continue
		S.band_join(src)
		//Always push current song/tempo to followers so they are primed, even if autoplay is disabled; this lets them press Play and sync
		if(!leader_using_uploaded_midi)
			S.lines = src.lines?.Copy() || list()
			S.tempo = src.tempo
			S.repeat = src.repeat
			S.compile_chords()
		//Reset manual pause on new leader start; obey follower autoplay
		S.band_paused_manually = FALSE
		S.clear_band_autoplay_start_failure()
		//Only start ready followers (held and in range) and with autoplay enabled
		if(S.band_autoplay && S.band_ready_for(src))
			//Ensure they are not already playing solo
			if(S.playing)
				S.stop_playing(TRUE)
			//Start their processing; progression is driven by leader
			if(!S.begin_playback(S.get_autoplay_user(user), browser_playback_start_time))
				S.band_autoplay_start_failed = TRUE
				continue
		else
			//Ensure not playing if not ready
			if(S.playing)
				S.stop_playing(TRUE)

//Stop and release all followers
/datum/song/proc/band_stop_followers()
	for(var/datum/song/S as anything in band_followers)
		if(QDELETED(S))
			continue
		S.stop_playing(TRUE)
		S.band_leave()
	band_followers.len = 0
	band_leader = null

//Stops playback for all followers but keeps membership intact
/datum/song/proc/band_stop_followers_playback()
	for(var/datum/song/S as anything in band_followers)
		if(QDELETED(S))
			continue
		S.stop_playing(TRUE)

/datum/song/proc/band_finish_uploaded_midi_followers_after_leader_stop()
	for(var/datum/song/S as anything in band_followers)
		if(QDELETED(S))
			continue
		if(!S.playing)
			continue
		if(S.browser_timeline_uploaded_midi && S.browser_timeline_duration_ds > 0 && S.browser_playback_start_time > 0)
			if(world.time < (S.browser_playback_start_time + S.browser_timeline_duration_ds))
				continue
		S.stop_playing(TRUE)

//A follower joins the given leader
/datum/song/proc/band_join(datum/song/leader)
	var/leader_changed = band_leader != leader
	band_leader = leader
	if(leader_changed)
		clear_band_autoplay_start_failure()
	if(!(src in leader.band_followers))
		leader.band_followers += src

//Leave the current band
/datum/song/proc/band_leave()
	if(band_leader)
		band_leader.band_followers -= src
	band_leader = null

/datum/song/proc/shared_song_state_matches(datum/song/other)
	if(!istype(other))
		return FALSE
	if(tempo != other.tempo || repeat != other.repeat)
		return FALSE
	if(length(lines) != length(other.lines))
		return FALSE
	for(var/i in 1 to length(lines))
		if(lines[i] != other.lines[i])
			return FALSE
	return TRUE

/datum/song/proc/band_sync_followers_for_timeline_rebuild(restart_playback = FALSE)
	if(!band_is_leader())
		return FALSE
	for(var/datum/song/S as anything in band_followers.Copy())
		if(QDELETED(S) || QDELETED(S.parent))
			band_followers -= S
			continue
		var/shared_song_changed = restart_playback || !S.shared_song_state_matches(src)
		S.band_join(src)
		if(shared_song_changed)
			S.lines = src.lines?.Copy() || list()
			S.tempo = src.tempo
			S.repeat = src.repeat
			S.compile_chords()
		if(!S.playing || !shared_song_changed)
			continue
		if(restart_playback)
			S.restart_active_playback(browser_playback_start_time)
		S.rebuild_browser_timeline_for_active_playback()
	return TRUE


//Transfer band leadership from this leader to one of its followers
/datum/song/proc/band_transfer_leadership(datum/song/new_leader)
	if(band_leader != src)
		return
	if(!istype(new_leader) || QDELETED(new_leader) || new_leader == src)
		return
	if(!(new_leader in band_followers))
		return

	//Snapshot current band membership including ourselves
	var/list/all_members = band_followers?.Copy() || list()
	all_members |= src

	var/was_playing = playing
	if(was_playing && using_uploaded_midi_playback() && !new_leader.uploaded_midi_uses_selected_instrument())
		return
	if(was_playing && !new_leader.can_begin_playback())
		return
	var/prev_chord = current_chord

	//Prime the new leader with our song data
	new_leader.lines = src.lines?.Copy() || list()
	new_leader.tempo = src.tempo
	new_leader.repeat = src.repeat
	new_leader.playback_source = src.using_uploaded_midi_playback() ? INSTRUMENT_PLAYBACK_SOURCE_UPLOADED_MIDI : INSTRUMENT_PLAYBACK_SOURCE_NOTES
	new_leader.uploaded_midi_name = src.uploaded_midi_name
	new_leader.uploaded_midi_resource = src.uploaded_midi_resource
	new_leader.uploaded_midi_alias = src.uploaded_midi_alias
	new_leader.uploaded_midi_duration_ds = src.uploaded_midi_duration_ds
	new_leader.uploaded_midi_serial = src.uploaded_midi_serial
	new_leader.uploaded_midi_ready_confirmed = src.uploaded_midi_ready_confirmed
	new_leader.compile_chords()

	//New leader becomes a leader
	new_leader.band_leader = new_leader
	if(!islist(new_leader.band_followers))
		new_leader.band_followers = list()
	else
		new_leader.band_followers.len = 0

	//Reassign all members to the new leader and rebuild their follower list
	for(var/datum/song/S as anything in all_members)
		if(QDELETED(S))
			continue
		if(S == new_leader)
			continue
		S.band_leader = new_leader
		if(!(S in new_leader.band_followers))
			new_leader.band_followers += S

	//Old leader is now a follower of the new leader
	band_followers.len = 0
	band_leader = new_leader

	//If we were playing, start the new leader and sync to our current chord
	if(was_playing)
		if(!new_leader.playing)
			new_leader.begin_playback(new_leader.get_autoplay_user(user_playing), browser_playback_start_time)
		new_leader.repeats_left = repeats_left
		//Align chord index for continuity
		new_leader.current_chord = clamp(prev_chord, 1, length(new_leader.compiled_chords))
		new_leader.elapsed_delay = 0
		if(length(new_leader.compiled_chords))
			var/list/ch = new_leader.compiled_chords[new_leader.current_chord]
			new_leader.delay_by = new_leader.tempodiv_to_delay(ch[length(ch)])

	//Broadcast notices
	var/new_leader_name = new_leader.get_holder_name()
	var/list/notify = list()
	notify += new_leader
	for(var/datum/song/S as anything in new_leader.band_followers)
		notify += S
	for(var/datum/song/N as anything in notify)
		var/mob/H = N.get_holder()
		if(!H)
			continue
		if(N == new_leader)
			to_chat(H, "<span class='notice'>You are now the band leader.</span>")
		else if(N == src)
			to_chat(H, "<span class='notice'>You made [new_leader_name] the band leader.</span>")
		else
			to_chat(H, "<span class='notice'>Band leader is now [new_leader_name].</span>")


//Broadcast a chord index to followers; they will play their own compiled chord at that index
/datum/song/proc/band_broadcast_play(chord_index)
	if(!band_is_leader())
		return
	//Ensure our own hearing list is fresh
	if((world.time - MUSICIAN_HEARCHECK_MINDELAY) > last_hearcheck)
		do_hearcheck()
	for(var/datum/song/S as anything in band_followers.Copy())
		if(QDELETED(S) || QDELETED(S.parent))
			band_followers -= S
			continue
		//Drop if out of range
		var/turf/other = get_turf(S.parent)
		if(!other || !S.band_ready_for(src))
			//Not ready: Ensure not playing but keep membership
			if(S.playing)
				S.stop_playing(TRUE)
			//Clear manual pause when follower becomes unready so that returning to ready state can auto-resume if autoplay is enabled
			S.band_paused_manually = FALSE
			S.clear_band_autoplay_start_failure()
			continue
		//Update follower hearing list too
		if((world.time - MUSICIAN_HEARCHECK_MINDELAY) > S.last_hearcheck)
			S.do_hearcheck()
		//Autoplay auto-resume: If follower is ready, not playing, autoplay enabled, and not manually paused, start them now synced to the leader's current chord
		if(!S.playing && S.band_autoplay && !S.band_paused_manually && !S.band_autoplay_start_failed)
			S.lines = src.lines?.Copy() || list()
			S.tempo = src.tempo
			S.repeat = src.repeat
			S.compile_chords()
			if(!S.begin_playback(S.get_autoplay_user(user_playing), browser_playback_start_time))
				S.band_autoplay_start_failed = TRUE
				continue
			S.elapsed_delay = 0
			S.current_chord = clamp(chord_index, 1, length(S.compiled_chords))
			if(length(S.compiled_chords))
				var/list/ch = S.compiled_chords[S.current_chord]
				S.delay_by = S.tempodiv_to_delay(ch[length(ch)])
			S.request_band_browser_resync()
		//Ensure chords exist
		if(chord_index > length(S.compiled_chords))
			continue
		var/list/f_chord = S.compiled_chords[chord_index]
		//Union of leader and follower targets so everyone in either range hears
		var/list/targets = hearing_mobs.Copy()
		targets |= S.hearing_mobs
		var/delay = max(0, round(S.band_delay_ds, get_instrument_time_step())) // RS Edit: Remove FPS dependency (Lira, November 2025)
		var/current_playback_generation = S.playback_generation
		if(delay)
			//Schedule with delay, snapshot targets
			var/list/targets_snapshot = targets.Copy()
			addtimer(CALLBACK(S, PROC_REF(play_chord_if_playing), f_chord, targets_snapshot, current_playback_generation), delay)
		else
			S.play_chord_if_playing(f_chord, targets, current_playback_generation)
//RS Add End
