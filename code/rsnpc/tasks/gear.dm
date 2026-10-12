/datum/npc_gear
	var/datum/weakref/item
	var/name
	var/slot
	var/turf/lost_at
	var/until = 0

/datum/npc_gear/proc/in_place(mob/living/carbon/human/H)
	var/obj/item/I = item?.resolve()
	if(!I)
		return FALSE
	if(slot)
		return H.get_equipped_item(slot) == I
	return I in H.get_contents()

/datum/ai_holder/complex_npc/proc/note_gear()
	var/mob/living/carbon/human/H = holder
	if(!istype(H))
		return
	for(var/slot in list(slot_wear_id, slot_w_uniform, slot_shoes, slot_back, slot_belt, slot_l_ear, slot_r_ear, slot_gloves, slot_glasses, slot_head, slot_wear_suit))
		var/obj/item/I = H.get_equipped_item(slot)
		if(!I)
			continue
		var/datum/npc_gear/G = new
		G.item = WEAKREF(I)
		G.name = I.name
		G.slot = slot
		gear += G

/datum/ai_holder/complex_npc/proc/check_gear()
	var/mob/living/carbon/human/H = holder
	if(!istype(H))
		return
	var/list/held = list(H.l_hand, H.r_hand) - null
	for(var/obj/item/I as anything in last_held)
		if(QDELETED(I) || !isturf(I.loc) || noted("dropped:\ref[I]") || gear_for(I))
			continue
		var/datum/npc_gear/G = new
		G.item = WEAKREF(I)
		G.name = I.name
		G.lost_at = (I in look()) ? I.loc : get_turf(holder)
		G.until = world.time + 5 MINUTES
		gear += G
		NPC_TRACE(src, NPC_TRACE_HANDS, "lost [I] from my hands")
	last_held = held
	for(var/datum/npc_gear/G as anything in gear.Copy())
		var/obj/item/I = G.item?.resolve()
		if(G.until && world.time > G.until)
			gear -= G
			continue
		if(I && G.in_place(H))
			if(!G.slot)
				gear -= G
			G.lost_at = null
			continue
		if(I && isturf(I.loc) && (I in look()))
			G.lost_at = I.loc
		else if(!G.lost_at)
			gear -= G
			NPC_TRACE(src, NPC_TRACE_HANDS, "gave up on my [G.name]; don't know where it is")
			say_line("gear_lost", list("thing" = G.name))

/datum/ai_holder/complex_npc/proc/gear_for(obj/item/I)
	for(var/datum/npc_gear/G as anything in gear)
		if(G.item?.resolve() == I)
			return G
	return null

/datum/ai_holder/complex_npc/proc/missing_gear()
	for(var/datum/npc_gear/G as anything in gear)
		if(G.lost_at && !G.in_place(holder))
			return G
	return null

/datum/npc_task/get_my_things
	name = "get my things back"
	tier = NPC_TIER_NEEDS

/datum/npc_task/get_my_things/can_start(datum/ai_holder/complex_npc/ai_mind)
	return !!ai_mind.missing_gear()

/datum/npc_task/get_my_things/value(datum/ai_holder/complex_npc/ai_mind)
	return 90

/datum/npc_task/get_my_things/goal(datum/ai_holder/complex_npc/ai_mind)
	var/datum/npc_gear/G = ai_mind.missing_gear()
	return G ? list(NPC_FACT_GEAR(G)) : list()

/datum/npc_action/get_back
	name = "get back what I lost"
	var/datum/npc_gear/gear

/datum/npc_action/get_back/variants(datum/ai_holder/complex_npc/ai_mind, fact)
	if(findtext(fact, "gear:") != 1)
		return list()
	var/datum/npc_gear/G = locate(copytext(fact, 6))
	if(!istype(G) || !G.lost_at)
		return list()
	var/obj/item/I = G.item?.resolve()
	var/datum/npc_action/get_back/A = copy(G.lost_at, 1 + get_dist(ai_mind.holder, G.lost_at) / 10, null, list(fact))
	A.gear = G
	A.want = I?.type
	A.name = "get my [G.name] back"
	return list(A)

/datum/npc_action/get_back/run_action(datum/ai_holder/complex_npc/ai_mind)
	var/mob/living/carbon/human/H = ai_mind.holder
	var/obj/item/I = gear.item?.resolve()
	if(!I || !isturf(I.loc) || get_turf(I) != get_turf(target))
		gear.lost_at = null
		why = "it's not where I saw it"
		return NPC_NOT_THERE
	if(!ai_mind.take(I))
		why = "my hands are full"
		return NPC_NOT_YET
	if(gear.slot && !H.equip_to_slot_if_possible(I, gear.slot, 0, 1))
		why = "couldn't put [I] back on"
		return NPC_CANT_DO
	NPC_TRACE(ai_mind, NPC_TRACE_HANDS, "got my [I] back")
	return NPC_DONE
