/*//Normal map defs
#define Z_LEVEL_MOONBASE_LOW				1
#define Z_LEVEL_MOONBASE_MID				2
#define Z_LEVEL_MOONBASE_HIGH				3
#define Z_LEVEL_MOONBASE_EAST				4
#define Z_LEVEL_MOONBASE_WEST				5
#define Z_LEVEL_MOONBASE_MINING				6
#define Z_LEVEL_CENTCOM						7
#define Z_LEVEL_MISC						8
#define Z_LEVEL_BEACH						9
#define Z_LEVEL_BEACH_CAVE					10
#define Z_LEVEL_AEROSTAT					11
#define Z_LEVEL_AEROSTAT_SURFACE			12
#define Z_LEVEL_DEBRISFIELD					13
#define Z_LEVEL_FUELDEPOT					14
#define Z_LEVEL_OVERMAP						15
#define Z_LEVEL_OFFMAP1						16
#define Z_LEVEL_SNOWBASE					17
#define Z_LEVEL_GLACIER						18
#define Z_LEVEL_GATEWAY						19
#define Z_LEVEL_OM_ADVENTURE				20
#define Z_LEVEL_REDGATE						21*/

/datum/map/sirius_point/New()
	if(global.using_map != src)	//Map swap related
		return ..()
	ai_shell_allowed_levels += list(z_list["z_misc"])
	ai_shell_allowed_levels += list(z_list["z_beach"])
	ai_shell_allowed_levels += list(z_list["z_aerostat"])
	..()
	var/choice = pickweight(list(
		"rs_lobby" = 50,
		"rs_lobby2" = 50
	))
	if(choice)
		lobby_screens = list(choice)

/datum/map/sirius_point
	name = "Sirius Point"
	full_name = "NSB Sirius Point"
	path = "sirius_point"

	use_overmap = TRUE
	overmap_size = 62
	overmap_event_areas = 100

	usable_email_tlds = list("virgo.nt")

	zlevel_datum_type = /datum/map_z_level/sirius_point

	lobby_icon = 'icons/misc/title_rs.dmi'
	lobby_screens = list("rs_lobby")
	id_hud_icons = 'icons/mob/hud_jobs_vr.dmi'


	holomap_smoosh = list(list(
		Z_LEVEL_MOONBASE_LOW,
		Z_LEVEL_MOONBASE_MID,
		Z_LEVEL_MOONBASE_HIGH))

	station_name  = "NSB Sirius Point"
	station_short = "Sirus Point"
	facility_type = "base"
	dock_name     = "Virgo-3B Colony"
	dock_type     = "surface"
	boss_name     = "Central Command"
	boss_short    = "CentCom"
	company_name  = "NanoTrasen"
	company_short = "NT"
	starsys_name  = "Virgo-Erigone"

	shuttle_docked_message = "The scheduled shuttle to the %dock_name% has arrived. It will depart in approximately %ETD%."
	shuttle_leaving_dock = "The shuttle has departed. Estimate %ETA% until arrival at %dock_name%."
	shuttle_called_message = "A scheduled crew transfer to the %dock_name% is occuring. The shuttle will arrive shortly. Those departing should proceed to deck three, west within %ETA%."
	shuttle_recall_message = "The scheduled crew transfer has been cancelled."
	shuttle_name = "Crew Transport"
	emergency_shuttle_docked_message = "The evacuation shuttle has arrived. You have approximately %ETD% to board the shuttle."
	emergency_shuttle_leaving_dock = "The emergency shuttle has departed. Estimate %ETA% until arrival at %dock_name%."
	emergency_shuttle_called_message = "An emergency evacuation has begun, and an off-schedule shuttle has been called. It will arrive at deck two, southeast in approximately %ETA%."
	emergency_shuttle_recall_message = "The evacuation shuttle has been recalled."

	station_networks = list(
							NETWORK_CARGO,
							NETWORK_CIRCUITS,
							NETWORK_CIVILIAN,
							NETWORK_COMMAND,
							NETWORK_ENGINE,
							NETWORK_ENGINEERING,
							NETWORK_EXPLORATION,
							NETWORK_MEDICAL,
							NETWORK_MINE,
							NETWORK_RESEARCH,
							NETWORK_RESEARCH_OUTPOST,
							NETWORK_ROBOTS,
							NETWORK_SECURITY,
							NETWORK_TELECOM,
							NETWORK_HALLS
							)
	secondary_networks = list(
							NETWORK_ERT,
							NETWORK_MERCENARY,
							NETWORK_THUNDER,
							NETWORK_COMMUNICATORS,
							NETWORK_ALARM_ATMOS,
							NETWORK_ALARM_POWER,
							NETWORK_ALARM_FIRE,
							NETWORK_TALON_HELMETS,
							NETWORK_TALON_SHIP
							)

	bot_patrolling = FALSE

	allowed_spawns = list("Gateway","Cryogenic Storage","Cyborg Storage","ITV Talon Cryo", "Redgate")
	spawnpoint_died = /datum/spawnpoint/cryo
	spawnpoint_left = /datum/spawnpoint/gateway
	spawnpoint_stayed = /datum/spawnpoint/cryo

	/*
	meteor_strike_areas = list(/area/tether/surfacebase/outside/outside3)
	*/

	default_skybox = /datum/skybox_settings/sirius_point

//unit tests are yet to be implemented
	unit_test_exempt_areas = list(
		/area/moonbasemine,
		/area/moonbasemine/unexplored,
		/area/moonbasemine/explored,
		/area/maintenance/moonbase,
		/area/moonbase/surface/east_crater,
		/area/moonbase/surface/east_crater/unexplored,
		/area/moonbase/surface/west_crater,
		/area/moonbase/surface/west_crater/unexplored,
		/area/moonbase/surface/underground,
		/area/moonbase/surface/levelone/north,
		/area/moonbase/surface/levelone/south,
		/area/moonbase/surface/levelone/east,
		/area/moonbase/surface/levelone/west,
		/area/moonbase/surface/leveltwo/north,
		/area/moonbase/surface/leveltwo/south,
		/area/moonbase/surface/leveltwo/east,
		/area/moonbase/surface/leveltwo/west
		)

	unit_test_exempt_from_atmos = list(
		/area/moonbasemine,
		/area/moonbasemine/unexplored,
		/area/moonbasemine/explored,
		/area/maintenance/moonbase,
		/area/moonbase/surface/east_crater,
		/area/moonbase/surface/east_crater/unexplored,
		/area/moonbase/surface/west_crater,
		/area/moonbase/surface/west_crater/unexplored,
		/area/moonbase/surface/underground,
		/area/moonbase/surface/levelone/north,
		/area/moonbase/surface/levelone/south,
		/area/moonbase/surface/levelone/east,
		/area/moonbase/surface/levelone/west,
		/area/moonbase/surface/leveltwo/north,
		/area/moonbase/surface/leveltwo/south,
		/area/moonbase/surface/leveltwo/east,
		/area/moonbase/surface/leveltwo/west
	)

	unit_test_z_levels = list(
		Z_LEVEL_MOONBASE_LOW,
		Z_LEVEL_MOONBASE_MID,
		Z_LEVEL_MOONBASE_HIGH
	)

//RS ADD START - Map swap related
	z_list = list(
	"z_centcom" = 7,
	"z_misc" = 8,
	"z_beach" = 9,
	"z_beach_cave" = 10,
	"z_aerostat" = 11,
	"z_aerostat_surface" = 12,
	"z_debrisfield" = 13,
	"z_fueldepot" = 14,
	"z_offmap1" = 15,
	"z_snowbase" = 16,
	"z_glacier" = 17,
	"z_gateway" = 18,
	"z_om_adventure" = 19,
	"z_redgate" = 20,
	"overmap_z" = 8
	)

	station_z_levels = list("SP0","SP1","SP2","SPE","SPW","SPM")	//RS ADD END
	lateload_z_levels = list(
		list("Moonbase - Central Command"),
		list("Moonbase - Misc"), //Shuttle transit zones, holodeck templates, etc
		list("Desert Planet - Z1 Beach","Desert Planet - Z2 Cave"),
		list("Remmi Aerostat - Z1 Aerostat","Remmi Aerostat - Z2 Surface"),
		list("Debris Field - Z1 Space"),
		list("Fuel Depot - Z1 Space"),
		list("Offmap Ship - Talon V2"),
		list("Virgo 5","Virgo 5 Glacier")
		)
	//List associations used in admin load selection feature
	lateload_gateway = list(
		"Carp Farm" = list("Gateway - Carp Farm"),
		"Snow Field" = list("Gateway - Snow Field"),
		"Listening Post" = list("Gateway - Listening Post"),
		"Honleth Highlands" = list(list("Gateway - Honleth Highlands A", "Gateway - Honleth Highlands B")),
		"Arynthi Lake A" = list("Gateway - Arynthi Lake Underground A","Gateway - Arynthi Lake A"),
		"Arynthi Lake B" = list("Gateway - Arynthi Lake Underground B","Gateway - Arynthi Lake B"),
		"Wild West" = list("Gateway - Wild West")
		)

	lateload_overmap = list(
		list("Grass Cave")
		)
	//List associations used in admin load selection feature
	lateload_redgate = list(
		"Teppi Ranch" = list("Redgate - Teppi Ranch"),
		"Innland" = list("Redgate - Innland"),
//		"Abandoned Island" = list("Redgate - Abandoned Island"),	//This will come back later
		"Dark Adventure" = list("Redgate - Dark Adventure"),
		"Eggnog Town" = list("Redgate - Eggnog Town Underground","Redgate - Eggnog Town"),
		"Star Dog" = list("Redgate - Star Dog"),
		"Hotsprings" = list("Redgate - Hotsprings"),
		"Rain City" = list("Redgate - Rain City"),
		"Islands" = list("Redgate - Islands Underwater","Redgate - Islands"),
		"Moving Train" = list("Redgate - Moving Train", "Redgate - Moving Train Upper Level"),
		"Fantasy Town" = list("Redgate - Fantasy Dungeon", "Redgate - Fantasy Town"),
		"Snowglobe" = list("Redgate - Snowglobe"),
		"Pet Island" = list("Redgate - Pet Island"),
		"Pizzaria" = list("Redgate - Pizzaria"),
		)

	ai_shell_restricted = TRUE
	ai_shell_allowed_levels = list(
		Z_LEVEL_MOONBASE_LOW,
		Z_LEVEL_MOONBASE_MID,
		Z_LEVEL_MOONBASE_HIGH,
		Z_LEVEL_MOONBASE_EAST,
		Z_LEVEL_MOONBASE_WEST,
		Z_LEVEL_MOONBASE_MINING
		)

	expected_station_connected = list(
		Z_LEVEL_MOONBASE_LOW,
		Z_LEVEL_MOONBASE_MID,
		Z_LEVEL_MOONBASE_HIGH,
		Z_LEVEL_MOONBASE_EAST,
		Z_LEVEL_MOONBASE_WEST,
		Z_LEVEL_MOONBASE_MINING
	)
/*
	belter_docked_z = 		list(Z_LEVEL_SPACE_LOW)
	belter_transit_z =	 	list(Z_LEVEL_MISC)
	belter_belt_z = 		list(Z_LEVEL_ROGUEMINE_1,
						 		 Z_LEVEL_ROGUEMINE_2)

	mining_station_z =		list(Z_LEVEL_SPACE_LOW)
	mining_outpost_z =		list(Z_LEVEL_SURFACE_MINE)
*/
	planet_datums_to_make = list(/datum/planet/virgo3b,
								/datum/planet/virgo3x,
								/datum/planet/virgo4,
								/datum/planet/snowbase)

/datum/map/sirius_point/get_map_info()
	. = list()
	. +=  "The [full_name] is a an aging but well-maintained research and ISRU facility on the surface of Virgo 3X. [station_short] was originally constructed to aid in construction of a massive colony, before complications caused the plans to be cancelled and relocated to what is now the city of Anhur on Virgo-3B.<br>"
	. +=  "Humanity has spread across the stars and has met many species on similar or even more advanced terms than them - it's a brave new world and many try to find their place in it . <br>"
	. +=  "Though Virgo-Erigone is not important for the great movers and shakers, it sees itself in the midst of the interests of a reviving alien species of the Zorren, corporate and subversive interests and other exciting dangers the Periphery has to face.<br>"
	. +=  "As an employee or contractor of NanoTrasen, operators of [station_short] and one of the galaxy's largest corporations, you're probably just here to do a job."
	return jointext(., "<br>")

/datum/skybox_settings/sirius_point
	icon_state = "space5"
	use_stars = FALSE

/datum/planet/virgo3x/New()
	expected_z_levels = list(
		Z_LEVEL_MOONBASE_LOW,
		Z_LEVEL_MOONBASE_MID,
		Z_LEVEL_MOONBASE_HIGH,
		Z_LEVEL_MOONBASE_EAST,
		Z_LEVEL_MOONBASE_WEST,
		Z_LEVEL_MOONBASE_MINING
		)
	. = ..()

/obj/effect/landmark/map_data/sirius_point
	height = 3

/obj/effect/overmap/visitable/sector/virgo3x
	name = "Virgo 3X"
	desc = "A small, barren moon."
	scanner_desc = @{"[i]Registration[/i]: NSB Sirius Point
[i]Class[/i]: Installation
[i]Transponder[/i]: Transmitting (CIV), NanoTrasen IFF
[b]Notice[/b]: NanoTrasen Base, authorized personnel only"}
	known = TRUE
	in_space = TRUE

	icon = 'icons/obj/overmap.dmi'
	icon_state = "barren"

//	skybox_icon = 'icons/skybox/skybox_rs.dmi'
//	skybox_icon_state = "3c"

	skybox_pixel_x = 0
	skybox_pixel_y = 0

	initial_generic_waypoints = list("east_shuttlepad", "west_shuttlepad","northeast_shuttlepad","sp_excursion_hangar","west_crater_pad1")
	initial_restricted_waypoints = list()
	levels_for_distress = list()


	extra_z_levels = list(
		Z_LEVEL_MOONBASE_MINING,
		Z_LEVEL_MOONBASE_EAST,
		Z_LEVEL_MOONBASE_WEST
	)

/obj/effect/overmap/visitable/sector/virgo3r/New(loc, ...)	//RS ADD START - Map swap related
	levels_for_distress += list(using_map.z_list["z_offmap1"])
	levels_for_distress += list(using_map.z_list["z_beach"])
	levels_for_distress += list(using_map.z_list["z_aerostat"])
	levels_for_distress += list(using_map.z_list["z_aerostat_surface"])
	levels_for_distress += list(using_map.z_list["z_fueldepot"])
	. = ..()	//RS ADD END


// We have a bunch of stuff common to the station z levels
/datum/map_z_level/sirius_point
	flags = MAP_LEVEL_STATION|MAP_LEVEL_CONTACT|MAP_LEVEL_PLAYER|MAP_LEVEL_CONSOLES|MAP_LEVEL_XENOARCH_EXEMPT|MAP_LEVEL_PERSIST|MAP_LEVEL_SEALED
	holomap_legend_x = 220
	holomap_legend_y = 160
	transit_chance = 0

/datum/map_z_level/sirius_point/level_zero
	z = Z_LEVEL_MOONBASE_LOW
	name = "Sirius Point Underground"
	base_turf = /turf/simulated/mineral/floor/vacuum/moonbase/outdoors
	transit_chance = 0
	holomap_offset_x = SHIP_HOLOMAP_MARGIN_X
	holomap_offset_y = SHIP_HOLOMAP_MARGIN_Y

/datum/map_z_level/sirius_point/level_one
	z = Z_LEVEL_MOONBASE_MID
	name = "Sirius Point Level One"
	base_turf = /turf/simulated/open
	transit_chance = 0
	holomap_offset_x = SHIP_HOLOMAP_MARGIN_X
	holomap_offset_y = SHIP_HOLOMAP_MARGIN_Y + SHIP_MAP_SIZE

/datum/map_z_level/sirius_point/level_two
	z = Z_LEVEL_MOONBASE_HIGH
	name = "Sirius Point Level Two"
	base_turf = /turf/simulated/open
	transit_chance = 0
	holomap_offset_x = HOLOMAP_ICON_SIZE - SHIP_HOLOMAP_MARGIN_X - SHIP_MAP_SIZE
	holomap_offset_y = SHIP_HOLOMAP_MARGIN_Y + SHIP_MAP_SIZE

/datum/map_z_level/sirius_point/east_crater
	z = Z_LEVEL_MOONBASE_EAST
	name = "Sirius Point East Crater"
	base_turf = /turf/simulated/mineral/floor/vacuum/moonbase/outdoors
	flags = MAP_LEVEL_CONTACT|MAP_LEVEL_PLAYER|MAP_LEVEL_CONSOLES|MAP_LEVEL_PERSIST|MAP_LEVEL_SEALED
	transit_chance = 0

/datum/map_z_level/sirius_point/west_crater
	z = Z_LEVEL_MOONBASE_WEST
	name = "Sirius Point West Crater"
	base_turf = /turf/simulated/mineral/floor/vacuum/moonbase/outdoors
	flags = MAP_LEVEL_CONTACT|MAP_LEVEL_PLAYER|MAP_LEVEL_CONSOLES|MAP_LEVEL_PERSIST|MAP_LEVEL_SEALED
	transit_chance = 0

/datum/map_z_level/sirius_point/mining
	z = Z_LEVEL_MOONBASE_MINING
	name = "Sirius Point Mining Depths"
	base_turf = /turf/simulated/mineral/floor/vacuum/moonbase
	flags = MAP_LEVEL_CONTACT|MAP_LEVEL_PLAYER|MAP_LEVEL_CONSOLES|MAP_LEVEL_PERSIST|MAP_LEVEL_SEALED
	transit_chance = 0

/datum/map_template/moonbase_lateload
	allow_duplicates = FALSE

/////STATIC LATELOAD/////

#include "../expedition_vr/snowbase/submaps/glacier.dm"
#include "../expedition_vr/snowbase/submaps/glacier_areas.dm"

/datum/map_template/moonbase_lateload/on_map_loaded(z)
	if(!associated_map_datum || !ispath(associated_map_datum))
		log_game("Extra z-level [src] has no associated map datum")
		return

	new associated_map_datum(using_map, z)

/datum/map_template/station_map/sp0
	name = "SP0"
	mappath = 'maps/sirius_point/sirius_point1.dmm'

	associated_map_datum = /datum/map_z_level/sirius_point/level_zero

/datum/map_template/station_map/sp1
	name = "SP1"
	mappath = 'maps/sirius_point/sirius_point2.dmm'

	associated_map_datum = /datum/map_z_level/sirius_point/level_one

/datum/map_template/station_map/sp2
	name = "SP2"
	mappath = 'maps/sirius_point/sirius_point3.dmm'

	associated_map_datum = /datum/map_z_level/sirius_point/level_two

/datum/map_template/station_map/spe
	name = "SPE"
	mappath = 'maps/sirius_point/sirius_point_east.dmm'

	associated_map_datum = /datum/map_z_level/sirius_point/east_crater

/datum/map_template/station_map/spw
	name = "SPW"
	mappath = 'maps/sirius_point/sirius_point_west.dmm'

	associated_map_datum = /datum/map_z_level/sirius_point/west_crater

/datum/map_template/station_map/spm
	name = "SPM"
	mappath = 'maps/sirius_point/sirius_point_mining.dmm'

	associated_map_datum = /datum/map_z_level/sirius_point/mining

/datum/map_template/station_map/spw/on_map_loaded(z)
	seed_submaps(list(Z_LEVEL_MOONBASE_WEST), 210, /area/moonbase/surface/west_crater/unexplored, /datum/map_template/surface/moonbase/west_crater)

/datum/map_template/station_map/spe/on_map_loaded(z)
	seed_submaps(list(Z_LEVEL_MOONBASE_EAST), 210, /area/moonbase/surface/east_crater/unexplored, /datum/map_template/surface/moonbase/east_crater)

/datum/map_template/station_map/spm/on_map_loaded(z)
	. = ..()
	new /datum/random_map/automata/cave_system/no_cracks(null, 3, 3, Z_LEVEL_MOONBASE_MINING, world.maxx - 4, world.maxy - 4)
	new /datum/random_map/noise/ore(null, 1, 1, Z_LEVEL_MOONBASE_MINING, 64, 64)

/datum/map_template/moonbase_lateload/moonbase_centcom
	name = "Moonbase - Central Command"
	desc = "Central Command lives here!"
	mappath = 'moonbase_centcom.dmm'

	associated_map_datum = /datum/map_z_level/moonbase_lateload/moonbase_centcom

/datum/map_z_level/moonbase_lateload/moonbase_centcom
	name = "Centcom"
	flags = MAP_LEVEL_ADMIN|MAP_LEVEL_SEALED|MAP_LEVEL_CONTACT|MAP_LEVEL_XENOARCH_EXEMPT
	base_turf = /turf/simulated/floor/outdoors/rocks

/area/centcom //Just to try to make sure there's not space!!!
	base_turf = /turf/simulated/floor/outdoors/rocks

/datum/map_template/moonbase_lateload/moonbase_misc
	name = "Moonbase - Misc"
	desc = "Misc areas, like some transit areas, holodecks, merc area, and the holodeck."
	mappath = 'moonbase_misc.dmm'

	associated_map_datum = /datum/map_z_level/moonbase_lateload/misc

/datum/map_z_level/moonbase_lateload/misc
	name = "Misc"
	flags = MAP_LEVEL_ADMIN|MAP_LEVEL_SEALED|MAP_LEVEL_CONTACT|MAP_LEVEL_XENOARCH_EXEMPT

/*#include "../submaps/space_rocks/space_rocks.dm"
/datum/map_template/ship_lateload/space_rocks
	name = "V3b Asteroid Field"
	desc = "Space debris is common in V3b's orbit due to the proximity of Virgo 3"
	mappath = 'maps/submaps/space_rocks/space_rocks.dmm'

	associated_map_datum = /datum/map_z_level/ship_lateload/space_rocks

/datum/map_template/ship_lateload/space_rocks/on_map_loaded(z)
	. = ..()
	seed_submaps(list(Z_LEVEL_SPACE_ROCKS), 60, /area/sdmine/unexplored, /datum/map_template/space_rocks)
	new /datum/random_map/automata/cave_system/no_cracks(null, 3, 3, Z_LEVEL_SPACE_ROCKS, world.maxx - 4, world.maxy - 4)
	new /datum/random_map/noise/ore(null, 1, 1, Z_LEVEL_SPACE_ROCKS, 64, 64)

/datum/map_z_level/ship_lateload/space_rocks
	z = Z_LEVEL_SPACE_ROCKS
	name = "V3b Asteroid Field"
	base_turf = /turf/space
	flags = MAP_LEVEL_PLAYER|MAP_LEVEL_CONTACT|MAP_LEVEL_CONSOLES

/datum/map_template/moonbase_lateload/overmap
	name = "Overmap"
	desc = "Overmap lives here :3c"
	mappath = 'overmap.dmm'

	associated_map_datum = /datum/map_z_level/moonbase_lateload/overmap

/datum/map_z_level/moonbase_lateload/overmap
	z = Z_LEVEL_OVERMAP
	name = "Overmap"
	flags = MAP_LEVEL_ADMIN|MAP_LEVEL_SEALED|MAP_LEVEL_CONTACT|MAP_LEVEL_XENOARCH_EXEMPT

#include "../expedition_vr/aerostat/_aerostat.dm"
/datum/map_template/common_lateload/away_aerostat
	name = "Remmi Aerostat - Z1 Aerostat"
	desc = "The Virgo 2 Aerostat away mission."
	mappath = 'maps/expedition_vr/aerostat/aerostat.dmm'
	associated_map_datum = /datum/map_z_level/common_lateload/away_aerostat*/
