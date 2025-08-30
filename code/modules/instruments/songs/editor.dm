/**
 * Returns the HTML for the status UI for this song datum.
 */

////////////////////////////////////////////////////////////////////////////////////
//Updated by Lira for Rogue Star August 2025 to support forming synchronized bands//
////////////////////////////////////////////////////////////////////////////////////

/datum/song/proc/instrument_status_ui()
	. = list()
	. += "<div class='statusDisplay'>"
	. += "<b><a href='?src=[REF(src)];switchinstrument=1'>Current instrument</a>:</b> "
	if(!using_instrument)
		. += "<span class='danger'>No instrument loaded!</span><br>"
	else
		. += "[using_instrument.name]<br>"
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
	. += using_instrument?.ready()? "Status: <span class='good'>Ready</span><br>" : "Status: <span class='bad'>!Instrument Definition Error!</span><br>"
	. += "Instrument Type: [legacy? "Legacy" : "Synthesized"]<br>"
	. += "<a href='?src=[REF(src)];setvolume=1'>Volume</a>: [volume]<br>"
	. += "<a href='?src=[REF(src)];setdropoffvolume=1'>Volume Dropoff Threshold</a>: [sustain_dropoff_volume]<br>"
	. += "<a href='?src=[REF(src)];togglesustainhold=1'>Sustain indefinitely last held note</a>: [full_sustain_held_note? "Enabled" : "Disabled"].<br>"
	. += "Band Sync Delay: [band_delay_ds / 10]s (<a href='?src=[REF(src)];setsyncdelay=1'>Set</a>)<br>" //RS Add: Band sync delay toggle (Lira, August 2025)
	. += "Band Autoplay: [band_autoplay ? "Enabled" : "Disabled"] (<a href='?src=[REF(src)];toggleautoplay=1'>Toggle</a>)<br>" //RS Add: Band autoplay toggle (Lira, August 2025)
	if(note_filter_enabled) //RS Add: Band note range filter toggle (Lira, August 2025)
		. += "Note Range Filter: [note_filter_min]-[note_filter_max] (<a href='?src=[REF(src)];setnotefilter=1'>Set</a> | <a href='?src=[REF(src)];clearnotefilter=1'>Clear</a> | <a href='?src=[REF(src)];notefilterpreset=1'>Presets</a>)<br>"
	else
		. += "Note Range Filter: Off (<a href='?src=[REF(src)];setnotefilter=1'>Set</a> | <a href='?src=[REF(src)];clearnotefilter=1'>Clear</a> | <a href='?src=[REF(src)];notefilterpreset=1'>Presets</a>)<br>"
	//RS Add Start: Band management UI (Lira, August 2025)
	if(band_leader == src)
		. += "<br><b>Band (Leader)</b>: <a href='?src=[REF(src)];inviteband=1'>Invite Nearby</a> | <a href='?src=[REF(src)];dissolveband=1'>Dissolve</a><br>"
		if(length(band_followers))
			. += "Members:<br>"
			var/turf/lt = get_turf(parent)
			for(var/datum/song/S as anything in band_followers)
				var/member_name = (S.parent && S.parent.name) ? S.parent.name : "instrument"
				var/configured_name = (S.using_instrument && S.using_instrument.name) ? S.using_instrument.name : "unconfigured"
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
		var/leader_configured = (band_leader.using_instrument && band_leader.using_instrument.name) ? band_leader.using_instrument.name : "unconfigured"
		. += "<br><b>Band (Member)</b>: Leader is [band_leader.get_holder_name()] ([leader_name]: [leader_configured]) | <a href='?src=[REF(src)];leaveband=1'>Leave</a><br>"
	else
		. += "<br><b>Band</b>: <a href='?src=[REF(src)];createband=1'>Create Sync</a><br>"
	//RS Add End
	. += "</div>"

/datum/song/proc/interact(mob/user)
	var/list/dat = list()

	dat += instrument_status_ui()

	if(lines.len > 0)
		dat += "<H3>Playback</H3>"
		if(!playing)
			dat += "<A href='?src=[REF(src)];play=1'>Play</A> <SPAN CLASS='linkOn'>Stop</SPAN><BR><BR>"
			dat += "Repeat Song: "
			dat += repeat > 0 ? "<A href='?src=[REF(src)];repeat=-10'>-</A><A href='?src=[REF(src)];repeat=-1'>-</A>" : "<SPAN CLASS='linkOff'>-</SPAN><SPAN CLASS='linkOff'>-</SPAN>"
			dat += " [repeat] times "
			dat += repeat < max_repeats ? "<A href='?src=[REF(src)];repeat=1'>+</A><A href='?src=[REF(src)];repeat=10'>+</A>" : "<SPAN CLASS='linkOff'>+</SPAN><SPAN CLASS='linkOff'>+</SPAN>"
			dat += "<BR>"
		else
			dat += "<SPAN CLASS='linkOn'>Play</SPAN> <A href='?src=[REF(src)];stop=1'>Stop</A><BR>"
			dat += "Repeats left: <B>[repeat]</B><BR>"
	if(!editing)
		dat += "<BR><B><A href='?src=[REF(src)];edit=2'>Show Editor</A></B><BR>"
	else
		dat += "<H3>Editing</H3>"
		dat += "<B><A href='?src=[REF(src)];edit=1'>Hide Editor</A></B>"
		dat += " <A href='?src=[REF(src)];newsong=1'>Start a New Song</A>"
		dat += " <A href='?src=[REF(src)];import=1'>Import a Song</A><BR><BR>"
		var/bpm = round(600 / tempo)
		dat += "Tempo: <A href='?src=[REF(src)];tempo=[world.tick_lag]'>-</A> [bpm] BPM <A href='?src=[REF(src)];tempo=-[world.tick_lag]'>+</A><BR><BR>"
		var/linecount = 0
		for(var/line in lines)
			linecount += 1
			dat += "Line [linecount]: <A href='?src=[REF(src)];modifyline=[linecount]'>Edit</A> <A href='?src=[REF(src)];deleteline=[linecount]'>X</A> [line]<BR>"
		dat += "<A href='?src=[REF(src)];newline=1'>Add Line</A><BR><BR>"
		if(help)
			dat += "<B><A href='?src=[REF(src)];help=1'>Hide Help</A></B><BR>"
			dat += {"
					Lines are a series of chords, separated by commas (,), each with notes separated by hyphens (-).<br>
					Every note in a chord will play together, with chord timed by the tempo.<br>
					<br>
					Notes are played by the names of the note, and optionally, the accidental, and/or the octave number.<br>
					By default, every note is natural and in octave 3. Defining otherwise is remembered for each note.<br>
					Example: <i>C,D,E,F,G,A,B</i> will play a C major scale.<br>
					After a note has an accidental placed, it will be remembered: <i>C,C4,C,C3</i> is <i>C3,C4,C4,C3</i><br>
					Chords can be played simply by separating each note with a hyphen: <i>A-C#,Cn-E,E-G#,Gn-B</i><br>
					A pause may be denoted by an empty chord: <i>C,E,,C,G</i><br>
					To make a chord be a different time, end it with /x, where the chord length will be length<br>
					defined by tempo / x: <i>C,G/2,E/4</i><br>
					Combined, an example is: <i>E-E4/4,F#/2,G#/8,B/8,E3-E4/4</i>
					<br>
					Lines may be up to [MUSIC_MAXLINECHARS] characters.<br>
					A song may only contain up to [MUSIC_MAXLINES] lines.<br>
					"}
		else
			dat += "<B><A href='?src=[REF(src)];help=2'>Show Help</A></B><BR>"

	var/datum/browser/popup = new(user, "instrument", parent?.name || "instrument", 700, 500)
	popup.set_content(dat.Join(""))
	popup.open()

/**
 * Parses a song the user has input into lines and stores them.
 */
/datum/song/proc/ParseSong(text)
	set waitfor = FALSE
	//split into lines
	lines = splittext(text, "\n")
	if(lines.len)
		var/bpm_string = "BPM: "
		if(findtext(lines[1], bpm_string, 1, length(bpm_string) + 1))
			var/divisor = text2num(copytext(lines[1], length(bpm_string) + 1)) || 120 // default
			tempo = sanitize_tempo(600 / round(divisor, 1))
			lines.Cut(1, 2)
		else
			tempo = sanitize_tempo(5) // default 120 BPM
		if(lines.len > MUSIC_MAXLINES)
			to_chat(usr, "Too many lines!")
			lines.Cut(MUSIC_MAXLINES + 1)
		var/linenum = 1
		for(var/l in lines)
			if(length_char(l) > MUSIC_MAXLINECHARS)
				to_chat(usr, "Line [linenum] too long!")
				lines.Remove(l)
			else
				linenum++
		updateDialog(usr) // make sure updates when complete

/datum/song/Topic(href, href_list)
	if(!parent.CanUseTopic(usr))
		usr << browse(null, "window=instrument")
		usr.unset_machine()
		return

	parent.add_fingerprint(usr)

	if(href_list["newsong"])
		lines = new()
		tempo = sanitize_tempo(5) // default 120 BPM
		name = ""

	else if(href_list["import"])
		var/t = ""
		do
			t = html_encode(tgui_input_text(usr, "Please paste the entire song, formatted:", text("[]", name), t, multiline = TRUE, prevent_enter = TRUE))
			if(!in_range(parent, usr))
				return

			if(length_char(t) >= MUSIC_MAXLINES * MUSIC_MAXLINECHARS)
				var/cont = tgui_alert(usr, "Your message is too long! Would you like to continue editing it?", "Too long!", list("Yes", "No"))
				if(cont == "No")
					break
		while(length_char(t) > MUSIC_MAXLINES * MUSIC_MAXLINECHARS)
		ParseSong(t)

	else if(href_list["help"])
		help = text2num(href_list["help"]) - 1

	else if(href_list["edit"])
		editing = text2num(href_list["edit"]) - 1

	if(href_list["repeat"]) //Changing this from a toggle to a number of repeats to avoid infinite loops.
		if(playing)
			return //So that people cant keep adding to repeat. If the do it intentionally, it could result in the server crashing.
		repeat += round(text2num(href_list["repeat"]))
		if(repeat < 0)
			repeat = 0
		if(repeat > max_repeats)
			repeat = max_repeats

	else if(href_list["tempo"])
		tempo = sanitize_tempo(tempo + text2num(href_list["tempo"]))

	else if(href_list["play"])
		band_paused_manually = FALSE //RS Add: Clear manual pause when the user explicitly plays again (Lira, August 2025)
		INVOKE_ASYNC(src, PROC_REF(start_playing), usr)

	else if(href_list["newline"])
		var/newline = html_encode(tgui_input_text(usr, "Enter your line: ", parent.name))
		if(!newline || !in_range(parent, usr))
			return
		if(lines.len > MUSIC_MAXLINES)
			return
		if(length(newline) > MUSIC_MAXLINECHARS)
			newline = copytext(newline, 1, MUSIC_MAXLINECHARS)
		lines.Add(newline)

	else if(href_list["deleteline"])
		var/num = round(text2num(href_list["deleteline"]))
		if(num > lines.len || num < 1)
			return
		lines.Cut(num, num+1)

	else if(href_list["modifyline"])
		var/num = round(text2num(href_list["modifyline"]),1)
		var/content = stripped_input(usr, "Enter your line: ", parent.name, lines[num], MUSIC_MAXLINECHARS)
		if(!content || !in_range(parent, usr))
			return
		if(num > lines.len || num < 1)
			return
		lines[num] = content

	else if(href_list["stop"])
		band_paused_manually = TRUE //RS Add: Mark as manually paused and do not leave band membership (Lira, August 2025)
		stop_playing(TRUE) //RS Edit: Pass true to keep band together (Lira, August 2025)

	else if(href_list["setlinearfalloff"])
		var/amount = tgui_input_number(usr, "Set linear sustain duration in seconds", "Linear Sustain Duration")
		if(!isnull(amount))
			set_linear_falloff_duration(round(amount * 10, world.tick_lag))

	else if(href_list["setexpfalloff"])
		var/amount = tgui_input_number(usr, "Set exponential sustain factor", "Exponential sustain factor")
		if(!isnull(amount))
			set_exponential_drop_rate(round(amount, 0.00001))

	else if(href_list["setvolume"])
		var/amount = tgui_input_number(usr, "Set volume", "Volume")
		if(!isnull(amount))
			set_volume(round(amount, 1))

	else if(href_list["setdropoffvolume"])
		var/amount = tgui_input_number(usr, "Set dropoff threshold", "Dropoff Threshold Volume")
		if(!isnull(amount))
			set_dropoff_volume(round(amount, 0.01))

	else if(href_list["switchinstrument"])
		if(!length(allowed_instrument_ids))
			return
		else if(length(allowed_instrument_ids) == 1)
			set_instrument(allowed_instrument_ids[1])
			return
		var/list/categories = list()
		for(var/i in allowed_instrument_ids)
			var/datum/instrument/I = SSinstruments.get_instrument(i)
			if(I)
				LAZYSET(categories[I.category || "ERROR CATEGORY"], I.name, I.id)
		var/cat = tgui_input_list(usr, "Select Category", "Instrument Category", categories)
		if(!cat)
			return
		var/list/instruments = categories[cat]
		var/choice = tgui_input_list(usr, "Select Instrument", "Instrument Selection", instruments)
		if(!choice)
			return
		choice = instruments[choice] //get id
		if(choice)
			set_instrument(choice)

	else if(href_list["setnoteshift"])
		var/amount = tgui_input_number(usr, "Set note shift", "Note Shift")
		if(!isnull(amount))
			note_shift = clamp(amount, note_shift_min, note_shift_max)

	else if(href_list["setsustainmode"])
		var/choice = tgui_input_list(usr, "Choose a sustain mode", "Sustain Mode", list("Linear", "Exponential"))
		switch(choice)
			if("Linear")
				sustain_mode = SUSTAIN_LINEAR
			if("Exponential")
				sustain_mode = SUSTAIN_EXPONENTIAL

	else if(href_list["togglesustainhold"])
		full_sustain_held_note = !full_sustain_held_note

	//RS Add Start: Define band sync hrefs (Lira, August 2025)

	else if(href_list["setsyncdelay"])
		var/seconds = tgui_input_number(usr, "Set band sync delay (seconds)", "Band Sync Delay", band_delay_ds / 10)
		if(!isnull(seconds))
			band_delay_ds = clamp(round(seconds * 10, world.tick_lag), 0, 5 SECONDS)

	else if(href_list["toggleautoplay"])
		band_autoplay = !band_autoplay

	else if(href_list["setnotefilter"])
		var/low = tgui_input_number(usr, "Lowest note key (0-127)", "Note Range Low", note_filter_min)
		if(isnull(low))
			return
		var/high = tgui_input_number(usr, "Highest note key (0-127)", "Note Range High", note_filter_max)
		if(isnull(high))
			return
		set_note_filter_bounds(low, high)

	else if(href_list["clearnotefilter"])
		clear_note_filter()

	else if(href_list["notefilterpreset"])
		var/list/presets = list(
			"Off",
			"Below middle C (<=59)",
			"Above middle C (>=60)",
			"Lows (C0-B3)",
			"Mids (C4-B5)",
			"Highs (C6-127)",
			"Only C3-B3",
			"Only C4-B4",
			"Only C5-B5"
		)
		var/choice = tgui_input_list(usr, "Select preset", "Note Filter Presets", presets)
		if(!choice)
			return
		switch(choice)
			if("Off")
				clear_note_filter()
			if("Below middle C (<=59)")
				set_note_filter_bounds(0, 59)
			if("Above middle C (>=60)")
				set_note_filter_bounds(60, 127)
			if("Lows (C0-B3)")
				set_note_filter_bounds(0, 47)
			if("Mids (C4-B5)")
				set_note_filter_bounds(48, 71)
			if("Highs (C6-127)")
				set_note_filter_bounds(72, 127)
			if("Only C3-B3")
				set_note_filter_bounds(36, 47)
			if("Only C4-B4")
				set_note_filter_bounds(48, 59)
			if("Only C5-B5")
				set_note_filter_bounds(60, 71)

	else if(href_list["createband"])
		band_create()

	else if(href_list["inviteband"])
		band_invite_nearby(usr)

	else if(href_list["dissolveband"])
		band_stop_followers()

	else if(href_list["leaveband"])
		if(band_leader)
			band_leave()

	else if(href_list["kick"])
		var/ref = href_list["kick"]
		var/datum/song/S = locate(ref)
		if(istype(S))
			S.stop_playing(TRUE)
			S.band_leave()

	else if(href_list["promote"])
		var/refp = href_list["promote"]
		var/datum/song/NS = locate(refp)
		if(istype(NS))
			var/target_holder = NS.get_holder_name()
			var/instr_name = (NS.parent && NS.parent.name) ? NS.parent.name : "instrument"
			var/ans = tgui_alert(usr, "Make [target_holder] ([instr_name]) the band leader?", "Transfer Band Leadership", list("Yes", "No"))
			if(ans == "Yes")
				band_transfer_leadership(NS)
				updateDialog(usr)

	//RS Add End

	updateDialog()
