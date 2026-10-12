/datum/npc_action/go_near
	name = "go near"
	var/turf/aim

/datum/npc_action/go_near/variants(datum/ai_holder/complex_npc/ai_mind, fact)
	if(findtext(fact, "near:") != 1)
		return list()
	var/mob/living/M = locate(copytext(fact, 6))
	if(!istype(M))
		return list()
	var/datum/npc_action/A = copy(M, 1, null, list(fact))
	A.name = "go to [M]"
	return list(A)

/datum/npc_action/go_near/tick(datum/ai_holder/complex_npc/ai_mind)
	var/mob/living/M = target
	if(ai_mind.fact_true(gives[1]))
		if(ai_mind.destination)
			ai_mind.stop_walk()
		return NPC_DONE
	var/turf/T = ai_mind.where_seen(M)
	if(!T)
		why = "lost sight of them"
		return NPC_CANT_REACH
	if(sent && !ai_mind.destination && ai_mind.walk_outcome_why)
		why = ai_mind.walk_outcome_why
		return NPC_CANT_REACH
	if(sent && get_z(T) == get_z(aim) && get_dist(T, aim) <= 3)
		return NPC_RUNNING
	sent = TRUE
	aim = T
	ai_mind.go_to(T)
	return NPC_RUNNING

/datum/ai_holder/complex_npc/proc/where_seen(mob/living/M)
	if(M in look())
		return get_turf(M)
	var/datum/npc_person/P = opinions[npc_person_key(M)]
	if(!P?.seen_turf || world.time > P.seen_at + 1 MINUTE)
		return null
	var/datum/npc_room/R = npc_room_of(P.seen_turf)
	if(R)
		for(var/datum/npc_link/L as anything in R.links)
			if((L.kind == NPC_LINK_STAIRS || L.kind == NPC_LINK_LADDER) && get_dist(L.tiles[1], P.seen_turf) <= 1)
				return L.far
	return P.seen_turf

/datum/npc_action/go_into
	name = "go into"

/datum/npc_action/go_into/variants(datum/ai_holder/complex_npc/ai_mind, fact)
	if(findtext(fact, "in:") != 1)
		return list()
	var/area/R = locate(copytext(fact, 4))
	if(!istype(R))
		return list()
	var/datum/npc_action/A = copy(R, 1, null, list(fact))
	A.name = "go to [R]"
	return list(A)
