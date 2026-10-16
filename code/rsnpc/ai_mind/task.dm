/datum/npc_task
	var/name = "task"
	var/tier = NPC_TIER_IDLE
	var/fail_sleep = 1 MINUTE
	var/slept_until = 0
	var/list/uses
	var/assignment_type
	var/idle = FALSE

/datum/npc_task/proc/level(datum/ai_holder/rsnpc/ai_mind)
	if(assignment_type)
		var/datum/npc_assignment/A = ai_mind.assignment(assignment_type)
		if(A?.urgent)
			return max(tier, NPC_TIER_NEEDS)
	return tier

/datum/npc_task/proc/fact_true(datum/ai_holder/rsnpc/ai_mind, fact)
	return null

/datum/npc_task/proc/can_start(datum/ai_holder/rsnpc/ai_mind)
	if(!assignment_type)
		return TRUE
	var/datum/npc_assignment/A = ai_mind.assignment(assignment_type)
	return A && (A.state || A == ai_mind.active_request())

/datum/npc_task/proc/stopped(datum/ai_holder/rsnpc/ai_mind)
	if(istype(src, /datum/npc_task/work) && ai_mind.assignment(/datum/npc_assignment/stop_work))
		return TRUE
	if(!istype(src, /datum/npc_task/work) && !istype(src, /datum/npc_task/stroll) && !istype(src, /datum/npc_task/take_break))
		return FALSE
	if(ai_mind.assignment(/datum/npc_assignment/follow))
		return TRUE
	var/datum/npc_assignment/summons/S = ai_mind.assignment(/datum/npc_assignment/summons)
	if(!S || S.at_post || ai_mind.task == src)
		return FALSE
	return !work_at(ai_mind, S.place)

/datum/npc_task/proc/work_at(datum/ai_holder/rsnpc/ai_mind, area/A)
	return FALSE

/datum/npc_task/proc/must_finish(datum/ai_holder/rsnpc/ai_mind)
	return FALSE

/datum/npc_task/proc/value(datum/ai_holder/rsnpc/ai_mind)
	return 0

/datum/npc_task/proc/goal(datum/ai_holder/rsnpc/ai_mind)
	var/datum/npc_assignment/A = assignment_type ? ai_mind.assignment(assignment_type) : null
	return A ? A.goal(ai_mind) : list()

/datum/npc_task/proc/score(datum/ai_holder/rsnpc/ai_mind)
	if(world.time < slept_until || !can_start(ai_mind) || stopped(ai_mind))
		return 0
	var/v = value(ai_mind)
	if(assignment_type)
		var/datum/npc_assignment/A = ai_mind.assignment(assignment_type)
		if(A && !A.state)
			v = 50 + A.importance
	return v * ai_mind.bored_factor(type) * ai_mind.task_weight(src)

/datum/npc_task/work
	name = "work"
	tier = NPC_TIER_FULFILLMENT
