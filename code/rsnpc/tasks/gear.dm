GLOBAL_LIST_INIT(npc_gear_kinds, list(
	"[slot_w_uniform]" = /obj/item/clothing/under,
	"[slot_shoes]" = /obj/item/clothing/shoes,
	"[slot_gloves]" = /obj/item/clothing/gloves,
	"[slot_glasses]" = /obj/item/clothing/glasses,
	"[slot_head]" = /obj/item/clothing/head,
	"[slot_wear_suit]" = /obj/item/clothing/suit,
	"[slot_belt]" = /obj/item/weapon/storage/belt,
	"[slot_back]" = /obj/item/weapon/storage/backpack,
))

GLOBAL_LIST_INIT(npc_always_worn, list(slot_wear_id, slot_w_uniform, slot_l_ear, slot_r_ear))

/datum/npc_gear
	var/datum/weakref/item
	var/name
	var/slot
	var/kind
	var/turf/lost_at
	var/gone = FALSE
	var/until = 0

/datum/npc_gear/proc/in_place(mob/living/carbon/human/H)
	var/obj/item/I = item?.resolve()
	if(!I)
		return FALSE
	if(slot)
		return H.get_equipped_item(slot) == I
	return I in H.get_contents()

/proc/npc_gear_kind(obj/item/I, slot)
	if(!slot || istype(I, /obj/item/weapon/card/id) || istype(I, /obj/item/device/pda))
		return null
	var/kind = GLOB.npc_gear_kinds["[slot]"]
	return (kind && istype(I, kind)) ? kind : I.type

/datum/ai_holder/rsnpc/proc/add_gear(obj/item/I, slot)
	var/datum/npc_gear/G = new
	G.item = WEAKREF(I)
	G.name = I.name
	G.slot = slot
	G.kind = npc_gear_kind(I, slot)
	gear += G
	return G

/datum/ai_holder/rsnpc/proc/note_gear()
	var/mob/living/carbon/human/H = holder
	if(!istype(H))
		return
	for(var/slot in list(slot_wear_id, slot_w_uniform, slot_shoes, slot_back, slot_belt, slot_l_ear, slot_r_ear, slot_gloves, slot_glasses, slot_head, slot_wear_suit, slot_l_store, slot_r_store))
		var/obj/item/I = H.get_equipped_item(slot)
		if(!I || ((slot == slot_l_store || slot == slot_r_store) && !istype(I, /obj/item/device/pda)))
			continue
		add_gear(I, slot)
	for(var/obj/item/device/pda/P in H.get_contents())
		if(!gear_for(P))
			add_gear(P, null)
		break

/datum/ai_holder/rsnpc/proc/check_gear()
	var/mob/living/carbon/human/H = holder
	if(!istype(H))
		return
	var/list/held = list(H.l_hand, H.r_hand) - null
	for(var/obj/item/I as anything in last_held)
		if(QDELETED(I) || !isturf(I.loc) || noted("dropped:\ref[I]") || gear_for(I))
			continue
		var/datum/npc_gear/G = add_gear(I, null)
		G.lost_at = (I in look()) ? I.loc : get_turf(holder)
		G.until = world.time + 5 MINUTES
		NPC_TRACE(src, NPC_TRACE_HANDS, "lost [I] from my hands")
	last_held = held
	for(var/datum/npc_gear/G as anything in gear.Copy())
		var/obj/item/I = G.item?.resolve()
		if(G.until && world.time > G.until)
			gear -= G
			continue
		if(G.slot && G.kind && !G.in_place(H))
			var/obj/item/W = H.get_equipped_item(G.slot)
			if(istype(W, G.kind))
				G.item = WEAKREF(W)
				G.name = W.name
				I = W
		if(I && G.in_place(H))
			if(G.until)
				gear -= G
			G.lost_at = null
			G.gone = FALSE
			continue
		if(I && (I in H.get_contents()))
			G.lost_at = get_turf(H)
			G.gone = FALSE
			continue
		if(I && isturf(I.loc) && (I in look()))
			G.lost_at = I.loc
			G.gone = FALSE
			continue
		if(G.lost_at || G.gone)
			continue
		G.gone = TRUE
		NPC_TRACE(src, NPC_TRACE_HANDS, "lost track of my [G.name][G.kind ? "; another will do" : ""]")
		say_line("gear_lost", list("thing" = G.name))
		if(G.until || (!I && !G.kind))
			gear -= G

/datum/ai_holder/rsnpc/proc/gear_for(obj/item/I)
	for(var/datum/npc_gear/G as anything in gear)
		if(G.item?.resolve() == I)
			return G
	return null

/datum/ai_holder/rsnpc/proc/gear_wants(obj/item/I)
	var/datum/npc_gear/G = gear_for(I)
	if(G)
		return G.in_place(holder) ? null : G
	for(G in gear)
		if(G.gone && G.kind && istype(I, G.kind) && !G.in_place(holder))
			return G
	return null

/datum/ai_holder/rsnpc/proc/can_wear_now(datum/npc_gear/G)
	if(!G.slot)
		return TRUE
	var/obj/item/I = G.item?.resolve()
	if(I)
		return I.mob_can_equip(holder, G.slot, TRUE, TRUE)
	return !holder.get_equipped_item(G.slot)

/datum/ai_holder/rsnpc/proc/missing_gear()
	var/datum/npc_gear/later
	for(var/datum/npc_gear/G as anything in gear)
		if(G.in_place(holder) || !can_wear_now(G) || !(G.lost_at || (G.gone && G.kind)))
			continue
		if(G.slot in GLOB.npc_always_worn)
			return G
		later = later || G
	return later

/datum/ai_holder/rsnpc/proc/take_off(obj/item/I)
	if(!take(I))
		return FALSE
	gear -= gear_for(I)
	return TRUE

/datum/npc_task/get_my_things
	name = "get my things back"
	tier = NPC_TIER_NEEDS

/datum/npc_task/get_my_things/can_start(datum/ai_holder/rsnpc/ai_mind)
	return !!ai_mind.missing_gear()

/datum/npc_task/get_my_things/level(datum/ai_holder/rsnpc/ai_mind)
	var/datum/npc_gear/G = ai_mind.missing_gear()
	var/obj/item/I = G?.item?.resolve()
	return (I && !(G.slot in GLOB.npc_always_worn) && (I in ai_mind.holder.get_contents())) ? NPC_TIER_FULFILLMENT : tier

/datum/npc_task/get_my_things/value(datum/ai_holder/rsnpc/ai_mind)
	return level(ai_mind) == tier ? 90 : 20

/datum/npc_task/get_my_things/goal(datum/ai_holder/rsnpc/ai_mind)
	var/datum/npc_gear/G = ai_mind.missing_gear()
	return G ? list(NPC_FACT_GEAR(G)) : list()

/datum/npc_action/get_back
	name = "get back what I lost"
	var/datum/npc_gear/gear

/datum/npc_action/get_back/variants(datum/ai_holder/rsnpc/ai_mind, fact)
	if(findtext(fact, "gear:") != 1)
		return list()
	var/datum/npc_gear/G = locate(copytext(fact, 6))
	if(!istype(G) || !G.lost_at)
		return list()
	var/obj/item/I = G.item?.resolve()
	var/on_me = I && (I in ai_mind.holder.get_contents())
	var/datum/npc_action/get_back/A = copy(on_me ? null : G.lost_at, 1 + (on_me ? 0 : get_dist(ai_mind.holder, G.lost_at) / 10), null, list(fact))
	A.gear = G
	A.want = I?.type
	A.name = "get my [G.name] back"
	A.key = "[A.key]:\ref[G]"
	return list(A)

/datum/npc_action/get_back/run_action(datum/ai_holder/rsnpc/ai_mind)
	var/mob/living/carbon/human/H = ai_mind.holder
	var/obj/item/I = gear.item?.resolve()
	var/on_me = I && (I in H.get_contents())
	if(!on_me && (!I || !isturf(I.loc) || get_turf(I) != get_turf(target)))
		gear.lost_at = null
		why = "it's not where I saw it"
		return NPC_NOT_THERE
	if(gear.slot && !I.mob_can_equip(H, gear.slot, TRUE, TRUE))
		why = "can't wear [I] yet"
		return NPC_CANT_DO
	if(!H.item_is_in_hands(I) && !(on_me && !gear.slot) && !ai_mind.take(I))
		why = "my hands are full"
		return NPC_NOT_YET
	if(gear.slot && !H.equip_to_slot_if_possible(I, gear.slot, 0, 1))
		why = "couldn't put [I] back on"
		return NPC_CANT_DO
	NPC_TRACE(ai_mind, NPC_TRACE_HANDS, "got my [I] back")
	return NPC_DONE

/datum/npc_action/replace_gear
	name = "replace my gear"
	var/datum/npc_gear/gear

/datum/npc_action/replace_gear/variants(datum/ai_holder/rsnpc/ai_mind, fact)
	if(findtext(fact, "gear:") != 1)
		return list()
	var/datum/npc_gear/G = locate(copytext(fact, 6))
	if(!istype(G) || !G.kind || !G.slot || !G.gone || G.lost_at)
		return list()
	var/datum/npc_action/replace_gear/A = copy(null, 1, list(NPC_FACT_HAVE(G.kind)), list(fact))
	A.gear = G
	A.want = G.kind
	A.name = "replace my [G.name] with a substitute"
	A.key = "[A.key]:\ref[G]"
	return list(A)

/datum/npc_action/replace_gear/run_action(datum/ai_holder/rsnpc/ai_mind)
	var/mob/living/carbon/human/H = ai_mind.holder
	var/obj/item/I = ai_mind.held_item(gear.kind)
	if(!I)
		why = "I don't have one"
		return NPC_CANT_DO
	if(!H.equip_to_slot_if_possible(I, gear.slot, 0, 1))
		why = "couldn't put [I] on"
		return NPC_CANT_DO
	NPC_TRACE(ai_mind, NPC_TRACE_HANDS, "wore [I] instead of my [gear.name]")
	gear.item = WEAKREF(I)
	gear.name = I.name
	gear.gone = FALSE
	return NPC_DONE
