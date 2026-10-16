/datum/npc_action
	var/name = "action"
	var/cost = 1
	var/last_resort = FALSE
	var/list/needs = list()
	var/list/gives = list()
	var/atom/target
	var/turf/target_place
	var/key
	var/want
	var/stay = 0
	var/stay_until = 0
	var/atom/heading
	var/arrived = FALSE
	var/started_at = 0
	var/why
	var/idle = FALSE

/datum/npc_action/proc/variants(datum/ai_holder/rsnpc/ai_mind, fact)
	return list()

/datum/npc_action/proc/copy(atom/target, cost, list/needs, list/gives)
	var/datum/npc_action/A = new type
	A.target = target
	A.target_place = get_turf(target)
	A.cost = cost
	A.needs = needs || list()
	A.gives = gives || list()
	A.key = "[type]@[target ? "\ref[target]" : "none"]"
	return A

/datum/npc_action/proc/tick(datum/ai_holder/rsnpc/ai_mind)
	idle = FALSE
	if(!started_at)
		started_at = world.time
	if(target && !arrived)
		if(!isturf(target) && !isarea(target) && (target in ai_mind.look()))
			target_place = get_turf(target)
		if(!npc_arrived(ai_mind.holder, target))
			if(world.time - started_at > 5 MINUTES)
				why = "took too long to get there"
				return NPC_NOT_YET
			return head_to(ai_mind, target, target_place)
		arrived = TRUE
		if(!arrive(ai_mind))
			return NPC_CANT_DO
	if(stay)
		idle = TRUE
		if(!stay_until)
			stay_until = world.time + stay
		return world.time >= stay_until ? NPC_DONE : NPC_RUNNING
	return run_action(ai_mind)

/datum/npc_action/proc/head_to(datum/ai_holder/rsnpc/ai_mind, atom/T, turf/place)
	if(ai_mind.destination == T || npc_arrived(ai_mind.holder, T))
		return NPC_RUNNING
	if(heading == T && ai_mind.walk_outcome_why)
		heading = null
		return walk_failed(ai_mind, T)
	heading = T
	ai_mind.go_to(T, place)
	return NPC_RUNNING

/datum/npc_action/proc/walk_failed(datum/ai_holder/rsnpc/ai_mind, atom/T)
	why = ai_mind.walk_outcome_why || "could not get there"
	return ai_mind.walk_lost_target ? NPC_NOT_THERE : NPC_CANT_REACH

/datum/npc_action/proc/arrive(datum/ai_holder/rsnpc/ai_mind)
	return TRUE

/datum/npc_action/proc/run_action(datum/ai_holder/rsnpc/ai_mind)
	return NPC_DONE

/datum/npc_action/proc/clean_up(datum/ai_holder/rsnpc/ai_mind)
	return
