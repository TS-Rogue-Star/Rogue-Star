///////////////////////////////
//pipe_cleaner STRUCTURE
///////////////////////////////


////////////////////////////////
// Definitions
////////////////////////////////

/* pipe_cleaner directions (d1 and d2)


  9   1   5
	\ | /
  8 - 0 - 4,
	/ | \
  10  2   6

If d1 = 0 and d2 = 0, there's no pipe_cleaner
If d1 = 0 and d2 = dir, it's a O-X pipe_cleaner, getting from the center of the tile to dir (knot pipe_cleaner)
If d1 = dir1 and d2 = dir2, it's a full X-X pipe_cleaner, getting from dir1 to dir2
By design, d1 is the smallest direction and d2 is the highest
*/

/obj/structure/pipe_cleaner
	anchored =TRUE
	unacidable = TRUE
	name = "pipe cleaner"
	desc = "A flexible suspiciously familiar cabling that lacks any conduit."
	icon = 'icons/obj/pipe_cleaners/power_cond_white.dmi'
	icon_state = "0-1"
	var/d1 = 0
	var/d2 = 1
	layer = WIRES_LAYER
	color = COLOR_RED

/obj/structure/pipe_cleaner/yellow
	color = COLOR_YELLOW

/obj/structure/pipe_cleaner/green
	color = COLOR_LIME

/obj/structure/pipe_cleaner/blue
	color = COLOR_BLUE

/obj/structure/pipe_cleaner/pink
	color = COLOR_PINK

/obj/structure/pipe_cleaner/orange
	color = COLOR_ORANGE

/obj/structure/pipe_cleaner/cyan
	color = COLOR_CYAN

/obj/structure/pipe_cleaner/white
	color = COLOR_WHITE

/obj/structure/pipe_cleaner/New()
	..()

	// ensure d1 & d2 reflect the icon_state for entering and exiting pipe_cleaner
	var/dash = findtext(icon_state, "-")
	d1 = text2num( copytext( icon_state, 1, dash ) )
	d2 = text2num( copytext( icon_state, dash+1 ) )

/obj/structure/pipe_cleaner/proc/deconstruct()
	var/obj/item/stack/pipe_cleaner_coil/cable = new(drop_location(), 1)
	cable.color = color
	qdel(src)

// Rotating pipe_cleaners requires d1 and d2 to be rotated
/obj/structure/pipe_cleaner/set_dir(new_dir)
	// If d1 is 0, then it's a not, and doesn't rotate
	if(d1)
		// Using turn will maintain the pipe_cleaner's shape
		// Taking the difference between current orientation and new one
		d1 = turn(d1, dir2angle(new_dir) - dir2angle(dir))
	d2 = turn(d2, dir2angle(new_dir) - dir2angle(dir))

	// Maintain d1 < d2
	if(d1 > d2)
		var/temp = d1
		d1 = d2
		d2 = temp
	update_icon()

///////////////////////////////////
// General procedures
///////////////////////////////////

/obj/structure/pipe_cleaner/update_icon()
	icon_state = "[d1]-[d2]"

//Telekinesis has no effect on a pipe_cleaner
/obj/structure/pipe_cleaner/attack_tk(mob/user)
	return

// Items usable on a pipe_cleaner :
//   - Wirecutters : cut it duh !
//   - pipe_cleaner coil : merge pipe_cleaners
//

/obj/structure/pipe_cleaner/attackby(obj/item/W, mob/user)
	var/turf/T = get_turf(user.loc)
	if(W.has_tool_quality(TOOL_WIRECUTTER))
		var/obj/item/stack/pipe_cleaner_coil/CC

		if(src.d1)	// 0-X pipe_cleaners are 1 unit, X-X pipe_cleaners are 2 units long
			CC = new/obj/item/stack/pipe_cleaner_coil(T, 2, color)
		else
			CC = new/obj/item/stack/pipe_cleaner_coil(T, 1, color)

		src.add_fingerprint(user)
		src.transfer_fingerprints_to(CC)

		user.visible_message("[user] cuts the pipe cleaner.", "<span class='notice'>You cut the pipe cleaner.</span>")
		deconstruct()
		investigate_log("was cut by [key_name(usr, usr.client)] in [user.loc.loc]","wires")
		return

	else if(istype(W, /obj/item/stack/pipe_cleaner_coil))
		var/obj/item/stack/pipe_cleaner_coil/coil = W
		if (coil.get_amount() < 1)
			to_chat(user, "<span class='warning'>Not enough pipe cleaner!</span>")
			return
		coil.pipe_cleaner_join(src, user)

	else if(W.has_tool_quality(TOOL_MULTITOOL))
		to_chat(user, "<span class='warning'>The pipe cleaner isn't conductive, silly.</span>")

	src.add_fingerprint(user)

//explosion handling
/obj/structure/pipe_cleaner/ex_act(severity)
	switch(severity)
		if(1.0)
			qdel(src)
		if(2.0)
			if (prob(50))
				new/obj/item/stack/pipe_cleaner_coil(src.loc, src.d1 ? 2 : 1, color)
				qdel(src)

		if(3.0)
			if (prob(25))
				new/obj/item/stack/pipe_cleaner_coil(src.loc, src.d1 ? 2 : 1, color)
				qdel(src)
	return

/obj/structure/pipe_cleaner/singularity_pull(S, current_size)
	..()
	if(current_size >= STAGE_FIVE)
		deconstruct()

///////////////////////////////////////////////
// The pipe_cleaner coil object, used for laying pipe_cleaner
///////////////////////////////////////////////

////////////////////////////////
// Definitions
////////////////////////////////

/obj/item/stack/pipe_cleaner_coil
	name = "pipe_cleaner coil"
	icon = 'icons/obj/power.dmi'
	icon_state = "coil"
	amount = MAXCOIL
	max_amount = MAXCOIL
	color = COLOR_RED
	gender = NEUTER
	desc = "A coil of power pipe_cleaner."
	throwforce = 0
	force = 0
	w_class = ITEMSIZE_SMALL
	throw_speed = 2
	throw_range = 5
	matter = list(MAT_STEEL = 50, MAT_GLASS = 20)
	slot_flags = SLOT_BELT
	item_state = "coil"
	attack_verb = list("whipped", "lashed", "disciplined", "flogged")
	stacktype = /obj/item/stack/pipe_cleaner_coil
	singular_name = "length"
	drop_sound = 'sound/items/drop/accessory.ogg'
	pickup_sound = 'sound/items/pickup/accessory.ogg'
	singular_name = "pipe_cleaner"

/obj/item/stack/pipe_cleaner_coil/cyborg
	name = "pipe_cleaner coil synthesizer"
	desc = "A device that makes pipe_cleaner."
	gender = NEUTER
	matter = null
	uses_charge = TRUE
	charge_costs = list(1)

/obj/item/stack/pipe_cleaner_coil/New(loc, length = MAXCOIL, var/param_color = null)
	..()
	src.amount = length
	if (param_color) // It should be red by default, so only recolor it if parameter was specified.
		color = param_color
	pixel_x = rand(-2,2)
	pixel_y = rand(-2,2)
	update_icon()
	update_wclass()

///////////////////////////////////
// General procedures
///////////////////////////////////

/obj/item/stack/pipe_cleaner_coil/update_icon()
	if (!color)
		color = pick(COLOR_RED, COLOR_BLUE, COLOR_LIME, COLOR_ORANGE, COLOR_WHITE, COLOR_PINK, COLOR_YELLOW, COLOR_CYAN)
	if(amount == 1)
		icon_state = "coil1"
		name = "pipe_cleaner piece"
	else if(amount == 2)
		icon_state = "coil2"
		name = "pipe_cleaner piece"
	else
		icon_state = "coil"
		name = initial(name)

/obj/item/stack/pipe_cleaner_coil/proc/set_pipe_cleaner_color(var/selected_color, var/user)
	if(!selected_color)
		return

	var/final_color = GLOB.possible_cable_coil_colours[selected_color]
	if(!final_color)
		final_color = GLOB.possible_cable_coil_colours["Red"]
		selected_color = "red"
	color = final_color
	to_chat(user, "<span class='notice'>You change \the [src]'s color to [lowertext(selected_color)].</span>")

/obj/item/stack/pipe_cleaner_coil/proc/update_wclass()
	if(amount == 1)
		w_class = ITEMSIZE_TINY
	else
		w_class = ITEMSIZE_SMALL

/obj/item/stack/pipe_cleaner_coil/attackby(obj/item/W, mob/user)
	if(W.has_tool_quality(TOOL_MULTITOOL))
		var/selected_type = tgui_input_list(usr, "Pick new colour.", "pipe_cleaner Colour", GLOB.possible_cable_coil_colours)
		set_pipe_cleaner_color(selected_type, usr)
		return
	return ..()

/obj/item/stack/pipe_cleaner_coil/cyborg/verb/set_colour()
	set name = "Change Colour"
	set category = "Object"

	var/selected_type = tgui_input_list(usr, "Pick new colour.", "pipe_cleaner Colour", GLOB.possible_cable_coil_colours)
	set_pipe_cleaner_color(selected_type, usr)

/obj/item/stack/cable_coil/proc/set_pipe_cleaner_color(var/selected_color, var/user)
	if(!selected_color)
		return
	var/final_color = GLOB.possible_cable_coil_colours[selected_color]
	if(!final_color)
		final_color = GLOB.possible_cable_coil_colours["Red"]
		selected_color = "red"
	color = final_color
	to_chat(user, "<span class='notice'>You change \the [src]'s color to [lowertext(selected_color)].</span>")

// Items usable on a pipe_cleaner coil :
//   - Wirecutters : cut them duh !
//   - pipe_cleaner coil : merge pipe_cleaners

/obj/item/stack/pipe_cleaner_coil/transfer_to(obj/item/stack/pipe_cleaner_coil/S)
	if(!istype(S))
		return
	..()

/obj/item/stack/pipe_cleaner_coil/use()
	. = ..()
	update_icon()
	return

/obj/item/stack/pipe_cleaner_coil/add()
	. = ..()
	update_icon()
	return

///////////////////////////////////////////////
// pipe_cleaner laying procedures
//////////////////////////////////////////////

// called when pipe_cleaner_coil is clicked on a turf/simulated/floor
/obj/item/stack/pipe_cleaner_coil/proc/place_turf(turf/simulated/F, mob/user)
	if(!isturf(user.loc))
		return

	if(get_amount() < 1) // Out of pipe_cleaner
		to_chat(user, "There is no pipe_cleaner left.")
		return

	if(get_dist(F,user) > 1) // Too far
		to_chat(user, "You can't lay pipe_cleaner at a place that far away.")
		return

	var/dirn
	if(user.loc == F)
		dirn = user.dir			// if laying on the tile we're on, lay in the direction we're facing
	else
		dirn = get_dir(F, user)

	var/end_dir = 0

	for(var/obj/structure/pipe_cleaner/LC in F)
		if((LC.d1 == dirn && LC.d2 == end_dir ) || ( LC.d2 == dirn && LC.d1 == end_dir))
			to_chat(user, "<span class='warning'>There's already a pipe_cleaner at that position.</span>")
			return

	put_pipe_cleaner(F, user, end_dir, dirn)

/obj/item/stack/pipe_cleaner_coil/proc/put_pipe_cleaner(turf/simulated/F, mob/user, d1, d2)
	if(!istype(F))
		return

	var/obj/structure/pipe_cleaner/C = new(F)
	C.color = color
	C.d1 = d1
	C.d2 = d2
	C.add_fingerprint(user)
	C.update_icon()

// called when pipe_cleaner_coil is click on an installed obj/pipe_cleaner
// or click on a turf that already contains a "node" pipe_cleaner
/obj/item/stack/pipe_cleaner_coil/proc/pipe_cleaner_join(obj/structure/pipe_cleaner/C, mob/user)
	var/turf/U = user.loc
	if(!isturf(U))
		return

	var/turf/T = C.loc

	if(!isturf(T))		// sanity checks
		return

	if(get_dist(C, user) > 1)		// make sure it's close enough
		to_chat(user, "You can't lay pipe_cleaner at a place that far away.")
		return

	if(U == T) //if clicked on the turf we're standing on, try to put a pipe_cleaner in the direction we're facing
		place_turf(T,user)
		return

	var/dirn = get_dir(C, user)
	// one end of the clicked pipe_cleaner is pointing towards us
	if(C.d1 == dirn || C.d2 == dirn)
		// pipe_cleaner is pointing at us, we're standing on an open tile
		// so create a stub pointing at the clicked pipe_cleaner on our tile
		var/fdirn = turn(dirn, 180)		// the opposite direction
		for(var/obj/structure/pipe_cleaner/LC in U)		// check to make sure there's not a pipe_cleaner there already
			if(LC.d1 == fdirn || LC.d2 == fdirn)
				to_chat(user, "There's already a pipe_cleaner at that position.")
				return
		put_pipe_cleaner(U,user,0,fdirn)
		return

	// exisiting pipe_cleaner doesn't point at our position, so see if it's a stub
	else if(C.d1 == 0)
							// if so, make it a full pipe_cleaner pointing from it's old direction to our dirn
		var/nd1 = C.d2	// these will be the new directions
		var/nd2 = dirn

		if(nd1 > nd2)		// swap directions to match icons/states
			nd1 = dirn
			nd2 = C.d2

		for(var/obj/structure/pipe_cleaner/LC in T)		// check to make sure there's no matching pipe_cleaner
			if(LC == C)			// skip the pipe_cleaner we're interacting with
				continue
			if((LC.d1 == nd1 && LC.d2 == nd2) || (LC.d1 == nd2 && LC.d2 == nd1) )	// make sure no pipe_cleaner matches either direction
				to_chat(user, "There's already a pipe_cleaner at that position.")
				return

		C.color = color
		C.d1 = nd1
		C.d2 = nd2
		C.add_fingerprint()
		C.update_icon()
		use(1)
		return

//////////////////////////////
// Misc.
/////////////////////////////

/obj/item/stack/pipe_cleaner_coil/cut
	item_state = "coil2"

/obj/item/stack/pipe_cleaner_coil/cut/New(loc)
	..()
	src.amount = rand(1,2)
	pixel_x = rand(-2,2)
	pixel_y = rand(-2,2)
	update_icon()
	update_wclass()

/obj/item/stack/pipe_cleaner_coil/yellow
	color = COLOR_YELLOW

/obj/item/stack/pipe_cleaner_coil/blue
	color = COLOR_BLUE

/obj/item/stack/pipe_cleaner_coil/green
	color = COLOR_GREEN

/obj/item/stack/pipe_cleaner_coil/pink
	color = COLOR_PINK

/obj/item/stack/pipe_cleaner_coil/orange
	color = COLOR_ORANGE

/obj/item/stack/pipe_cleaner_coil/cyan
	color = COLOR_CYAN

/obj/item/stack/pipe_cleaner_coil/white
	color = COLOR_WHITE

/obj/item/stack/pipe_cleaner_coil/silver
	color = COLOR_SILVER

/obj/item/stack/pipe_cleaner_coil/gray
	color = COLOR_GRAY

/obj/item/stack/pipe_cleaner_coil/black
	color = COLOR_BLACK

/obj/item/stack/pipe_cleaner_coil/maroon
	color = COLOR_MAROON

/obj/item/stack/pipe_cleaner_coil/olive
	color = COLOR_OLIVE

/obj/item/stack/pipe_cleaner_coil/lime
	color = COLOR_LIME

/obj/item/stack/pipe_cleaner_coil/teal
	color = COLOR_TEAL

/obj/item/stack/pipe_cleaner_coil/navy
	color = COLOR_NAVY

/obj/item/stack/pipe_cleaner_coil/purple
	color = COLOR_PURPLE

/obj/item/stack/pipe_cleaner_coil/beige
	color = COLOR_BEIGE

/obj/item/stack/pipe_cleaner_coil/brown
	color = COLOR_BROWN

/obj/item/stack/pipe_cleaner_coil/random/New()
	color = pick(COLOR_RED, COLOR_BLUE, COLOR_LIME, COLOR_WHITE, COLOR_PINK, COLOR_YELLOW, COLOR_CYAN, COLOR_SILVER, COLOR_GRAY, COLOR_BLACK, COLOR_MAROON, COLOR_OLIVE, COLOR_LIME, COLOR_TEAL, COLOR_NAVY, COLOR_PURPLE, COLOR_BEIGE, COLOR_BROWN)
	..()

//Endless alien pipe_cleaner coil

/datum/category_item/catalogue/anomalous/precursor_a/alien_pipe_cleaner
	name = "Precursor Alpha Object - Recursive Spool"
	desc = "Upon visual inspection, this merely appears to be a \
	spool for silver-colored pipe_cleaner. If one were to use this for \
	some time, however, it would become apparent that the pipe_cleaners \
	inside the spool appear to coil around the spool endlessly, \
	suggesting an infinite length of useless pipe cleaner.\
	<br><br>\
	In reality, an infinite amount of something within a finite space \
	would likely not be able to exist. Instead, the spool likely has \
	some method of creating new wire as it is unspooled. How this is \
	accomplished without an apparent source of material would require \
	further study."
	value = CATALOGUER_REWARD_EASY

/obj/item/stack/pipe_cleaner_coil/alien
	name = "alien spool"
	desc = "A spool of pipe_cleaner. No matter how hard you try, you can never seem to get to the end."
	catalogue_data = list(/datum/category_item/catalogue/anomalous/precursor_a/alien_pipe_cleaner)
	icon = 'icons/obj/abductor.dmi'
	icon_state = "coil"
	amount = MAXCOIL
	max_amount = MAXCOIL
	stacktype = /obj/item/stack/pipe_cleaner_coil/alien
	color = COLOR_SILVER
	w_class = ITEMSIZE_SMALL
	throw_speed = 2
	throw_range = 5
	matter = list(MAT_STEEL = 50, MAT_GLASS = 20)
	slot_flags = SLOT_BELT
	attack_verb = list("whipped", "lashed", "disciplined", "flogged")
	stacktype = null

/obj/item/stack/pipe_cleaner_coil/alien/New(loc, length = MAXCOIL, var/param_color = null)		//There has to be a better way to do this.
	if(embed_chance == -1)		//From /obj/item, don't want to do what the normal pipe_cleaner_coil does
		if(sharp)
			embed_chance = force/w_class
		else
			embed_chance = force/(w_class*3)
	update_icon()

/obj/item/stack/pipe_cleaner_coil/alien/update_icon()
	icon_state = initial(icon_state)

/obj/item/stack/pipe_cleaner_coil/alien/can_use(var/used)
	return TRUE

/obj/item/stack/pipe_cleaner_coil/alien/use()	//It's endless
	return TRUE

/obj/item/stack/pipe_cleaner_coil/alien/add()	//Still endless
	return FALSE

/obj/item/stack/pipe_cleaner_coil/alien/update_wclass()
	return FALSE

/obj/item/stack/pipe_cleaner_coil/alien/examine(mob/user)
	. = ..()

	if(Adjacent(user))
		. += "It doesn't seem to have a beginning, or an end."

/obj/item/stack/pipe_cleaner_coil/alien/attack_hand(mob/user as mob)
	if (user.get_inactive_hand() == src)
		var/N = tgui_input_number(usr, "How many units of wire do you want to take from [src]?  You can only take up to [amount] at a time.", "Split stacks", 1)
		if(N && N <= amount)
			var/obj/item/stack/pipe_cleaner_coil/CC = new/obj/item/stack/pipe_cleaner_coil(user.loc)
			CC.amount = N
			CC.update_icon()
			to_chat(user,"<font color='blue'>You take [N] units of wire from the [src].</font>")
			if (CC)
				user.put_in_hands(CC)
				src.add_fingerprint(user)
				CC.add_fingerprint(user)
				spawn(0)
					if (src && usr.machine==src)
						src.interact(usr)
		else
			return
	else
		..()
	return
