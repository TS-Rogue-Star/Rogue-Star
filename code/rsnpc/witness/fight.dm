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

/proc/npc_away_from(turf/from, turf/T)
	return get_dist(from, T) >= 9

/datum/ai_holder/complex_npc/proc/composure()
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

/datum/ai_holder/complex_npc/proc/fight_or_flight(mob/living/M)
	if(health_share() < npc_psetting("flee_health"))
		return NPC_FLIGHT
	if(npc_armed(M, TRUE) && !npc_armed(holder, TRUE))
		return NPC_FLIGHT
	return NPC_FIGHT

/datum/ai_holder/complex_npc/proc/take_on(mob/living/M, mode, why)
	if(threat?.resolve() == M && threat_mode == mode)
		return
	threat = WEAKREF(M)
	threat_key = npc_person_key(M)
	threat_mode = mode
	threat_seen_at = world.time
	threat_seen_turf = get_turf(M)
	clear_task()
	NPC_TRACE(src, NPC_TRACE_WITNESS, "[mode == NPC_FIGHT ? "fighting" : "fleeing from"] [M]; [why]")

/datum/ai_holder/complex_npc/proc/threat_danger()
	var/datum/npc_person/P = opinions[threat_key]
	return P ? P.danger_now() : 0

/datum/ai_holder/complex_npc/proc/end_fight(why)
	NPC_TRACE(src, NPC_TRACE_WITNESS, "stopped [threat_mode == NPC_FIGHT ? "fighting" : "fleeing from"] [threat?.resolve()]; [why]")
	threat = null
	holder.a_intent = I_HELP
	stop_walk()

/datum/ai_holder/complex_npc/proc/fight_back(mob/living/M)
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

/datum/ai_holder/complex_npc/proc/threat_seen(mob/living/M)
	var/key = "sighted:[npc_person_key(M)]"
	if(!noted(key))
		note(key, M.name, 2 MINUTES)
		say_line("alarm_sighting", list("name" = M.name, "place" = "[get_area(M)]"), radiochannels["Security"])
	if(threat)
		return
	if(SSjob.is_job_in_department(npc_job_of(holder), DEPARTMENT_SECURITY) || (npc_armed(holder, TRUE) && fight_or_flight(M) == NPC_FIGHT))
		say_line("threat_confront", list("name" = M.name))
		take_on(M, NPC_FIGHT, "they're dangerous")
		return
	say_line("threat_avoid", list("name" = M.name))
	take_on(M, NPC_FLIGHT, "they're dangerous")

/datum/ai_holder/complex_npc/proc/check_panic()
	var/damage = holder.getBruteLoss() + holder.getFireLoss() + holder.getToxLoss() + holder.getOxyLoss() + holder.getCloneLoss()
	var/mob/living/A = last_attacker?.resolve()
	if(damage - last_damage >= npc_psetting("panic_damage") * composure() && danger_of(A) < NPC_DANGEROUS)
		panic_until = world.time + 8 SECONDS
		NPC_TRACE(src, NPC_TRACE_WITNESS, "panicking; took [round(damage - last_damage)] damage at once")
	last_damage = damage

/datum/ai_holder/complex_npc/proc/run_from(mob/living/M)
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

/datum/ai_holder/complex_npc/proc/fight_tick()
	check_panic()
	if(world.time < panic_until)
		clear_task()
		var/mob/living/A = last_attacker?.resolve()
		if(A && (A in look()) && run_from(A))
			say_line("narrate_retreat", list("name" = A.name))
		return TRUE
	if(!threat)
		for(var/mob/living/T in look())
			if(npc_is_person(T) && danger_of(T) >= NPC_DANGEROUS && npc_menace(T))
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
		threat_seen_at = world.time
		threat_seen_turf = get_turf(M)
	else if(world.time > threat_seen_at + 20 SECONDS)
		end_fight("lost sight of them")
		return FALSE
	if(threat_mode == NPC_FIGHT && threat_danger() < NPC_DANGEROUS && world.time > when_last_attacked + 20 SECONDS)
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

/datum/ai_holder/complex_npc/proc/attack(mob/living/M, sees)
	holder.a_intent = I_HURT
	arm()
	if(sees && (istype(holder.get_active_hand(), /obj/item/weapon/gun) || M.Adjacent(holder)))
		stop_walk()
		holder.face_atom(M)
		holder.IAttack(M)
		return
	var/atom/where = sees ? M : threat_seen_turf
	if(where && destination != where)
		go_to(where)

/datum/ai_holder/complex_npc/proc/arm()
	var/mob/living/carbon/human/H = holder
	var/obj/item/best
	var/best_value = 0
	for(var/obj/item/I in list(H.get_active_hand(), H.get_inactive_hand(), H.belt, H.s_store))
		var/value = npc_weapon_value(I)
		if(value > best_value)
			best = I
			best_value = value
	if(!best)
		if(H.get_active_hand() && !H.get_inactive_hand())
			H.swap_hand()
		return
	if(best == H.get_active_hand())
		return
	if(best == H.get_inactive_hand())
		H.swap_hand()
		return
	take(best)
