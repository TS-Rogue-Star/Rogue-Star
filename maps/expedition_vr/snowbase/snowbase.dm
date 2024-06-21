////////////////////////////////////////////////////////////////////////////////////////////////////
//overmap node
/obj/effect/overmap/visitable/sector/centaur944november
	name = "944 November"
	desc = "Home to ice, snow, and more ice."
	scanner_desc = @{"[i]Stellar Body[/i]: 944 November
[i]Class[/i]: Centaur
[i]Habitability[/i]: Low (Low Temperature)
[b]Notice[/b]: Arctic survival gear is recommended. Contact traffic control for weather advisories."}
	icon_state = "frozen"
	in_space = 0
	initial_generic_waypoints = list("snowpad_e", "snowpad_w")
	extra_z_levels = list(Z_LEVEL_BEACH_CAVE)
	known = TRUE

////////////////////////////////////////////////////////////////////////////////////////////////////
//areas
/area/tether_away/snowbase/
	name = "Away Mission - Snowbase"
	icon_state = "away"
	lightswitch = FALSE
	ambience = list('sound/music/main.ogg', 'sound/ambience/maintenance/maintenance4.ogg', 'sound/ambience/sif/sif1.ogg', 'sound/ambience/ruins/ruins1.ogg')
	base_turf = /turf/simulated/floor/beach/sand/outdoors

/area/tether_away/snowbase/outside

	ambience = list('sound/music/main.ogg', 'sound/ambience/maintenance/maintenance4.ogg', 'sound/ambience/sif/sif1.ogg', 'sound/ambience/ruins/ruins1.ogg')
