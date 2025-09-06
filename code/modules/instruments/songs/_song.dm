#define MUSICIAN_HEARCHECK_MINDELAY 4
#define MUSIC_MAXLINES 1000
#define MUSIC_MAXLINECHARS 300

/**
 * # Song datum
 *
 * These are the actual backend behind instruments.
 * They attach to an atom and provide the editor + playback functionality.
 */

////////////////////////////////////////////////////////////////////////////////////
//Updated by Lira for Rogue Star August 2025 to support forming synchronized bands//
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
	//////////////////////////////////////////////////////

	/// Last world.time we checked for who can hear us
	var/last_hearcheck = 0
	/// The list of mobs that can hear us
	var/list/hearing_mobs
	/// If this is enabled, some things won't be strictly cleared when they usually are (liked compiled_chords on play stop)
	var/debug_mode = FALSE
	/// Max sound channels to occupy
	var/max_sound_channels = CHANNELS_PER_INSTRUMENT
	/// Current channels, so we can save a length() call.
	var/using_sound_channels = 0
	/// Last channel to play. text.
	var/last_channel_played
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

/**
 * Checks and stores which mobs can hear us. Terminates sounds for mobs that leave our range.
 */
/datum/song/proc/do_hearcheck()
	last_hearcheck = world.time
	var/list/old = hearing_mobs.Copy()
	hearing_mobs.len = 0
	var/turf/source = get_turf(parent)
	var/list/in_range = get_mobs_and_objs_in_view_fast(source, instrument_range, remote_ghosts = FALSE)
	for(var/mob/M in in_range["mobs"])
		hearing_mobs[M] = get_dist(M, source)
	var/list/exited = old - hearing_mobs
	for(var/i in exited)
		terminate_sound_mob(i)

/**
 * Sets our instrument, caching anything necessary for faster accessing. Accepts an ID, typepath, or instantiated instrument datum.
 */
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

/**
 * Attempts to start playing our song.
 */
/datum/song/proc/start_playing(mob/user)
	if(playing)
		return
	if(!using_instrument?.ready())
		to_chat(user, "<span class='warning'>An error has occurred with [src]. Please reset the instrument.</span>")
		return
	if(band_is_follower() && !(band_leader?.playing)) //RS Add: If we're a band member and the leader isn't playing, block manual start (Lira, August 2025)
		to_chat(user, "<span class='warning'>Band leader is not currently playing; no active song to sync.</span>")
		return
	band_paused_manually = FALSE //RS Add: User explicitly started playback; clear any manual pause state
	if(band_is_follower() && band_leader?.playing) //RS Add: If we're a band follower and the leader is currently playing, mirror the leader's lines and tempo so chord indices align (Lira, August 2025)
		lines = band_leader.lines?.Copy() || list()
		tempo = band_leader.tempo
	compile_chords()
	if(!length(compiled_chords))
		to_chat(user, "<span class='warning'>Song is empty.</span>")
		return
	playing = TRUE
	updateDialog(user_playing)
	//we can not afford to runtime, since we are going to be doing sound channel reservations and if we runtime it means we have a channel allocation leak.
	//wrap the rest of the stuff to ensure stop_playing() is called.
	do_hearcheck()
	SEND_SIGNAL(parent, COMSIG_SONG_START)
	elapsed_delay = 0
	delay_by = 0
	current_chord = 1
	user_playing = user
	last_note_fx_time = world.time - note_fx_interval_ds //RS Add: Prime visual cue so the first note shows quickly (Lira, August 2025)
	START_PROCESSING(SSinstruments, src)

	//RS Add Start: Band playing (Lira, August 2025)
	//If we're a band leader with selected followers, start them now
	if(band_is_leader())
		band_start_followers(user)
	//If we just started as a follower while leader is mid-song, immediately sync by playing the leader's current chord so we "catch up".
	else if(band_is_follower() && band_leader?.playing)
		//Only sync if we're ready (held and in range)
		if(band_ready_for(band_leader))
			//Ensure hearing lists are fresh
			if((world.time - MUSICIAN_HEARCHECK_MINDELAY) > band_leader.last_hearcheck)
				band_leader.do_hearcheck()
			if((world.time - MUSICIAN_HEARCHECK_MINDELAY) > last_hearcheck)
				do_hearcheck()
			var/ch_idx = clamp(band_leader.current_chord, 1, length(compiled_chords))
			if(ch_idx <= length(compiled_chords))
				//Reflect our current chord to match leader for UI consistency
				current_chord = ch_idx
				var/list/f_chord = compiled_chords[ch_idx]
				var/list/targets = band_leader.hearing_mobs?.Copy() || list()
				targets |= hearing_mobs
				var/delay = max(0, round(band_delay_ds, world.tick_lag))
				if(delay)
					var/list/targets_snapshot = targets.Copy()
					addtimer(CALLBACK(src, PROC_REF(play_chord_if_playing), f_chord, targets_snapshot), delay)
				else
					play_chord_if_playing(f_chord, targets)
	//RS Add End

/**
 * Stops playing, terminating all sounds if in synthesized mode. Clears hearing_mobs.
 */
/datum/song/proc/stop_playing(keep_band = FALSE) //RS Edit: End band by default (Lira, August 2025)
	if(!playing)
		return
	playing = FALSE
	if(!debug_mode)
		compiled_chords = null
	STOP_PROCESSING(SSinstruments, src)
	SEND_SIGNAL(parent, COMSIG_SONG_END)
	terminate_all_sounds(TRUE)
	hearing_mobs.len = 0
	user_playing = null
	//RS Add Start: Band stop playing (Lira, August 2025)
	if(band_leader == src)
		band_stop_followers_playback()
	if(!keep_band && band_is_follower())
		band_leave()
	//RS Add End

/**
 * Processes our song.
 */
/datum/song/proc/process_song(wait)
	if(playing) //RS Add: Visual cue when playing (Lira, August 2025)
		//Throttle to once every note_fx_interval_ds deciseconds
		if(world.time - last_note_fx_time >= note_fx_interval_ds)
			var/atom/anchor = get_holder() || parent
			if(anchor)
				//Show a musical note above the performer/instrument to viewers in instrument range
				var/note = pick("♪", "♫")
				anchor.runechat_message(note, instrument_range, FALSE, list("musicnote", "black_outline"))
			last_note_fx_time = world.time

	if(band_is_follower()) //RS Add: Followers don't advance their own chord progression; leader drives playback (Lira, August 2025)
		return

	if(!length(compiled_chords) || should_stop_playing(user_playing))
		stop_playing()
		return
	var/list/chord = compiled_chords[current_chord]
	if(++elapsed_delay >= delay_by)
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
		play_chord(chord, targets_override)
		//Broadcast this chord to followers (if any)
		if(band_is_leader())
			band_broadcast_play(current_chord)
		//RS Add End
		elapsed_delay = 0
		delay_by = tempodiv_to_delay(chord[length(chord)])
		current_chord++
		if(current_chord > length(compiled_chords))
			if(repeat)
				repeat--
				current_chord = 1
				return
			else
				stop_playing()
				return

/**
 * Converts a tempodiv to ticks to elapse before playing the next chord, taking into account our tempo.
 */
/datum/song/proc/tempodiv_to_delay(tempodiv)
	if(!tempodiv)
		tempodiv = 1 // no division by 0. some song converters tend to use 0 for when it wants to have no div, for whatever reason.
	return max(1, round((tempo/tempodiv) / world.tick_lag, 1))

/**
 * Compiles chords.
 */
/datum/song/proc/compile_chords()
	legacy ? compile_legacy() : compile_synthesized()

/**
 * Plays a chord.
 */
/datum/song/proc/play_chord(list/chord, list/targets_override) //RS Edit: Adds band override (Lira, August 2025)
	// last value is timing information
	for(var/i in 1 to (length(chord) - 1))
		legacy? playkey_legacy(chord[i][1], chord[i][2], chord[i][3], user_playing, targets_override) : playkey_synth(chord[i], user_playing, targets_override) //RS Edit: Adds band override (Lira, August 2025)

/**
 * Checks if we should halt playback.
 */
/datum/song/proc/should_stop_playing(mob/user)
	return QDELETED(parent) || !using_instrument || !playing

/**
 * Sanitizes tempo to a value that makes sense and fits the current world.tick_lag.
 */
/datum/song/proc/sanitize_tempo(new_tempo)
	new_tempo = abs(new_tempo)
	return clamp(round(new_tempo, world.tick_lag), world.tick_lag, 5 SECONDS)

/**
 * Gets our beats per minute based on our tempo.
 */
/datum/song/proc/get_bpm()
	return 600 / tempo

/**
 * Sets our tempo from a beats-per-minute, sanitizing it to a valid number first.
 */
/datum/song/proc/set_bpm(bpm)
	tempo = sanitize_tempo(600 / bpm)

/**
 * Updates the window for our users. Override down the line.
 */
/datum/song/proc/updateDialog(mob/user)
	interact(user)

/datum/song/process(wait)
	if(!playing)
		return PROCESS_KILL
	// it's expected this ticks at every world.tick_lag. if it lags, do not attempt to catch up.
	process_song(world.tick_lag)
	process_decay(world.tick_lag)

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
	updateDialog()

/**
 * Setter for setting how low the volume has to get before a note is considered "dead" and dropped
 */
/datum/song/proc/set_dropoff_volume(volume)
	sustain_dropoff_volume = clamp(volume, INSTRUMENT_MIN_SUSTAIN_DROPOFF, 100)
	update_sustain()
	updateDialog()

/**
 * Setter for setting exponential falloff factor.
 */
/datum/song/proc/set_exponential_drop_rate(drop)
	sustain_exponential_dropoff = clamp(drop, INSTRUMENT_EXP_FALLOFF_MIN, INSTRUMENT_EXP_FALLOFF_MAX)
	update_sustain()
	updateDialog()

/**
 * Setter for setting linear falloff duration.
 */
/datum/song/proc/set_linear_falloff_duration(duration)
	sustain_linear_duration = clamp(duration, 0.1, INSTRUMENT_MAX_TOTAL_SUSTAIN)
	update_sustain()
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

//RS Add Start: Band sync support procs (Lira, August 2025)

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
	return (get_dist(lt, ft) <= leader.band_range)

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
	updateDialog()

//Disable note range filter
/datum/song/proc/clear_note_filter()
	note_filter_enabled = FALSE
	updateDialog()

 //Plays a chord only if we are still playing
/datum/song/proc/play_chord_if_playing(list/chord, list/targets_override)
	if(!playing)
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

//Start all collected followers: copy song state and start their processing
/datum/song/proc/band_start_followers(mob/user)
	if(!band_is_leader())
		return
	for(var/datum/song/S as anything in band_followers.Copy())
		if(QDELETED(S) || QDELETED(S.parent))
			band_followers -= S
			continue
		S.band_join(src)
		//Always push current song/tempo to followers so they are primed, even if autoplay is disabled; this lets them press Play and sync
		S.lines = src.lines?.Copy() || list()
		S.tempo = src.tempo
		S.compile_chords()
		//Reset manual pause on new leader start; obey follower autoplay
		S.band_paused_manually = FALSE
		//Only start ready followers (held and in range) and with autoplay enabled
		if(S.band_autoplay && S.band_ready_for(src))
			//Ensure they are not already playing solo
			if(S.playing)
				S.stop_playing(TRUE)
			//Start their processing; progression is driven by leader
			S.playing = TRUE
			S.elapsed_delay = 0
			S.delay_by = 0
			S.current_chord = 1
			S.user_playing = user
			SEND_SIGNAL(S.parent, COMSIG_SONG_START)
			START_PROCESSING(SSinstruments, S)
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

//A follower joins the given leader
/datum/song/proc/band_join(datum/song/leader)
	band_leader = leader
	if(!(src in leader.band_followers))
		leader.band_followers += src

//Leave the current band
/datum/song/proc/band_leave()
	if(band_leader)
		band_leader.band_followers -= src
	band_leader = null


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
	var/prev_chord = current_chord

	//Prime the new leader with our song data
	new_leader.lines = src.lines?.Copy() || list()
	new_leader.tempo = src.tempo
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
			new_leader.start_playing(user_playing)
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
			continue
		//Update follower hearing list too
			if((world.time - MUSICIAN_HEARCHECK_MINDELAY) > S.last_hearcheck)
				S.do_hearcheck()
		//Autoplay auto-resume: If follower is ready, not playing, autoplay enabled, and not manually paused, start them now synced to the leader's current chord
		if(!S.playing && S.band_autoplay && !S.band_paused_manually)
			S.lines = src.lines?.Copy() || list()
			S.tempo = src.tempo
			S.compile_chords()
			S.playing = TRUE
			S.elapsed_delay = 0
			S.delay_by = 0
			S.current_chord = clamp(chord_index, 1, length(S.compiled_chords))
			S.user_playing = user_playing
			SEND_SIGNAL(S.parent, COMSIG_SONG_START)
			START_PROCESSING(SSinstruments, S)
		//Ensure chords exist
		if(chord_index > length(S.compiled_chords))
			continue
		var/list/f_chord = S.compiled_chords[chord_index]
		//Union of leader and follower targets so everyone in either range hears
		var/list/targets = hearing_mobs.Copy()
		targets |= S.hearing_mobs
		var/delay = max(0, round(S.band_delay_ds, world.tick_lag))
		if(delay)
			//Schedule with delay, snapshot targets
			var/list/targets_snapshot = targets.Copy()
			addtimer(CALLBACK(S, PROC_REF(play_chord_if_playing), f_chord, targets_snapshot), delay)
		else
			S.play_chord_if_playing(f_chord, targets)
//RS Add End
