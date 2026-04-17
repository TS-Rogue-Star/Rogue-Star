#define HS_NOT_PLAYING 0	//When the game is not running
#define HS_PREGAME 1		//Before anyone has been released
#define HS_HIDE_PHASE 2		//When hiders have been released, but not seekers
#define HS_SEEK_PHASE 3		//Everyone is playing
#define TEAM_CAUGHT	0
#define TEAM_HIDE	1
#define TEAM_SEEK	2

/obj/hide_and_seek
	name = "Hide and Seek Score Keeper"
	desc = "It is keeping score!"
	icon = 'icons/rogue-star/misc_32x64.dmi'
	icon_state = "scorekeeper"

	anchored = TRUE
	pixel_y = 16
	plane = MOB_PLANE
	layer = MOB_LAYER

	var/game_state = 0
	var/phase_start = 0
	var/duration_pregame = 5
	var/duration_hide = 3
	var/duration_seek = 30
	var/halftime = 0
	var/fifthstime = 0
	var/joinable = TRUE
	var/list/hs_modifiers = list()
	var/list/hidescore = list()
	var/list/seekscore = list()
	var/list/vorescore = list()

/obj/hide_and_seek/Destroy()
	for(var/datum/modifier/hide_and_seek/mod in hs_modifiers)
		hs_modifiers -= mod
		mod.expire()

	. = ..()

/obj/hide_and_seek/attack_hand(mob/user)
	. = ..()
	if(game_state == HS_NOT_PLAYING)
		if(!check_rights(R_FUN,FALSE))
			to_chat(user,SPAN_DANGER("The game is not currently running, so you can not pick a team."))
			return
		var/choice = tgui_alert(user,"What would you like to do?","[src] configuration",list("Report","Start"))
		if(!choice)
			return
		switch(choice)
			if("Start")
				start_game()
			if("Report")
				report(user)
	else
		var/list/options = list()
		if(joinable)
			options += "Hide"
			options += "Seek"
		if(check_rights(R_FUN,FALSE))
			options += "Report"
			options += "End"
		if(!options.len)
			to_chat(user,SPAN_DANGER("You can't join right now as the round is about to end."))
			return
		var/choice = tgui_alert(user,"What would you like to do?","[src] configuration",options)
		if(!choice)
			return

		switch(choice)
			if("Hide" , "Seek")
				join_team(choice,user)
			if("Report")
				report(user)
			if("End")
				set_game_state(HS_NOT_PLAYING)

/obj/hide_and_seek/process()
	switch(game_state)
		if(HS_NOT_PLAYING)
			STOP_PROCESSING(SSobj,src)
			return
		if(HS_PREGAME)
			if(world.time >= phase_start + duration_pregame MINUTES)
				set_game_state(HS_HIDE_PHASE)
		if(HS_HIDE_PHASE)
			if(world.time >= phase_start + duration_hide MINUTES)
				set_game_state(HS_SEEK_PHASE)
		if(HS_SEEK_PHASE)
			if(world.time >= phase_start + duration_seek MINUTES)
				set_game_state(HS_NOT_PLAYING)
				return
			if(halftime > 0)
				if(world.time >= phase_start + halftime MINUTES)
					announce_msg("halftime")
					halftime = 0
			else if(fifthstime > 0)
				if(world.time >= phase_start + fifthstime MINUTES)
					announce_msg("fifthstime")
					fifthstime = 0
					joinable = FALSE

/obj/hide_and_seek/proc/start_game()

	if(game_state)
		return
	START_PROCESSING(SSobj,src)

	//announce start message
	set_game_state(HS_PREGAME)
	joinable = TRUE

/obj/hide_and_seek/proc/set_game_state(var/newstate)
	game_state = newstate
	phase_start = world.time
	switch(game_state)
		if(HS_NOT_PLAYING)
			announce_msg("end")
			STOP_PROCESSING(SSobj,src)
			SEND_SIGNAL(src,HIDE_AND_SEEK_ROUND_END)
		if(HS_PREGAME)
			halftime = duration_seek * 0.5
			fifthstime = duration_seek - (duration_seek * 0.2)
			announce_msg("pregame")
		if(HS_HIDE_PHASE)
			announce_msg("hide")
		if(HS_SEEK_PHASE)
			announce_msg("seek")

/obj/hide_and_seek/proc/announce_msg(var/ourmsg)

	if(!ourmsg)
		return
	var/spoilers = FALSE
	switch(ourmsg)
		if("pregame")
			ourmsg = SPAN_NOTICE("Hide and Seek will begin shortly! HIDERS and SEEKERS should come touch \the [src], and select the side they would like to be on! In [duration_pregame] minutes, the HIDERS will be released to go hide. They will have [duration_hide] minutes to hide. Then the SEEKERS will be released to find the HIDERS. SEEKERS should hug, grab, or disarm any HIDERS they discover, they will earn a seeking point for doing so. The SEEKERS will have [duration_seek] minutes to find the HIDERS. Any HIDERS who are not found at the end of the seeking phase will also get a point. If a HIDER is caught, they may return and touch \the [src] again to resume hiding. No points will be awarded to SEEKERS who catch the same HIDER repeatedly in a short timeframe. You can also change teams at any time by touching \the [src]! Remember, the point of the game is to have fun, so try not to take it too seriously, and have a good time together!")
		if("hide")
			ourmsg = span_critical("HIDERS are released! You have [duration_hide] minutes to hide before seekers will be released.")
		if("seek")
			ourmsg = span_critical("SEEKERS are released! The round will end in [duration_seek] minutes.")
			spoilers = TRUE
		if("end")
			ourmsg = span_critical("The round is over, everyone return to start.")
		if("halftime")
			ourmsg = span_orange("Time is half over, [halftime] minutes remain.")
			spoilers = TRUE
		if("fifthstime")
			ourmsg = SPAN_WARNING("The round is almost over, [duration_seek - fifthstime] minutes remain. Joining the game is now restricted.")
			spoilers = TRUE

	if(spoilers)
		ourmsg += span_green("<br><br>There are currently [assess_active_hiders()] unfound hiders.")

	for(var/mob/M in player_list)
		if(!istype(M,/mob/new_player))
			to_chat(M, "<h2 class='alert'>HIDE AND SEEK ANNOUNCEMENT</h2>")
			to_chat(M, "<span class='alert'>[ourmsg]</span>")
			M << 'sound/AI/preamble.ogg'

/obj/hide_and_seek/proc/report(var/mob/living/user)
	//AAAAAAAAAAAAAAAAA

	var/scoreland = SPAN_DANGER("HIDE AND SEEK SCOREBOARD BEGIN:<br>")
	var/tempmsg = report_my_list_please(hidescore)
	if(tempmsg)
		scoreland += span_alien("HIDERS<br>")
		scoreland += tempmsg
	tempmsg = report_my_list_please(seekscore)
	if(tempmsg)
		scoreland += span_alien("SEEKERS<br>")
		scoreland += tempmsg
	tempmsg = report_my_list_please(vorescore)
	if(tempmsg)
		scoreland += span_alien("COMPATIBILITY<br>")
		scoreland += tempmsg

	to_chat(user, scoreland)

	if(tgui_alert(user,"Would you like to show the report to everyone?","Global report?",list("Yes","No")) == "Yes")
		to_world(scoreland)

/obj/hide_and_seek/proc/report_my_list_please(var/list/input)
	if(!input)
		return
	var/list/subjects = input.Copy()
	var/report = ""
	var/iterations = 0
	while(subjects.len)
		iterations ++
		var/greatest = list_get_greatest(subjects)

		subjects -= greatest

		report += SPAN_NOTICE("[greatest] - [input[greatest]]<br>")

	if(iterations == 0)
		return FALSE
	return report

/obj/hide_and_seek/proc/join_team(var/team, var/mob/living/user)
	if(!team || !user)
		return
	if(!isliving(user))
		return
	if(team == "Hide")
		team = TEAM_HIDE
	else
		team = TEAM_SEEK
	var/datum/modifier/hide_and_seek/mod = user.get_modifier_of_type(/datum/modifier/hide_and_seek)
	if(!mod)
		mod = user.add_modifier(/datum/modifier/hide_and_seek)
	mod.RegisterSignal(src,HIDE_AND_SEEK_ROUND_END,/datum/modifier/hide_and_seek/proc/round_end,TRUE)
	mod.team(team)
	hs_modifiers |= mod
	mod.scorekeeper = src

/obj/hide_and_seek/proc/assess_active_hiders()
	var/active_hiders = 0
	for(var/datum/modifier/hide_and_seek/mod in hs_modifiers)
		if(mod.mode == TEAM_HIDE)
			active_hiders ++
	return active_hiders

/datum/modifier/hide_and_seek
	name = "hide and seek"
	desc = "You're playing a game!"

	mob_overlay_icon = 'icons/rogue-star/misc.dmi'

	var/mode = TEAM_CAUGHT
	var/last_getter
	var/last_got_time = -9999
	var/last_vorer
	var/last_vore_time = -9999
	var/vore_point = TRUE
	var/obj/hide_and_seek/scorekeeper

/datum/modifier/hide_and_seek/New(new_holder, new_origin)
	. = ..()
	RegisterSignal(holder, COMSIG_ATOM_ATTACK_HAND, /datum/modifier/hide_and_seek/proc/tagged, TRUE)

/datum/modifier/hide_and_seek/expire(silent)
	scorekeeper = null
	. = ..()

/datum/modifier/hide_and_seek/tick()
	. = ..()
	if(scorekeeper.game_state != HS_SEEK_PHASE)
		return
	if(!vore_point)
		return
	var/atom/where = holder.loc
	if(ismicro(where))
		where = where.loc

	if(isbelly(where))
		var/obj/belly/B = where
		if(B.owner.name == last_vorer && world.time < last_vore_time + 5 MINUTES)
			return
		var/datum/modifier/hide_and_seek/mod = B.owner.get_modifier_of_type(/datum/modifier/hide_and_seek)
		if(mod)
			scorekeeper.vorescore[holder.name] = scorekeeper.vorescore[holder.name]+ 1
			scorekeeper.vorescore[mod.holder.name] = scorekeeper.vorescore[mod.holder.name] + 1
			playsound(get_turf(mod.holder), 'sound/machines/ping.ogg', 50, TRUE)
			if(mode != TEAM_CAUGHT)
				tagged(holder,B.owner)
			vore_point = FALSE
			last_vorer = mod.holder.name
			last_vore_time = world.time
			mod.last_vorer = holder.name
			mod.last_vore_time = world.time
	if(isliving(where))
		var/mob/living/L = where
		var/datum/modifier/hide_and_seek/mod = L.get_modifier_of_type(/datum/modifier/hide_and_seek)
		if(mod)
			tagged(holder,L)

/datum/modifier/hide_and_seek/proc/tagged()	//Someone clicked our mob! Let's make sure they are a seeker!
	if(mode != TEAM_HIDE)	//We are not hiding so we don't really need to worry about anything right now!
		return
	if(scorekeeper.game_state != HS_SEEK_PHASE)
		return
	var/mob/living/L = args[2]
	if(!L)
		return
	if(L == holder)
		return

	var/turf/T = get_turf(L)

	if(L.name == last_getter)
		if(world.time < last_got_time + 5 MINUTES)
			to_chat(L,SPAN_DANGER("You found \the [holder] too recently, try seeking someone else for now."))
			playsound(T, 'sound/machines/buzz-sigh.ogg', 50, TRUE)

			return

	var/datum/modifier/hide_and_seek/mod = L.get_modifier_of_type(/datum/modifier/hide_and_seek)

	if(!mod)
		return

	if(mod.mode == TEAM_SEEK)
		team(TEAM_CAUGHT)
		scorekeeper.seekscore[L.name] = scorekeeper.seekscore[L.name] + 1
		last_getter = L.real_name
		last_got_time = world.time
		L.grant_xp(SKILL_SEEKING, 1)
		to_chat(holder, SPAN_DANGER("\The [L] tagged you. You have been caught."))
		to_chat(L, SPAN_NOTICE("You tagged \the [holder] and gained a point! \The [holder] has been caught."))
		playsound(T, 'sound/machines/ping.ogg', 50, TRUE)
		if(vore_point)
			to_chat(L, span_alien("You can get a vore point too if you eat [holder]. Make sure your prefs line up though!"))

/datum/modifier/hide_and_seek/proc/team(var/team)
	mode = team
	switch(mode)
		if(TEAM_HIDE)
			mob_overlay_state = "hide"
			vore_point = TRUE
		if(TEAM_SEEK)
			mob_overlay_state = "seek"
			vore_point = TRUE
		if(TEAM_CAUGHT)
			mob_overlay_state = null

	holder.update_modifier_visuals()

/datum/modifier/hide_and_seek/proc/round_end()
	if(mode == TEAM_HIDE)
		scorekeeper.hidescore[holder.name] = scorekeeper.hidescore[holder.name] + 1
		holder.grant_xp(SKILL_HIDING, 1)
	mode = TEAM_CAUGHT
	vore_point = FALSE
	mob_overlay_state = null
	holder.update_modifier_visuals()

#undef HS_NOT_PLAYING
#undef HS_PREGAME
#undef HS_HIDE_PHASE
#undef HS_SEEK_PHASE
#undef TEAM_CAUGHT
#undef TEAM_HIDE
#undef TEAM_SEEK
