//RS FILE
#define TAG_OVERLAY_ICON "it"
#define TAG_DISABLE_ICON "disabled"

/client/proc/tag_game()	//I'm sorry
	set name = "Tag Game"
	set category = "Fun"

	if(!check_rights(R_FUN))
		return

	var/mode = tgui_alert(usr,"Tag or Infection?","MODE SELECT",list("TAG","INFECTION","REPORT","STOP"))
	if(!mode)
		return
	if(mode == "REPORT" || mode == "STOP")
		var/list/scores = list()
		for(var/mob/living/L in world)
			for(var/datum/modifier/M in L.modifiers)
				if(istype(M,/datum/modifier/tag_game))
					var/datum/modifier/tag_game/T = M
					if(T.score)
						scores[T.holder.name] = T.score
					if(mode == "STOP")
						if(M.mob_overlay_state != TAG_DISABLE_ICON)	//The only thing that really changes when it's disabled is the iconstate so we'll just use that for truth
							T.expire()
						else
							T.enable_locked = FALSE	//While false, players can re-enable their tag!
		if(scores.len)
			var/report = report_scores("INFECTION SCORES",scores)
			to_chat(usr,report)
			if(tgui_alert(usr,"Would you like to report the scores to everyone?","INFECTION SCORES",list("Yes","No")) != "Yes")
				return
			for(var/mob/M in player_list)
				if(M == usr)
					continue
				to_chat(M,report)
			to_chat(usr,SPAN_NOTICE("Scores reported."))
		return
	var/mob/living/choice
	if(tgui_alert(usr,"Do you want to select the first person to be 'it', or should they be randomly selected?","[mode] SELECT",list("Choose","Random")) == "Random")
		var/z_mode = tgui_alert(usr,"Would you like the system to pick from all Zs or just the one you are on?","[mode] SELECT",list("All Zs","This Z", "Cancel"))
		if(z_mode == "Cancel")
			return
		var/list/valid_targets = list()
		for(var/mob/living/L in player_list)	//We're randomly picking a target, so we're gonna try to cut the list down to try to make a smart choice
			if(!isliving(L))	//The player_list contains ghosts I think, so we'll ignore all of them
				continue
			if(isAI(L))	//AI can't move, so we'll ignore it
				continue
			if(L.client?.inactivity > 3 MINUTES)	//It would be boring to pick someone who's afk
				continue
			if(z_mode == "This Z")	//And if the event runner picked "This Z" then we'll only pick from the Z our usr is on
				var/turf/ourturf = get_turf(usr)
				if(L.z != ourturf.z)
					continue
			var/invalid = FALSE
			for(var/datum/modifier/tag_game/game in L.modifiers)	//Let's also make sure we don't pick anyone who already has the modifier.
				if(!istype(game,/datum/modifier/tag_game))
					continue
				if(game.mob_overlay_state == TAG_DISABLE_ICON)
					invalid = TRUE
					break
			if(invalid)
				continue
			valid_targets |= L
		choice = pick(valid_targets)	//Now you're cooking with gas
	else
		choice = tgui_input_list(usr,"Who will be the first 'it'?","[mode] SELECT",player_list)
	if(!choice)
		return
	if(!isliving(choice))
		to_chat(usr,SPAN_DANGER("[choice] is not a living target, you should probably pick someone else."))
		return	//Rekt
	var/type
	if(mode == "INFECTION")
		type = /datum/modifier/tag_game/infection
	else
		type = /datum/modifier/tag_game

	if(!choice.add_modifier(type))	//You're it!
		to_chat(usr,SPAN_DANGER("[choice] isn't valid for some reason. They may be already tagged, or have disabled tag. Pick someone else!"))

/datum/modifier/tag_game
	name = "Tagged"

	mob_overlay_icon = 'icons/rogue-star/misc.dmi'
	mob_overlay_state = TAG_OVERLAY_ICON
	var/infinite = FALSE
	var/score = 0
	var/enable_locked = FALSE

/datum/modifier/tag_game/proc/tagged(var/mob/living/L)
	if(!L.client)
		to_chat(holder,SPAN_WARNING("You can't tag \the [L], tagging only works on player controlled mobs!"))
		return
	if(!holder.Adjacent(L))
		to_chat(holder,SPAN_WARNING("You need to get closer!"))
		return
	if(!L.add_modifier(src.type))
		return
	if(!infinite)
		expire()
		return
	score ++

/datum/modifier/tag_game/New(new_holder, new_origin)
	. = ..()
	if(mob_overlay_state == TAG_DISABLE_ICON)	//This doesn't really get used but maybe if you want people to be able to start with tag disabled you can lol
		return
	if(infinite)	//Infection vs Tag, tag expires when you tag someone, infection doesn't, ezpz
		to_chat(holder,FONT_LARGE(SPAN_DANGER("YOU ARE INFECTED!!!")))
		holder.throw_alert("tag", /obj/screen/alert/tagged/infected)
		if(iscarbon(holder))
			to_chat(holder,SPAN_DANGER("Help, disarm, or grab someone to infect them too!"))
		else
			to_chat(holder,SPAN_DANGER("Help someone to infect them too!"))
	else
		to_chat(holder,FONT_LARGE(SPAN_DANGER("YOU ARE IT!!!")))
		holder.throw_alert("tag", /obj/screen/alert/tagged)
		if(iscarbon(holder))
			to_chat(holder,SPAN_DANGER("Help, disarm, or grab someone to tag them!"))
		else
			to_chat(holder,SPAN_DANGER("Help someone to tag them!"))

/datum/modifier/tag_game/expire(silent)
	. = ..()
	if(!silent)	//If you disable tag and then re-enable it, it causes the modifier to expire, and it would be a little silly to tell someone they're no longer it then.
		to_chat(holder,FONT_LARGE(SPAN_NOTICE("You are no longer it!")))
	holder.clear_alert("tag")
	if(score > 0)
		to_chat(holder,SPAN_NOTICE("You infected [score] others!"))
	if(ishuman(holder))
		holder.update_modifier_visuals()
	else
		holder.update_icon()

/datum/modifier/tag_game/proc/disable_tag()	//For people who hate fun and whimsy
	QDEL_NULL(overlay_image)
	if(mob_overlay_state != TAG_DISABLE_ICON)
		to_chat(holder,FONT_LARGE(SPAN_NOTICE("You will no longer be able to be able to tag or be tagged this shift.")))
		mob_overlay_state = TAG_DISABLE_ICON
		score = 0
		holder.clear_alert("tag")
		if(ishuman(holder))
			holder.update_modifier_visuals()	//Humans don't have update_icons and that's wild
		else
			holder.update_icon()	//I put update_modifier_visuals in everything but humans update_icons so it does both. Basically we want to make sure it properly cuts the overlays before applying them!
		log_and_message_admins(SPAN_DANGER("[holder.name] has DISABLED tag, and is no longer taggable."))
		holder.throw_alert("tag", /obj/screen/alert/tagged/disabled)
		enable_locked = TRUE
		if(!infinite)
			pass_it_on()
	else if(!enable_locked)
		to_chat(holder,FONT_LARGE(SPAN_NOTICE("You are now eligable to be tagged again!")))
		log_and_message_admins(SPAN_DANGER("[holder.name] has RE-ENABLED tag."))
		holder.clear_alert("tag")
		expire(TRUE)	//Expire SNEAKILY so people don't get weirded out
	else
		to_chat(usr,SPAN_DANGER("You can't do that right now, wait until the next round of the game."))

/datum/modifier/tag_game/proc/pass_it_on()
	var/mob/living/choice = seek_random_target()
	if(!choice)
		log_and_message_admins("Tag player disabled tag, attempted to jump to new target, but was unable to find new target, so no new target was selected.")
	else
		log_and_message_admins("Tag player disabled tag, selected [choice] as new Tag target.")
		choice.add_modifier(/datum/modifier/tag_game)

/datum/modifier/tag_game/proc/seek_random_target()	//Duplicate code... gross - anyway, this lets us pick a random mob in case a solo tag instance gets rekt by someone disabling it
	var/list/valid_targets = list()
	for(var/mob/living/L in player_list)	//We're randomly picking a target, so we're gonna try to cut the list down to try to make a smart choice
		if(!isliving(L))	//The player_list contains ghosts I think, so we'll ignore all of them
			continue
		if(isAI(L))	//AI can't move, so we'll ignore it
			continue
		if(L.client?.inactivity > 3 MINUTES)	//It would be boring to pick someone who's afk
			continue
		var/invalid = FALSE
		for(var/datum/modifier/tag_game/game in L.modifiers)	//Let's also make sure we don't pick anyone who already has the modifier.
			if(!istype(game,/datum/modifier/tag_game))
				continue
			if(game.mob_overlay_state == TAG_DISABLE_ICON)
				invalid = TRUE
				break
		if(invalid)
			continue
		valid_targets |= L
	if(!valid_targets.len)
		return
	return pick(valid_targets)

/datum/modifier/tag_game/infection
	infinite = TRUE
	mob_overlay_state = "infected"

/datum/modifier/tag_game/disabled
	mob_overlay_state = TAG_DISABLE_ICON

/mob/living/proc/game_tag(var/mob/living/L)	//Called on the game infected src, to infect a new target (L)!
	if(!isliving(L))
		return
	if(L == src)	//U can't infect yourself in SS13, we are anti bug chasers here
		return
	for(var/datum/modifier/tag_game/M in modifiers)
		if(istype(M,/datum/modifier/tag_game))
			M.tagged(L)	//Gottem

/proc/list_get_greatest(var/list/ourlist = list())	//This should go somewhere else, anyway I got tired of wanting to get the greatest value in a list and having to remake the code every time so I made a general proc, you're welcome future me, but we both know you'll just forget and get annoyed and remake it again in yet another place
	if(!ourlist)
		log_and_message_admins("list_get_greatest was called but was not provided a list")
		return

	var/greatest

	for(var/thing in ourlist)
		if(!greatest)
			greatest = thing
			continue
		else if(ourlist[thing] > ourlist[greatest])
			greatest = thing
		else if(ourlist[thing] == ourlist[greatest])
			continue

	return greatest

/proc/report_scores(preamble = "SCOREBOARD",var/list/scores,style = "danger")	//Maybe I will make more things where we need to report scores! This should also probably co somewhere else.
	if(!islist(scores))
		return
	var/msg = "<font size='5'>[preamble]:</font><br>"
	while(scores.len)
		var/greatest = list_get_greatest(scores)
		msg += "[greatest]: [scores[greatest]]<br>"
		scores -= greatest
	return"<span class='[style]'>[msg]</span>"

/obj/screen/alert/tagged
	name = "YOU'RE IT!!!"
	desc = "You need to tag someone else!!!"
	icon = 'icons/mob/screen1.dmi'
	icon_state = "warnmarker"

/obj/screen/alert/tagged/Click(location, control, params)
	. = ..()
	if(tgui_alert(usr,"Would you like to toggle tag for the round?","TOGGLE TAG",list("Yes","No")) != "Yes")
		return
	if(isliving(usr))
		var/mob/living/L = usr
		for(var/datum/modifier/tag_game/M in L.modifiers)
			if(istype(M,/datum/modifier/tag_game))
				M.disable_tag()

/obj/screen/alert/tagged/infected
	name = "YOU'RE INFECTED!!!"
	desc = "You need to tag others to infect them!!!"
	icon = 'icons/mob/screen1_stats.dmi'
	icon_state = "biohazard_protection_icon"

/obj/screen/alert/tagged/disabled
	name = "Tag Disabled"
	desc = "You can't tag or be tagged! You can click this to re-enable tag if you want!"
	icon = 'icons/mob/screen1_animal.dmi'
	icon_state = "blocked"

#undef TAG_OVERLAY_ICON
#undef TAG_DISABLE_ICON
