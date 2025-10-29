/datum/unit_test/apc_area_test
	name = "MAP: Area Test APC / Scrubbers / Vents (Defined Z-Levels)"

/datum/unit_test/apc_area_test/start_test()
	var/list/bad_areas = list()
	var/area_test_count = 0
	var/list/exempt_areas = typesof(/area/space,
					/area/syndicate_station,
					/area/skipjack_station,
					/area/solar,
					/area/shuttle,
					/area/holodeck,
					/area/supply/station,
					/area/mine,
					/area/vacant/vacant_shop,
					/area/turbolift,
					/area/submap					)

	var/list/exempt_from_atmos = typesof(/area/maintenance,
						/area/storage,
						/area/engineering/atmos/storage,
						/area/rnd/test_area,
						/area/construction,
						/area/server,
						/area/mine,
						/area/vacant/vacant_shop,
						/area/rnd/research_storage, // This should probably be fixed,
						/area/security/riot_control // This should probably be fixed,
						)

	var/list/exempt_from_apc = typesof(/area/construction,
						/area/medical/genetics,
						/area/mine,
						/area/vacant/vacant_shop
						)

	// Some maps have areas specific to the map, so include those.
	exempt_areas += using_map.unit_test_exempt_areas.Copy()
	exempt_from_atmos += using_map.unit_test_exempt_from_atmos.Copy()
	exempt_from_apc += using_map.unit_test_exempt_from_apc.Copy()

	var/list/zs_to_test = using_map.unit_test_z_levels || list(1) //Either you set it, or you just get z1

	for(var/area/A in world)
		if((A.z in zs_to_test) && !(A.type in exempt_areas))
			area_test_count++
			var/area_good = 1
			var/bad_msg = "--------------- [A.name]([A.type])"

			if(isnull(A.apc) && !(A.type in exempt_from_apc))
				log_unit_test("[bad_msg] lacks an APC. (X[A.x]|Y[A.y]) - Z[A.z])")
				area_good = 0

			if(!A.air_scrub_info.len && !(A.type in exempt_from_atmos))
				log_unit_test("[bad_msg] lacks an Air scrubber. (X[A.x]|Y[A.y]) - (Z[A.z])")
				area_good = 0

			if(!A.air_vent_info.len && !(A.type in exempt_from_atmos))
				log_unit_test("[bad_msg] lacks an Air vent. (X[A.x]|Y[A.y]) - (Z[A.z])")
				area_good = 0

			if(!area_good)
				bad_areas.Add(A)

	if(bad_areas.len)
		fail("\[[bad_areas.len]/[area_test_count]\]Some areas lacked APCs, Air Scrubbers, or Air vents.")
	else
		pass("All \[[area_test_count]\] areas contained APCs, Air scrubbers, and Air vents.")

	return 1

// RS Edit Start - Atmospherics & Disposal Pipe Tests
/datum/unit_test/pipe_test
	name = "MAP: Pipe Test (Defined Z-Levels)"

/datum/unit_test/pipe_test/start_test()
	set background=1

	var/pipe_test_count = 0
	var/bad_tests = 0
	var/turf/T = null
	var/obj/machinery/atmospherics/pipe/P = null
	var/list/pipe_turfs = list()
	var/list/dirs_checked = list()

	var/list/exempt_from_pipes = list()
	exempt_from_pipes += using_map.unit_test_exempt_from_pipes.Copy()

	var/list/zs_to_test = using_map.unit_test_z_levels || list(1) //Either you set it, or you just get z1

	finding_pipe_turfs:
		for(P in world)
			T = null
			T = get_turf(P)
			var/area/A = get_area(T)
			if(T && (T.z in zs_to_test) && !(A.type in exempt_from_pipes))
				for(var/color in pipe_colors)
					if(P.pipe_color == pipe_colors[color] || P.color == pipe_colors[color])
						pipe_turfs |= T
						continue finding_pipe_turfs // Pipes only have one color

	for(var/color in pipe_colors)
		for(T in pipe_turfs)
			var/bad_msg = "--------------- [T.name] \[[T.x] / [T.y] / [T.z]\] [color]"
			dirs_checked.Cut()
			for(P in T)
				pipe_test_count++
				if(istype(P, /obj/machinery/atmospherics/pipe/zpipe))
					continue // Do not check zpipes. They are magic.
				if(P.pipe_color == pipe_colors[color] || P.color == pipe_colors[color]) // It's okay to have different color pipes in the same direction (supply/waste)
					if(P.dir in dirs_checked)
						bad_tests++
						log_unit_test("[bad_msg] Contains multiple pipes with same direction on top of each other.")
					dirs_checked.Add(P.dir)

		log_unit_test("[color] pipes checked.")

	if(bad_tests)
		fail("\[[bad_tests] / [pipe_test_count]\] Some turfs had overlapping pipes going the same direction.")
	else
		pass("All \[[pipe_test_count]\] pipes had no overlapping going the same direction.")

	return 1

/datum/unit_test/disposals_test
	name = "MAP: Disposal Pipe Test (Defined Z-Levels)"

/datum/unit_test/disposals_test/start_test()
	set background=1

	var/pipe_test_count = 0
	var/bad_tests = 0
	var/turf/T = null
	var/obj/structure/disposalpipe/P = null
	var/list/pipe_turfs = list()
	var/list/dirs_checked = list()
	var/other_pipe_on_turf = FALSE
	var/pipe_segment = FALSE

	var/list/exempt_from_pipes = list()
	exempt_from_pipes += using_map.unit_test_exempt_from_pipes.Copy()

	var/list/zs_to_test = using_map.unit_test_z_levels || list(1) //Either you set it, or you just get z1

	for(P in world)
		T = null
		T = get_turf(P)
		var/area/A = get_area(T)
		if(T && (T.z in zs_to_test) && !(A.type in exempt_from_pipes))
			pipe_turfs |= T

	for(T in pipe_turfs)
		var/bad_msg = "--------------- [T.name] \[[T.x] / [T.y] / [T.z]\]"
		other_pipe_on_turf = FALSE
		dirs_checked.Cut()

		for(P in T)
			pipe_test_count++

			pipe_segment = FALSE
			pipe_segment = istype(P, /obj/structure/disposalpipe/segment)
			if (!pipe_segment)
				other_pipe_on_turf = TRUE

			// Check if there are pipes with duplicate directions, or if there is a 3 or 4 way pipe on the turf, but also a segment
			if ((pipe_segment && (P.dir in dirs_checked)) || (dirs_checked.len > 0 && other_pipe_on_turf) || (pipe_segment && other_pipe_on_turf))
				bad_tests++
				log_unit_test("[bad_msg] Contains multiple pipes on top of each other.")
			dirs_checked.Add(P.dir)

	if(bad_tests)
		fail("\[[bad_tests] / [pipe_test_count]\] Some turfs had overlapping disposal pipes going the same direction.")
	else
		pass("All \[[pipe_test_count]\] disposal pipes had no overlapping going the same direction.")

	return 1

//RS Edit End

/datum/unit_test/wire_test
	name = "MAP: Cable Test (Defined Z-Levels)"

/datum/unit_test/wire_test/start_test()
	set background=1

	var/wire_test_count = 0
	var/bad_tests = 0
	var/turf/T = null
	var/obj/structure/cable/C = null
	var/list/cable_turfs = list()
	var/list/dirs_checked = list()

	var/list/exempt_from_wires = list()
	exempt_from_wires += using_map.unit_test_exempt_from_wires.Copy()

	var/list/zs_to_test = using_map.unit_test_z_levels || list(1) //Either you set it, or you just get z1

	for(var/color in possible_cable_coil_colours)
		cable_turfs = list()

		for(C in world)
			T = null

			T = get_turf(C)
			var/area/A = get_area(T)
			if(T && (T.z in zs_to_test) && !(A.type in exempt_from_wires))
				if(C.color == possible_cable_coil_colours[color])
					cable_turfs |= get_turf(C)

		for(T in cable_turfs)
			var/bad_msg = "--------------- [T.name] \[[T.x] / [T.y] / [T.z]\] [color]"
			dirs_checked.Cut()
			for(C in T)
				wire_test_count++
				var/combined_dir = "[C.d1]-[C.d2]"
				if(combined_dir in dirs_checked)
					bad_tests++
					log_unit_test("[bad_msg] Contains multiple wires with same direction on top of each other.")
				dirs_checked.Add(combined_dir)

		log_unit_test("[color] wires checked.")

	if(bad_tests)
		fail("\[[bad_tests] / [wire_test_count]\] Some turfs had overlapping wires going the same direction.")
	else
		pass("All \[[wire_test_count]\] wires had no overlapping cables going the same direction.")

	return 1

/datum/unit_test/active_edges
	name = "MAP: Active edges (all maps)"

/datum/unit_test/active_edges/start_test()

	var/active_edges = air_master.active_edges.len
	var/list/edge_log = list()
	if(active_edges)
		for(var/connection_edge/E in air_master.active_edges)
			var/a_temp = E.A.air.temperature
			var/a_moles = E.A.air.total_moles
			var/a_vol = E.A.air.volume
			var/a_gas = ""
			for(var/gas in E.A.air.gas)
				a_gas += "[gas]=[E.A.air.gas[gas]]"

			var/b_temp
			var/b_moles
			var/b_vol
			var/b_gas = ""

			// Two zones mixing
			if(istype(E, /connection_edge/zone))
				var/connection_edge/zone/Z = E
				b_temp = Z.B.air.temperature
				b_moles = Z.B.air.total_moles
				b_vol = Z.B.air.volume
				for(var/gas in Z.B.air.gas)
					b_gas += "[gas]=[Z.B.air.gas[gas]]"

			// Zone and unsimulated turfs mixing
			if(istype(E, /connection_edge/unsimulated))
				var/connection_edge/unsimulated/U = E
				b_temp = U.B.temperature
				b_moles = "Unsim"
				b_vol = "Unsim"
				for(var/gas in U.air.gas)
					b_gas += "[gas]=[U.air.gas[gas]]"

			edge_log += "Active Edge [E] ([E.type])"
			edge_log += "Edge side A: T:[a_temp], Mol:[a_moles], Vol:[a_vol], Gas:[a_gas]"
			edge_log += "Edge side B: T:[b_temp], Mol:[b_moles], Vol:[b_vol], Gas:[b_gas]"

			for(var/turf/T in E.connecting_turfs)
				edge_log += "+--- Connecting Turf [T] ([T.type]) @ [T.x], [T.y], [T.z] ([T.loc])"

	if(active_edges)
		fail("Maps contained [active_edges] active edges at round-start.\n" + edge_log.Join("\n"))
	else
		pass("No active edges.")

	return 1
