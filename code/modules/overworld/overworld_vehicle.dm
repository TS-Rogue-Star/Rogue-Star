//RS FILE
/obj/overworld_vehicle
	name = "vehicle"
	desc = "I'm not driving I'm travelling!"
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "pip"

//	pixel_y = -16

	var/speed = 1
	var/mob/living/driver			//The mob who's input we care about.
	var/list/passengers = list()	//All the player mobs we care about
	var/list/mounts = list()		//All the mobs and vehicles that might be affecting our ability to get around
	var/list/cargo = list()			//All the cargo that we decided to bring
	var/list/turfpos = list(0,0)
	var/lastmove
	var/move_cooldown = 0.25 SECONDS

/obj/overworld_vehicle/Initialize(mapload)
	. = ..()

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
			ymo = 0.5
			xmo = 0.5
		if(NORTHWEST)
			ymo = 0.5
			xmo = -0.5
		if(SOUTHEAST)
			ymo = -0.5
			xmo = 0.5
		if(SOUTHWEST)
			ymo = -0.5
			xmo = -0.5

	do_move(list(xmo,ymo))


/obj/overworld_vehicle/proc/get_slowdown()
	var/turf/T = get_turf(src)

	return T.movement_cost

/obj/overworld_vehicle/proc/do_move(var/list/momentum)
	if(!momentum)
		return
	if(world.time < lastmove + move_cooldown)
		return
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

		if(locdata[1])
			x = newx
		else
			new_pos_x = pixel_x
		if(locdata[2])
			y = newy
		else
			new_pos_y = pixel_y

	animate(src, pixel_x = new_pos_x, pixel_y = new_pos_y, time = move_cooldown, flags = ANIMATION_END_NOW)


	turfpos[1] = new_pos_x
	turfpos[2] = new_pos_y
	for(var/mob/living/passenger in passengers)
		if(passenger.client)
			animate(passenger.client, pixel_x = new_pos_x, pixel_y = new_pos_y, time = move_cooldown, flags = ANIMATION_END_NOW)
	lastmove = world.time

/obj/overworld_vehicle/proc/consider_location(var/turf/location)
	var/list/locdata = list(TRUE,TRUE)
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
