/datum/npc_action/go_near
	name = "go near"

/datum/npc_action/go_near/variants(datum/ai_holder/rsnpc/ai_mind, fact)
	if(findtext(fact, "near:") != 1)
		return list()
	var/mob/living/M = locate(copytext(fact, 6))
	if(!istype(M))
		return list()
	var/datum/npc_action/A = copy(M, 1, null, list(fact))
	A.name = "go to [M]"
	return list(A)

/datum/npc_action/go_near/tick(datum/ai_holder/rsnpc/ai_mind)
	var/mob/living/M = target
	if(ai_mind.fact_true(gives[1]))
		if(ai_mind.destination)
			ai_mind.stop_walk()
		return NPC_DONE
	var/turf/T = ai_mind.where_seen(M)
	if(!T)
		why = "lost sight of them"
		return NPC_CANT_REACH
	if(!(M in ai_mind.look()) && npc_arrived(ai_mind.holder, T))
		why = "they're not where I last saw them"
		return NPC_NOT_THERE
	if(heading && !npc_arrived(ai_mind.holder, heading) && get_z(T) == get_z(heading) && get_dist(T, heading) <= 3)
		T = heading
	return head_to(ai_mind, T)

/datum/ai_holder/rsnpc/proc/reach_spot(mob/living/M)
	return (M in look()) ? M : where_seen(M)

/datum/ai_holder/rsnpc/proc/where_seen(mob/living/M)
	if(M in look())
		return get_turf(M)
	var/datum/npc_person/P = opinions[npc_person_key(M)]
	if(!P?.seen_turf || world.time > P.seen_at + 1 MINUTE)
		return null
	var/datum/npc_room/R = npc_room_of(P.seen_turf)
	if(R)
		for(var/datum/npc_link/L as anything in R.links)
			if((L.kind == NPC_LINK_STAIRS || L.kind == NPC_LINK_LADDER || L.kind == NPC_LINK_PORTAL) && get_dist(L.tiles[1], P.seen_turf) <= 1)
				return L.far
	return P.seen_turf

/datum/npc_action/go_into
	name = "go into"

/datum/npc_action/go_into/variants(datum/ai_holder/rsnpc/ai_mind, fact)
	if(findtext(fact, "in:") != 1)
		return list()
	var/area/R = locate(copytext(fact, 4))
	if(!istype(R))
		return list()
	var/datum/npc_action/A = copy(R, 1, null, list(fact))
	A.name = "go to [R]"
	return list(A)

/datum/npc_task/vacate_airlock
	name = "prevent a traffic jam"
	tier = NPC_TIER_FULFILLMENT

/datum/npc_task/vacate_airlock/can_start(datum/ai_holder/rsnpc/ai_mind)
	return !ai_mind.destination && isturf(ai_mind.holder.loc) && !ai_mind.holder.pulledby && npc_cycling_airlock_at(ai_mind.holder.loc)

/datum/npc_task/vacate_airlock/value(datum/ai_holder/rsnpc/ai_mind)
	return 90

/datum/npc_task/vacate_airlock/goal(datum/ai_holder/rsnpc/ai_mind)
	return list(NPC_FACT_OUT_OF_AIRLOCK)

/datum/npc_action/vacate_airlock
	name = "vacate airlock"

/datum/npc_action/vacate_airlock/variants(datum/ai_holder/rsnpc/ai_mind, fact)
	if(fact != NPC_FACT_OUT_OF_AIRLOCK)
		return list()
	var/turf/here = get_turf(ai_mind.holder)
	for(var/dir in GLOB.cardinal)
		var/turf/N = get_step(here, dir)
		if(N?.npc_room && !(locate(/mob/living) in N) && npc_can_step(here, N, ai_mind.holder.GetAccess(), ai_mind.holder))
			return list(copy(N, 1, null, list(fact)))
	return list()

/datum/npc_action/vacate_airlock/run_action(datum/ai_holder/rsnpc/ai_mind)
	return NPC_DONE
