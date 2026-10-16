/datum/npc_task/consume
	tier = NPC_TIER_FULFILLMENT
	uses = list(/obj/structure/closet, /obj/machinery/vending)
	var/need
	var/fact
	var/start_at = 0
	var/weight = 100

/datum/npc_task/consume/can_start(datum/ai_holder/rsnpc/ai_mind)
	return ai_mind.need_pressure(need) > start_at

/datum/npc_task/consume/value(datum/ai_holder/rsnpc/ai_mind)
	return weight * ai_mind.need_pressure(need)

/datum/npc_task/consume/goal(datum/ai_holder/rsnpc/ai_mind)
	return list(fact)

/datum/npc_task/consume/eat
	name = "eat"
	need = NPC_NEED_HUNGER
	fact = NPC_FACT_FED

/datum/npc_task/consume/eat/starving
	name = "eat, starving"
	tier = NPC_TIER_NEEDS

/datum/npc_task/consume/eat/starving/can_start(datum/ai_holder/rsnpc/ai_mind)
	return ai_mind.need_pressure(need) >= ai_mind.npc_psetting("starving_threshold")

/datum/npc_task/consume/drink
	name = "have a drink"
	need = NPC_NEED_REST
	fact = NPC_FACT_DRANK
	start_at = 0.5
	weight = 50

/datum/npc_task/consume/drink/can_start(datum/ai_holder/rsnpc/ai_mind)
	return ..() && !ai_mind.noted("drank")
