//RS FILE
/turf/proc/reagent_interact(var/reagent_id, var/amount)
	return

/turf/simulated/floor/outdoors
	var/water = 0
	var/water_saturation = 0
	var/mushroom_capacity = 0
	var/shrooming = 0
	var/shroom_hospitality = 0

/turf/simulated/floor/outdoors/reagent_interact(reagent_id, amount)
	if(!reagent_id || !amount)
		return FALSE

	if(reagent_id == "water")
		water(amount, list(src))

/turf/simulated/floor/outdoors/wet_floor(wet_val)
	if(wet_val == 3)
		return ..()
	if(water_saturation <= 0)
		return ..()

/turf/simulated/floor/outdoors/proc/water(var/amount, var/list/sources)
	if(!amount)
		return
	if(water_saturation <= 0)
		return
	water += amount
	if(islist(sources))
		if(sources.len >= 25)
			return
	water_communism(sources)
	begin_shrooming()
	visible_message(runemessage = "[water]")

/turf/simulated/floor/outdoors/proc/water_communism(var/list/sources)
	if(water <= water_saturation * 2)
		return
	var/list/viable_neighbors = list()
	var/search = get_step(src,NORTH)
	if(assess_neighbor(search))
		viable_neighbors += search
	search = get_step(src,SOUTH)
	if(assess_neighbor(search))
		viable_neighbors += search
	search = get_step(src,EAST)
	if(assess_neighbor(search))
		viable_neighbors += search
	search = get_step(src,WEST)
	if(assess_neighbor(search))
		viable_neighbors += search
	if(!islist(sources))
		sources = list(src)
	else
		sources |= src
	for(var/thing in viable_neighbors)
		if(thing in sources)
			viable_neighbors -= thing

	if(!viable_neighbors.len)
		return
	var/total_water = water
	for(var/turf/simulated/floor/outdoors/thing in viable_neighbors)
		total_water += thing.water

	var/average_water = total_water / (viable_neighbors.len)
	if(water == average_water)
		return

	water = average_water
	for(var/turf/simulated/floor/outdoors/thing in viable_neighbors)
		if(thing in sources)
			continue
		thing.water(average_water - thing.water, sources)

/turf/simulated/floor/outdoors/proc/assess_neighbor(var/turf/simulated/floor/outdoors/neighbor)
	if(!istype(neighbor, /turf/simulated/floor/outdoors))
		return FALSE
	if(neighbor.water_saturation <= 0)
		return FALSE
	if(neighbor.water > water)
		return FALSE
	return neighbor

/turf/simulated/floor/outdoors/proc/begin_shrooming()
	if(mushroom_capacity <= 0 || shroom_hospitality <= 0)
		return
	START_PROCESSING(SSturfs, src)

/turf/simulated/floor/outdoors/process()
	if(water < 50)
		STOP_PROCESSING(SSturfs, src)
	if(contents.len >= mushroom_capacity)	//I don't really want to iterate through a potentially huge list to check for exactly how many mushrooms there are every tick, we'll just use the contents len, it will be close enough.
		return
	var/howbright = get_lumcount()
	if(howbright > 0.3)
		return
	var/grow_rate = 0.5
	if(howbright >= 0.2)
		grow_rate = 0.5
	else if(howbright >= 0.1)
		grow_rate = 1
	else if(howbright < 0.1)
		grow_rate = 2
	shrooming += grow_rate
	if(shrooming >= 50)
		shroom()

/turf/simulated/floor/outdoors/proc/shroom()
	shrooming = 0
	water -= 20
	var/obj/structure/flora/mushroom/grower/M = new(src)

	M.pixel_x = rand(-14,14)
	M.pixel_y = rand(-14,14)
	M.visible_message(span_green("\The [M] appears from \the [src]..."),runemessage = "🍄")


/turf/simulated/floor/outdoors/grass
	water_saturation = 200
	mushroom_capacity = 1
	shroom_hospitality = 0.25

/turf/simulated/floor/outdoors/dirt
	water_saturation = 200

/turf/simulated/floor/outdoors/dirt/water(amount)
	. = ..()
	if(water > 200)
		mudify()

/turf/simulated/floor/outdoors/dirt/proc/mudify()
	var/stored_water = water
	var/turf/simulated/floor/outdoors/mud/M = ChangeTurf(/turf/simulated/floor/outdoors/mud, preserve_outdoors = TRUE)
	M.water = stored_water
	M.begin_shrooming()

/turf/simulated/floor/outdoors/mud
	water = 200
	water_saturation = 200
	mushroom_capacity = 6
	shroom_hospitality = 1

/turf/simulated/floor/outdoors/mud/process()
	if(water <= 0)
		water = 0
		ChangeTurf(/turf/simulated/floor/outdoors/dirt/soft, preserve_outdoors = TRUE)
		return
	return ..()

/turf/simulated/floor/outdoors/mud/water(amount, var/communism = TRUE)
	var/oldwater = water
	. = ..()
	if(oldwater <= 50 && water > 50)
		START_PROCESSING(SSturfs, src)
		for(var/obj/structure/flora/mushroom/grower/G in contents)
			if(istype(G, /obj/structure/flora/mushroom/grower))
				if(G.grown >= 100)
					continue
				START_PROCESSING(SSobj, src)

//////🍄🍄🍄🍄🍄//////
///🍄 MUSHROOMS!!! 🍄///
//////🍄🍄🍄🍄🍄//////

/obj/structure/flora/mushroom/grower
	name = "mushroom"
	desc = "Shroomy!"
	icon = 'icons/rogue-star/mushroom.dmi'
	icon_state = "shroom-prime"
	var/shroom_state = "shroom"
	var/grown = 0
	var/stage = 1

/obj/structure/flora/mushroom/grower/Initialize()
	. = ..()
	update_icon()
	START_PROCESSING(SSobj, src)

/obj/structure/flora/mushroom/grower/process()
	var/turf/simulated/floor/outdoors/T = get_turf(src)
	if(!istype(T, /turf/simulated/floor/outdoors))
		STOP_PROCESSING(SSobj, src)
		return
	if(T.shroom_hospitality <= 0)
		STOP_PROCESSING(SSobj, src)
		return
	grow()

/obj/structure/flora/mushroom/grower/proc/grow()
	var/turf/T = get_turf(src)
	var/hospitality = 0
	if(istype(T, /turf/simulated/floor/outdoors))
		var/turf/simulated/floor/outdoors/mush_zone = T
		hospitality = mush_zone.shroom_hospitality
	var/howbright = T.get_lumcount()
	if(howbright > 0.3)
		return
	var/grow_rate = 0.5
	if(howbright >= 0.2)
		grow_rate = 0.5
	else if(howbright >= 0.1)
		grow_rate = 1
	else if(howbright < 0.1)
		grow_rate = 2
	grown += grow_rate * hospitality
	switch(grown)
		if(0 to 10)
			stage = 1
		if(11 to 25)
			stage = 2
		if(26 to 75)
			stage = 3
		if(76 to 99)
			stage = 4
		if(100 to INFINITY)
			stage = 5
			STOP_PROCESSING(SSobj, src)
	update_icon()

/obj/structure/flora/mushroom/grower/update_icon()
	. = ..()
	switch(stage)
		if(1)
			icon_state = "[shroom_state]_nub"
		if(2)
			icon_state = "[shroom_state]_stem"
		if(3)
			icon_state = "[shroom_state]_bud-[rand(1,3)]"
		if(4)
			icon_state = "[shroom_state]-[rand(1,3)]"
		if(5)
			icon_state = "[shroom_state]_prime"

/mob/living/verb/water()
	set category = "WATER"
	set name = "WATER"

	var/turf/simulated/floor/outdoors/T = get_turf(src)
	if(!istype(T, /turf/simulated/floor/outdoors))
		return

	playsound(T, 'sound/effects/sink.ogg', 75, 1)
	T.water(100)
