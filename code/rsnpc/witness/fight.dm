/proc/npc_menace(mob/living/M)
	return M && !QDELETED(M) && M.stat == CONSCIOUS && !M.restrained() && !M.lying && !M.incapacitated(INCAPACITATION_STUNNED)

/proc/npc_gun_ready(obj/item/weapon/gun/G)
	if(istype(G, /obj/item/weapon/gun/energy))
		var/obj/item/weapon/gun/energy/E = G
		return E.power_supply && E.power_supply.charge >= E.charge_cost
	if(istype(G, /obj/item/weapon/gun/projectile))
		var/obj/item/weapon/gun/projectile/P = G
		return P.getAmmo() > 0
	return istype(G)

/proc/npc_weapon_value(obj/item/I)
	if(!istype(I))
		return 0
	if(istype(I, /obj/item/weapon/gun))
		return npc_gun_ready(I) ? 100 : 0
	return I.force > 5 ? I.force : 0

/proc/npc_clear_shot(mob/living/shooter, mob/living/M)
	if(shooter.Adjacent(M))
		return TRUE
	var/list/hits = check_trajectory(M, shooter)
	if(!islist(hits) || !(M in hits))
		return FALSE
	for(var/mob/living/L in hits)
		if(L != M && L != shooter)
			return FALSE
	return TRUE

/proc/npc_away_from(turf/from, turf/T)
	return get_dist(from, T) >= 9

/datum/ai_holder/rsnpc/proc/composure()
	var/job = npc_job_of(holder)
	if(SSjob.is_job_in_department(job, DEPARTMENT_SECURITY))
		return 1.9
	if(SSjob.is_job_in_department(job, DEPARTMENT_COMMAND))
		return 1.5
	if(SSjob.is_job_in_department(job, DEPARTMENT_MEDICAL))
		return 1.4
	if(SSjob.is_job_in_department(job, DEPARTMENT_CIVILIAN))
		return 0.8
	return 1

/datum/ai_holder/rsnpc/proc/fight_or_flight(mob/living/M)
	if(health_share() < npc_psetting("flee_health"))
		return NPC_FLIGHT
	if(npc_armed(M, TRUE) && !can_arm(TRUE))
		return NPC_FLIGHT
	return NPC_FIGHT

/datum/ai_holder/rsnpc/proc/weapons_at_hand()
	. = reachable_items()
	for(var/obj/item/I in look())
		if(isturf(I.loc) && get_dist(holder, I) <= 3)
			. |= I

/datum/ai_holder/rsnpc/proc/can_arm(heavy)
	for(var/obj/item/I as anything in weapons_at_hand())
		if(istype(I, /obj/item/weapon/gun) ? npc_gun_ready(I) : (heavy ? I.force >= 15 : npc_weapon_value(I) > 0))
			return TRUE
	return FALSE

/datum/ai_holder/rsnpc/proc/take_on(mob/living/M, mode, why)
	if(threat?.resolve() == M && threat_mode == mode)
		return
	threat = WEAKREF(M)
	threat_key = npc_person_key(M)
	threat_mode = mode
	threat_seen_at = world.time
	threat_seen_turf = get_turf(M)
	threat_dist = get_dist(holder, M)
	threat_walk = null
	clear_task()
	NPC_TRACE(src, NPC_TRACE_WITNESS, "[mode == NPC_FIGHT ? "fighting" : "fleeing from"] [M]; [why]")

/datum/ai_holder/rsnpc/proc/threat_danger()
	var/datum/npc_person/P = opinions[threat_key]
	return P ? P.danger_now() : 0

/datum/ai_holder/rsnpc/proc/threat_permanent()
	var/datum/npc_person/P = opinions[threat_key]
	return P && P.permanent()

/datum/ai_holder/rsnpc/proc/end_fight(why)
	NPC_TRACE(src, NPC_TRACE_WITNESS, "stopped [threat_mode == NPC_FIGHT ? "fighting" : "fleeing from"] [threat?.resolve()]; [why]")
	threat = null
	holder.a_intent = I_HELP
	stop_walk()

/datum/ai_holder/rsnpc/proc/fight_back(mob/living/M)
	var/datum/npc_person/P = person(M)
	if(threat?.resolve() == M)
		return
	var/hit_before = FALSE
	for(var/at in P.touches)
		if(at != world.time && at > world.time - 20 SECONDS)
			hit_before = TRUE
	if(!hit_before && P.opinion > npc_psetting("opinion_disliked_at") && P.danger_now() < NPC_DANGEROUS)
		return
	take_on(M, fight_or_flight(M), "continued attacks")

/datum/ai_holder/rsnpc/proc/threat_seen(mob/living/M)
	if(threat)
		return
	if(SSjob.is_job_in_department(npc_job_of(holder), DEPARTMENT_SECURITY))
		say_line("threat_confront", list("name" = M.name))
		take_on(M, NPC_FIGHT, "they're dangerous")
		return
	var/datum/npc_person/D = opinions[npc_person_key(M)]
	if(D?.permanent() && can_arm(TRUE) && fight_or_flight(M) == NPC_FIGHT)
		say_line("threat_confront", list("name" = M.name))
		take_on(M, NPC_FIGHT, "they're dangerous for good")
		return
	say_line("threat_avoid", list("name" = M.name))
	take_on(M, NPC_FLIGHT, "they're dangerous")

/datum/ai_holder/rsnpc/proc/check_panic()
	var/damage = holder.getBruteLoss() + holder.getFireLoss() + holder.getToxLoss() + holder.getOxyLoss() + holder.getCloneLoss()
	var/mob/living/A = last_attacker?.resolve()
	if(damage - last_damage >= npc_psetting("panic_damage") * composure() && danger_of(A) < NPC_DANGEROUS)
		panic_until = world.time + 8 SECONDS
		NPC_TRACE(src, NPC_TRACE_WITNESS, "panicking; took [round(damage - last_damage)] damage at once")
	last_damage = damage

/datum/ai_holder/rsnpc/proc/run_from(mob/living/M)
	if(escaping || !isturf(holder.loc))
		return FALSE
	var/list/way = npc_radius_find(get_turf(holder), 20, holder.GetAccess(), CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(npc_away_from), get_turf(M)))
	if(!way)
		return FALSE
	stop_walk()
	escaping = TRUE
	path = way
	NPC_TRACE(src, NPC_TRACE_WITNESS, "running from [M], [length(way)] steps")
	return TRUE

/datum/ai_holder/rsnpc/proc/fight_tick()
	check_panic()
	if(world.time < panic_until)
		clear_task()
		var/mob/living/A = last_attacker?.resolve()
		if(A && (A in look()) && run_from(A))
			say_line("narrate_retreat", list("name" = A.name))
		return TRUE
	if(!threat)
		for(var/mob/living/T in look())
			if((npc_is_person(T) || istype(T, /mob/living/simple_mob)) && T != holder && wanted(T) && npc_menace(T) && !noted("ran_off:[npc_person_key(T)]"))
				threat_seen(T)
				break
	if(!threat)
		return FALSE
	var/mob/living/M = threat.resolve()
	var/sees = M && (M in look())
	if(sees)
		if(!npc_menace(M))
			end_fight("they're down")
			return FALSE
		var/dist = get_dist(holder, M)
		if(threat_mode == NPC_FIGHT && dist > 1 && dist > threat_dist && !threat_permanent() && !(SSjob.is_job_in_department(npc_job_of(holder), DEPARTMENT_SECURITY) && wanted(M)))
			note("ran_off:[threat_key]", M.name, 30 SECONDS)
			end_fight("they ran off")
			return FALSE
		threat_dist = dist
		threat_seen_at = world.time
		threat_seen_turf = get_turf(M)
	else if(world.time > threat_seen_at + 20 SECONDS)
		end_fight("lost sight of them")
		return FALSE
	if(threat_mode == NPC_FIGHT && !(sees ? wanted(M) : threat_danger() >= NPC_DANGEROUS) && world.time > when_last_attacked + 20 SECONDS)
		end_fight("they stopped")
		return FALSE
	clear_task()
	if(threat_mode == NPC_FIGHT && sees && fight_or_flight(M) == NPC_FLIGHT)
		threat_mode = NPC_FLIGHT
		NPC_TRACE(src, NPC_TRACE_WITNESS, "losing to [M]; running")
	if(threat_mode == NPC_FLIGHT)
		if(sees)
			run_from(M)
		return TRUE
	attack(M, sees)
	return TRUE

/datum/ai_holder/rsnpc/proc/attack(mob/living/M, sees)
	if(!arm(M))
		return
	var/obj/item/weapon/melee/baton/B = holder.get_active_hand()
	if(istype(B) && !B.status && holder.checkClickCooldown())
		B.attack_self(holder)
		holder.setClickCooldown(DEFAULT_QUICK_COOLDOWN)
		NPC_TRACE(src, NPC_TRACE_WITNESS, "switched [B] on")
		return
	holder.a_intent = istype(B) ? I_DISARM : I_HURT
	var/gun = istype(holder.get_active_hand(), /obj/item/weapon/gun)
	if(sees && (gun && npc_clear_shot(holder, M) || M.Adjacent(holder)))
		stop_walk()
		holder.face_atom(M)
		holder.IAttack(M)
		return
	var/atom/where = sees ? M : threat_seen_turf
	if(!sees && where && npc_arrived(holder, where))
		end_fight("they're not where I last saw them")
		return
	if(where && destination != where)
		if(threat_walk == where && walk_outcome_why && !walk_lost_target)
			note("ran_off:[threat_key]", M?.name, 30 SECONDS)
			end_fight("can't get to them: [walk_outcome_why]")
			return
		threat_walk = where
		go_to(where)

/datum/ai_holder/rsnpc/proc/arm(mob/living/M)
	var/mob/living/carbon/human/H = holder
	var/obj/item/best
	var/best_value = 0
	for(var/obj/item/I as anything in weapons_at_hand())
		var/value = npc_weapon_value(I)
		if(value && istype(I, /obj/item/weapon/gun) && M && !M.Adjacent(H))
			value *= 2
		if(value > best_value)
			best = I
			best_value = value
	if(!best)
		if(H.get_active_hand() && !H.get_inactive_hand())
			H.swap_hand()
		if(H.get_active_hand() && !free_hand())
			return FALSE
		if(H.get_active_hand())
			H.swap_hand()
		return !H.get_active_hand()
	if(best == H.get_active_hand())
		return TRUE
	if(best == H.get_inactive_hand())
		H.swap_hand()
		return TRUE
	if(isturf(best.loc) && !best.Adjacent(H))
		if(destination != best)
			go_to(best)
		return FALSE
	take(best)
	return TRUE
