/////////////////////////////////////////////////////////////////////////////////
//Created by Lira for Rogue Star March 2026 for browser-based instrument audio //
/////////////////////////////////////////////////////////////////////////////////
#define INSTRUMENT_AUDIO_WINDOW_ID "rpane.instrumentpanel"
#define INSTRUMENT_AUDIO_SAMPLE_BATCH_SIZE 4
#define INSTRUMENT_AUDIO_SAMPLE_BATCH_DELAY 1
#define INSTRUMENT_AUDIO_PRIME_TIMEOUT 5 SECONDS

/client
	var/datum/instrument_audio_manager/instrument_audio

/client/proc/refresh_instrument_audio()
	if(!instrument_audio?.supports_browser_audio())
		return
	for(var/datum/song/S as anything in SSinstruments.songs)
		if(!S?.playing)
			continue
		if(S.get_active_uploaded_midi_source_song() && instrument_audio.song_has_state(S))
			S.reset_uploaded_midi_ready_timeout(world.time)
		S.sync_browser_listener(mob)

/client/proc/cleanup_instrument_audio()
	if(!instrument_audio)
		return FALSE
	var/datum/instrument_audio_manager/manager = instrument_audio
	instrument_audio = null
	qdel(manager)
	return TRUE

/mob/Login()
	. = ..()
	if(client)
		addtimer(CALLBACK(client, TYPE_PROC_REF(/client, refresh_instrument_audio)), 0)

/datum/instrument_audio_manager
	var/client/owner
	var/ready = FALSE
	var/capable = FALSE
	var/list/primed_songs = list()
	var/list/priming_songs = list()
	var/list/priming_started_at = list()
	var/list/active_songs = list()
	var/list/sent_sample_aliases = list()
	var/list/queued_sample_aliases = list()
	var/list/queued_sample_paths = list()
	var/list/queued_sample_dependents = list()
	var/list/queued_song_payloads = list()
	var/list/song_waiting_samples = list()
	var/list/pending_midi_inspections = list()
	var/processing_sample_queue = FALSE

/datum/instrument_audio_manager/New(client/C)
	owner = C
	..()
	open()

/datum/instrument_audio_manager/Destroy()
	reset_browser_page_state()
	ready = FALSE
	capable = FALSE
	owner = null
	primed_songs = null
	priming_songs = null
	priming_started_at = null
	active_songs = null
	sent_sample_aliases = null
	queued_sample_aliases = null
	queued_sample_paths = null
	queued_sample_dependents = null
	queued_song_payloads = null
	song_waiting_samples = null
	return ..()

/datum/instrument_audio_manager/proc/open()
	if(!owner || QDELETED(owner) || !winexists(owner, INSTRUMENT_AUDIO_WINDOW_ID))
		return
	owner << browse_rsc(file("code/modules/instruments/browser/instrument_audio.js"), "instrument_audio.js")
	owner << browse(return_file_text("code/modules/instruments/browser/instrument_audio.html"), "window=[INSTRUMENT_AUDIO_WINDOW_ID]")

/datum/instrument_audio_manager/proc/reset_browser_page_state()
	clear_song_listener_state()
	primed_songs.Cut()
	priming_songs.Cut()
	priming_started_at.Cut()
	active_songs.Cut()
	sent_sample_aliases.Cut()
	queued_sample_aliases.Cut()
	queued_sample_paths.Cut()
	queued_sample_dependents.Cut()
	queued_song_payloads.Cut()
	song_waiting_samples.Cut()
	for(var/song_id in pending_midi_inspections)
		var/midi_serial = pending_midi_inspections[song_id]
		var/datum/song/S = locate(song_id)
		if(!istype(S))
			continue
		S.reset_uploaded_midi_channel_scan_request(midi_serial)
	pending_midi_inspections.Cut()
	processing_sample_queue = FALSE

/datum/instrument_audio_manager/proc/clear_song_listener_state()
	if(!owner)
		return FALSE
	var/cleared = FALSE
	for(var/datum/song/S as anything in SSinstruments.songs)
		if(!S)
			continue
		cleared = S.clear_browser_listener_client(owner) || cleared
	return cleared

/datum/instrument_audio_manager/proc/browser_status(new_ready, new_capable)
	reset_browser_page_state()
	ready = !!new_ready
	capable = !!new_capable
	if(!owner || QDELETED(owner))
		return
	if(!supports_browser_audio())
		return
	if(owner?.mob)
		owner.refresh_instrument_audio()

/datum/instrument_audio_manager/proc/supports_browser_audio()
	return owner && !QDELETED(owner) && ready && capable

/datum/instrument_audio_manager/proc/browser_listener_supported(datum/song/S, mob/M)
	if(!supports_browser_audio() || !owner || !S || !M || owner.mob != M)
		return FALSE
	if(!S.can_use_browser_audio())
		return FALSE
	if(M.ear_deaf > 0)
		return FALSE
	return owner.is_preference_enabled(/datum/client_preference/instrument_toggle)

/datum/instrument_audio_manager/proc/song_uses_browser(datum/song/S)
	if(!supports_browser_audio() || !S)
		return FALSE
	var/song_id = S.browser_song_id()
	var/timeline_key = S.browser_timeline_key || md5(S.browser_timeline_json || "")
	return !!(active_songs[song_id] && primed_songs[song_id] == timeline_key)

/datum/instrument_audio_manager/proc/song_is_priming(datum/song/S)
	if(!supports_browser_audio() || !S)
		return FALSE
	var/song_id = S.browser_song_id()
	var/timeline_key = S.browser_timeline_key || md5(S.browser_timeline_json || "")
	return priming_songs[song_id] == timeline_key

/datum/instrument_audio_manager/proc/song_is_primed(datum/song/S)
	if(!supports_browser_audio() || !S)
		return FALSE
	var/song_id = S.browser_song_id()
	var/timeline_key = S.browser_timeline_key || md5(S.browser_timeline_json || "")
	return primed_songs[song_id] == timeline_key

/datum/instrument_audio_manager/proc/song_has_state(datum/song/S)
	if(!S)
		return FALSE
	var/song_id = S.browser_song_id()
	return !!(primed_songs[song_id] || priming_songs[song_id] || active_songs[song_id] || queued_song_payloads[song_id] || song_waiting_samples[song_id])

/datum/instrument_audio_manager/proc/clear_song_queue_state(song_id)
	if(!song_id)
		return
	song_waiting_samples -= song_id
	queued_song_payloads -= song_id
	for(var/alias in queued_sample_dependents.Copy())
		var/list/dependents = queued_sample_dependents[alias]
		if(!islist(dependents))
			continue
		dependents -= song_id
		if(length(dependents))
			continue
		queued_sample_dependents -= alias
		queued_sample_paths -= alias
		queued_sample_aliases -= alias

/datum/instrument_audio_manager/proc/prime_song(datum/song/S)
	if(!supports_browser_audio() || !S?.can_use_browser_audio() || !S.browser_timeline_json)
		return FALSE
	var/song_id = S.browser_song_id()
	var/timeline_key = S.browser_timeline_key || md5(S.browser_timeline_json)
	var/list/priming_samples = S.get_browser_initial_sample_manifest()
	if(primed_songs[song_id] == timeline_key)
		return TRUE
	if(priming_songs[song_id] == timeline_key)
		var/started_at = priming_started_at[song_id]
		if(isnum(started_at) && ((world.time - started_at) < INSTRUMENT_AUDIO_PRIME_TIMEOUT))
			return FALSE
	clear_song_queue_state(song_id)
	primed_songs -= song_id
	active_songs -= song_id
	priming_songs[song_id] = timeline_key
	priming_started_at[song_id] = world.time
	queued_song_payloads[song_id] = list(
		"payload" = url_encode(S.browser_timeline_json),
		"timeline_key" = timeline_key
	)
	var/waiting_samples = 0
	for(var/alias in priming_samples)
		if(sent_sample_aliases[alias])
			continue
		var/list/dependents = queued_sample_dependents[alias]
		if(!islist(dependents))
			dependents = list()
			queued_sample_dependents[alias] = dependents
		if(!(song_id in dependents))
			dependents += song_id
			waiting_samples++
		if(queued_sample_paths[alias])
			continue
		queued_sample_paths[alias] = priming_samples[alias]
		queued_sample_aliases += alias
	if(waiting_samples)
		song_waiting_samples[song_id] = waiting_samples
		process_sample_queue()
	else
		send_song_payload(song_id)
	return FALSE

/datum/instrument_audio_manager/proc/send_sample_resource(alias, sample_path)
	if(!owner || QDELETED(owner) || !alias)
		return FALSE
	if(istext(sample_path))
		owner << browse_rsc(file(sample_path), alias)
	else
		owner << browse_rsc(sample_path, alias)
	sent_sample_aliases[alias] = TRUE
	return TRUE

/datum/instrument_audio_manager/proc/inspect_uploaded_midi(datum/song/S)
	if(!supports_browser_audio() || !S?.has_uploaded_midi() || !S.uploaded_midi_alias || !S.uploaded_midi_resource)
		return FALSE
	pending_midi_inspections[S.browser_song_id()] = S.uploaded_midi_serial
	if(!sent_sample_aliases[S.uploaded_midi_alias])
		send_sample_resource(S.uploaded_midi_alias, S.uploaded_midi_resource)
	if(!owner || QDELETED(owner))
		return FALSE
	owner << output(list2params(list(S.browser_song_id(), S.uploaded_midi_alias, "[S.uploaded_midi_serial]")), "[INSTRUMENT_AUDIO_WINDOW_ID]:instrumentAudio.inspectMidi")
	return TRUE

/datum/instrument_audio_manager/proc/dispatch_sample(alias, sample_path = null)
	if(!alias || sent_sample_aliases[alias])
		return FALSE
	queued_sample_aliases -= alias
	if(isnull(sample_path))
		sample_path = queued_sample_paths[alias]
	queued_sample_paths -= alias
	if(sample_path)
		send_sample_resource(alias, sample_path)
	var/list/dependents = queued_sample_dependents[alias]
	queued_sample_dependents -= alias
	if(islist(dependents))
		for(var/song_id in dependents)
			var/waiting = song_waiting_samples[song_id]
			if(!isnum(waiting))
				continue
			waiting--
			if(waiting <= 0)
				song_waiting_samples -= song_id
				send_song_payload(song_id)
			else
				song_waiting_samples[song_id] = waiting
	return !!sample_path

/datum/instrument_audio_manager/proc/request_song_samples(datum/song/S, list/aliases)
	if(!supports_browser_audio() || !S || !song_has_state(S) || !islist(aliases) || !length(aliases))
		return FALSE
	var/sent_any = FALSE
	for(var/alias in aliases)
		if(!istext(alias) || sent_sample_aliases[alias])
			continue
		var/sample_path = S.browser_sample_manifest[alias]
		if(isnull(sample_path) && !queued_sample_paths[alias])
			continue
		sent_any = dispatch_sample(alias, sample_path) || sent_any
	return sent_any

/datum/instrument_audio_manager/proc/process_sample_queue()
	if(processing_sample_queue)
		return
	processing_sample_queue = TRUE
	addtimer(CALLBACK(src, PROC_REF(process_sample_queue_tick)), 0)

/datum/instrument_audio_manager/proc/process_sample_queue_tick()
	if(QDELETED(src) || !owner || QDELETED(owner))
		processing_sample_queue = FALSE
		return
	var/sent_this_tick = 0
	while(sent_this_tick < INSTRUMENT_AUDIO_SAMPLE_BATCH_SIZE && length(queued_sample_aliases))
		var/alias = queued_sample_aliases[1]
		dispatch_sample(alias)
		sent_this_tick++
	if(length(queued_sample_aliases))
		addtimer(CALLBACK(src, PROC_REF(process_sample_queue_tick)), INSTRUMENT_AUDIO_SAMPLE_BATCH_DELAY)
	else
		processing_sample_queue = FALSE

/datum/instrument_audio_manager/proc/send_song_payload(song_id)
	var/list/payload_data = queued_song_payloads[song_id]
	if(!islist(payload_data))
		return FALSE
	if(!owner || QDELETED(owner))
		return FALSE
	queued_song_payloads -= song_id
	owner << output(list2params(list(song_id, payload_data["payload"], payload_data["timeline_key"])), "[INSTRUMENT_AUDIO_WINDOW_ID]:instrumentAudio.prime")
	return TRUE

/datum/instrument_audio_manager/proc/browser_song_ready(song_id, timeline_key, duration_seconds)
	if(!supports_browser_audio() || !song_id || !timeline_key)
		return FALSE
	var/datum/song/S = locate(song_id)
	if(!istype(S))
		return FALSE
	var/expected_key = S.browser_timeline_key || md5(S.browser_timeline_json || "")
	if(expected_key != timeline_key)
		return FALSE
	primed_songs[song_id] = timeline_key
	priming_songs -= song_id
	priming_started_at -= song_id
	S.browser_timeline_ready(timeline_key, duration_seconds)
	if(owner && !QDELETED(owner) && owner.mob)
		S.sync_browser_listener(owner.mob)
	return TRUE

/datum/instrument_audio_manager/proc/browser_song_midi_channels(song_id, midi_serial, metadata_json, successful)
	if(!supports_browser_audio() || !song_id)
		return FALSE
	var/expected_serial = pending_midi_inspections[song_id]
	if(isnull(expected_serial) || expected_serial != midi_serial)
		return FALSE
	pending_midi_inspections -= song_id
	var/datum/song/S = locate(song_id)
	if(!istype(S))
		return FALSE
	var/list/channel_data = null
	if(successful && metadata_json)
		channel_data = json_decode(metadata_json)
		if(!islist(channel_data))
			successful = FALSE
	S.receive_uploaded_midi_channel_metadata(channel_data, midi_serial, successful, owner?.mob)
	return TRUE

/datum/instrument_audio_manager/proc/start_song(datum/song/S, elapsed_seconds, gain, position_x = 0, position_z = 0)
	if(!prime_song(S))
		return FALSE
	if(!owner || QDELETED(owner))
		return FALSE
	owner << output(list2params(list(S.browser_song_id(), "[elapsed_seconds]", "[gain]", "[position_x]", "[position_z]")), "[INSTRUMENT_AUDIO_WINDOW_ID]:instrumentAudio.start")
	active_songs[S.browser_song_id()] = TRUE
	return TRUE

/datum/instrument_audio_manager/proc/update_song_gain(datum/song/S, gain, position_x = 0, position_z = 0)
	if(!supports_browser_audio() || !S)
		return FALSE
	if(!active_songs[S.browser_song_id()])
		return FALSE
	if(!owner || QDELETED(owner))
		return FALSE
	owner << output(list2params(list(S.browser_song_id(), "[gain]", "[position_x]", "[position_z]")), "[INSTRUMENT_AUDIO_WINDOW_ID]:instrumentAudio.updateGain")
	return TRUE

/datum/instrument_audio_manager/proc/stop_song(datum/song/S, preserve_active_notes = FALSE)
	if(!supports_browser_audio() || !S)
		return FALSE
	if(!active_songs[S.browser_song_id()])
		return FALSE
	active_songs -= S.browser_song_id()
	if(!owner || QDELETED(owner))
		return FALSE
	owner << output(list2params(list(S.browser_song_id(), preserve_active_notes ? "1" : "0")), "[INSTRUMENT_AUDIO_WINDOW_ID]:instrumentAudio.stop")
	return TRUE

/datum/instrument_audio_manager/proc/drop_song(datum/song/S, preserve_active_notes = FALSE)
	if(!S)
		return FALSE
	stop_song(S, preserve_active_notes)
	primed_songs -= S.browser_song_id()
	priming_songs -= S.browser_song_id()
	priming_started_at -= S.browser_song_id()
	active_songs -= S.browser_song_id()
	clear_song_queue_state(S.browser_song_id())
	if(supports_browser_audio() && owner && !QDELETED(owner))
		owner << output(list2params(list(S.browser_song_id(), preserve_active_notes ? "1" : "0")), "[INSTRUMENT_AUDIO_WINDOW_ID]:instrumentAudio.drop")
	return TRUE

#undef INSTRUMENT_AUDIO_WINDOW_ID
#undef INSTRUMENT_AUDIO_SAMPLE_BATCH_SIZE
#undef INSTRUMENT_AUDIO_SAMPLE_BATCH_DELAY
#undef INSTRUMENT_AUDIO_PRIME_TIMEOUT
