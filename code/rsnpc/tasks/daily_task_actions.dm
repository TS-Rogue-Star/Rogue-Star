/proc/npc_public_area(area/A)
	if(istype(A, /area/maintenance) || istype(A, /area/space) || istype(A, /area/shuttle))
		return FALSE
	return !findtext(lowertext(A.name), "maint")

/datum/npc_action/stand_at_workplace
	name = "stand at workplace"

/datum/npc_action/stand_at_workplace/variants(datum/ai_holder/rsnpc/ai_mind, fact)
	var/area/spot = ai_mind.work_spot()
	if(fact != NPC_FACT_WORKED || !spot)
		return list()
	var/datum/npc_action/A = copy(spot, 1, null, list(NPC_FACT_WORKED))
	A.stay = 3 MINUTES
	return list(A)

/datum/npc_action/stroll
	name = "stroll"

/datum/npc_action/stroll/variants(datum/ai_holder/rsnpc/ai_mind, fact)
	if(fact != NPC_FACT_STROLLED)
		return list()
	var/datum/npc_room/here = npc_room_of(ai_mind.holder)
	if(!here)
		return list()
	var/list/access = ai_mind.holder.GetAccess()
	var/list/depth = list()
	depth[here] = 0
	var/list/queue = list(here)
	var/list/picks = list()
	var/i = 0
	while(i < length(queue))
		var/datum/npc_room/R = queue[++i]
		if(depth[R] >= 4)
			continue
		for(var/datum/npc_link/L as anything in R.links)
			var/datum/npc_room/next = L.into
			if(!isnull(depth[next]) || !L.navigable_by(access))
				continue
			depth[next] = depth[R] + 1
			queue += next
			if(next.size >= 10 && next.area != here.area && !ai_mind.noted("stroll:\ref[next.area]") && npc_air_known_safe(next.middle, ai_mind.holder))
				picks |= next.area
	if(!length(picks))
		return list()
	var/datum/npc_action/A = copy(pick(picks), 1, null, list(NPC_FACT_STROLLED))
	A.stay = 20 SECONDS
	return list(A)

/datum/npc_action/stroll/arrive(datum/ai_holder/rsnpc/ai_mind)
	ai_mind.note("stroll:\ref[target]", "[target]", 5 MINUTES)
	return TRUE

/datum/npc_action/sit_down
	name = "sit down"
	var/obj/structure/bed/chair/seat
	var/seated_at = 0

/datum/npc_action/sit_down/variants(datum/ai_holder/rsnpc/ai_mind, fact)
	if(fact != NPC_FACT_RESTED)
		return list()
	var/datum/npc_source/S = ai_mind.npc_search(/obj/structure/bed/chair, CALLBACK(src, PROC_REF(good_seat), ai_mind))
	if(!S)
		return list()
	var/datum/npc_action/A = copy(S.place, 1 + S.cost / 10, null, list(NPC_FACT_RESTED))
	A.stay = ai_mind.npc_psetting("break_seconds") SECONDS
	return list(A)

/datum/npc_action/sit_down/proc/good_seat(datum/ai_holder/rsnpc/ai_mind, kind, turf/place, atom/movable/thing)
	if(ispath(kind, /obj/structure/bed/chair/wheelchair) || ispath(kind, /obj/structure/bed/chair/janicart))
		return FALSE
	var/area/A = get_area(place)
	if(!A || !npc_public_area(A))
		return FALSE
	var/area/called = ai_mind.called_to()
	if(called && A != called)
		return FALSE
	return !thing || !thing.has_buckled_mobs()

/datum/npc_action/sit_down/arrive(datum/ai_holder/rsnpc/ai_mind)
	var/turf/T = target
	for(var/obj/structure/bed/chair/C in T)
		if(!C.has_buckled_mobs())
			seat = C
			break
	if(!seat)
		why = "the seat is gone or taken"
		ai_mind.cross_off(npc_place_key(T), 2 MINUTES, why)
		return FALSE
	seat.user_buckle_mob(ai_mind.holder, ai_mind.holder)
	if(ai_mind.holder.buckled != seat)
		why = "could not sit down"
		return FALSE
	seated_at = world.time
	NPC_TRACE(ai_mind, NPC_TRACE_TASK, "sitting down in [get_area(T)]")
	return TRUE

/datum/npc_action/sit_down/clean_up(datum/ai_holder/rsnpc/ai_mind)
	if(seated_at)
		var/datum/npc_need/N = ai_mind.needs[NPC_NEED_REST]
		N?.add((world.time - seated_at) / (1 MINUTE) * ai_mind.npc_psetting("rest_gain_per_minute"))
		seated_at = 0
	if(seat && ai_mind.holder.buckled == seat)
		seat.user_unbuckle_mob(ai_mind.holder, ai_mind.holder)
	seat = null
