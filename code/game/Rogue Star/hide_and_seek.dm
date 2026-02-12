#define HS_NOT_PLAYING 0	//When the game is not running
#define HS_PREGAME 1		//Before anyone has been released
#define HS_HIDE_PHASE 2		//When hiders have been released, but not seekers
#define HS_SEEK_PHASE 3		//Everyone is playing

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
	var/fivetime = 0
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
		var/options = list("Hide","Seek")
		if(check_rights(R_FUN,FALSE))
			options += "Report"
			options += "End"
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
					halftime = 0
					announce_msg("halftime")
			else if(fivetime > 0)
				if(world.time >= phase_start + fivetime MINUTES)
					fivetime = 0
					announce_msg("fivetime")

/obj/hide_and_seek/proc/start_game()

	if(game_state)
		return
	START_PROCESSING(SSobj,src)

	//announce start message
	set_game_state(HS_PREGAME)

/obj/hide_and_seek/proc/set_game_state(var/newstate)
	game_state = newstate
	phase_start = world.time
	switch(game_state)
		if(HS_NOT_PLAYING)
			announce_msg("end")
			STOP_PROCESSING(SSobj,src)
			SEND_SIGNAL(src,HIDE_AND_SEEK_ROUND_END)
		if(HS_PREGAME)
			halftime = duration_seek / 2
			fivetime = duration_seek - 5
			announce_msg("pregame")
		if(HS_HIDE_PHASE)
			announce_msg("hide")
		if(HS_SEEK_PHASE)
			announce_msg("seek")

/obj/hide_and_seek/proc/announce_msg(var/ourmsg)

	if(!ourmsg)
		return

	switch(ourmsg)
		if("pregame")
			ourmsg = SPAN_NOTICE("Hide and Seek will begin shortly! HIDERS and SEEKERS should come touch \the [src], and select the side they would like to be on! In [duration_pregame] minutes, the HIDERS will be released to go hide. They will have [duration_hide] minutes to hide. Then the SEEKERS will be released to find the HIDERS. SEEKERS should hug, grab, or disarm any HIDERS they discover, they will earn a seeking point for doing so. The SEEKERS will have [duration_seek] minutes to find the HIDERS. Any HIDERS who are not found at the end of the seeking phase will also get a point. If a HIDER is caught, they may return and touch \the [src] again to resume hiding. No points will be awarded to SEEKERS who catch the same HIDER repeatedly in a short timeframe. You can also change teams at any time by touching \the [src]! Remember, the point of the game is to have fun, so try not to take it too seriously, and have a good time together!")
		if("hide")
			ourmsg = SPAN_DANGER("HIDERS are released! You have [duration_hide] minutes to hide before seekers will be released.")
		if("seek")
			ourmsg = SPAN_DANGER("SEEKERS are released! The round will end in [duration_seek / 2] minutes.")
		if("end")
			ourmsg = SPAN_DANGER("The round is over, everyone return to start.")
		if("halftime")
			ourmsg = SPAN_NOTICE("Time is half over, [halftime] minutes remain.")
		if("fivetime")
			ourmsg = SPAN_WARNING("The round is almost over, 5 minutes remain.")

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
	user.add_modifier(/datum/modifier/hide_and_seek)
	var/datum/modifier/hide_and_seek/mod = user.get_modifier_of_type(/datum/modifier/hide_and_seek)
	if(!mod)
		return
	mod.RegisterSignal(src,HIDE_AND_SEEK_ROUND_END,/datum/modifier/hide_and_seek/proc/round_end,TRUE)
	mod.team(team)
	hs_modifiers |= mod
	mod.scorekeeper = src

/datum/modifier/hide_and_seek
	name = "hide and seek"
	desc = "You're playing a game!"

	mob_overlay_icon = 'icons/rogue-star/misc.dmi'

	var/mode = 0	//0 is nothing, 1 is hide, 2 is seek lol
	var/last_getter
	var/last_got_time = 0
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
	if(!vore_point)
		return
	if(isbelly(holder.loc))
		var/obj/belly/B = holder.loc
		var/datum/modifier/hide_and_seek/mod = B.owner.get_modifier_of_type(/datum/modifier/hide_and_seek)
		if(mod)
			if(B.owner.name == last_getter)
				if(world.time < last_got_time + 5 MINUTES)
					vore_point = FALSE
					return
			scorekeeper.vorescore[holder.name] = scorekeeper.vorescore[holder.name]+ 1
			scorekeeper.vorescore[mod.holder.name] = scorekeeper.vorescore[mod.holder.name] + 1
		vore_point = FALSE

/datum/modifier/hide_and_seek/proc/tagged()	//Someone clicked our mob! Let's make sure they are a seeker!
	if(mode != 1)	//We are not hiding so we don't really need to worry about anything right now!
		return

	var/mob/living/L = args[2]
	if(!L)
		return
	if(L == holder)
		return

	if(L.name == last_getter)
		if(world.time < last_got_time + 5 MINUTES)
			to_chat(L,SPAN_DANGER("You found \the [holder] too recently, try seeking someone else for now."))
			return

	var/datum/modifier/hide_and_seek/mod = L.get_modifier_of_type(/datum/modifier/hide_and_seek)

	if(!mod)
		return

	if(mod.mode == 2)	//They are a seeker!
		team("CAUGHT")
		scorekeeper.seekscore[L.name] = scorekeeper.seekscore[L.name] + 1
		last_getter = L.real_name
		last_got_time = world.time
		L.grant_xp("Seeking", 1)
		to_chat(holder, SPAN_DANGER("\The [L] tagged you. You have been caught."))
		to_chat(L, SPAN_NOTICE("You tagged \the [holder] and gained a point! \The [holder] has been caught."))
		if(vore_point)
			to_chat(L, span_alien("You can get a vore point too if you eat [holder]. Make sure your prefs line up though!"))

/datum/modifier/hide_and_seek/proc/team(var/team)
	switch(team)
		if("Hide")
			mode = 1
			mob_overlay_state = "hide"
		if("Seek")
			mode = 2
			mob_overlay_state = "seek"
		if("CAUGHT")
			mode = 0
			mob_overlay_state = null
			holder.update_modifier_visuals()

	vore_point = TRUE
	holder.update_modifier_visuals()

/datum/modifier/hide_and_seek/proc/round_end()
	if(mode == 1)
		scorekeeper.hidescore[holder.name] = scorekeeper.hidescore[holder.name] + 1
		holder.grant_xp("Hiding", 1)
	mode = 0
	vore_point = 0
	mob_overlay_state = null
	holder.update_modifier_visuals()
