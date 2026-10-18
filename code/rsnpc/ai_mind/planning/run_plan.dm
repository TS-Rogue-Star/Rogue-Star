/datum/ai_holder/rsnpc/proc/fact_true(fact)
	if(findtext(fact, "holding:") == 1)
		var/obj/item/I = locate(copytext(fact, 9))
		return istype(I) && !QDELETED(I) && holder.item_is_in_hands(I)
	if(findtext(fact, "have:") == 1)
		return !!held_item(text2path(copytext(fact, 6)))
	switch(fact)
		if(NPC_FACT_FED)
			return need_pressure(NPC_NEED_HUNGER) <= 0
		if(NPC_FACT_INTERNALS)
			return npc_on_air(holder)
		if(NPC_FACT_INTERNALS_OFF)
			return !holder.internal
		if(NPC_FACT_UNCUFFED)
			var/mob/living/carbon/C = holder
			return !istype(C) || !C.handcuffed && !C.legcuffed
		if(NPC_FACT_MASKED)
			var/mob/living/carbon/human/H = holder
			return (H.wear_mask && (H.wear_mask.item_flags & AIRTIGHT)) || (H.head && (H.head.item_flags & AIRTIGHT))
		if(NPC_FACT_BANDAGED)
			return !wound_to_dress(/obj/item/stack/medical/bruise_pack)
		if(NPC_FACT_SALVED)
			return !wound_to_dress(/obj/item/stack/medical/ointment)
		if(NPC_FACT_TREATED)
			return health_share() >= npc_psetting("medic_call_threshold")
		if(NPC_FACT_DRANK)
			return !!noted("drank")
		if(NPC_FACT_STOMACH_HANDLED)
			return !bellies_due()
		if(NPC_FACT_MOUTH_FREE)
			var/mob/living/carbon/human/H = holder
			return !istype(H) || !H.check_mouth_coverage()
		if(NPC_FACT_SHUTTERS_UP)
			return !length(shutters_down())
		if(NPC_FACT_SAFE)
			var/turf/T = get_turf(holder)
			return T && npc_safe_spot(holder, dangers_in_sight(), T)
	if(findtext(fact, "agreed_prey:") == 1)
		var/mob/living/P = locate(copytext(fact, 13))
		var/datum/npc_assignment/eat_prey/O = assignment(/datum/npc_assignment/eat_prey)
		return istype(P) && (O?.asker?.resolve() == P && O.mode == "agreed" || agreed(P, holder, FALSE))
	if(findtext(fact, "eaten:") == 1)
		var/mob/living/E = locate(copytext(fact, 7))
		var/obj/belly/B = E?.loc
		return istype(B) && B.owner == holder
	if(fact == NPC_FACT_OUT_OF_AIRLOCK)
		return !npc_cycling_airlock_at(get_turf(holder))
	if(fact == NPC_FACT_HAND_FREE)
		return !holder.hands_are_full()
	if(findtext(fact, "received:") == 1)
		var/datum/npc_assignment/receive/R = locate(copytext(fact, 10))
		return !istype(R) || R.received
	if(findtext(fact, "given:") == 1)
		var/datum/npc_assignment/give/G = locate(copytext(fact, 7))
		return !istype(G) || G.given
	if(findtext(fact, "gear:") == 1)
		var/datum/npc_gear/G = locate(copytext(fact, 6))
		return !istype(G) || G.in_place(holder)
	if(findtext(fact, "responded:") == 1)
		var/datum/npc_assignment/respond_stomach/R = locate(copytext(fact, 11))
		return !(R in assignments) || !length(R.requests)
	if(findtext(fact, "near:") == 1)
		var/mob/living/M = locate(copytext(fact, 6))
		return istype(M) && get_dist(M, holder) <= 2 && (M.Adjacent(holder) || (M in look()))
	if(findtext(fact, "greeted:") == 1)
		var/datum/npc_assignment/talk/T = assignment(/datum/npc_assignment/talk)
		return T && T.asker?.resolve() == locate(copytext(fact, 9))
	if(findtext(fact, "in:") == 1)
		var/area/A = locate(copytext(fact, 4))
		return istype(A) && npc_arrived(holder, A)
	return task ? !!task.fact_true(src, fact) : FALSE

/datum/ai_holder/rsnpc/proc/plan_tick()
	if(!task || world.time < step_wait_until)
		return
	if(!plan)
		make_plan()
		return
	do_step()

/datum/ai_holder/rsnpc/proc/make_plan()
	if(!plan_search)
		plan_search = new(src, task.goal(src))
	switch(plan_search.advance(300))
		if(NPC_PLAN_SEARCHING)
			return
		if(NPC_PLAN_FOUND)
			plan = plan_search.steps
			plan_step = 1
			var/list/names = list()
			for(var/datum/npc_action/A as anything in plan)
				names += A.name
			NPC_TRACE(src, NPC_TRACE_PLAN, "plan for [task.name] in [plan_search.tries] tries; [jointext(names, ", ")]")
		if(NPC_PLAN_ALREADY_DONE)
			plan_search = null
			plan_finished()
			return
		if(NPC_PLAN_NONE)
			if(!plan_search.asking)
				NPC_TRACE(src, NPC_TRACE_PLAN, "no plan for [task.name] without help ([plan_search.why]); planning again with asking")
				plan_search = new(src, task.goal(src), TRUE)
				return
			var/why = plan_search.why
			if(plan_search.missing)
				note("short_of:[plan_search.missing]", task.type, 5 MINUTES)
			plan_search = null
			plan_failed("no plan; [why]", TRUE)
			return
	plan_search = null

/datum/ai_holder/rsnpc/proc/do_step()
	var/datum/npc_action/A = plan[plan_step]
	var/result = A.tick(src)
	switch(result)
		if(NPC_RUNNING)
			return
		if(NPC_DONE)
			NPC_TRACE(src, NPC_TRACE_PLAN, "[A.name] done")
			A.clean_up(src)
			step_fails -= A.key
			if(++plan_step > length(plan))
				plan_finished()
		if(NPC_NOT_YET)
			step_fails[A.key] += 1
			if(step_fails[A.key] >= 3)
				step_failed(A, NPC_CANT_DO)
				return
			NPC_TRACE(src, NPC_TRACE_PLAN, "[A.name] not yet: [A.why]")
			step_wait_until = world.time + 2 SECONDS
		else
			step_failed(A, result)

/datum/ai_holder/rsnpc/proc/step_failed(datum/npc_action/A, result)
	var/turf/T = A.target_place
	switch(result)
		if(NPC_NOT_THERE)
			NPC_TRACE(src, NPC_TRACE_PLAN, "[A.name] failed, not there: [A.why]")
			if(T)
				forget_place(T, A.want)
				cross_off(npc_place_key(T), 2 MINUTES, A.why)
		if(NPC_CANT_REACH)
			NPC_TRACE(src, NPC_TRACE_PLAN, "[A.name] failed, can't get there: [A.why]")
			if(T)
				cross_off(npc_place_key(T), 2 MINUTES, A.why)
		if(NPC_CANT_DO)
			NPC_TRACE(src, NPC_TRACE_PLAN, "[A.name] failed, can't be done: [A.why]")
			cross_off("act:[A.key]", 2 MINUTES, A.why)
			step_fails -= A.key
	clear_plan()
	plan_failed(A.why)

/datum/ai_holder/rsnpc/proc/clear_plan()
	if(plan && plan_step <= length(plan))
		var/datum/npc_action/A = plan[plan_step]
		A.clean_up(src)
	plan = null
	plan_step = 0
	plan_search = null
	wanted_for_plan = list()
	step_wait_until = 0
	stop_walk()
