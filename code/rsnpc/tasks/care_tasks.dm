/datum/ai_holder/rsnpc/proc/wound_to_dress(kind)
	var/mob/living/carbon/human/H = holder
	if(!istype(H))
		return null
	for(var/obj/item/organ/external/O in H.organs)
		if(O.robotic >= ORGAN_ROBOT || O.open)
			continue
		for(var/datum/wound/W in O.wounds)
			if(W.internal || (W.damage < 10 && !W.bleeding()))
				continue
			if(kind == /obj/item/stack/medical/bruise_pack && W.damage_type != BURN && !W.bandaged)
				return O
			if(kind == /obj/item/stack/medical/ointment && W.damage_type == BURN && !W.salved)
				return O
	return null

/datum/npc_task/treat_wounds
	name = "treat my wounds"
	tier = NPC_TIER_NEEDS
	uses = list(/obj/structure/closet)

/datum/npc_task/treat_wounds/can_start(datum/ai_holder/rsnpc/ai_mind)
	return !ai_mind.fact_true(NPC_FACT_BANDAGED) || !ai_mind.fact_true(NPC_FACT_SALVED)

/datum/npc_task/treat_wounds/value(datum/ai_holder/rsnpc/ai_mind)
	return 100

/datum/npc_task/treat_wounds/goal(datum/ai_holder/rsnpc/ai_mind)
	return list(NPC_FACT_BANDAGED, NPC_FACT_SALVED)

/datum/npc_task/get_treated
	name = "get treated"
	tier = NPC_TIER_NEEDS

/datum/npc_task/get_treated/can_start(datum/ai_holder/rsnpc/ai_mind)
	return !ai_mind.fact_true(NPC_FACT_TREATED)

/datum/npc_task/get_treated/value(datum/ai_holder/rsnpc/ai_mind)
	return 50

/datum/npc_task/get_treated/goal(datum/ai_holder/rsnpc/ai_mind)
	return list(NPC_FACT_TREATED)

/datum/npc_action/dress_wounds
	name = "bandage myself"
	var/kind = /obj/item/stack/medical/bruise_pack
	var/fact = NPC_FACT_BANDAGED
	var/obj/item/organ/external/organ
	var/tries = 0
	var/wait_until = 0

/datum/npc_action/dress_wounds/variants(datum/ai_holder/rsnpc/ai_mind, fact)
	if(fact != src.fact)
		return list()
	return list(copy(null, 1, list(NPC_FACT_HAVE(kind)), list(fact)))

/datum/npc_action/dress_wounds/run_action(datum/ai_holder/rsnpc/ai_mind)
	var/mob/living/carbon/human/H = ai_mind.holder
	if(world.time < wait_until)
		return NPC_RUNNING
	var/obj/item/organ/external/O = ai_mind.wound_to_dress(kind)
	if(!O)
		return NPC_DONE
	if(O == organ && ++tries >= 3)
		why = "couldn't treat my [O.name]"
		return NPC_CANT_DO
	if(O != organ)
		organ = O
		tries = 0
	var/obj/item/stack/medical/S = ai_mind.held_item(kind)
	if(!S)
		why = "nothing left to treat with"
		return NPC_NOT_THERE
	if(!H.checkClickCooldown())
		return NPC_RUNNING
	if(H.get_active_hand() != S)
		H.swap_hand()
	H.zone_sel.set_selected_zone(O.organ_tag, H)
	H.setClickCooldown(DEFAULT_QUICK_COOLDOWN)
	NPC_TRACE(ai_mind, NPC_TRACE_TASK, "treating my [O.name] with [S]")
	INVOKE_ASYNC(S, TYPE_PROC_REF(/obj/item, attack), H, H)
	wait_until = world.time + 4 SECONDS
	return NPC_RUNNING

/datum/npc_action/dress_wounds/salve
	name = "salve my burns"
	kind = /obj/item/stack/medical/ointment
	fact = NPC_FACT_SALVED
