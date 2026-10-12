/datum/npc_task
	var/name = "task"
	var/tier = NPC_TIER_IDLE
	var/fail_sleep = 1 MINUTE
	var/slept_until = 0
	var/list/uses
	var/assignment_type

/datum/npc_task/proc/can_start(datum/ai_holder/complex_npc/ai_mind)
	return !assignment_type || ai_mind.assignment(assignment_type)

/datum/npc_task/proc/stopped(datum/ai_holder/complex_npc/ai_mind)
	return istype(src, /datum/npc_task/work) && ai_mind.assignment(/datum/npc_assignment/stop_work)

/datum/npc_task/proc/value(datum/ai_holder/complex_npc/ai_mind)
	return 0

/datum/npc_task/proc/goal(datum/ai_holder/complex_npc/ai_mind)
	var/datum/npc_assignment/A = assignment_type ? ai_mind.assignment(assignment_type) : null
	return A ? A.goal(ai_mind) : list()

/datum/npc_task/proc/score(datum/ai_holder/complex_npc/ai_mind)
	if(world.time < slept_until || !can_start(ai_mind) || stopped(ai_mind))
		return 0
	return value(ai_mind) * ai_mind.bored_factor(type) * ai_mind.task_weight(src)

/datum/npc_task/work
	name = "work"
	tier = NPC_TIER_FULFILLMENT
