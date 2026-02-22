//RS FILE
/obj/overworld_vehicle
	name = "vehicle"
	desc = "I'm not driving I'm travelling!"
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "pip"
	appearance_flags = TILE_BOUND|PIXEL_SCALE|KEEP_TOGETHER
	animate_movement = 0
	glide_size = 0

	var/speed = 4
	var/mob/living/driver			//The mob who's input we care about.
	var/list/passengers = list()	//All the player mobs we care about
	var/list/mounts = list()		//All the mobs and vehicles that might be affecting our ability to get around
	var/list/cargo = list()			//All the cargo that we decided to bring
	var/list/turfpos = list(0,0)
	var/last_input
	var/input_cooldown = 0.25 SECONDS
	var/list/input_momentum = list(0,0)
	var/list/momentum = list(0,0)
	var/max_ground_momentum = 1
	var/max_water_momentum = 0.5
	var/max_air_momentum = 2
	var/max_space_momentum = 3

/obj/overworld_vehicle/Initialize(mapload)
	. = ..()
/obj/overworld_vehicle/process()
	process_move()

	if(momentum[1] == 0 && momentum[2] == 0)
		STOP_PROCESSING(SSprocessing,src)
		return

/obj/overworld_vehicle/attack_hand(mob/living/user)
	user.loc = src
	passengers += user
	if(!driver)
		driver = user

/obj/overworld_vehicle/proc/manifest(var/list/our_manifest)	//We need to figure out how to get a list of things this object will care about
	if(!our_manifest)
		qdel(src)
		return

/obj/overworld_vehicle/proc/register_driver(var/mob/living/driver)
	if(!driver)
		return

/obj/overworld_vehicle/relaymove(mob/user, direction)
	if(user != driver)
		return

	if(world.time < last_input + input_cooldown)
		return
	last_input = world.time

	var/xmo = 0
	var/ymo = 0
	switch(direction)
		if(NORTH)
			ymo = 1
		if(SOUTH)
			ymo = -1
		if(EAST)
			xmo = 1
		if(WEST)
			xmo = -1
		if(NORTHEAST)
			xmo = 0.5
			ymo = 0.5
		if(NORTHWEST)
			xmo = -0.5
			ymo = 0.5
		if(SOUTHEAST)
			xmo = 0.5
			ymo = -0.5
		if(SOUTHWEST)
			xmo = -0.5
			ymo = -0.5

	input_momentum[1] = xmo
	input_momentum[2] = ymo

	if(momentum[1] == 0 && momentum[2] == 0)
		START_PROCESSING(SSprocessing, src)

/obj/overworld_vehicle/proc/get_slowdown()
	var/turf/T = get_turf(src)

	return T.movement_cost

/obj/overworld_vehicle/proc/process_move()

	var/momentum_add = speed
	var/friction = 0.5

	if(isoverworld(loc))
		var/turf/unsimulated/map/T = loc
		friction = T.friction
		if(T.movement_cost)
			momentum_add *=	T.movement_cost

	if(!input_momentum[1])
		if(friction)
			momentum[1] *= friction
			if(momentum[1] < 1)
				momentum[1] = 0
	else
		momentum[1] = clamp(momentum[1] + input_momentum[1] * momentum_add ,-max_ground_momentum,max_ground_momentum)
	if(!input_momentum[2])
		if(friction)
			momentum[2] *= friction
			if(momentum[2] < 1)
				momentum[2] = 0
	else
		momentum[2] = clamp(momentum[2] + input_momentum[2] * momentum_add ,-max_ground_momentum,max_ground_momentum)

	input_momentum[1] = 0
	input_momentum[2] = 0

	var/animate_movement = TRUE
	var/slowdown = get_slowdown()

	var/new_pos_x = turfpos[1] + momentum[1] * speed - (100 * slowdown)
	var/new_pos_y = turfpos[2] + momentum[2] * speed - (100 * slowdown)
	var/newx = x
	var/newy = y
	if(new_pos_x > 16)
		newx ++
		new_pos_x -= 32
	if(new_pos_x < -16)
		newx --
		new_pos_x += 32
	if(new_pos_y > 16)
		newy ++
		new_pos_y -= 32
	if(new_pos_y < -16)
		newy--
		new_pos_y += 32

	if(newx != x || newy != y)
		var/turf/T = locate(newx,newy,z)
		var/list/locdata = consider_location(T)
		var/final_x = x
		var/final_y = y
		animate_movement = locdata[3]

		if(locdata[1])
			final_x = newx
		else
			new_pos_x = pixel_x
			if(!animate_movement)
				momentum[x] = 0

		if(locdata[2])
			final_y = newy
		else
			new_pos_y = pixel_y
			if(!animate_movement)
				momentum[y] = 0

		if(final_x != x || final_y != y)
			var/turf/final_turf = locate(final_x,final_y,z)
			pixel_x += (final_turf.x - x) * -32
			pixel_y += (final_turf.y - y) * -32
			match_client_pix()
			forceMove(final_turf,NONE,0)


	turfpos[1] = new_pos_x
	turfpos[2] = new_pos_y

	if(animate_movement)
		animate_move(new_pos_x,new_pos_y)

/obj/overworld_vehicle/proc/animate_move(var/pixx,var/pixy)
	animate(src, pixel_x = pixx, pixel_y = pixy, time = 1 SECOND, flags = ANIMATION_END_NOW)
	for(var/mob/living/passenger in passengers)
		if(passenger.client)
			animate(passenger.client, pixel_x = pixx, pixel_y = pixy, time = 1 SECOND, flags = ANIMATION_END_NOW)

/obj/overworld_vehicle/proc/consider_location(var/turf/location)
	var/list/locdata = list(TRUE,TRUE,TRUE)	//1 = x density 2 = y density 3 = should we animate our movement
	if(!location)
		return FALSE
	if(!isturf(location))
		location = get_turf(location)
	if(location.check_density(FALSE,TRUE))
		if(location.x != x)
			locdata[1] = FALSE
		if(location.y != y)
			locdata[2] = FALSE
	if(istype(location,/turf/unsimulated/map/edge))
		location.Bumped(src)
		if(!locdata[1])
			wrap("x")
			locdata[3] = FALSE
		if(!locdata[2])
			wrap("y")
	return locdata

/obj/overworld_vehicle/proc/wrap(var/which)
	switch(which)
		if("x")
			pixel_x *= -1
		if("y")
			pixel_y *= -1

	pixel_x = CLAMP(pixel_x, -16,16)
	pixel_y = CLAMP(pixel_y, -16,16)
	match_client_pix()

/obj/overworld_vehicle/proc/match_client_pix()

	for(var/mob/living/passenger in passengers)
		if(passenger.client)
			passenger.client.pixel_x = pixel_x
			passenger.client.pixel_y = pixel_y

/turf/unsimulated/map
	var/friction = 0
