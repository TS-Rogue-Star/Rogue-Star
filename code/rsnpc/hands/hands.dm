/datum/ai_holder/rsnpc/proc/held_item(kind)
	for(var/obj/item/I in list(holder.l_hand, holder.r_hand))
		if(istype(I, kind) && npc_worth_taking(kind, null, I))
			return I
	return null

/datum/ai_holder/rsnpc/proc/in_reach(obj/item/I)
	return isturf(I.loc) || I.loc == holder || istype(I.loc, /obj/item/weapon/storage) && I.loc.loc == holder

/datum/ai_holder/rsnpc/proc/reachable_items()
	. = list()
	for(var/obj/item/I in holder.get_contents())
		if(in_reach(I))
			. += I

/datum/ai_holder/rsnpc/proc/take(obj/item/I)
	if(holder.restrained() || !holder.can_use_hands())
		return FALSE
	if(holder.hands_are_full() && !free_hand())
		return FALSE
	if(holder.get_active_hand())
		holder.swap_hand()
	var/turf/T = isturf(I.loc) ? I.loc : null
	if(I.loc == holder && !holder.item_is_in_hands(I))
		if(!holder.checkClickCooldown() || !holder.unEquip(I))
			return FALSE
		holder.put_in_hands(I)
		holder.setClickCooldown(DEFAULT_QUICK_COOLDOWN)
	else
		use_hand(I)
	if(I.loc != holder || !holder.item_is_in_hands(I))
		return FALSE
	wanted_for_plan |= I
	if(T)
		seen -= npc_thing_key(I.type, T)
	return TRUE

/datum/ai_holder/rsnpc/proc/free_hand()
	if(!holder.hands_are_full())
		return TRUE
	for(var/obj/item/I in list(holder.get_active_hand(), holder.get_inactive_hand()))
		if((I in wanted_for_plan) || I == holder.internal || istype(I, /obj/item/weapon/grab))
			continue
		if(put_away(I) || drop(I))
			NPC_TRACE(src, NPC_TRACE_HANDS, "freed hand by putting away [I] ([I.loc])")
			return !holder.hands_are_full()
	return FALSE

/datum/ai_holder/rsnpc/proc/put_away(obj/item/I)
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

/datum/ai_holder/rsnpc/proc/grip_of(mob/living/M)
	for(var/obj/item/weapon/grab/G in list(holder.l_hand, holder.r_hand))
		if(G.affecting == M)
			return G
	return null

/datum/ai_holder/rsnpc/proc/drop(obj/item/I)
	if(istype(I, /obj/item/weapon/card/id) || istype(I, /obj/item/device/pda) || istype(I, /obj/item/device/radio/headset) || istype(I, /obj/item/weapon/grab))
		return FALSE
	note("dropped:\ref[I]", I.name, 1 MINUTE)
	holder.drop_from_inventory(I)
	return isturf(I.loc)

/datum/ai_holder/rsnpc/proc/accepts(mob/living/giver, obj/item/I)
	var/need = plan_needs(I)
	var/key = need ? null : gave_up_key(I)
	var/datum/npc_gear/G = (need || key) ? null : gear_wants(I)
	if(!need && !key && !G)
		NPC_TRACE(src, NPC_TRACE_HANDS, "refused [I] from [giver]: not needed for plan")
		say_line("say_offer_declined", list("name" = giver.name))
		return FALSE
	var/datum/npc_assignment/receive/R = new(giver, null, 30 SECONDS)
	R.thing = WEAKREF(I)
	R.name = "receive [I] from [giver]"
	R.why = G ? "it's for my [G.name]" : (need ? "plan needs [need]" : "gave up a task without it")
	R.wake_key = key
	start_assignment(R)
	var/until = world.time + 30 SECONDS
	while(world.time < until && (R in assignments) && !R.ready)
		sleep(2)
	if(R.ready)
		return TRUE
	R.offer_over = TRUE
	NPC_TRACE(src, NPC_TRACE_HANDS, "wasn't ready to receive [I] from [giver] in time")
	return FALSE

/datum/ai_holder/rsnpc/proc/plan_missing()
	. = list()
	if(!plan)
		return
	var/datum/npc_action/current = plan_step <= length(plan) ? plan[plan_step] : null
	for(var/i in (current?.started_at ? plan_step + 1 : plan_step) to length(plan))
		var/datum/npc_action/A = plan[i]
		for(var/fact in A.needs)
			if(findtext(fact, "have:") == 1 && !fact_true(fact))
				. |= fact

/datum/ai_holder/rsnpc/proc/gave_up_key(obj/item/I)
	for(var/key in notes.Copy())
		if(findtext(key, "short_of:") != 1 || !noted(key))
			continue
		if(!I || istype(I, text2path(copytext(key, 10))))
			return key
	return null

/datum/ai_holder/rsnpc/proc/plan_needs(obj/item/I)
	for(var/fact in plan_missing())
		if(istype(I, text2path(copytext(fact, 6))))
			return fact
	return null

/mob/living/carbon/human/ai_controlled/rsnpc/station/accepts_offer(mob/living/giver, obj/item/I)
	var/datum/ai_holder/rsnpc/ai_mind = npc_ai_mind(src)
	if(!ai_mind || client)
		return ..()
	return ai_mind.accepts(giver, I)

/datum/ai_holder/rsnpc/proc/suited()
	var/mob/living/carbon/human/H = holder
	return istype(H) && istype(H.wear_suit, /obj/item/clothing/suit/space) && istype(H.head, /obj/item/clothing/head/helmet/space) && npc_on_air(H)
