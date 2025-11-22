//RS FILE

/proc/get_random_unobserved_station_turf()
	if(!islist(using_map.expected_station_connected))
		return 1	//Return something other than a turf or null to indicate that we can't effectively do our search.
	if(!using_map.expected_station_connected.len)
		return 1
	var/which_z = pick(using_map.expected_station_connected)
	var/turf/T = locate(rand(1, world.maxx), rand(1,world.maxy), which_z)
	if(!T)
		return FALSE
	var/area/A = T.loc
	if(A.flags & BLUE_SHIELDED)
		return FALSE
	if(isspace(T) || isopenspace(T))
		return FALSE
	if(T.check_density())
		return FALSE
	for(var/mob/living/L in view(8,T))
		if(isliving(L))
			return FALSE

	return T

/datum/controller/subsystem/events/proc/add_seasonal_events()

/////MUNDANE/////
	var/datum/event_container/mundane_container = event_containers[EVENT_LEVEL_MUNDANE]
	switch(world_time_season)
		if("spring")
//			mundane_container.available_events += new /datum/event_meta(EVENT_LEVEL_MUNDANE, "EXAMPLE EVENT", /datum/event/EXAMPLE, 10, is_one_shot = TRUE)

		if("summer")
			mundane_container.available_events += new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Ant Spawn", /datum/event/mobspawner/ant_anarchy, 10, is_one_shot = TRUE)

		if("autumn")
			mundane_container.available_events += new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Turkey Spawn", /datum/event/mobspawner/turkey_anarchy, 10, is_one_shot = TRUE)

		if("winter")
			mundane_container.available_events += new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Elf Spawn", /datum/event/mobspawner/elfish_whimsy, 10, is_one_shot = TRUE)
			mundane_container.available_events += new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Deer Spawn", /datum/event/mobspawner/deer_anarchy, 10, is_one_shot = TRUE)

/////MODERATE/////
	var/datum/event_container/moderate_container = event_containers[EVENT_LEVEL_MODERATE]
	switch(world_time_season)
		if("spring")
//			moderate_container.available_events += new /datum/event_meta(EVENT_LEVEL_MODERATE, "EXAMPLE EVENT", /datum/event/EXAMPLE, 5, is_one_shot = TRUE)

		if("summer")
			moderate_container.available_events += new /datum/event_meta(EVENT_LEVEL_MODERATE, "Ant Spawn", /datum/event/mobspawner/ant_anarchy/moderate, 5, is_one_shot = TRUE)

		if("autumn")
			moderate_container.available_events += new /datum/event_meta(EVENT_LEVEL_MODERATE, "Turkey Spawn", /datum/event/mobspawner/turkey_anarchy/moderate, 5, is_one_shot = TRUE)

		if("winter")
			moderate_container.available_events += new /datum/event_meta(EVENT_LEVEL_MODERATE, "Elf Spawn", /datum/event/mobspawner/elfish_whimsy/moderate, 5, is_one_shot = TRUE)
			moderate_container.available_events += new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Deer Spawn", /datum/event/mobspawner/deer_anarchy/moderate, 5, is_one_shot = TRUE)

/////MAJOR/////
	var/datum/event_container/major_container = event_containers[EVENT_LEVEL_MAJOR]
	switch(world_time_season)
		if("spring")
//			major_container.available_events += new /datum/event_meta(EVENT_LEVEL_MAJOR, "EXAMPLE EVENT", /datum/event/EXAMPLE, 1, is_one_shot = TRUE)

		if("summer")
			major_container.available_events += new /datum/event_meta(EVENT_LEVEL_MAJOR, "Ant Spawn", /datum/event/mobspawner/ant_anarchy/major, 1, is_one_shot = TRUE)

		if("autumn")
			major_container.available_events += new /datum/event_meta(EVENT_LEVEL_MAJOR, "Turkey Spawn", /datum/event/mobspawner/turkey_anarchy/major, 1, is_one_shot = TRUE)

		if("winter")
			major_container.available_events += new /datum/event_meta(EVENT_LEVEL_MAJOR, "Elf Spawn", /datum/event/mobspawner/elfish_whimsy/major, 1, is_one_shot = TRUE)
			major_container.available_events += new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Deer Spawn", /datum/event/mobspawner/deer_anarchy/major, 1, is_one_shot = TRUE)

/datum/event/mobspawner
	startWhen = 1
	endWhen = 30
	var/spawn_quantity = 1
	var/list/spawnlist = list(/mob/living/simple_mob/elf = 100)

/datum/event/mobspawner/start()

	var/turf/spawnspot = null
	var/loop = TRUE
	while(loop)
		var/potential = get_random_unobserved_station_turf()
		if(potential)
			loop = FALSE
		if(isturf(potential))
			spawnspot = potential

	if(!spawnspot)
		kill()
		return FALSE

	var/howmany = rand(1,spawn_quantity)
	log_debug("EVENT spawning mobs at [spawnspot.loc] - [spawnspot.x],[spawnspot.y],[spawnspot.z]")
	while(howmany > 0)
		howmany --
		var/spawnable = pickweight(spawnlist)
		if(!spawnable)
			howmany = 0
			return
		log_debug("EVENT spawning [spawnable]")
		do_spawning(spawnable,spawnspot)

/datum/event/mobspawner/proc/do_spawning(what,where)
	new what(get_turf(where))

//ELFS
/datum/event/mobspawner/elfish_whimsy
	spawn_quantity = 1
	spawnlist = list(/mob/living/simple_mob/elf = 100)

/datum/event/mobspawner/elfish_whimsy/moderate
	spawn_quantity = 5

/datum/event/mobspawner/elfish_whimsy/major
	spawn_quantity = 20

/datum/event/mobspawner/turkey_anarchy
	spawn_quantity = 1
	spawnlist = list(/mob/living/simple_mob/vore/turkeygirl = 100)

/datum/event/mobspawner/turkey_anarchy/moderate
	spawn_quantity = 5

/datum/event/mobspawner/turkey_anarchy/major
	spawn_quantity = 20

/datum/event/mobspawner/deer_anarchy
	spawn_quantity = 1
	spawnlist = list(/mob/living/simple_mob/vore/deer = 100,/mob/living/simple_mob/vore/deer/hat = 25,/mob/living/simple_mob/vore/deer/nose = 1)

/datum/event/mobspawner/deer_anarchy/moderate
	spawn_quantity = 5

/datum/event/mobspawner/deer_anarchy/major
	spawn_quantity = 20

/datum/event/mobspawner/ant_anarchy
	spawn_quantity = 1
	spawnlist = list(/mob/living/simple_mob/vore/ant = 100)
	var/unified_color

/datum/event/mobspawner/ant_anarchy/start()
	unified_color = random_color()
	. = ..()

/datum/event/mobspawner/ant_anarchy/moderate
	spawn_quantity = 5

/datum/event/mobspawner/ant_anarchy/major
	spawn_quantity = 20

/datum/event/mobspawner/ant_anarchy/do_spawning(what,where)
	new what(get_turf(where),unified_color)
