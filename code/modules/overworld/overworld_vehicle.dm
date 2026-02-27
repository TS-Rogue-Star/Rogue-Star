//RS FILE

#define OWV_WALK	1
#define OWV_DRIVE	2
#define OWV_SPACE	3

/obj/overworld_vehicle
	name = "vehicle"
	desc = "I'm not driving I'm travelling!"
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "pip"
	appearance_flags = TILE_BOUND|PIXEL_SCALE|KEEP_TOGETHER
	animate_movement = 0
	glide_size = 0

	var/idle_state = "pip"
	var/move_state = "pip_m"
	var/speed = 1							//We're basing our movement around 1 pixel!
	var/mob/living/driver					//The mob who's input we care about.
	var/list/passengers = list()			//All the player mobs we care about
	var/list/mounts = list()				//All the mobs and vehicles that might be affecting our ability to get around
	var/list/cargo = list()					//All the cargo that we decided to bring
	var/list/turfpos = list(0,0)

	var/last_input							//The time of the last accepted input
	var/input_cooldown = 0.25 SECONDS		//How often we think about inputs we recieve
	var/list/input_momentum = list(0,0)		//What direction vector we will next process

	var/list/momentum = list(0,0)			//What direction vector are we currently moving in

	var/ground_accelleration = 1			//How many pixels per input we accellerate on the ground
	var/max_ground_momentum = 1				//How many pixels per process we are allowed to move on the ground
	var/water_accelleration = 0.1			//How many pixels per input we accellerate in the water
	var/max_water_momentum = 0.5			//How many pixels per process we are allowed to move in the water
	var/air_accelleration = 0				//How many pixels per input we accellerate in the air
	var/max_air_momentum = 5				//How many pixels per process we are allowed to move in the air
	var/space_accelleration = 0				//How many pixels per input we accellerate in space
	var/max_space_momentum = 10				//How many pixels per process we are allowed to move in space

	var/movement_mode = OWV_WALK			//Our current movement mode, determines how our inputs are interpretted and how our momentum is processed

/obj/overworld_vehicle/Initialize(mapload)
	. = ..()

/obj/overworld_vehicle/update_icon()
	. = ..()
	if(!isstopped())
		var/heading = get_heading_degrees(momentum)
		dir = angle2dir(round(heading, 45))
		icon_state = move_state
	else
		icon_state = idle_state

/obj/overworld_vehicle/process()
	switch(movement_mode)
		if(OWV_WALK)
			process_walk()
		if(OWV_DRIVE)
			process_drive()
		if(OWV_SPACE)
			process_space()

	if(isstopped())
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

	if(movement_mode == OWV_WALK)
		process_walk()
	else if(isstopped())
		START_PROCESSING(SSprocessing, src)
		process()

/obj/overworld_vehicle/proc/get_slowdown()
	var/turf/T = get_turf(src)

	return T.movement_cost

/obj/overworld_vehicle/proc/process_walk()
	if(noinput())
		return

	var/momentum_add = ground_accelleration
	var/friction = TRUE

	if(isoverworld(loc))
		var/turf/unsimulated/map/T = loc
		friction = T.friction
		if(T.movement_cost)
			momentum_add *=	T.movement_cost

	if(friction)
		momentum[1] = 0
		momentum[2] = 0

	if(input_momentum[1])
		momentum[1] = clamp(momentum[1] + (input_momentum[1] * momentum_add) ,-max_ground_momentum,max_ground_momentum)
	if(input_momentum[2])
		momentum[2] = clamp(momentum[2] + (input_momentum[2] * momentum_add) ,-max_ground_momentum,max_ground_momentum)

	momentum_check(max_ground_momentum)
	actually_move()


/obj/overworld_vehicle/proc/actually_move(var/animate_movement = TRUE)

	input_momentum[1] = 0
	input_momentum[2] = 0

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
			if(animate_movement)
				momentum[1] = 0

		if(locdata[2])
			final_y = newy
		else
			new_pos_y = pixel_y
			if(animate_movement)
				momentum[2] = 0

		if(final_x != x || final_y != y)
			var/turf/final_turf = locate(final_x,final_y,z)
			pixel_x += (final_turf.x - x) * -32
			pixel_y += (final_turf.y - y) * -32
			match_client_pix()
			forceMove(final_turf,NONE,0)


	turfpos[1] = new_pos_x
	turfpos[2] = new_pos_y
	update_icon()

	if(isoverworld(loc))
		var/turf/unsimulated/map/consider = loc
		if(!consider.friction)
			movement_mode = OWV_SPACE
			START_PROCESSING(SSprocessing, src)

	if(animate_movement)
		animate_move(new_pos_x,new_pos_y)













/obj/overworld_vehicle/proc/process_drive()

	if(momentum[1] == 0 && momentum[2] == 0 & input_momentum[1] == 0 && input_momentum[2] == 0)
		return

	var/momentum_add = ground_accelleration
	var/friction = 0.1

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

	actually_move()









/obj/overworld_vehicle/proc/process_space()
	if(isstopped())
		to_world("Stopped")
		if(space_accelleration <= 0)
			to_world("No accelleration")
			input_momentum[1] = 0
			input_momentum[2] = 0
			return
		if(noinput())
			to_world("No input")
			return

	if(space_accelleration > 0)
		var/momentum_add = space_accelleration

		if(isoverworld(loc))
			var/turf/unsimulated/map/T = loc
			if(T.movement_cost)
				momentum_add *=	T.movement_cost

		if(input_momentum[1])
			momentum[1] = clamp(momentum[1] + (input_momentum[1] * momentum_add) ,-max_space_momentum,max_space_momentum)
		if(input_momentum[2])
			momentum[2] = clamp(momentum[2] + (input_momentum[2] * momentum_add) ,-max_space_momentum,max_space_momentum)

	momentum_check(max_space_momentum)
	actually_move()















/obj/overworld_vehicle/proc/animate_move(var/pixx,var/pixy)
	var/anim_time = 1 SECOND
	if(movement_mode == OWV_WALK)
		anim_time = 0.25 SECONDS

	animate(src, pixel_x = pixx, pixel_y = pixy, time = anim_time, flags = ANIMATION_END_NOW)
	for(var/mob/living/passenger in passengers)
		if(passenger.client)
			animate(passenger.client, pixel_x = pixx, pixel_y = pixy, time = anim_time, flags = ANIMATION_END_NOW)

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

/obj/overworld_vehicle/proc/noinput()
	if(input_momentum[1] == 0 && input_momentum[2] == 0)
		return TRUE
	return FALSE

/obj/overworld_vehicle/proc/isstopped()
	if(momentum[1] == 0 && momentum[2] == 0)
		return TRUE
	return FALSE

/obj/overworld_vehicle/proc/momentum_check(var/ourlimit)
	var/xmo = abs(momentum[1])
	var/ymo = abs(momentum[2])

	if(xmo < 0.001)
		momentum[1] = 0
	if(ymo < 0.001)
		momentum[2] = 0

	var/total_mo = xmo + ymo

	if(total_mo <= ourlimit)
		return

	var/ratio = ourlimit / total_mo

	momentum[1] *= ratio
	momentum[2] *= ratio

/obj/overworld_vehicle/proc/process_drive_move()


/turf/unsimulated/map
	var/friction = 0

/proc/get_heading_degrees(var/list/heading)
	if(heading)
		return (ATAN2(heading[2], heading[1]) + 360) % 360










































#undef OWV_WALK
#undef OWV_DRIVE
#undef OWV_SPACE
