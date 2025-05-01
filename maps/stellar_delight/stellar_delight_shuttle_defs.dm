////////////////SHUTTLE TIME///////////////////

//////////////////////////////////////////////////////////////
// Escape shuttle and pods
/datum/shuttle/autodock/ferry/emergency/escape
	name = "Escape"
	location = FERRY_LOCATION_OFFSITE
	shuttle_area = /area/shuttle/escape
	warmup_time = 10
	landmark_offsite = "escape_cc"
	landmark_station = "escape_station"
	landmark_transition = "escape_transit"
	move_time = SHUTTLE_TRANSIT_DURATION_RETURN
	move_direction = SOUTH
	docking_controller_tag = "escape_shuttle"

/datum/shuttle/autodock/ferry/escape_pod/portescape
	name = "Port Escape Pod"
	location = FERRY_LOCATION_STATION
	shuttle_area = /area/stellardelight/deck2/portescape
	warmup_time = 0
	landmark_station = "port_ship_berth"
	landmark_offsite = "port_escape_cc"
	landmark_transition = "port_escape_transit"
	docking_controller_tag = "port_escape_pod"
	move_time = SHUTTLE_TRANSIT_DURATION_RETURN
	move_direction = EAST
	map_specific = "StellarDelight"	//RS ADD

/datum/shuttle/autodock/ferry/escape_pod/starboardescape
	name = "Starboard Escape Pod"
	location = FERRY_LOCATION_STATION
	shuttle_area = /area/stellardelight/deck2/starboardescape
	warmup_time = 0
	landmark_station = "starboard_ship_berth"
	landmark_offsite = "starboard_escape_cc"
	landmark_transition = "starboard_escape_transit"
	docking_controller_tag = "starboard_escape_pod"
	move_time = SHUTTLE_TRANSIT_DURATION_RETURN
	move_direction = WEST
	map_specific = "StellarDelight"	//RS ADD

//////////////////////////////////////////////////////////////
// Supply shuttle
/datum/shuttle/autodock/ferry/supply/cargo
	name = "Supply"
	location = FERRY_LOCATION_OFFSITE
	shuttle_area = /area/shuttle/supply
	warmup_time = 10
	landmark_offsite = "supply_cc"
	landmark_station = "supply_station"
	docking_controller_tag = "supply_shuttle"
	flags = SHUTTLE_FLAGS_PROCESS|SHUTTLE_FLAGS_SUPPLY
	move_direction = WEST

/////EXPLORATION SHUTTLE
// The shuttle's 'shuttle' computer
/obj/machinery/computer/shuttle_control/explore/stellardelight/exploration
	name = "boat control console"
	shuttle_tag = "SD Exploration Shuttle"	//RS ADD
	req_one_access = null
	ai_control = TRUE

// A shuttle lateloader landmark
/obj/effect/shuttle_landmark/shuttle_initializer/exploration
	name = "Exploration Shuttle Landing Pad"
	base_area = /area/stellardelight/deck1/shuttlebay
	base_turf = /turf/simulated/floor/reinforced
	landmark_tag = "sd_explo"
	docking_controller = "explodocker_bay"
	shuttle_type = /datum/shuttle/autodock/overmap/exboat

// The 'shuttle'
/datum/shuttle/autodock/overmap/exboat
	name = "SD Exploration Shuttle"	//RS ADD
	current_location = "sd_explo"
	docking_controller_tag = "explodocker"
	shuttle_area = /area/stellardelight/deck1/exploshuttle
	fuel_consumption = 0
	defer_initialisation = TRUE
	range = 1
	map_specific = "StellarDelight"	//RS ADD

/////MINING SHUTTLE
// The shuttle's 'shuttle' computer
/obj/machinery/computer/shuttle_control/explore/stellardelight/mining
	name = "boat control console"
	shuttle_tag = "Mining Shuttle"
	req_one_access = null
	ai_control = TRUE

// A shuttle lateloader landmark
/obj/effect/shuttle_landmark/shuttle_initializer/mining
	name = "Mining Shuttle Landing Pad"
	base_area = /area/stellardelight/deck1/shuttlebay
	base_turf = /turf/simulated/floor/reinforced
	landmark_tag = "sd_mining"
	docking_controller = "miningdocker_bay"
	shuttle_type = /datum/shuttle/autodock/overmap/mineboat

// The 'shuttle'
/datum/shuttle/autodock/overmap/mineboat
	name = "Mining Shuttle"
	current_location = "sd_mining"
	docking_controller_tag = "miningdocker"
	shuttle_area = /area/stellardelight/deck1/miningshuttle
	fuel_consumption = 0
	defer_initialisation = TRUE
	range = 1
	map_specific = "StellarDelight"	//RS ADD

/////STARSTUFF/////
// The shuttle's 'shuttle' computer
/obj/machinery/computer/shuttle_control/explore/sdboat
	name = "Starstuff control console"
	shuttle_tag = "Starstuff"
	req_one_access = list(access_pilot)

/obj/effect/overmap/visitable/ship/landable/sd_boat
	name = "NTV Starstuff"
	desc = "A small shuttle from the NRV Stellar Delight."
	vessel_mass = 2500
	vessel_size = SHIP_SIZE_TINY
	shuttle = "Starstuff"
	known = TRUE

// A shuttle lateloader landmark
/obj/effect/shuttle_landmark/shuttle_initializer/sdboat
	name = "Port Shuttlepad"
	base_area = /area/stellardelight/deck3/exterior
	base_turf = /turf/simulated/floor/reinforced/airless
	landmark_tag = "port_shuttlepad"
	docking_controller = "sd_port_landing"
	shuttle_type = /datum/shuttle/autodock/overmap/sdboat

/datum/shuttle/autodock/overmap/sdboat
	name = "Starstuff"
	current_location = "port_shuttlepad"
	docking_controller_tag = "sdboat_docker"
	shuttle_area = list(/area/shuttle/sdboat/fore,/area/shuttle/sdboat/aft)
	fuel_consumption = 1
	defer_initialisation = TRUE
	map_specific = "StellarDelight"	//RS ADD

/area/shuttle/sdboat/fore
	icon = 'icons/turf/areas_vr.dmi'
	icon_state = "yelwhitri"
	name = "Starstuff Cockpit"
	requires_power = 1

/area/shuttle/sdboat/aft
	icon = 'icons/turf/areas_vr.dmi'
	icon_state = "yelwhitri"
	name = "Starstuff Crew Compartment"
	requires_power = 1

/////Virgo Flyer/////
// The shuttle's 'shuttle' computer
/obj/machinery/computer/shuttle_control/explore/ccboat
	name = "Virgo Flyer control console"
	shuttle_tag = "Virgo Flyer"
	req_one_access = list(access_pilot)

/obj/effect/overmap/visitable/ship/landable/ccboat
	name = "NTV Virgo Flyer"
	desc = "A small shuttle from Central Command."
	vessel_mass = 1000
	vessel_size = SHIP_SIZE_TINY
	shuttle = "Virgo Flyer"
	known = TRUE

// A shuttle lateloader landmark
/obj/effect/shuttle_landmark/shuttle_initializer/ccboat
	name = "Central Command Shuttlepad"
	base_area = /area/shuttle/centcom/ccbay
	base_turf = /turf/simulated/floor/reinforced
	landmark_tag = "cc_shuttlepad"
	docking_controller = "cc_landing_pad"
	shuttle_type = /datum/shuttle/autodock/overmap/ccboat

/datum/shuttle/autodock/overmap/ccboat
	name = "Virgo Flyer"
	current_location = "cc_shuttlepad"
	docking_controller_tag = "ccboat"
	shuttle_area = /area/shuttle/ccboat
	fuel_consumption = 0
	defer_initialisation = TRUE

/area/shuttle/ccboat
	icon = 'icons/turf/areas_vr.dmi'
	icon_state = "yelwhitri"
	name = "Virgo Flyer"
	requires_power = 0

/area/shuttle/centcom/ccbay
	icon = 'icons/turf/areas_vr.dmi'
	icon_state = "bluwhisqu"
	name = "Central Command Shuttle Bay"
	requires_power = 0
	dynamic_lighting = 0

/////LANDING LANDMARKS/////
/obj/effect/shuttle_landmark/premade/sd/deck1/portairlock
	name = "Near Deck 1 Port Airlock"
	landmark_tag = "sd-1-23-54"
/obj/effect/shuttle_landmark/premade/sd/deck1/aft
	name = "Near Deck 1 Aft"
	landmark_tag = "sd-1-67-15"
/obj/effect/shuttle_landmark/premade/sd/deck1/fore
	name = "Near Deck 1 Fore"
	landmark_tag = "sd-1-70-130"
/obj/effect/shuttle_landmark/premade/sd/deck1/starboard
	name = "Near Deck 1 Starboard"
	landmark_tag = "sd-1-115-85"

/obj/effect/shuttle_landmark/premade/sd/deck2/port
	name = "Near Deck 2 Port"
	landmark_tag = "sd-2-25-98"
/obj/effect/shuttle_landmark/premade/sd/deck2/starboard
	name = "Near Deck 2 Starboard"
	landmark_tag = "sd-2-117-98"

/obj/effect/shuttle_landmark/premade/sd/deck3/portairlock
	name = "Near Deck 3 Port Airlock"
	landmark_tag = "sd-3-22-78"
/obj/effect/shuttle_landmark/premade/sd/deck3/portlanding
	name = "Near Deck 3 Port Landing Pad"
	landmark_tag = "sd-3-36-33"
/obj/effect/shuttle_landmark/premade/sd/deck3/starboardlanding
	name = "Near Deck 3 Starboard Landing Pad"
	landmark_tag = "sd-3-104-33"
/obj/effect/shuttle_landmark/premade/sd/deck3/starboardairlock
	name = "Near Deck 3 Starboard Airlock"
	landmark_tag = "sd-3-120-78"

/obj/item/weapon/paper/dockingcodes/sd
	name = "Stellar Delight Docking Codes"
	codes_from_z = Z_LEVEL_SHIP_LOW
