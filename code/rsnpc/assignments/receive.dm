/datum/npc_assignment/receive
	state = TRUE
	name = "receive something"
	var/datum/weakref/thing
	var/why
	var/wake_key
	var/ready = FALSE
	var/ready_at = 0
	var/received = FALSE
	var/offer_over = FALSE

/datum/npc_assignment/receive/goal(datum/ai_holder/rsnpc/ai_mind)
	return list(NPC_FACT_RECEIVED(src))

/datum/npc_assignment/receive/check(datum/ai_holder/rsnpc/ai_mind)
	var/obj/item/I = thing?.resolve()
	var/mob/living/giver = asker?.resolve()
	if(received)
		if(wake_key)
			var/task_type = ai_mind.noted(wake_key)
			ai_mind.notes -= wake_key
			for(var/datum/npc_task/T as anything in ai_mind.tasks)
				if(T.type == task_type)
					T.slept_until = 0
		NPC_TRACE(ai_mind, NPC_TRACE_HANDS, "received [I] from [giver]: [why]")
		if(giver)
			ai_mind.change_opinion(giver, ai_mind.npc_psetting("delivered"), "handed me [I]")
			ai_mind.say_line("say_handover_thanks", list("name" = giver.name))
			ai_mind.received(giver, I)
		ai_mind.wanted_for_plan |= I
		ai_mind.end_assignment(src, "received it")
		return
	if(offer_over)
		ai_mind.end_assignment(src, "the offer ended")
		return
	..()

/datum/npc_task/receive
	name = "receive what I'm handed"
	tier = NPC_TIER_NEEDS
	assignment_type = /datum/npc_assignment/receive

/datum/npc_task/receive/value(datum/ai_holder/rsnpc/ai_mind)
	return 200

/datum/npc_action/shuffle_inventory
	name = "free a hand"

/datum/npc_action/shuffle_inventory/variants(datum/ai_holder/rsnpc/ai_mind, fact)
	if(fact != NPC_FACT_HAND_FREE)
		return list()
	return list(copy(null, 1, null, list(fact)))

/datum/npc_action/shuffle_inventory/run_action(datum/ai_holder/rsnpc/ai_mind)
	if(!ai_mind.holder.hands_are_full())
		return NPC_DONE
	if(!ai_mind.holder.checkClickCooldown())
		return NPC_RUNNING
	if(ai_mind.free_hand())
		return NPC_DONE
	why = "nowhere to put what I hold"
	return NPC_CANT_DO

/datum/npc_action/received
	name = "receive it"
	var/datum/npc_assignment/receive/order

/datum/npc_action/received/variants(datum/ai_holder/rsnpc/ai_mind, fact)
	if(findtext(fact, "received:") != 1)
		return list()
	var/datum/npc_assignment/receive/R = locate(copytext(fact, 10))
	var/mob/living/giver = R?.asker?.resolve()
	if(!istype(R) || !giver)
		return list()
	var/datum/npc_action/received/A = copy(null, 1, list(NPC_FACT_HAND_FREE, NPC_FACT_NEAR(giver)), list(fact))
	A.order = R
	A.name = R.name
	A.key = "[A.key]:\ref[R]"
	return list(A)

/datum/npc_action/received/run_action(datum/ai_holder/rsnpc/ai_mind)
	var/obj/item/I = order.thing?.resolve()
	if(I && ai_mind.holder.item_is_in_hands(I))
		order.received = TRUE
		return NPC_DONE
	if(order.offer_over)
		why = "the offer ended"
		return NPC_CANT_DO
	if(!order.ready)
		var/mob/living/giver = order.asker?.resolve()
		if(giver && !giver.Adjacent(ai_mind.holder))
			return head_to(ai_mind, giver)
		order.ready = TRUE
		order.ready_at = world.time
		return NPC_RUNNING
	if(world.time > order.ready_at + 5 SECONDS)
		why = "it never reached my hand"
		return NPC_CANT_DO
	return NPC_RUNNING
