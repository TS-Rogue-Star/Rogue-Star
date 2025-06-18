/area/moonbase
	name = "Sirius Point"
	icon = 'icons/turf/areas_vr.dmi'
	icon_state = "blublatri"
	requires_power = TRUE
	dynamic_lighting = TRUE

/////////////////
// The Station //
/////////////////

/area/arrival/moonbase
	icon = 'icons/turf/areas_rs.dmi'
	icon_state = "floor2"
	ambience = AMBIENCE_ARRIVALS
	sound_env = LARGE_ENCLOSED
/area/arrival/moonbase/main
	name = "Arrivals Hallway"
/area/arrival/moonbase/dockingbays
	name = "Docking Bays"

/area/hallway/moonbase
	icon = 'icons/turf/areas_rs.dmi'
	icon_state = "floor1"
	ambience = AMBIENCE_GENERIC
	sound_env = LARGE_ENCLOSED
/area/hallway/moonbase/central
	name = "MedSci Wing"
/area/hallway/moonbase/northhall
	name = "Biodome & AI Wing"
/area/hallway/moonbase/southhall
	name = "Southern Corridor"
/area/hallway/moonbase/easthall
	name = "Operations Wing"
/area/hallway/moonbase/westhall
	name = "Cargo & Docking Wing"
/area/hallway/moonbase/southwesthall
	name = "Dormitory Wing"
/area/hallway/moonbase/basement
	name = "Basement Rec Area"
	icon_state = "basement"
/area/hallway/moonbase/shop
	name = "Commercial Area"
	icon_state = "basement"


/area/crew_quarters/moonbase/abandonedoffice
	name = "Disused Offices"
	icon = 'icons/turf/areas_vr.dmi'
	icon_state = "magwhisqu"
	ambience = AMBIENCE_RUINS
/area/crew_quarters/moonbase/abandonedoffice/solgov
	name = "Commonwealth Liason Office"
/area/crew_quarters/moonbase/pilotroom
	name = "Flight Lounge"
	icon = 'icons/turf/areas_vr.dmi'
	icon_state = "magwhisqu"
/area/crew_quarters/moonbase/bartender
	name = "The Backrooms"
/area/crew_quarters/moonbase/carproom
	name = "Carp Encounter Simulator"
	ambience = AMBIENCE_SPACE
/area/crew_quarters/moonbase/smallroom
	name = "Small Room"
/area/crew_quarters/moonbase/maintbar
	name = "Unused Observation Deck"
	ambience = AMBIENCE_RUINS
/area/crew_quarters/moonbase/basement/iceroom
	name = "Tundra Biosphere Simulation"
	ambience = AMBIENCE_RUINS
/area/library/moonbase/office
	name = "Librarian Office"

/area/security/moonbase
	icon_state = "brig"
/area/security/moonbase/cellone
	name = "Cell One"
/area/security/moonbase/celltwo
	name = "Cell Two"
/area/security/moonbase/legal
	name = "Legal Department"
	icon = 'icons/turf/areas_vr.dmi'
	icon_state = "redblasqu"
/area/lawoffice/moonbase/iaaone
	name = "Internal Affairs Office One"
/area/lawoffice/moonbase/iaatwo
	name = "Internal Affairs Office Two"

/area/quartermaster/moonbase/hallway
	name = "Cargo Hallway"
/area/quartermaster/moonbase/lockerrom
	name = "Cargo Locker Room"
/area/quartermaster/moonbase/trashroom
	name = "Trash Sorting"
/area/quartermaster/moonbase/mining
	name = "ISRU & Mining"
	icon = 'icons/turf/areas_vr.dmi'
	icon_state = "orawhisqu"
/area/quartermaster/moonbase/mining/lockerroom
	name = "Mining Locker Room"
/area/quartermaster/moonbase/mining/eva
	name = "Mining EVA"

/area/medical/moonbase
	icon_state = "medbay"
/area/medical/moonbase/traumaward
	name = "Emergency Trauma Center"
	icon_state = "medbay3"
/area/medical/moonbase/upperlevel
	name = "Medbay Halls"
	icon_state = "medbay2"
/area/medical/moonbase/basement
	name = "Medical Basement"
/area/medical/moonbase/accesshall
	name = "Medical Access Hall"
/area/medical/moonbase/basement
	name = "Medical Basement"
/area/medical/moonbase/resleeving
	name = "Auto-Sleeving Lab"
/area/medical/moonbase/basementresleeving
	name = "Private Auto-Sleeving Lab"

/area/engineering/moonbase
	icon_state = "engineering"
/area/engineering/moonbase/techstorage
	name = "Tech Storage"
/area/engineering/moonbase/securetechstorage
	name = "Secure Tech Storage"
/area/engineering/moonbase/eva
	name = "Engineering EVA"
/area/engineering/moonbase/powerroom
	name = "Engine Room Power Station"
/area/engineering/moonbase/oxygenproduction
	name = "Oxygen Production Lab"

/area/rnd/moonbase/rndlab
	icon = 'icons/turf/areas_vr.dmi'
	icon_state = "magwhisqu"
/area/rnd/moonbase/robotics
	name = "Robotics Lab"
	icon_state = "robotics"
/area/rnd/moonbase/robotics/mechbay
	name = "Mech Bay"
	icon_state = "mechbay"
/area/rnd/moonbase/robotics/synthetics
	name = "Synthetics Lab"
/area/rnd/moonbase/rndlab
	name = "Research and Development Lab"
/area/rnd/moonbase/serverroom
	name = "Research Server Room"

/area/bridge/moonbase/secretaryoffice
	name = "Command Secretary Offices"
/area/bridge/moonbase/waitingroom
	name = "Command Waiting Room"
/area/crew_quarters/captain/moonbase/office
	name = "Colony Director's Office"
/area/crew_quarters/captain/moonbase/bedroom
	name = "Colony Director's Bedroom"

/area/moonbase/dorms
	icon_state = "greblasqu"
	name = "Dormitory Lobby"
	sound_env = SMALL_SOFTFLOOR
	flags = RAD_SHIELDED| BLUE_SHIELDED |AREA_FLAG_IS_NOT_PERSISTENT
	soundproofed = TRUE
	limit_mob_size = FALSE
	block_suit_sensors = TRUE
	forbid_events = TRUE
	forbid_singulo = TRUE
	emotes_from_beyond = FALSE
	block_phase_shift = TRUE

/area/moonbase/dorms/dorm1
	name = "Dorm 1"
	icon_state = "dorm1"
/area/moonbase/dorms/dorm2
	name = "Dorm 2"
	icon_state = "dorm2"
/area/moonbase/dorms/dorm3
	name = "Dorm 3"
	icon_state = "dorm3"
/area/moonbase/dorms/dorm4
	name = "Dorm 4"
	icon_state = "dorm4"
/area/moonbase/dorms/dorm5
	name = "Dorm 5"
	icon_state = "dorm5"
/area/moonbase/dorms/dorm6
	name = "Dorm 6"
	icon_state = "dorm6"
/area/moonbase/dorms/dorm7
	name = "Dorm 7"
	icon_state = "dorm7"
/area/moonbase/dorms/dorm8
	name = "Dorm 8"
	icon_state = "dorm8"


/////////////////////////
// Maintenance & Caves //
/////////////////////////

/area/maintenance/moonbase
	flags = RAD_SHIELDED
	ambience = AMBIENCE_MAINTENANCE

/area/maintenance/moonbase/level1
	icon = 'icons/turf/areas_rs.dmi'
	icon_state = "floor1maint"
/area/maintenance/moonbase/level1/north
	name = "North Level 1 Maintenance"
/area/maintenance/moonbase/level1/south
	name = "South Level 1 Maintenance"
/area/maintenance/moonbase/level1/east
	name = "East Level 1 Maintenance"
/area/maintenance/moonbase/level1/west
	name = "West Level 1 Maintenance"
/area/maintenance/moonbase/level1/northwest
	name = "Northwest Level 1 Maintenance"
/area/maintenance/moonbase/level1/southwest
	name = "Southwest Level 1 Maintenance"
/area/maintenance/moonbase/level1/northeast
	name = "Northeast Level 1 Maintenance"
/area/maintenance/moonbase/level1/southeast
	name = "Southeast Level 1 Maintenance"
/area/maintenance/moonbase/level1/solars
	name = "Northern Solar Farm"
/area/maintenance/moonbase/level1/workshop
	name = "Unused Workshop"
/area/maintenance/moonbase/level1/powerstorage
	name = "Engineering Power Storage"

/area/maintenance/moonbase/level2
	icon = 'icons/turf/areas_rs.dmi'
	icon_state = "floor2maint"
/area/maintenance/moonbase/level2/north
	name = "North Level 2 Maintenance"
/area/maintenance/moonbase/level2/south
	name = "South Level 2 Maintenance"
/area/maintenance/moonbase/level2/east
	name = "East Level 2 Maintenance"
/area/maintenance/moonbase/level2/west
	name = "West Level 2 Maintenance"
/area/maintenance/moonbase/level2/center
	name = "Central Level 2 Maintenance"
/area/maintenance/moonbase/level2/bar
	name = "Abandoned Observation Deck"

/area/maintenance/moonbase/basement
	name = "Basement Maintenance"
	icon = 'icons/turf/areas_rs.dmi'
	icon_state = "basementmaint"
/area/maintenance/moonbase/basement/north
	name = "North Basement Maintenance"
/area/maintenance/moonbase/basement/south
	name = "South Basement Maintenance"
/area/maintenance/moonbase/basement/east
	name = "East Basement Maintenance"
/area/maintenance/moonbase/basement/west
	name = "West Basement Maintenance"

/area/maintenance/moonbase/basement/annex
	name = "Maintenance Annex"
/area/maintenance/moonbase/basement/dorms
	name = "Dorms Maintenance"
/area/maintenance/moonbase/basement/engibreakroom
	name = "Atmospherics Break Room"
/area/maintenance/moonbase/basement/techmonitoring
	name = "Technical Monitoring"
/area/maintenance/moonbase/basement/dorms
	name = "Dorms Maintenance"
/area/maintenance/moonbase/basement/toystore
	name = "Toys R U"
/area/maintenance/moonbase/basement/emstorage
	name = "Emergency Storage"
/area/maintenance/moonbase/basement/olddorms
	name = "Unused Barracks"
/area/maintenance/moonbase/basement/borgroom
	name = "Cyborg Mental Health"
/area/maintenance/moonbase/basement/whalers
	name = "Whaling Department"
/area/maintenance/moonbase/basement/northair
	name = "North Emergency Atmospherics"
/area/maintenance/moonbase/basement/southair
	name = "South Emergency Atmospherics"
/area/maintenance/moonbase/basement/archive
	name = "Archives"
/area/maintenance/moonbase/basement/motel
	name = "Unused Dorms"
/area/maintenance/moonbase/basement/poolmaint
	name = "Water Systems Maintenance"
/area/maintenance/moonbase/basement/iceroomcontrol
	name = "Tundra Biosphere Control"
/area/maintenance/moonbase/basement/boxingring
	name = "Unused Storage"
/area/maintenance/moonbase/basement/boxingring
	name = "Unused Storage"

/area/moonbase/basement/caves
	ambience = AMBIENCE_RUINS
	flags = AREA_FLAG_IS_NOT_PERSISTENT
	icon = 'icons/turf/areas_vr.dmi'
	icon_state = "orablasqu"
/area/moonbase/basement/caves/northeast
	name = "Northeast Tunnels"
/area/moonbase/basement/caves/northwest
	name = "Northwest Tunnels"
/area/moonbase/basement/caves/southwest
	name = "Southwest Tunnels"
/area/moonbase/basement/caves/southwest
	name = "Southwest Tunnels"
/area/moonbase/basement/caves/east
	name = "East Tunnels"
/area/moonbase/basement/caves/flooded
	name = "Flooded Tunnels"
/area/moonbase/basement/caves/level2
	name = "Level One Tunnels"

/////////////////
// The Surface //
/////////////////

/area/moonbase/surface
	name = "Sirius Point Exterior"
	ambience = list('sound/ambience/ambimine.ogg', 'sound/goonstation/spooky/Somewhere_Tone.ogg', 'sound/goonstation/spooky/Void_Song.ogg', 'sound/music/main.ogg', 'sound/music/space.ogg')
	base_turf = /turf/simulated/open/vacuum/outdoors
	icon = 'icons/turf/areas_vr.dmi'
	icon_state = "blublacir"
	flags = AREA_FLAG_IS_NOT_PERSISTENT
	sound_env = SOUND_ENVIRONMENT_MOUNTAINS

/area/moonbase/surface/underground
	name = "Sirius Point Underground"
	base_turf = /turf/simulated/mineral/floor/vacuum/moonbase/outdoors
//level one is Z-level 2
/area/moonbase/surface/levelone/north
	name = "Northern Sirius Point Level One"
/area/moonbase/surface/levelone/south
	name = "Southern Sirius Point Level One"
/area/moonbase/surface/levelone/east
	name = "Eastern Sirius Point Level One"
/area/moonbase/surface/levelone/west
	name = "Western Sirius Point Level One"
/area/moonbase/surface/leveltwo/north
	name = "Northern Sirius Point Level Two"
/area/moonbase/surface/leveltwo/south
	name = "Southern Sirius Point Level Two"
/area/moonbase/surface/leveltwo/east
	name = "Eastern Sirius Point Level Two"
/area/moonbase/surface/leveltwo/west
	name = "Western Sirius Point Level Two"


//////////////
// The Mine //
//////////////

/area/moonbasemine
	ambience = list('sound/ambience/ambimine.ogg', 'sound/goonstation/spooky/Somewhere_Tone.ogg', 'sound/goonstation/spooky/Void_Song.ogg', 'sound/music/main.ogg', 'sound/music/space.ogg')
	base_turf = /turf/simulated/mineral/floor/vacuum/moonbase
/area/moonbasemine/unexplored
	name = "mining caves"
	icon_state = "unexplored"
/area/moonbasemine/explored
	name = "mining caves"
	icon_state = "explored"

////////////////
// Substations//
////////////////

/area/maintenance/moonbase/substation/atmospherics
	name = "Atmospherics Substation"
/area/maintenance/moonbase/substation/cargo
	name = "Cargo Substation"
/area/maintenance/moonbase/substation/civilian
	name = "Civilian Substation"
/area/maintenance/moonbase/substation/command
	name = "Command Substation"
/area/maintenance/moonbase/substation/engineering
	name = "Engineering Substation"
/area/maintenance/moonbase/substation/exploration
	name = "Exploration Substation"
/area/maintenance/moonbase/substation/medical
	name = "Medical Substation"
/area/maintenance/moonbase/substation/research
	name = "Research Substation"
/area/maintenance/moonbase/substation/security
	name = "Security Substation"

//////////////
// Shuttles //
//////////////

/area/shuttle/excursion
	requires_power = 1
	icon_state = "shuttle2"
	base_turf = /turf/simulated/floor/reinforced

/area/shuttle/excursion/general
	name = "\improper Excursion Shuttle"

/area/shuttle/excursion/cockpit
	name = "\improper Excursion Shuttle Cockpit"

/area/shuttle/excursion/cargo
	name = "\improper Excursion Shuttle Cargo"

/area/shuttle/excursion/power
	name = "\improper Excursion Shuttle Power"
