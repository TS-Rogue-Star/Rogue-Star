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

////////////////////////////////////////
//////// Excursion Shuttle /////////////
////////////////////////////////////////
// The 'shuttle' of the excursion shuttle
/datum/shuttle/autodock/overmap/sp_excursion
	name = "Sirius Point Excursion Shuttle"
	warmup_time = 0
	current_location = "sp_excursion_hangar"
	docking_controller_tag = "expshuttle_docker"
	shuttle_area = list(/area/shuttle/excursion/cockpit, /area/shuttle/excursion/general, /area/shuttle/excursion/cargo, /area/shuttle/excursion/power)
	fuel_consumption = 3
	move_direction = NORTH
	map_specific = "Sirius Point"

// The 'ship' of the excursion shuttle
/obj/effect/overmap/visitable/ship/landable/sp_excursion
	name = "Sirius Point Excursion Shuttle"
	desc = "The reliable Excursion Shuttle. NT Approved!"
	icon_state = "htu_destroyer_g"
	vessel_mass = 8000
	vessel_size = SHIP_SIZE_SMALL
	shuttle = "Sirius Point Excursion Shuttle"

/obj/machinery/computer/shuttle_control/explore/sp_excursion
	name = "short jump console"
	shuttle_tag = "Sirius Point Excursion Shuttle"
	req_one_access = list(access_pilot)

////////////////////////////////////////
////////////// MOONSTUFF ///////////////
////////////////////////////////////////
/obj/effect/overmap/visitable/ship/landable/spboat
	name = "NTV Moonstuff"
	desc = "A small shuttle from the NRV Stellar Delight."
	vessel_mass = 2500
	vessel_size = SHIP_SIZE_TINY
	shuttle = "Moonstuff"
	known = TRUE

// A shuttle lateloader landmark
/obj/effect/shuttle_landmark/shuttle_initializer/spboat
	name = "West Shuttlepad"
	base_area = /area/moonbase/surface
	base_turf = /turf/simulated/floor/reinforced/airless
	landmark_tag = "west_shuttlepad"
	docking_controller = "sp_west_landing"
	shuttle_type = /datum/shuttle/autodock/overmap/spboat

// The shuttle's 'shuttle' computer
/obj/machinery/computer/shuttle_control/explore/spboat
	name = "Moonstuff control console"
	shuttle_tag = "Moonstuff"
	req_one_access = list(access_pilot)

/datum/shuttle/autodock/overmap/spboat
	name = "Moonstuff"
	current_location = "west_shuttlepad"
	docking_controller_tag = "spboat_docker"
	shuttle_area = list(/area/shuttle/spboat/fore,/area/shuttle/spboat/aft)
	fuel_consumption = 1
	defer_initialisation = TRUE
	map_specific = "Sirius Point"

/area/shuttle/spboat/fore
	icon = 'icons/turf/areas_vr.dmi'
	icon_state = "yelwhitri"
	name = "Moonstuff Cockpit"
	requires_power = 1

/area/shuttle/spboat/aft
	icon = 'icons/turf/areas_vr.dmi'
	icon_state = "yelwhitri"
	name = "Moonstuff Crew Compartment"
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
/*/obj/effect/shuttle_landmark/premade/sd/deck1/portairlock
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
	landmark_tag = "sd-3-120-78"*/

/obj/item/weapon/paper/dockingcodes/sp
	name = "Sirius Point Docking Codes"
	codes_from_z = Z_LEVEL_MOONBASE_HIGH

/////FOR CENTCOMM (at least)/////
/obj/effect/overmap/visitable/sector/virgo3b
	name = "Virgo 3B"
	desc = "Full of phoron, and home to the NSB Adephagia."
	scanner_desc = @{"[i]Registration[/i]: NSB Adephagia
[i]Class[/i]: Installation
[i]Transponder[/i]: Transmitting (CIV), NanoTrasen IFF
[b]Notice[/b]: NanoTrasen Base, authorized personnel only"}
	known = TRUE
	in_space = TRUE

	icon = 'icons/obj/overmap_vr.dmi'
	icon_state = "virgo3b"

	skybox_icon = 'icons/skybox/virgo3b.dmi'
	skybox_icon_state = "small"
	skybox_pixel_x = 0
	skybox_pixel_y = 0

	initial_generic_waypoints = list("sr-c","sr-n","sr-s")
	initial_restricted_waypoints = list("Central Command Shuttlepad" = list("cc_shuttlepad"))

	//extra_z_levels = list(Z_LEVEL_SPACE_ROCKS)

/*/////SD Starts at V3b to pick up crew refuel and repair (And to make sure it doesn't spawn on hazards)
/obj/effect/overmap/visitable/sector/virgo3b/Initialize()
	. = ..()
	for(var/obj/effect/overmap/visitable/ship/stellar_delight/sd in world)
		sd.forceMove(loc, SOUTH)
		return*/


///obj/effect/overmap/visitable/sector/virgo3b/get_space_zlevels()
//	return list(Z_LEVEL_SPACE_ROCKS)
