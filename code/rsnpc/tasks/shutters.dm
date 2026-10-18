/datum/ai_holder/rsnpc/proc/shutters_down()
	if(!workplace || get_area(holder) != workplace || !(istype(role, /datum/npc_role/service) || istype(role, /datum/npc_role/medical)))
		return list()
	. = list()
	var/list/seen_here = look()
	for(var/obj/machinery/door/blast/D in seen_here)
		if(!D.density || get_area(D) != workplace)
			continue
		for(var/obj/machinery/button/remote/blast_door/B in seen_here)
			if(B.id == D.id && get_area(B) == workplace)
				. |= B

/datum/ai_holder/rsnpc/proc/shutter_button()
	for(var/obj/machinery/button/remote/blast_door/B as anything in shutters_down())
		if(!(B.stat & (NOPOWER|BROKEN)) && B.allowed(holder))
			return B
	return null

/datum/npc_task/raise_shutters
	name = "raise the shutters"
	tier = NPC_TIER_FULFILLMENT

/datum/npc_task/raise_shutters/can_start(datum/ai_holder/rsnpc/ai_mind)
	return !ai_mind.fact_true(NPC_FACT_SHUTTERS_UP)

/datum/npc_task/raise_shutters/value(datum/ai_holder/rsnpc/ai_mind)
	return 80

/datum/npc_task/raise_shutters/goal(datum/ai_holder/rsnpc/ai_mind)
	return list(NPC_FACT_SHUTTERS_UP)

/datum/npc_action/press_shutter_button
	name = "press the shutter button"
	var/pressed_at = 0

/datum/npc_action/press_shutter_button/variants(datum/ai_holder/rsnpc/ai_mind, fact)
	if(fact != NPC_FACT_SHUTTERS_UP)
		return list()
	var/obj/machinery/button/remote/blast_door/B = ai_mind.shutter_button()
	return B ? list(copy(B, 1, null, list(fact))) : list()

/datum/npc_action/press_shutter_button/run_action(datum/ai_holder/rsnpc/ai_mind)
	if(!(target in ai_mind.shutters_down()))
		return NPC_DONE
	if(!pressed_at)
		if(!ai_mind.use_hand(target))
			return NPC_RUNNING
		pressed_at = world.time
		ai_mind.say_line("narrate_raise_shutters", list())
		return NPC_RUNNING
	if(world.time > pressed_at + 5 SECONDS)
		why = "the shutters didn't open"
		return NPC_CANT_DO
	return NPC_RUNNING
