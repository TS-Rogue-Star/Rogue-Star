/datum/ai_holder/complex_npc/proc/held_item(kind)
	for(var/obj/item/I in list(holder.l_hand, holder.r_hand))
		if(istype(I, kind))
			return I
	return null

/datum/ai_holder/complex_npc/proc/take(obj/item/I)
	if(holder.hands_are_full() && !free_hand())
		return FALSE
	if(holder.get_active_hand())
		holder.swap_hand()
	var/turf/T = isturf(I.loc) ? I.loc : null
	use_hand(I)
	if(I.loc != holder || !holder.item_is_in_hands(I))
		return FALSE
	wanted_for_plan |= I
	if(T)
		seen -= npc_thing_key(I.type, T)
	return TRUE

/datum/ai_holder/complex_npc/proc/free_hand()
	if(!holder.hands_are_full())
		return TRUE
	for(var/obj/item/I in list(holder.get_active_hand(), holder.get_inactive_hand()))
		if((I in wanted_for_plan) || I == holder.internal)
			continue
		if(put_away(I) || drop(I))
			NPC_TRACE(src, NPC_TRACE_HANDS, "freed hand by putting away [I] ([I.loc])")
			return !holder.hands_are_full()
	return FALSE

/datum/ai_holder/complex_npc/proc/put_away(obj/item/I)
	if(!holder.checkClickCooldown())
		return FALSE
	if(holder.get_active_hand() != I)
		holder.swap_hand()
	if(holder.get_active_hand() != I)
		return FALSE
	var/mob/living/carbon/human/H = holder
	for(var/obj/item/weapon/storage/bag in list(holder.back, istype(H) ? H.belt : null))
		if(!bag.can_be_inserted(I, TRUE))
			continue
		var/old_usr = usr
		usr = holder
		bag.attackby(I, holder)
		usr = old_usr
		holder.setClickCooldown(DEFAULT_QUICK_COOLDOWN)
		return I.loc == bag
	if(istype(H))
		for(var/slot in list(slot_l_store, slot_r_store))
			if(H.equip_to_slot_if_possible(I, slot, 0, 1))
				return TRUE
	return FALSE

/datum/ai_holder/complex_npc/proc/drop(obj/item/I)
	if(istype(I, /obj/item/weapon/card/id) || istype(I, /obj/item/device/pda) || istype(I, /obj/item/device/radio/headset))
		return FALSE
	note("dropped:\ref[I]", I.name, 1 MINUTE)
	holder.drop_from_inventory(I)
	return isturf(I.loc)

/datum/ai_holder/complex_npc/proc/accepts(mob/living/giver, obj/item/I)
	var/need = plan_needs(I)
	var/key = need ? null : gave_up_key(I)
	if(!need && !key)
		NPC_TRACE(src, NPC_TRACE_HANDS, "refused [I] from [giver]: not needed for plan")
		say_line("say_offer_declined", list("name" = giver.name))
		return FALSE
	var/why = "plan needs [need]"
	if(key)
		var/task_type = noted(key)
		notes -= key
		for(var/datum/npc_task/T as anything in tasks)
			if(T.type == task_type)
				T.slept_until = 0
				why = "gave up [T.name] without it"
	if(holder.hands_are_full())
		for(var/obj/item/H in list(holder.get_active_hand(), holder.get_inactive_hand()))
			if(!(H in wanted_for_plan) && drop(H))
				break
	NPC_TRACE(src, NPC_TRACE_HANDS, "took [I] from [giver]: [why]")
	change_opinion(giver, npc_psetting("delivered"), "handed me [I]")
	say_line("say_handover_thanks", list("name" = giver.name))
	received(giver, I)
	clear_plan()
	wanted_for_plan |= I
	return TRUE

/datum/ai_holder/complex_npc/proc/plan_missing()
	. = list()
	if(!plan)
		return
	for(var/i in plan_step to length(plan))
		var/datum/npc_action/A = plan[i]
		for(var/fact in A.needs)
			if(findtext(fact, "have:") == 1 && !fact_true(fact))
				. |= fact

/datum/ai_holder/complex_npc/proc/gave_up_key(obj/item/I)
	for(var/key in notes.Copy())
		if(findtext(key, "short_of:") != 1 || !noted(key))
			continue
		if(!I || istype(I, text2path(copytext(key, 10))))
			return key
	return null

/datum/ai_holder/complex_npc/proc/plan_needs(obj/item/I)
	for(var/fact in plan_missing())
		if(istype(I, text2path(copytext(fact, 6))))
			return fact
	return null

/mob/living/carbon/human/ai_controlled/station/accepts_offer(mob/living/giver, obj/item/I)
	var/datum/ai_holder/complex_npc/ai_mind = npc_ai_mind(src)
	if(!ai_mind || client)
		return ..()
	return ai_mind.accepts(giver, I)

/datum/ai_holder/complex_npc/proc/suited()
	var/mob/living/carbon/human/H = holder
	return istype(H) && istype(H.wear_suit, /obj/item/clothing/suit/space) && istype(H.head, /obj/item/clothing/head/helmet/space) && H.internal
