/proc/npc_walls_off(obj/O)
	return istype(O, /obj/structure/inflatable)

/proc/npc_can_stand(turf/T)
	if(!istype(T) || T.density || isopenspace(T) && !(locate(/obj/structure/stairs/top) in T))
		return FALSE
	for(var/obj/O in T)
		if(istype(O, /obj/effect/portal) || istype(O, /obj/effect/map_effect/portal) || npc_walls_off(O))
			return FALSE
		if(O.density && !istype(O, /obj/machinery/door) && !(O.flags & ON_BORDER))
			return FALSE
	return TRUE

/proc/npc_can_step(turf/here, turf/next, list/access, mob/living/who)
	if(!npc_can_stand(next) || npc_tape_blocks(next, access))
		return FALSE
	var/list/doors
	for(var/obj/machinery/door/D in here)
		LAZYADD(doors, D)
	for(var/obj/machinery/door/D in next)
		LAZYADD(doors, D)
	if(LinkBlockedWithAccess(here, next, null, doors))
		return FALSE
	if(doors && npc_door_blocks(here, next, access))
		return FALSE
	if(who && npc_step_danger(next, who))
		return FALSE
	return TRUE

/proc/npc_door_blocks(turf/here, turf/next, list/access)
	var/dir = get_dir(here, next)
	for(var/obj/machinery/door/D in here)
		if((D.flags & ON_BORDER) && D.dir == dir && !npc_door_passable(D, access))
			return TRUE
	for(var/obj/machinery/door/D in next)
		if(D.flags & ON_BORDER)
			if(D.dir == GLOB.reverse_dir[dir] && !npc_door_passable(D, access))
				return TRUE
		else if(!npc_door_passable(D, access))
			return TRUE
	return FALSE

/proc/npc_door_passable(obj/machinery/door/D, list/access, anyone = FALSE)
	if(istype(D, /obj/machinery/door/blast))
		return !D.density
	if(istype(D, /obj/machinery/door/firedoor))
		var/obj/machinery/door/firedoor/F = D
		if(!F.density)
			return TRUE
		if(!anyone && npc_firedoor_alarmed(F))
			return FALSE
		return !F.blocked && !(F.stat & (BROKEN|NOPOWER)) && !(F.lockdown && !anyone && !F.check_access_list(access))
	var/key = anyone || !D.requiresID() || D.check_access_list(access)
	if(!D.density || D.operating)
		return key
	return key && D.can_open()

/proc/npc_tape_blocks(turf/T, list/access)
	for(var/obj/item/tape/P in T)
		if(!P.lifted && !P.check_access_list(access))
			return TRUE
	return FALSE

/proc/npc_firedoor_alarmed(obj/machinery/door/firedoor/F)
	if(F.lockdown || F.pdiff_alert)
		return TRUE
	for(var/area/A in F.areas_added)
		if(A.firedoors_closed)
			return TRUE
	return FALSE

/proc/npc_stairs_other_end(turf/T)
	var/obj/structure/stairs/bottom/B = locate() in T
	if(B?.top && B.check_integrity())
		return get_turf(B.top)
	var/obj/structure/stairs/top/S = locate() in T
	if(S?.bottom && S.check_integrity())
		return get_turf(S.bottom)
	return null

/proc/npc_step_danger(turf/T, mob/living/who)
	var/datum/ai_holder/rsnpc/ai_mind = who && npc_ai_mind(who)
	return npc_fixed_danger(T) || ai_mind?.danger_seen[T] || !npc_air_known_safe(T, who) || !npc_grip_at(T, who)

/proc/npc_air_known_safe(turf/T, mob/living/who)
	var/datum/ai_holder/rsnpc/ai_mind = who && npc_ai_mind(who)
	if(!ai_mind || T == get_turf(who) || ai_mind.turfs_in_sight[T])
		return npc_air_safe_for(T, who)
	var/bad = ai_mind.air_seen[T]
	if(isnull(bad))
		bad = npc_built_air_bad(T, who)
	return !bad || ai_mind.suited()

/proc/npc_built_air_bad(turf/T, mob/living/carbon/human/H)
	if(!istype(H))
		return FALSE
	if(isspace(T))
		return TRUE
	var/total = T.oxygen + T.nitrogen + T.carbon_dioxide + T.phoron
	if(total <= 0)
		return TRUE
	var/pressure = total * R_IDEAL_GAS_EQUATION * T.temperature / CELL_VOLUME
	if(pressure < H.species.hazard_low_pressure || pressure >= H.species.hazard_high_pressure)
		return TRUE
	if(T.temperature < H.species.cold_level_1 || T.temperature > H.species.heat_level_1)
		return TRUE
	var/breath = H.species.breath_type ? T.vars[H.species.breath_type] : total
	if(breath / total * pressure < H.species.minimum_breath_pressure)
		return TRUE
	var/poison = H.species.poison_type ? T.vars[H.species.poison_type] : 0
	return poison / total * pressure > 0.2

/proc/npc_air_bad(turf/T, mob/living/carbon/human/H, list/checked_air)
	if(!istype(H))
		return FALSE
	if(isspace(T))
		return TRUE
	var/datum/gas_mixture/G = T.return_air()
	if(!G)
		return FALSE
	if(checked_air && (G in checked_air))
		return checked_air[G]
	var/bad = npc_gas_bad(G, H, FALSE)
	if(checked_air)
		checked_air[G] = bad
	return bad

/proc/npc_gas_bad(datum/gas_mixture/G, mob/living/carbon/human/H, protected)
	var/pressure = G.return_pressure()
	var/felt = protected ? H.calculate_affecting_pressure(pressure) : pressure
	if(felt < H.species.hazard_low_pressure || felt >= H.species.hazard_high_pressure)
		return TRUE
	if(G.temperature < H.species.cold_level_1 && (!protected || H.get_cold_protection(G.temperature) < 0.99))
		return TRUE
	if(G.temperature > H.species.heat_level_1 && (!protected || H.get_heat_protection(G.temperature) < 0.99))
		return TRUE
	return !(protected && npc_on_air(H)) && !npc_gas_breathable(G, H, pressure)

/proc/npc_on_air(mob/living/carbon/human/H)
	return istype(H) && H.internal

/proc/npc_grip_at(turf/T, mob/living/who)
	if(!who || T.has_gravity())
		return TRUE
	var/shoes
	for(var/turf/N in orange(1, T))
		if(isspace(N))
			continue
		if(istype(N, /turf/simulated/floor) && !N.has_gravity())
			if(isnull(shoes))
				shoes = !!who?.Check_Shoegrip()
			if(!shoes)
				continue
		return TRUE
	for(var/obj/O in orange(1, T))
		if(istype(O, /obj/structure/lattice) || istype(O, /obj/structure/catwalk) || O.density && O.anchored)
			return TRUE
	return FALSE

/proc/npc_fixed_danger(turf/T)
	return (locate(/obj/fire) in T) || (locate(/obj/effect/temporary_effect/shuttle_landing) in T)

/proc/npc_dense_thing_in(turf/T)
	for(var/obj/O in T)
		if(O.density)
			return TRUE
	return FALSE

/proc/npc_machine_danger_tiles(atom/A)
	. = list()
	if(istype(A, /obj/machinery/containment_field))
		. += get_turf(A)
	else if(istype(A, /obj/machinery/power/emitter))
		var/obj/machinery/power/emitter/E = A
		if(!E.active || (E.stat & BROKEN))
			return
		var/turf/T = get_turf(E)
		for(var/i in 1 to 20)
			T = get_step(T, E.dir)
			if(!T || T.density || npc_dense_thing_in(T))
				break
			. += T
	else if(istype(A, /obj/machinery/gravity_generator/main))
		var/obj/machinery/gravity_generator/main/G = A
		if(!G.charging_state || (G.stat & BROKEN))
			return
		var/area/place = get_area(G)
		for(var/turf/T in range(6, G))
			if(T.loc == place)
				. += T
	else if(istype(A, /obj/singularity))
		for(var/turf/T in range(8, A))
			. += T

/proc/npc_air_safe_for(turf/T, mob/living/carbon/human/H)
	if(!istype(H))
		return TRUE
	var/datum/gas_mixture/G = T.return_air()
	if(!G)
		return TRUE
	return !npc_gas_bad(G, H, TRUE)

/proc/npc_air_breathable(turf/T, mob/living/carbon/human/H)
	if(!istype(H) || !H.species.breath_type)
		return TRUE
	var/datum/gas_mixture/G = T.return_air()
	if(!G)
		return TRUE
	return npc_gas_breathable(G, H)

/proc/npc_gas_breathable(datum/gas_mixture/G, mob/living/carbon/human/H, pressure)
	if(!H.species.breath_type)
		return TRUE
	if(!G.total_moles)
		return FALSE
	if(isnull(pressure))
		pressure = G.return_pressure()
	if(G.gas[H.species.breath_type] / G.total_moles * pressure < H.species.minimum_breath_pressure)
		return FALSE
	if(H.species.poison_type && G.gas[H.species.poison_type] / G.total_moles * pressure > 0.2)
		return FALSE
	return TRUE
