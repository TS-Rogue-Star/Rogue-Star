///////////////////////////////////////////////////////////////////
//Created by Lira for Rogue Star March 2026 to add advanced synth//
///////////////////////////////////////////////////////////////////

/datum/song/handheld/multisynth
	var/max_instrument_layers = 3
	var/list/datum/instrument/using_instruments
	var/multisynth_playback_channel_cap = 0

/datum/song/handheld/multisynth/New(atom/parent, list/instrument_ids, new_range)
	using_instruments = list()
	using_instruments.len = max_instrument_layers
	. = ..()
	initialize_multisynth_layers()

/datum/song/handheld/multisynth/Destroy()
	if(islist(using_instruments))
		for(var/datum/instrument/I as anything in using_instruments)
			if(I)
				I.songs_using -= src
		using_instruments = null
	using_instrument = null
	cached_samples = null
	cached_legacy_ext = null
	cached_legacy_dir = null
	legacy = FALSE
	return ..()

/datum/song/handheld/multisynth/proc/initialize_multisynth_layers()
	if(!islist(using_instruments))
		using_instruments = list()
	using_instruments.len = max_instrument_layers
	if(!using_instruments[1] && length(allowed_instrument_ids))
		assign_layer_instrument(1, SSinstruments.get_instrument(allowed_instrument_ids[1]))
	sync_multisynth_primary_instrument()

/datum/song/handheld/multisynth/proc/assign_layer_instrument(slot, datum/instrument/new_instrument)
	if(slot < 1 || slot > max_instrument_layers)
		return FALSE
	if(!islist(using_instruments))
		using_instruments = list()
	using_instruments.len = max_instrument_layers
	var/datum/instrument/old_instrument = using_instruments[slot]
	if(old_instrument == new_instrument)
		return FALSE
	if(old_instrument)
		old_instrument.songs_using -= src
	using_instruments[slot] = new_instrument
	if(new_instrument && !(src in new_instrument.songs_using))
		new_instrument.songs_using += src
	return TRUE

/datum/song/handheld/multisynth/proc/sync_multisynth_primary_instrument()
	using_instrument = null
	if(!islist(using_instruments))
		cached_samples = null
		cached_legacy_ext = null
		cached_legacy_dir = null
		legacy = FALSE
		return
	for(var/i in 1 to max_instrument_layers)
		var/datum/instrument/I = using_instruments[i]
		if(!I || !I.ready())
			continue
		using_instrument = I
		break
	cached_samples = using_instrument?.samples
	cached_legacy_ext = null
	cached_legacy_dir = null
	legacy = FALSE

/datum/song/handheld/multisynth/proc/get_active_multisynth_layer_count()
	if(!islist(using_instruments))
		return 0
	var/count = 0
	for(var/datum/instrument/I as anything in using_instruments)
		if(I)
			count++
	return count

/datum/song/handheld/multisynth/proc/get_configured_multisynth_channel_cap()
	return CHANNELS_PER_INSTRUMENT * max(1, get_active_multisynth_layer_count())

/datum/song/handheld/multisynth/proc/refresh_multisynth_channel_cap()
	if(!playing)
		multisynth_playback_channel_cap = 0
		return get_configured_multisynth_channel_cap()
	multisynth_playback_channel_cap = max(multisynth_playback_channel_cap, get_configured_multisynth_channel_cap())
	return multisynth_playback_channel_cap

/datum/song/handheld/multisynth/proc/find_instrument_layer(datum/instrument/target, exclude_slot = 0)
	if(!target || !islist(using_instruments))
		return 0
	var/max_slot = min(max_instrument_layers, using_instruments.len)
	for(var/i in 1 to max_slot)
		if(i == exclude_slot)
			continue
		if(using_instruments[i] == target)
			return i
	return 0

/datum/song/handheld/multisynth/proc/release_inactive_multisynth_hold_channels()
	if(!length(held_synth_channels_by_layer))
		return FALSE
	var/list/active_layer_keys = list()
	for(var/datum/instrument/I as anything in get_synth_playback_instruments())
		active_layer_keys[get_synth_playback_layer_key(I)] = TRUE
	. = FALSE
	for(var/layer_key in held_synth_channels_by_layer.Copy())
		if(active_layer_keys[layer_key])
			continue
		held_synth_channels_by_layer -= layer_key
		. = TRUE

/datum/song/handheld/multisynth/proc/refresh_multisynth_playback()
	sync_multisynth_primary_instrument()
	refresh_multisynth_channel_cap()
	if(!playing)
		return
	release_inactive_multisynth_hold_channels()
	if(!using_instrument)
		stop_playing(TRUE)
		return
	refresh_browser_playback(TRUE)

/datum/song/handheld/multisynth/proc/set_layer_instrument(slot, instrument_choice)
	if(slot < 1 || slot > max_instrument_layers)
		return FALSE
	var/datum/instrument/new_instrument = instrument_choice
	if(istext(instrument_choice) || ispath(instrument_choice))
		new_instrument = SSinstruments.get_instrument(instrument_choice)
	if(new_instrument)
		if(length(allowed_instrument_ids) && !(new_instrument.id in allowed_instrument_ids))
			return FALSE
		if(new_instrument.instrument_flags & INSTRUMENT_LEGACY)
			return FALSE
		if(find_instrument_layer(new_instrument, slot))
			return FALSE
	if(!assign_layer_instrument(slot, new_instrument))
		return FALSE
	clear_band_autoplay_start_failure()
	refresh_multisynth_playback()
	return TRUE

/datum/song/handheld/multisynth/proc/clear_layer_instrument(slot)
	return set_layer_instrument(slot, null)

/datum/song/handheld/multisynth/proc/layers_ready()
	if(!get_active_multisynth_layer_count())
		return FALSE
	if(!islist(using_instruments))
		return FALSE
	for(var/datum/instrument/I as anything in using_instruments)
		if(I && !I.ready())
			return FALSE
	return TRUE

/datum/song/handheld/multisynth/can_begin_playback()
	if(!get_active_multisynth_layer_count())
		return FALSE
	return layers_ready()

/datum/song/handheld/multisynth/get_current_instrument_label()
	if(!islist(using_instruments))
		return "unconfigured"
	var/list/names = list()
	for(var/datum/instrument/I as anything in using_instruments)
		if(I)
			names += I.name
	if(!length(names))
		return "unconfigured"
	return names.Join(" + ")

/datum/song/handheld/multisynth/get_synth_playback_instruments()
	var/list/active_layers = list()
	if(!islist(using_instruments))
		return active_layers
	for(var/datum/instrument/I as anything in using_instruments)
		if(I?.ready())
			active_layers += I
	return active_layers

/datum/song/handheld/multisynth/handle_destroyed_instrument(datum/instrument/I)
	if(!I || !islist(using_instruments))
		return
	var/cleared_layer = FALSE
	var/max_slot = min(max_instrument_layers, using_instruments.len)
	for(var/slot in 1 to max_slot)
		if(using_instruments[slot] != I)
			continue
		assign_layer_instrument(slot, null)
		cleared_layer = TRUE
	if(cleared_layer)
		refresh_multisynth_playback()

/datum/song/handheld/multisynth/get_max_sound_channels()
	var/configured_cap = get_configured_multisynth_channel_cap()
	if(!playing)
		return configured_cap
	return max(configured_cap, multisynth_playback_channel_cap)

/datum/song/handheld/multisynth/begin_playback(mob/user, playback_start_time = world.time)
	. = ..()
	if(.)
		refresh_multisynth_channel_cap()

/datum/song/handheld/multisynth/stop_playing(keep_band = FALSE)
	..()
	if(!playing)
		multisynth_playback_channel_cap = 0

/datum/song/handheld/multisynth/set_instrument(datum/instrument/I)
	return set_layer_instrument(1, I)

/datum/song/handheld/multisynth/start_playing(mob/user)
	if(!get_active_multisynth_layer_count())
		to_chat(user, "<span class='warning'>Load at least one synth layer before playing.</span>")
		return
	if(!layers_ready())
		to_chat(user, "<span class='warning'>One or more loaded synth layers failed to initialize.</span>")
		return
	return ..()

/datum/song/handheld/multisynth/instrument_status_ui()
	. = list()
	. += "<div class='statusDisplay'>"
	. += "<b>Loaded synth layers</b>: [get_active_multisynth_layer_count()]/[max_instrument_layers]<br>"
	for(var/i in 1 to max_instrument_layers)
		var/datum/instrument/I = using_instruments[i]
		. += "Layer [i]: "
		if(I)
			. += "[I.name]"
		else
			. += "<span class='notice'>Empty</span>"
		. += " (<a href='?src=[REF(src)];setlayerinstrument=[i]'>Set</a>"
		if(I)
			. += " | <a href='?src=[REF(src)];clearlayer=[i]'>Clear</a>"
		else
			. += " | <span class='linkOff'>Clear</span>"
		. += ")<br>"
	. += "Playback Settings:<br>"
	if(can_noteshift)
		. += "<a href='?src=[REF(src)];setnoteshift=1'>Note Shift/Note Transpose</a>: [note_shift] keys / [round(note_shift / 12, 0.01)] octaves<br>"
	var/smt
	var/modetext = ""
	switch(sustain_mode)
		if(SUSTAIN_LINEAR)
			smt = "Linear"
			modetext = "<a href='?src=[REF(src)];setlinearfalloff=1'>Linear Sustain Duration</a>: [sustain_linear_duration / 10] seconds<br>"
		if(SUSTAIN_EXPONENTIAL)
			smt = "Exponential"
			modetext = "<a href='?src=[REF(src)];setexpfalloff=1'>Exponential Falloff Factor</a>: [sustain_exponential_dropoff]% per decisecond<br>"
	. += "<a href='?src=[REF(src)];setsustainmode=1'>Sustain Mode</a>: [smt]<br>"
	. += modetext
	if(get_active_multisynth_layer_count())
		. += layers_ready() ? "Status: <span class='good'>Ready</span><br>" : "Status: <span class='bad'>!Layer Definition Error!</span><br>"
	else
		. += "Status: <span class='bad'>No layers loaded</span><br>"
	. += "Instrument Type: Synthesized layered<br>"
	. += "<a href='?src=[REF(src)];setvolume=1'>Volume</a>: [volume]<br>"
	. += "<a href='?src=[REF(src)];setdropoffvolume=1'>Volume Dropoff Threshold</a>: [sustain_dropoff_volume]<br>"
	. += "<a href='?src=[REF(src)];togglesustainhold=1'>Sustain indefinitely last held note</a>: [full_sustain_held_note? "Enabled" : "Disabled"].<br>"
	. += "Band Sync Delay: [band_delay_ds / 10]s (<a href='?src=[REF(src)];setsyncdelay=1'>Set</a>)<br>"
	. += "Band Autoplay: [band_autoplay ? "Enabled" : "Disabled"] (<a href='?src=[REF(src)];toggleautoplay=1'>Toggle</a>)<br>"
	if(note_filter_enabled)
		. += "Note Range Filter: [note_filter_min]-[note_filter_max] (<a href='?src=[REF(src)];setnotefilter=1'>Set</a> | <a href='?src=[REF(src)];clearnotefilter=1'>Clear</a> | <a href='?src=[REF(src)];notefilterpreset=1'>Presets</a>)<br>"
	else
		. += "Note Range Filter: Off (<a href='?src=[REF(src)];setnotefilter=1'>Set</a> | <a href='?src=[REF(src)];clearnotefilter=1'>Clear</a> | <a href='?src=[REF(src)];notefilterpreset=1'>Presets</a>)<br>"
	if(band_leader == src)
		. += "<br><b>Band (Leader)</b>: <a href='?src=[REF(src)];inviteband=1'>Invite Nearby</a> | <a href='?src=[REF(src)];dissolveband=1'>Dissolve</a><br>"
		if(length(band_followers))
			. += "Members:<br>"
			var/turf/lt = get_turf(parent)
			for(var/datum/song/S as anything in band_followers)
				var/member_name = (S.parent && S.parent.name) ? S.parent.name : "instrument"
				var/configured_name = S.get_current_instrument_label()
				var/status
				var/mob/holder = S.get_holder()
				if(!holder)
					status = "Not ready (unheld)"
				else
					var/turf/ft = get_turf(S.parent)
					if(!ft || !lt || (get_dist(lt, ft) > band_range))
						status = "Not ready (out of range)"
					else
						status = "Ready"
				. += "- [S.get_holder_name()] ([member_name]: [configured_name]) - [status] <a href='?src=[REF(src)];kick=[REF(S)]'>Kick</a> | <a href='?src=[REF(src)];promote=[REF(S)]'>Make Leader</a><br>"
		else
			. += "No members yet.<br>"
	else if(band_leader)
		var/leader_name = (band_leader.parent && band_leader.parent.name) ? band_leader.parent.name : "instrument"
		var/leader_configured = band_leader.get_current_instrument_label()
		. += "<br><b>Band (Member)</b>: Leader is [band_leader.get_holder_name()] ([leader_name]: [leader_configured]) | <a href='?src=[REF(src)];leaveband=1'>Leave</a><br>"
	else
		. += "<br><b>Band</b>: <a href='?src=[REF(src)];createband=1'>Create Sync</a><br>"
	. += "</div>"

/datum/song/handheld/multisynth/Topic(href, href_list)
	if(href_list["setlayerinstrument"] || href_list["clearlayer"])
		if(!parent.CanUseTopic(usr))
			usr << browse(null, "window=instrument")
			usr.unset_machine()
			return
		parent.add_fingerprint(usr)
		var/slot_ref = href_list["setlayerinstrument"]
		if(!slot_ref)
			slot_ref = href_list["clearlayer"]
		var/slot = clamp(round(text2num(slot_ref)), 1, max_instrument_layers)
		if(href_list["setlayerinstrument"])
			var/choice = prompt_allowed_instrument_choice(usr, "Instrument Category", "Layer [slot] Instrument")
			if(choice)
				var/datum/instrument/I = SSinstruments.get_instrument(choice)
				if(find_instrument_layer(I, slot))
					to_chat(usr, "<span class='warning'>That instrument is already loaded in another layer.</span>")
				else
					set_layer_instrument(slot, I)
			updateDialog()
			return
		if(href_list["clearlayer"])
			clear_layer_instrument(slot)
			updateDialog()
			return
	return ..()
