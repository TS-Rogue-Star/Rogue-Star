GLOBAL_LIST_INIT(npc_danger_ranges, list(
	/obj/fire = 2,
	/obj/effect/temporary_effect/shuttle_landing = 1,
	/obj/singularity/energy_ball = 8,
))

/proc/npc_danger_range(atom/A)
	for(var/kind in GLOB.npc_danger_ranges)
		if(istype(A, kind))
			return GLOB.npc_danger_ranges[kind]
	return 0

/proc/npc_clear_of(list/dangers, turf/T)
	for(var/atom/A as anything in dangers)
		if(get_z(A) == T.z && get_dist(A, T) <= npc_danger_range(A))
			return FALSE
	return TRUE

/proc/npc_safe_spot(mob/living/who, list/dangers, turf/T)
	return npc_safe_tile(who, T) && npc_clear_of(dangers, T)

/datum/ai_holder/rsnpc/proc/dangers_in_sight()
	. = list()
	for(var/atom/A as anything in look())
		if(npc_danger_range(A))
			. += A

/datum/npc_task/internals_off
	name = "take off internals"
	tier = NPC_TIER_FULFILLMENT

/datum/npc_task/internals_off/can_start(datum/ai_holder/rsnpc/ai_mind)
	var/mob/living/carbon/human/H = ai_mind.holder
	return istype(H) && H.internal && isturf(H.loc) && npc_air_breathable(H.loc, H) && !(istype(H.wear_suit, /obj/item/clothing/suit/space) && istype(H.head, /obj/item/clothing/head/helmet/space))

/datum/npc_task/internals_off/value(datum/ai_holder/rsnpc/ai_mind)
	return 80

/datum/npc_task/internals_off/goal(datum/ai_holder/rsnpc/ai_mind)
	return list(NPC_FACT_INTERNALS_OFF)

/datum/npc_action/internals_off
	name = "turn off internals"

/datum/npc_action/internals_off/variants(datum/ai_holder/rsnpc/ai_mind, fact)
	if(fact != NPC_FACT_INTERNALS_OFF)
		return list()
	return list(copy(null, 1, null, list(fact)))

/datum/npc_action/internals_off/run_action(datum/ai_holder/rsnpc/ai_mind)
	var/mob/living/carbon/H = ai_mind.holder
	if(!H.internal)
		return NPC_DONE
	if(!H.checkClickCooldown())
		return NPC_RUNNING
	H.toggle_internals_hud()
	H.setClickCooldown(DEFAULT_QUICK_COOLDOWN)
	if(H.internal)
		why = "internals didn't turn off"
		return NPC_CANT_DO
	NPC_TRACE(ai_mind, NPC_TRACE_TASK, "internals off; the air is fine")
	return NPC_DONE

/datum/npc_task/internals
	name = "use internals"
	tier = NPC_TIER_SURVIVAL

/datum/npc_task/internals/can_start(datum/ai_holder/rsnpc/ai_mind)
	var/mob/living/carbon/human/H = ai_mind.holder
	return istype(H) && !npc_on_air(H) && isturf(H.loc) && !npc_air_breathable(H.loc, H)

/datum/npc_task/internals/value(datum/ai_holder/rsnpc/ai_mind)
	return 200

/datum/npc_task/internals/goal(datum/ai_holder/rsnpc/ai_mind)
	return list(NPC_FACT_INTERNALS)

/datum/npc_task/get_out_of_danger
	name = "get out of danger"
	tier = NPC_TIER_SURVIVAL

/datum/npc_task/get_out_of_danger/can_start(datum/ai_holder/rsnpc/ai_mind)
	return isturf(ai_mind.holder.loc) && !ai_mind.fact_true(NPC_FACT_SAFE)

/datum/npc_task/get_out_of_danger/value(datum/ai_holder/rsnpc/ai_mind)
	return 100

/datum/npc_task/get_out_of_danger/goal(datum/ai_holder/rsnpc/ai_mind)
	return list(NPC_FACT_SAFE)

/datum/npc_action/internals_on
	name = "turn on internals"

/datum/npc_action/internals_on/variants(datum/ai_holder/rsnpc/ai_mind, fact)
	if(fact != NPC_FACT_INTERNALS)
		return list()
	return list(copy(null, 1, list(NPC_FACT_HAVE(/obj/item/weapon/tank), NPC_FACT_MASKED), list(NPC_FACT_INTERNALS)))

/datum/npc_action/internals_on/run_action(datum/ai_holder/rsnpc/ai_mind)
	var/mob/living/carbon/H = ai_mind.holder
	if(H.internal)
		return NPC_DONE
	if(!H.checkClickCooldown())
		return NPC_RUNNING
	H.toggle_internals_hud()
	H.setClickCooldown(DEFAULT_QUICK_COOLDOWN)
	if(!H.internal)
		why = "internals didn't turn on"
		return NPC_CANT_DO
	NPC_TRACE(ai_mind, NPC_TRACE_TASK, "internals on")
	return NPC_DONE

/datum/npc_action/put_on_mask
	name = "put on a mask"

/datum/npc_action/put_on_mask/variants(datum/ai_holder/rsnpc/ai_mind, fact)
	if(fact != NPC_FACT_MASKED)
		return list()
	return list(copy(null, 1, list(NPC_FACT_HAVE(/obj/item/clothing/mask/breath)), list(NPC_FACT_MASKED)))

/datum/npc_action/put_on_mask/run_action(datum/ai_holder/rsnpc/ai_mind)
	var/mob/living/carbon/human/H = ai_mind.holder
	if(ai_mind.fact_true(NPC_FACT_MASKED))
		return NPC_DONE
	if(H.wear_mask)
		why = "already wearing [H.wear_mask]"
		return NPC_CANT_DO
	var/obj/item/I = ai_mind.held_item(/obj/item/clothing/mask/breath)
	if(!I)
		why = "no mask in hand"
		return NPC_NOT_THERE
	if(!H.checkClickCooldown())
		return NPC_RUNNING
	if(H.get_active_hand() != I)
		H.swap_hand()
	H.quick_equip()
	H.setClickCooldown(DEFAULT_QUICK_COOLDOWN)
	if(H.wear_mask != I)
		why = "couldn't put [I] on"
		return NPC_CANT_DO
	return NPC_DONE

/datum/npc_action/seen_safe_spot
	name = "go to a safe spot I can see"

/datum/npc_action/seen_safe_spot/variants(datum/ai_holder/rsnpc/ai_mind, fact)
	if(fact != NPC_FACT_SAFE)
		return list()
	var/turf/here = get_turf(ai_mind.holder)
	var/list/dangers = ai_mind.dangers_in_sight()
	var/turf/best
	for(var/turf/T as anything in ai_mind.turfs_in_sight)
		if(T == here || !T.npc_room || !npc_can_stand(T) || ai_mind.crossed_off(npc_place_key(T)) || !npc_safe_spot(ai_mind.holder, dangers, T))
			continue
		if(!best || get_dist(here, T) < get_dist(here, best))
			best = T
	if(!best)
		return list()
	return list(copy(best, 1 + get_dist(here, best) / 10, null, list(fact)))

/datum/npc_task/houdini_cuffs
	name = "escape cuffs"
	tier = NPC_TIER_NEEDS

/datum/npc_task/houdini_cuffs/can_start(datum/ai_holder/rsnpc/ai_mind)
	var/mob/living/carbon/C = ai_mind.holder
	return istype(C) && (C.handcuffed || C.legcuffed) && !ai_mind.assignment(/datum/npc_assignment/hold_still)

/datum/npc_task/houdini_cuffs/value(datum/ai_holder/rsnpc/ai_mind)
	return 95

/datum/npc_task/houdini_cuffs/goal(datum/ai_holder/rsnpc/ai_mind)
	return list(NPC_FACT_UNCUFFED)

/datum/npc_action/houdini_cuffs
	name = "resist out of my cuffs"
	var/struggle_since = 0

/datum/npc_action/houdini_cuffs/variants(datum/ai_holder/rsnpc/ai_mind, fact)
	if(fact != NPC_FACT_UNCUFFED)
		return list()
	return list(copy(null, 1, null, list(fact)))

/datum/npc_action/houdini_cuffs/run_action(datum/ai_holder/rsnpc/ai_mind)
	var/mob/living/carbon/C = ai_mind.holder
	if(!C.handcuffed && !C.legcuffed)
		NPC_TRACE(ai_mind, NPC_TRACE_TASK, "out of my cuffs")
		return NPC_DONE
	if(!struggle_since)
		struggle_since = world.time
		NPC_TRACE(ai_mind, NPC_TRACE_TASK, "trying to resist out of [C.handcuffed || C.legcuffed]")
		INVOKE_ASYNC(ai_mind, TYPE_PROC_REF(/datum/ai_holder/rsnpc, start_resist))
		return NPC_RUNNING
	if(world.time > struggle_since + 2.5 MINUTES)
		why = "couldn't slip [C.handcuffed || C.legcuffed]"
		return NPC_CANT_DO
	idle = TRUE
	return NPC_RUNNING
