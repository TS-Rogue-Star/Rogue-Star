/datum/ai_holder/rsnpc/proc/bad_touch(mob/living/M)
	if(!sees(M))
		return
	var/datum/npc_person/P = person(M)
	if(!P || P.touched_at == world.time)
		return
	if(M.a_intent == I_GRAB && holds_still_for(P.key))
		NPC_TRACE(src, NPC_TRACE_WITNESS, "let [M] grab me; holding still for them")
		return
	if(M.a_intent != I_HURT && agreed(holder, M, FALSE))
		NPC_TRACE(src, NPC_TRACE_WITNESS, "let [M] handle me; agreed to be eaten")
		return
	P.touched_at = world.time
	var/window = npc_psetting("manhandle_remembered_seconds") SECONDS
	var/list/old = list()
	for(var/at in P.touches)
		if(at < world.time - window)
			old += at
	P.touches -= old
	P.touches += world.time
	last_attacker = WEAKREF(M)
	when_last_attacked = world.time
	change_opinion(M, -npc_psetting("attacked_opinion"), "manhandled me")
	fight_back(M)
	if(world.time < when_protested + npc_psetting("protest_delay_seconds") SECONDS)
		return
	when_protested = world.time
	var/list/blanks = list("name" = M.name)
	for(var/obj/item/weapon/grab/G in holder.grabbed_by)
		if(G.assailant == M && G.state >= GRAB_AGGRESSIVE)
			say_line("protest_grabbed", blanks)
			return
	if(length(P.touches) >= npc_psetting("manhandle_shoves"))
		say_line("protest_escalating", blanks)
		return
	say_line("protest_mild", blanks)

/datum/ai_holder/rsnpc/proc/stripped_by(mob/living/M, what_done)
	var/mob/living/carbon/human/H = holder
	if(istype(H))
		for(var/obj/item/I in list(H.handcuffed, H.legcuffed, H.glasses, H.wear_mask))
			if(findtext(what_done, "[I]") && (I == H.handcuffed || I == H.legcuffed || istype(I, /obj/item/clothing/glasses/sunglasses/blindfold) || istype(I, /obj/item/clothing/mask/muzzle)))
				NPC_TRACE(src, NPC_TRACE_WITNESS, "[M] helped me; took off [I]")
				return
	bad_touch(M)

/datum/ai_holder/rsnpc/proc/radio_attacked(mob/living/M)
	if(!in_the_room() || world.time < called_security_at + npc_psetting("attack_call_interlude") SECONDS)
		return
	called_security_at = world.time
	called_help_at = world.time
	say_line("help_attacked", list("name" = M.name, "place" = "[get_area(holder)]"), radiochannels["Security"])

/datum/ai_holder/rsnpc/proc/call_for_help()
	if(holder.client || holder.stat != CONSCIOUS || !in_the_room())
		down_since = 0
		return
	if(!holder.restrained() && !holder.incapacitated(INCAPACITATION_STUNNED) && (!holder.lying || holder.buckled))
		down_since = 0
		return
	if(!down_since)
		down_since = world.time
		return
	if(world.time < down_since + npc_psetting("stuck_before_call") SECONDS || world.time < called_help_at + npc_psetting("call_interlude") SECONDS)
		return
	called_help_at = world.time
	var/list/blanks = list("place" = "[get_area(holder)]")
	var/mob/living/A = last_attacker?.resolve()
	if(A && world.time < when_last_attacked + npc_psetting("remember_attacker_time") SECONDS)
		blanks["name"] = A.name
		say_line("help_attacked", blanks, radiochannels["Security"])
	else if(health_share() < npc_psetting("medic_call_threshold"))
		say_line("help_hurt", blanks, radiochannels["Medical"])
	else
		say_line("help_stuck", blanks, PUB_FREQ)
