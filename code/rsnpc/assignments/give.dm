/datum/npc_command/give_me
	say = "give me"
	obedience = 21

/datum/npc_command/give_me/run_command(datum/ai_holder/complex_npc/ai_mind, mob/living/speaker, rest, via)
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

/datum/ai_holder/complex_npc/proc/item_named(name)
	var/mob/living/carbon/human/H = holder
	for(var/obj/item/I in holder.get_contents())
		if(I.loc != holder && !istype(I.loc, /obj/item/weapon/storage))
			continue
		if(istype(I, /obj/item/organ) || istype(I, /obj/item/weapon/card/id) || istype(I, /obj/item/device/pda) || istype(I, /obj/item/device/radio/headset) || istype(H) && I == H.w_uniform)
			continue
		if(npc_words_after(name, I.name) == "")
			return I
	return null

/datum/npc_assignment/give
	name = "give"
	var/datum/weakref/thing
	var/thing_name

/datum/npc_assignment/give/blanks()
	return list("name" = asker_name, "thing" = thing_name)

/datum/npc_assignment/give/goal(datum/ai_holder/complex_npc/ai_mind)
	var/mob/living/M = asker?.resolve()
	return M ? list(NPC_FACT_NEAR(M)) : list()

/datum/npc_assignment/give/check(datum/ai_holder/complex_npc/ai_mind)
	var/obj/item/I = thing?.resolve()
	if(!I || !(I in ai_mind.holder.get_contents()))
		ai_mind.end_assignment(src, "I don't have it any more")
		return
	var/mob/living/M = asker?.resolve()
	if(M && (M in ai_mind.look()) && M.Adjacent(ai_mind.holder))
		if(!ai_mind.take(I))
			return
		INVOKE_ASYNC(ai_mind.holder, TYPE_PROC_REF(/mob/living, do_give), M, I)
		ai_mind.end_assignment(src, "offered it", "give_here")
		return
	..()

/datum/npc_task/give
	name = "give"
	tier = NPC_TIER_SOCIAL
	assignment_type = /datum/npc_assignment/give

/datum/npc_task/give/value(datum/ai_holder/complex_npc/ai_mind)
	return 110
