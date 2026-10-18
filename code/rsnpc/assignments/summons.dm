/datum/npc_command/come_to
	say = "come to"
	radio = TRUE
	repeat = 15 SECONDS
	obedience = 21

/datum/npc_command/come_to/run_command(datum/ai_holder/rsnpc/ai_mind, mob/living/speaker, rest, via)
	var/area/A = npc_area_named(rest, ai_mind.holder)
	if(!A)
		NPC_TRACE(ai_mind, NPC_TRACE_TALK, "no room called \"[rest]\"")
		ai_mind.say_line("summons_where", list("name" = speaker.name), via)
		return
	ai_mind.start_summons(speaker, A, via, FALSE)

/datum/npc_command/come_here
	say = "come here"
	repeat = 15 SECONDS
	obedience = 21

/datum/npc_command/come_here/run_command(datum/ai_holder/rsnpc/ai_mind, mob/living/speaker, rest, via)
	var/area/A = (speaker in ai_mind.look()) ? get_area(speaker) : npc_area_named(rest, ai_mind.holder)
	if(!A)
		ai_mind.say_line("summons_where", list("name" = speaker.name), via)
		return
	ai_mind.start_summons(speaker, A, via, FALSE)

/datum/npc_command/go_to_your_post
	say = "go to your post"
	radio = TRUE
	repeat = 15 SECONDS
	obedience = 15

/datum/npc_command/go_to_your_post/run_command(datum/ai_holder/rsnpc/ai_mind, mob/living/speaker, rest, via)
	var/list/blanks = list("name" = speaker.name)
	if(!ai_mind.workplace)
		ai_mind.say_line("summons_no_post", blanks, via)
		return
	if(npc_arrived(ai_mind.holder, ai_mind.workplace))
		ai_mind.say_line("summons_already_at_post", blanks, via)
		return
	ai_mind.start_summons(speaker, ai_mind.workplace, via, TRUE)

/proc/npc_area_named(line, mob/living/near)
	var/area/best
	var/best_name
	var/best_distance
	for(var/area/A as anything in GLOB.npc_rooms.area_rooms)
		var/name = npc_clean_line(A.name)
		if(!name || !npc_has_words(line, name) || length(name) < length(best_name))
			continue
		var/distance
		for(var/datum/npc_room/R as anything in GLOB.npc_rooms.area_rooms[A])
			var/d = get_dist(near, R.middle) + abs(get_z(near) - R.z) * 20
			if(isnull(distance) || d < distance)
				distance = d
		if(length(name) == length(best_name) && distance >= best_distance)
			continue
		best = A
		best_name = name
		best_distance = distance
	return best

/datum/ai_holder/rsnpc/proc/start_summons(mob/living/M, area/A, via, at_post)
	var/list/blanks = list("name" = M.name, "place" = "[A]")
	var/datum/npc_assignment/follow/F = assignment(/datum/npc_assignment/follow)
	if(F && F.asker?.resolve() != M)
		NPC_TRACE(src, NPC_TRACE_TALK, "can't go to [A] for [M]; following [F.asker_name]")
		blanks["other"] = F.asker_name
		say_line("follow_already_busy", blanks, via)
		return
	if(!at_post && npc_arrived(holder, A))
		NPC_TRACE(src, NPC_TRACE_TALK, "[M] called me to [A]; I'm already here")
		say_now("summons_arrived_room", blanks, via)
		return
	var/datum/npc_assignment/summons/T = new(M, via, 5 MINUTES)
	T.name = "go to [A]"
	T.place = A
	T.at_post = at_post
	T.wait = at_post ? 0 : npc_psetting("come_to_wait_minutes") MINUTES
	start_assignment(T, at_post ? "summons_agreed_post" : "summons_agreed_room")

/datum/npc_assignment/summons
	weight = 10
	name = "summons"
	uses_legs = TRUE
	time_up_line = "summons_gave_up"
	max_failures = 2
	failed_line = "summons_cant_get_there"
	var/area/place
	var/wait = 0
	var/arrived_at = 0
	var/at_post = FALSE

/datum/npc_assignment/summons/blanks()
	var/list/blanks = ..()
	blanks["place"] = "[place]"
	return blanks

/datum/ai_holder/rsnpc/proc/called_to()
	var/datum/npc_assignment/summons/A = assignment(/datum/npc_assignment/summons)
	return (A && !A.at_post && A.arrived_at) ? A.place : null

/datum/npc_assignment/summons/proc/pending(datum/ai_holder/rsnpc/ai_mind)
	return !arrived_at || !at_post && !ai_mind.noted("looked:\ref[place]")

/datum/npc_assignment/summons/wants_turn(datum/ai_holder/rsnpc/ai_mind)
	return pending(ai_mind)

/datum/npc_assignment/summons/needs_legs(datum/ai_holder/rsnpc/ai_mind)
	return pending(ai_mind)

/datum/npc_assignment/summons/goal(datum/ai_holder/rsnpc/ai_mind)
	return at_post ? list(NPC_FACT_IN(place)) : list(NPC_FACT_IN(place), "looked:\ref[place]")

/datum/npc_assignment/summons/check(datum/ai_holder/rsnpc/ai_mind)
	if(!arrived_at && npc_arrived(ai_mind.holder, place))
		arrived_at = world.time
		ai_mind.say_line(at_post ? "summons_arrived_post" : "summons_arrived_room", blanks(), via)
	if(arrived_at)
		if(world.time >= arrived_at + wait)
			ai_mind.end_assignment(src, at_post ? "back at my post" : "waited long enough", at_post ? null : "summons_done_room")
		return
	..()

/datum/npc_task/summons
	name = "summons"
	tier = NPC_TIER_SOCIAL
	assignment_type = /datum/npc_assignment/summons

/datum/npc_task/summons/value(datum/ai_holder/rsnpc/ai_mind)
	return 100

/datum/npc_task/summons/can_start(datum/ai_holder/rsnpc/ai_mind)
	var/datum/npc_assignment/summons/A = ai_mind.assignment(/datum/npc_assignment/summons)
	return A && A.pending(ai_mind)

/datum/npc_task/summons/fact_true(datum/ai_holder/rsnpc/ai_mind, fact)
	if(findtext(fact, "looked:") == 1)
		return !!ai_mind.noted(fact)
	return null

/datum/npc_action/look_around
	name = "look around"

/datum/npc_action/look_around/variants(datum/ai_holder/rsnpc/ai_mind, fact)
	if(findtext(fact, "looked:") != 1)
		return list()
	var/area/A = locate(copytext(fact, 8))
	if(!istype(A) || !length(GLOB.npc_rooms.area_rooms[A]))
		return list()
	var/turf/far
	var/list/access = ai_mind.holder.GetAccess()
	for(var/datum/npc_room/R as anything in GLOB.npc_rooms.area_rooms[A])
		var/open = !length(R.links)
		for(var/datum/npc_link/L as anything in R.links)
			if(L.navigable_by(access))
				open = TRUE
				break
		if(!open)
			continue
		if(!far || get_dist(ai_mind.holder, R.middle) > get_dist(ai_mind.holder, far))
			far = R.middle
	if(!far)
		return list()
	var/datum/npc_action/look_around/L = copy(far, 1, list(NPC_FACT_IN(A)), list(fact))
	L.want = A
	L.name = "look around [A]"
	return list(L)

/datum/npc_action/look_around/run_action(datum/ai_holder/rsnpc/ai_mind)
	ai_mind.note(gives[1], "[want]", 5 MINUTES)
	return NPC_DONE

/datum/ai_holder/rsnpc/proc/work_spot()
	var/datum/npc_assignment/summons/A = assignment(/datum/npc_assignment/summons)
	if(A && A.arrived_at && !A.at_post)
		return A.place
	return workplace
