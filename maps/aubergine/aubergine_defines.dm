//Normal map defs
#define Z_LEVEL_SURFACE			1
#define Z_LEVEL_SHIP_ONE		2 //Stupid sublime text linter won't trust defines with numerals
#define Z_LEVEL_SHIP_TWO		3
#define Z_LEVEL_SHIP_THREE		4
#define Z_LEVEL_SHIP_FOUR		5

#define Z_LEVEL_CENTCOM						10
#define Z_LEVEL_ROGUEMINE_1					15
#define Z_LEVEL_ROGUEMINE_2					16
#define Z_LEVEL_ROGUEMINE_3					17
#define Z_LEVEL_ROGUEMINE_4					18
#define Z_LEVEL_ALIENSHIP					19
#define Z_LEVEL_BEACH						20
#define Z_LEVEL_BEACH_CAVE					21
#define Z_LEVEL_AEROSTAT					22
#define Z_LEVEL_AEROSTAT_SURFACE			23
#define Z_LEVEL_DEBRISFIELD					24
#define Z_LEVEL_GATEWAY						25

/datum/map/aubergine
	name = "Aubergine"
	full_name = "NSB Aubergine & NIV Consider It Done"
	path = "aubergine"

	zlevel_datum_type = /datum/map_z_level/aubergine

	lobby_icon = 'icons/misc/title_vr.dmi'
	lobby_screens = list("tether")
	id_hud_icons = 'icons/mob/hud_jobs_vr.dmi'

	holomap_smoosh = list(list(
		Z_LEVEL_SHIP_ONE,
		Z_LEVEL_SHIP_TWO,
		Z_LEVEL_SHIP_THREE,
		Z_LEVEL_SHIP_FOUR))

	station_name  = "NSB Aubergine"
	station_short = "Aubergine"
	dock_name     = "Virgo-4 Ground Station"
	boss_name     = "Central Command"
	boss_short    = "CentCom"
	company_name  = "NanoTrasen"
	company_short = "NT"
	starsys_name  = "Virgo-Erigone"

	shuttle_docked_message = "The scheduled Orange Line tram to the %dock_name% has arrived. It will depart in approximately %ETD%."
	shuttle_leaving_dock = "The Orange Line tram has left the station. Estimate %ETA% until the tram arrives at %dock_name%."
	shuttle_called_message = "A scheduled crew transfer to the %dock_name% is occuring. The tram will be arriving shortly. Those departing should proceed to the Orange Line tram station within %ETA%."
	shuttle_recall_message = "The scheduled crew transfer has been cancelled."
	emergency_shuttle_docked_message = "The evacuation tram has arrived at the tram station. You have approximately %ETD% to board the tram."
	emergency_shuttle_leaving_dock = "The emergency tram has left the station. Estimate %ETA% until the shuttle arrives at %dock_name%."
	emergency_shuttle_called_message = "An emergency evacuation has begun, and an off-schedule tram has been called. It will arrive at the tram station in approximately %ETA%."
	emergency_shuttle_recall_message = "The evacuation tram has been recalled."

	station_networks = list(
							NETWORK_CARGO,
							NETWORK_CIRCUITS,
							NETWORK_CIVILIAN,
							NETWORK_COMMAND,
							NETWORK_ENGINE,
							NETWORK_ENGINEERING,
							//NETWORK_EXPLORATION,
							NETWORK_MEDICAL,
							NETWORK_MINE,
							//NETWORK_OUTSIDE,
							NETWORK_RESEARCH,
							NETWORK_RESEARCH_OUTPOST,
							NETWORK_ROBOTS,
							NETWORK_SECURITY,
							//NETWORK_TCOMMS,
							//NETWORK_TETHER
							)
	secondary_networks = list(
							NETWORK_ERT,
							NETWORK_MERCENARY,
							NETWORK_THUNDER,
							NETWORK_COMMUNICATORS,
							NETWORK_ALARM_ATMOS,
							NETWORK_ALARM_POWER,
							NETWORK_ALARM_FIRE
							)

	bot_patrolling = FALSE

	allowed_spawns = list("Tram Station","Gateway","Cryogenic Storage","Cyborg Storage")
	//spawnpoint_died = /datum/spawnpoint/tram
	//spawnpoint_left = /datum/spawnpoint/tram
	spawnpoint_stayed = /datum/spawnpoint/cryo

	//meteor_strike_areas = list(/area/tether/surfacebase/outside/outside3)

	unit_test_exempt_areas = list()
	unit_test_exempt_from_atmos = list()

	lateload_z_levels = list(
		//list("Tether - Misc","Tether - Ships","Tether - Underdark","Tether - Plains")
		)

	lateload_single_pick = list(
		//list("Snow Field")
		)

	ai_shell_restricted = TRUE
	ai_shell_allowed_levels = list(
		Z_LEVEL_SURFACE,
		Z_LEVEL_SHIP_ONE,
		Z_LEVEL_SHIP_TWO,
		Z_LEVEL_SHIP_THREE,
		Z_LEVEL_SHIP_FOUR
		)

	//belter_docked_z = 		list(Z_LEVEL_SPACE_HIGH)
	//belter_transit_z =	 	list(Z_LEVEL_SHIPS)
	//belter_belt_z = 		list(Z_LEVEL_ROGUEMINE_1,
						 		 //Z_LEVEL_ROGUEMINE_2,
						 	 	 //Z_LEVEL_ROGUEMINE_3,
								 //Z_LEVEL_ROGUEMINE_4)


/datum/map/aubergine/perform_map_generation()
	/*
	new /datum/random_map/automata/cave_system/no_cracks(null, 1, 1, Z_LEVEL_SURFACE_MINE, world.maxx, world.maxy) // Create the mining Z-level.
	new /datum/random_map/noise/ore(null, 1, 1, Z_LEVEL_SURFACE_MINE, 64, 64)         // Create the mining ore distribution map.

	new /datum/random_map/automata/cave_system/no_cracks(null, 1, 1, Z_LEVEL_SOLARS, world.maxx, world.maxy) // Create the mining Z-level.
	new /datum/random_map/noise/ore(null, 1, 1, Z_LEVEL_SOLARS, 64, 64)         // Create the mining ore distribution map.
	*/
	return 1

/datum/planet/virgo4
	expected_z_levels = list(Z_LEVEL_SURFACE)

// Short range computers see only the six main levels, others can see the surrounding surface levels.
/datum/map/aubergine/get_map_levels(var/srcz, var/long_range = TRUE)
	if (long_range && (srcz in map_levels))
		return map_levels
	//Ship can see ship
	else if (srcz >= Z_LEVEL_SHIP_ONE && srcz <= Z_LEVEL_SHIP_FOUR)
		return list(
			Z_LEVEL_SHIP_ONE,
			Z_LEVEL_SHIP_TWO,
			Z_LEVEL_SHIP_THREE,
			Z_LEVEL_SHIP_FOUR)
	//Beach can see beach
	else if(srcz >= Z_LEVEL_BEACH && srcz <= Z_LEVEL_BEACH_CAVE)
		return list(
			Z_LEVEL_BEACH,
			Z_LEVEL_BEACH_CAVE)
	//Aerostat can see aerostat
	else if(srcz >= Z_LEVEL_AEROSTAT && srcz <= Z_LEVEL_AEROSTAT_SURFACE)
		return list(
			Z_LEVEL_AEROSTAT,
			Z_LEVEL_AEROSTAT_SURFACE)
	else
		return list(srcz) //prevents runtimes when using CMC. any Z-level not defined above will be 'isolated' and only show to GPSes/CMCs on that same Z (e.g. CentCom).

// For making the 6-in-1 holomap, we calculate some offsets
#define AUBERGINE_MAP_SIZE 200 // Width and height of compiled in tether z levels.
#define AUBERGINE_HOLOMAP_CENTER_GUTTER 40 // 40px central gutter between columns
#define AUBERGINE_HOLOMAP_MARGIN_X ((HOLOMAP_ICON_SIZE - (2*AUBERGINE_MAP_SIZE) - AUBERGINE_HOLOMAP_CENTER_GUTTER) / 2)
#define AUBERGINE_HOLOMAP_MARGIN_Y ((HOLOMAP_ICON_SIZE - (3*AUBERGINE_MAP_SIZE)) / 2)

// We have a bunch of stuff common to the station z levels
/datum/map_z_level/aubergine/surface
	z = Z_LEVEL_SURFACE
	name = "Aubergine"
	base_turf = /turf/simulated/floor/outdoors/dirt
	flags = MAP_LEVEL_STATION|MAP_LEVEL_CONTACT|MAP_LEVEL_PLAYER|MAP_LEVEL_CONSOLES|MAP_LEVEL_XENOARCH_EXEMPT
	holomap_legend_x = 220
	holomap_legend_y = 160

/datum/map_z_level/aubergine/ship
	base_turf = /turf/simulated/open

/datum/map_z_level/aubergine/ship/deck1
	z = Z_LEVEL_SHIP_ONE
	name = "NIV Consider It Done (Deck 1)"
	flags = MAP_LEVEL_STATION|MAP_LEVEL_CONTACT|MAP_LEVEL_PLAYER|MAP_LEVEL_CONSOLES|MAP_LEVEL_XENOARCH_EXEMPT
	transit_chance = 25
	base_turf = /turf/space
	holomap_offset_x = AUBERGINE_HOLOMAP_MARGIN_X
	holomap_offset_y = AUBERGINE_HOLOMAP_MARGIN_Y + AUBERGINE_MAP_SIZE*0

/datum/map_z_level/aubergine/ship/deck2
	z = Z_LEVEL_SHIP_TWO
	name = "NIV Consider It Done (Deck 2)"
	flags = MAP_LEVEL_STATION|MAP_LEVEL_CONTACT|MAP_LEVEL_PLAYER|MAP_LEVEL_CONSOLES|MAP_LEVEL_XENOARCH_EXEMPT
	transit_chance = 25
	base_turf = /turf/simulated/open
	holomap_offset_x = AUBERGINE_HOLOMAP_MARGIN_X
	holomap_offset_y = AUBERGINE_HOLOMAP_MARGIN_Y + AUBERGINE_MAP_SIZE*1

/datum/map_z_level/aubergine/ship/deck3
	z = Z_LEVEL_SHIP_THREE
	name = "NIV Consider It Done (Deck 3)"
	flags = MAP_LEVEL_STATION|MAP_LEVEL_CONTACT|MAP_LEVEL_PLAYER|MAP_LEVEL_CONSOLES|MAP_LEVEL_XENOARCH_EXEMPT
	transit_chance = 25
	base_turf = /turf/simulated/open
	holomap_offset_x = AUBERGINE_HOLOMAP_MARGIN_X
	holomap_offset_y = AUBERGINE_HOLOMAP_MARGIN_Y + AUBERGINE_MAP_SIZE*2

/datum/map_z_level/aubergine/ship/deck4
	z = Z_LEVEL_SHIP_FOUR
	name = "NIV Consider It Done (Deck 4)"
	flags = MAP_LEVEL_STATION|MAP_LEVEL_CONTACT|MAP_LEVEL_PLAYER|MAP_LEVEL_CONSOLES|MAP_LEVEL_XENOARCH_EXEMPT
	transit_chance = 25
	base_turf = /turf/simulated/open
	holomap_offset_x = AUBERGINE_HOLOMAP_MARGIN_X
	holomap_offset_y = AUBERGINE_HOLOMAP_MARGIN_Y + AUBERGINE_MAP_SIZE*2
