/datum/npc_command/give_me
	say = "give me"
	obedience = 21

/datum/npc_command/give_me/run_command(datum/ai_holder/rsnpc/ai_mind, mob/living/speaker, rest, via)
	var/obj/item/I = ai_mind.item_named(rest)
	if(!I)
		NPC_TRACE(ai_mind, NPC_TRACE_TALK, "[speaker] asked for \"[rest]\"; I have none")
		ai_mind.say_line("give_none", list("name" = speaker.name))
		return
	var/datum/npc_assignment/give/G = new(speaker, null, 1 MINUTE)
	G.thing = WEAKREF(I)
	G.thing_name = I.name
	G.name = "give [I] to [speaker]"
	ai_mind.start_assignment(G)

/datum/ai_holder/rsnpc/proc/item_named(name)
	var/mob/living/carbon/human/H = holder
	for(var/obj/item/I in holder.get_contents())
		if(!holder.item_is_in_hands(I) && !istype(I.loc, /obj/item/weapon/storage))
			continue
		if(istype(I, /obj/item/organ) || istype(I, /obj/item/weapon/card/id) || istype(I, /obj/item/device/pda) || istype(I, /obj/item/device/radio/headset) || istype(H) && I == H.w_uniform)
			continue
		if(npc_words_after(name, I.name) == "")
			return I
	return null

/datum/npc_assignment/give
	weight = 10
	name = "give"
	var/datum/weakref/thing
	var/thing_name
	var/given = FALSE

/datum/npc_assignment/give/blanks()
	return list("name" = asker_name, "thing" = thing_name)

/datum/npc_assignment/give/goal(datum/ai_holder/rsnpc/ai_mind)
	return list(NPC_FACT_GIVEN(src))

/datum/npc_assignment/give/check(datum/ai_holder/rsnpc/ai_mind)
	if(given)
		ai_mind.end_assignment(src, "gave it")
		return
	var/obj/item/I = thing?.resolve()
	if(!I || !(I in ai_mind.holder.get_contents()))
		ai_mind.end_assignment(src, "I don't have it any more")
		return
	..()

/datum/npc_action/give
	name = "give"
	var/datum/npc_assignment/give/order
	var/said = FALSE
	var/offered = FALSE
	var/answered = FALSE
	var/accepted = FALSE

/datum/npc_action/give/variants(datum/ai_holder/rsnpc/ai_mind, fact)
	if(findtext(fact, "given:") != 1)
		return list()
	var/datum/npc_assignment/give/G = locate(copytext(fact, 7))
	var/obj/item/I = G?.thing?.resolve()
	var/mob/living/M = G?.asker?.resolve()
	if(!istype(G) || !I || !M)
		return list()
	var/datum/npc_action/give/A = copy(null, 1, list(NPC_FACT_HOLDING(I), NPC_FACT_NEAR(M)), list(fact))
	A.order = G
	A.name = "give [G.thing_name] to [M]"
	A.key = "[A.key]:\ref[G]"
	return list(A)

/datum/npc_action/give/run_action(datum/ai_holder/rsnpc/ai_mind)
	if(!offered)
		var/obj/item/I = order.thing?.resolve()
		var/mob/living/M = order.asker?.resolve()
		if(QDELETED(I) || !ai_mind.holder.item_is_in_hands(I))
			why = "it's not in my hands"
			return NPC_NOT_THERE
		if(!M || !(M in ai_mind.look()))
			why = "they're not next to me"
			return NPC_NOT_YET
		if(!M.Adjacent(ai_mind.holder))
			return head_to(ai_mind, M)
		if(!said)
			said = TRUE
			ai_mind.say_line("give_here", order.blanks())
			return NPC_RUNNING
		if(ai_mind.busy_talking())
			return NPC_RUNNING
		offered = TRUE
		INVOKE_ASYNC(src, PROC_REF(offer), ai_mind.holder, M, I)
		return NPC_RUNNING
	if(!answered)
		return NPC_RUNNING
	if(!accepted)
		why = "they didn't take it"
		return NPC_CANT_DO
	order.given = TRUE
	return NPC_DONE

/datum/npc_action/give/proc/offer(mob/living/giver, mob/living/M, obj/item/I)
	accepted = giver.do_give(M, I)
	answered = TRUE

/datum/npc_task/give
	name = "give"
	tier = NPC_TIER_SOCIAL
	assignment_type = /datum/npc_assignment/give

/datum/npc_task/give/value(datum/ai_holder/rsnpc/ai_mind)
	return 110
