/datum/npc_task/work/workplace
	name = "go to workplace"
	fail_sleep = 2 MINUTES

/datum/npc_task/work/workplace/can_start(datum/ai_holder/rsnpc/ai_mind)
	return !!ai_mind.work_spot()

/datum/npc_task/work/workplace/value(datum/ai_holder/rsnpc/ai_mind)
	return 30

/datum/npc_task/work/workplace/goal(datum/ai_holder/rsnpc/ai_mind)
	return list(NPC_FACT_WORKED)

/datum/npc_task/stroll
	name = "stroll"
	tier = NPC_TIER_FULFILLMENT

/datum/npc_task/stroll/can_start(datum/ai_holder/rsnpc/ai_mind)
	return ai_mind.need_pressure(NPC_NEED_REST) < 0.3

/datum/npc_task/stroll/value(datum/ai_holder/rsnpc/ai_mind)
	return 20

/datum/npc_task/stroll/goal(datum/ai_holder/rsnpc/ai_mind)
	return list(NPC_FACT_STROLLED)

/datum/npc_task/take_break
	name = "take a break"
	tier = NPC_TIER_FULFILLMENT
	uses = list(/obj/structure/bed/chair)

/datum/npc_task/take_break/can_start(datum/ai_holder/rsnpc/ai_mind)
	return ai_mind.need_pressure(NPC_NEED_REST) > 0

/datum/npc_task/take_break/work_at(datum/ai_holder/rsnpc/ai_mind, area/A)
	return TRUE

/datum/npc_task/take_break/value(datum/ai_holder/rsnpc/ai_mind)
	return 100 * ai_mind.need_pressure(NPC_NEED_REST)

/datum/npc_task/take_break/goal(datum/ai_holder/rsnpc/ai_mind)
	return list(NPC_FACT_RESTED)
