
// RS Edit: TGUI emote interface (Lira, February 2026)
/client/verb/ooc()
	set name = "OOC"
	set category = "OOC"

	open_unified_ooc_input("ooc")

// RS Edit: TGUI emote interface (Lira, February 2026)
/client/verb/looc()
	set name = "LOOC"
	set desc = "Local OOC, seen only by those in view."
	set category = "OOC"

	open_unified_ooc_input("looc")

// RS Add: TGUI emote interface (Lira, February 2026)
/client/proc/open_unified_ooc_input(default_channel = "ooc")
	if(!mob)
		return

	var/channel = sanitize_unified_say_emote_channel(default_channel, "ooc")
	var/title = (channel == "looc") ? "LOOC" : "OOC"

	if(prefs?.tgui_input_mode)
		var/list/input_payload = tgui_input_say_emote(mob, title, "say", FALSE, "Type your message:", channel)
		mob.dispatch_unified_say_emote_input(input_payload)
		return

	var/msg = input(src, "Type your message:", title) as text|null
	if(isnull(msg))
		return

	if(channel == "looc")
		submit_looc_message(msg)
	else
		submit_ooc_message(msg)

/client/proc/submit_ooc_message(msg)
	if(say_disabled)	//This is here to try to identify lag problems
		to_chat(src, "<span class='warning'>Speech is currently admin-disabled.</span>") // RS Edit: Cleanup (Lira, February 2026)
		return

	// RS Edit: Formating (Lira, February 2026)
	if(!mob)
		return
	if(IsGuestKey(key))
		to_chat(src, "Guests may not use OOC.")
		return

	msg = sanitize(msg)
	// RS Edit: Formating (Lira, February 2026)
	if(!msg)
		return

	if(!is_preference_enabled(/datum/client_preference/show_ooc))
		to_chat(src, "<span class='warning'>You have OOC muted.</span>")
		return

	if(!holder)
		if(!config.ooc_allowed)
			to_chat(src, "<span class='danger'>OOC is globally muted.</span>")
			return
		if(!config.dooc_allowed && (mob.stat == DEAD))
			to_chat(src, "<span class='danger'>OOC for dead mobs has been turned off.</span>") // RS Edit: Cleanup (Lira, February 2026)
			return
		if(prefs.muted & MUTE_OOC)
			to_chat(src, "<span class='danger'>You cannot use OOC (muted).</span>")
			return
		if(findtext(msg, "byond://") && !config.allow_byond_links)
			to_chat(src, "<B>Advertising other servers is not allowed.</B>")
			log_admin("[key_name(src)] has attempted to advertise in OOC: [msg]")
			message_admins("[key_name_admin(src)] has attempted to advertise in OOC: [msg]")
			return
		if(findtext(msg, "discord.gg") && !config.allow_discord_links)
			to_chat(src, "<B>Advertising discords is not allowed.</B>")
			log_admin("[key_name(src)] has attempted to advertise a discord server in OOC: [msg]")
			message_admins("[key_name_admin(src)] has attempted to advertise a discord server in OOC: [msg]")
			return
		if((findtext(msg, "http://") || findtext(msg, "https://")) && !config.allow_url_links)
			to_chat(src, "<B>Posting external links is not allowed.</B>")
			log_admin("[key_name(src)] has attempted to post a link in OOC: [msg]")
			message_admins("[key_name_admin(src)] has attempted to post a link in OOC: [msg]")
			return

	log_ooc(msg, src)

	if(msg)
		handle_spam_prevention(MUTE_OOC)

	var/ooc_style = "everyone"
	if(holder && !holder.fakekey)
		ooc_style = "elevated"

		if(holder.rights & R_EVENT) //Retired Admins
			ooc_style = "event_manager"
		if(holder.rights & R_ADMIN && !(holder.rights & R_BAN)) //Game Masters
			ooc_style = "moderator"
		if(holder.rights & R_SERVER && !(holder.rights & R_BAN)) //Developers
			ooc_style = "developer"
		if(holder.rights & R_ADMIN && holder.rights & R_BAN) //Admins
			ooc_style = "admin"


	for(var/client/target in GLOB.clients)
		if(target.is_preference_enabled(/datum/client_preference/show_ooc))
			if(target.is_key_ignored(key)) // If we're ignored by this person, then do nothing.
				continue
			var/display_name = src.key
			if(holder)
				if(holder.fakekey)
					if(target.holder)
						display_name = "[holder.fakekey]/([src.key])"
					else
						display_name = holder.fakekey
			if(holder && !holder.fakekey && (holder.rights & R_ADMIN|R_FUN|R_EVENT) && config.allow_admin_ooccolor && (src.prefs.ooccolor != initial(src.prefs.ooccolor))) // keeping this for the badmins
				to_chat(target, "<font color='[src.prefs.ooccolor]'><span class='ooc'>" + create_text_tag("ooc", "OOC:", target) + " <EM>[display_name]:</EM> <span class='message'>[msg]</span></span></font>")
			else
				to_chat(target, "<span class='ooc'><span class='[ooc_style]'>" + create_text_tag("ooc", "OOC:", target) + " <EM>[display_name]:</EM> <span class='message'>[msg]</span></span></span>")

// RS Edit: TGUI emote interface (Lira, February 2026)
/client/proc/submit_looc_message(msg)
	if(say_disabled)	//This is here to try to identify lag problems
		to_chat(src, "<span class='danger'>Speech is currently admin-disabled.</span>")
		return

	if(!mob)
		return

	if(IsGuestKey(key))
		to_chat(src, "Guests may not use OOC.")
		return

	msg = sanitize(msg)
	if(!msg)
		return

	if(!is_preference_enabled(/datum/client_preference/show_looc))
		to_chat(src, "<span class='danger'>You have LOOC muted.</span>")
		return

	if(!holder)
		if(!config.looc_allowed)
			to_chat(src, "<span class='danger'>LOOC is globally muted.</span>")
			return
		if(!config.dooc_allowed && (mob.stat == DEAD))
			to_chat(src, "<span class='danger'>OOC for dead mobs has been turned off.</span>") // RS Edit: Cleanup (Lira, February 2026)
			return
		if(prefs.muted & MUTE_OOC)
			to_chat(src, "<span class='danger'>You cannot use OOC (muted).</span>")
			return
		if(findtext(msg, "byond://") && !config.allow_byond_links)
			to_chat(src, "<B>Advertising other servers is not allowed.</B>")
			log_admin("[key_name(src)] has attempted to advertise in OOC: [msg]")
			message_admins("[key_name_admin(src)] has attempted to advertise in OOC: [msg]")
			return
		if(findtext(msg, "discord.gg") && !config.allow_discord_links)
			to_chat(src, "<B>Advertising discords is not allowed.</B>")
			log_admin("[key_name(src)] has attempted to advertise a discord server in OOC: [msg]")
			message_admins("[key_name_admin(src)] has attempted to advertise a discord server in OOC: [msg]")
			return
		if((findtext(msg, "http://") || findtext(msg, "https://")) && !config.allow_url_links)
			to_chat(src, "<B>Posting external links is not allowed.</B>")
			log_admin("[key_name(src)] has attempted to post a link in OOC: [msg]")
			message_admins("[key_name_admin(src)] has attempted to post a link in OOC: [msg]")
			return

	log_looc(msg,src)

	if(msg)
		handle_spam_prevention(MUTE_OOC)

	var/mob/source = mob.get_looc_source()
	var/turf/T = get_turf(source)
	if(!T) return
	var/list/in_range = get_mobs_and_objs_in_view_fast(T,world.view,0)
	var/list/m_viewers = in_range["mobs"]

	var/list/receivers = list() //Clients, not mobs.
	var/list/r_receivers = list()

	var/display_name = key
	if(holder && holder.fakekey)
		display_name = holder.fakekey
	if(mob.stat != DEAD)
		display_name = mob.name

	if(ishuman(mob))
		var/mob/living/carbon/human/H = mob
		if(H.original_player && H.original_player != H.ckey) //In a body not their own
			display_name = "[H.mind.name] (as [H.name])"


	// Everyone in normal viewing range of the LOOC
	for(var/mob/viewer in m_viewers)
		if(viewer.client && viewer.client.is_preference_enabled(/datum/client_preference/show_looc))
			receivers |= viewer.client
		else if(istype(viewer,/mob/observer/eye)) // For AI eyes and the like
			var/mob/observer/eye/E = viewer
			if(E.owner && E.owner.client)
				receivers |= E.owner.client

	// Admins with RLOOC displayed who weren't already in
	for(var/client/admin in GLOB.admins)
		if(!(admin in receivers) && admin.is_preference_enabled(/datum/client_preference/holder/show_rlooc))
			r_receivers |= admin

	// Send a message
	for(var/client/target in receivers)
		var/admin_stuff = ""

		if(target in GLOB.admins)
			admin_stuff += "/([key])"

		to_chat(target, "<span class='looc'>" + create_text_tag("looc", "LOOC:", target) + " <EM>[display_name][admin_stuff]:</EM> <span class='message'>[msg]</span></span>")
		//RS ADDITION
		if(target.is_preference_enabled(/datum/client_preference/looc_sounds))
			target << sound('sound/talksounds/looc_sound.ogg', volume = 50)
		//RS ADDITION END

	for(var/client/target in r_receivers)
		var/admin_stuff = "/([key])([admin_jump_link(mob, target.holder)])"

		to_chat(target, "<span class='rlooc'>" + create_text_tag("looc", "LOOC:", target) + " <span class='prefix'>(R)</span><EM>[display_name][admin_stuff]:</EM> <span class='message'>[msg]</span></span>")

/mob/proc/get_looc_source()
	return src

/mob/living/silicon/ai/get_looc_source()
	if(eyeobj)
		return eyeobj
	return src
