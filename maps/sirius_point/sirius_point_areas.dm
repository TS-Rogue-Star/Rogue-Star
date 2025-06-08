/area/siriuspoint
	name = "Sirius Point"
	icon = 'icons/turf/areas_vr.dmi'
	icon_state = "blublatri"
	requires_power = TRUE
	dynamic_lighting = TRUE

/area/maintenance/siriuspoint
	name = "Maintenance"
	icon = 'icons/turf/areas_vr.dmi'
	icon_state = "purblasqu"
	flags = RAD_SHIELDED
	ambience = AMBIENCE_MAINTENANCE

/area/asteroid/siriuspoint
	ambience = AMBIENCE_SPACE

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
