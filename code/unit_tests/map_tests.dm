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

/datum/unit_test/wire_test
	name = "MAP: Cable Test (Defined Z-Levels)"

/datum/unit_test/wire_test/start_test()
	//set background=1
	var/list/zs_to_test = using_map.unit_test_z_levels || list(1) //Either you set it, or you just get z1

	for(var/datum/powernet/powernets as anything in powernets)

		//nodes (machines, which includes APCs and SMES)
		if(!length(powernets.nodes))
			log_unit_test(length(powernets.cables), "[powernets] found with no nodes OR cables connected, something has gone horribly wrong.")

			var/obj/structure/cable/found_cable = powernets.cables[1]
			//Check if they're a station area
			var/area/cable_area = get_area(found_cable)
			if(!(cable_area.type in zs_to_test) || !cable_area.requires_power)
				continue
			log_unit_test("[powernets] found with no nodes connected ([found_cable.x], [found_cable.y], [found_cable.z])).")

		//cables
		if(!length(powernets.cables))
			log_unit_test(length(powernets.nodes), "[powernets] found with no cables OR nodes connected, something has gone horribly wrong.")

			var/obj/machinery/power/found_machine = powernets.nodes[1]
			//Check if they're a station area
			var/area/machine_area = get_area(found_machine)
			if(!(machine_area.type in zs_to_test || !machine_area.requires_power))
				continue
			log_unit_test("[powernets] found with no cables connected ([found_machine.x], [found_machine.y], [found_machine.z]).")

		if(!powernets.avail && !(locate(/obj/machinery/power/terminal) in powernets.nodes)) //No power roundstart, so check for an SMES connection (Solars, Turbine).
			var/obj/structure/cable/random_cable = powernets.cables[1]
			//Check if they're a station area
			var/area/cable_area = get_area(random_cable)
			if(!(cable_area.type in zs_to_test || !cable_area.requires_power))
				continue
			log_unit_test("[powernets] found with no power roundstart, connected to a cable at ([random_cable.x], [random_cable.y], [random_cable.z]).")
		else
			pass("No Abnormal powernets detected!")

		return TRUE

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
		pass("No active edges.\n")

	return 1
