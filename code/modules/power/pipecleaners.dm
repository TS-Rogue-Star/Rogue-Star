GLOBAL_LIST_INIT(pipe_cleaner_colors, list(
	"yellow" = "#ffff00",
	"green" = "#00aa00",
	"blue" = "#1919c8",
	"pink" = "#ff3cc8",
	"orange" = "#ff8000",
	"cyan" = "#00ffff",
	"white" = "#ffffff",
	"red" = "#ff0000"
	))

//This is the old cable code, but minus any actual powernet logic
//Wireart is fun

///////////////////////////////
//CABLE STRUCTURE
///////////////////////////////


////////////////////////////////
// Definitions
////////////////////////////////

/* Cable directions (d1 and d2)


  9   1   5
	\ | /
  8 - 0 - 4
	/ | \
  10  2   6

If d1 = 0 and d2 = 0, there's no pipe_cleaner
If d1 = 0 and d2 = dir, it's a O-X pipe_cleaner, getting from the center of the tile to dir (knot pipe_cleaner)
If d1 = dir1 and d2 = dir2, it's a full X-X pipe_cleaner, getting from dir1 to dir2
By design, d1 is the smallest direction and d2 is the highest
*/

/obj/structure/pipe_cleaner
	name = "pipe cleaner"
	desc = "A bendable piece of wire covered in fuzz. Fun for arts and crafts!"
	icon = 'icons/obj/cables/pipe_cleaner.dmi'
	icon_state = "0-1"
	layer = WIRES_LAYER //Above hidden pipes, GAS_PIPE_HIDDEN_LAYER
	anchored = TRUE
	var/d1 = 0   // pipe_cleaner direction 1 (see above)
	var/d2 = 1   // pipe_cleaner direction 2 (see above)
	var/obj/item/stack/pipe_cleaner_coil/stored

	var/pipe_cleaner_color = "red"
	color = "#ff0000"

/obj/structure/pipe_cleaner/yellow
	pipe_cleaner_color = "yellow"
	color = "#ffff00"

/obj/structure/pipe_cleaner/green
	pipe_cleaner_color = "green"
	color = "#00aa00"

/obj/structure/pipe_cleaner/blue
	pipe_cleaner_color = "blue"
	color = "#1919c8"

/obj/structure/pipe_cleaner/pink
	pipe_cleaner_color = "pink"
	color = "#ff3cc8"

/obj/structure/pipe_cleaner/orange
	pipe_cleaner_color = "orange"
	color = "#ff8000"

/obj/structure/pipe_cleaner/cyan
	pipe_cleaner_color = "cyan"
	color = "#00ffff"

/obj/structure/pipe_cleaner/white
	pipe_cleaner_color = "white"
	color = "#ffffff"

// the power pipe_cleaner object
/obj/structure/pipe_cleaner/Initialize(mapload, param_color)
	. = ..()

	// ensure d1 & d2 reflect the icon_state for entering and exiting pipe_cleaner
	var/dash = findtext(icon_state, "-")
	d1 = text2num( copytext( icon_state, 1, dash ) )
	d2 = text2num( copytext( icon_state, dash+1 ) )

	if(d1)
		stored = new/obj/item/stack/pipe_cleaner_coil(null,2,pipe_cleaner_color)
	else
		stored = new/obj/item/stack/pipe_cleaner_coil(null,1,pipe_cleaner_color)

	var/list/pipe_cleaner_colors = GLOB.pipe_cleaner_colors
	pipe_cleaner_color = param_color || pipe_cleaner_color || pick(pipe_cleaner_colors)
	if(pipe_cleaner_colors[pipe_cleaner_color])
		pipe_cleaner_color = pipe_cleaner_colors[pipe_cleaner_color]
	update_icon()

/obj/structure/pipe_cleaner/Destroy()					// called when a pipe_cleaner is deleted
	//If we have a stored item at this point, lets just delete it, since that should be
	//handled by deconstruction
	if(stored)
		QDEL_NULL(stored)
	return ..()									// then go ahead and delete the pipe_cleaner

/obj/structure/pipe_cleaner/deconstruct(disassembled = TRUE)
	var/obj/item/stack/pipe_cleaner_coil/cable = new(drop_location(), 1)
	cable.color = color

///////////////////////////////////
// General procedures
///////////////////////////////////

/obj/structure/pipe_cleaner/update_icon()
	icon_state = "[d1]-[d2]"

// Items usable on a pipe_cleaner :
//   - Wirecutters : cut it duh !
//   - pipe cleaner coil : merge pipe cleaners
//
/obj/structure/pipe_cleaner/proc/handlecable(obj/item/W, mob/user, params)
	if(W.has_tool_quality(TOOL_WIRECUTTER))
		user.visible_message("[user] cuts the pipe cleaner.", "<span class='notice'>You cut the pipe cleaner.</span>")
		stored.add_fingerprint(user)
		deconstruct()
		return

	else if(istype(W, /obj/item/stack/pipe_cleaner_coil))
		var/obj/item/stack/pipe_cleaner_coil/coil = W
		if (coil.get_amount() < 1)
			to_chat(user, "<span class='warning'>Not enough pipe cleaner!</span>")
			return
		coil.pipe_cleaner_join(src, user)

	add_fingerprint(user)

/obj/structure/pipe_cleaner/attackby(obj/item/W, mob/user, params)
	handlecable(W, user, params)


/obj/structure/pipe_cleaner/singularity_pull(S, current_size)
	..()
	if(current_size >= STAGE_FIVE)
		deconstruct()

/obj/structure/pipe_cleaner/proc/update_stored(length = 1, color = "red")
	stored.amount = length
	stored.color = color
	stored.update_icon()

///////////////////////////////////////////////
// The pipe cleaner coil object, used for laying pipe cleaner
///////////////////////////////////////////////

////////////////////////////////
// Definitions
////////////////////////////////

/obj/item/stack/pipe_cleaner_coil
	name = "pipe cleaner coil"
	desc = "A coil of pipe cleaners. Good for arts and crafts, not to build with."
	gender = NEUTER //That's a pipe_cleaner coil sounds better than that's some pipe_cleaner coils
	icon = 'icons/obj/power.dmi'
	icon_state = "coil"
	item_state = "coil"
	max_amount = MAXCOIL
	amount = MAXCOIL
	stacktype = /obj/item/stack/pipe_cleaner_coil // This is here to let its children merge between themselves
	throwforce = 0
	w_class = ITEMSIZE_SMALL
	throw_speed = 2
	throw_range = 5
	matter = list(MAT_STEEL = 50, MAT_GLASS = 20)
	slot_flags = SLOT_BELT
	item_state = "coil"
	attack_verb = list("whipped", "lashed", "disciplined", "flogged")
	stacktype = /obj/item/stack/cable_coil
	singular_name = "length"
	drop_sound = 'sound/items/drop/accessory.ogg'
	pickup_sound = 'sound/items/pickup/accessory.ogg'
	singular_name = "cable"

/obj/item/stack/pipe_cleaner_coil/cyborg
	name = "pipe cleaner coil synthesizer"
	desc = "A device that makes decorative pipe cleaner."
	matter = null
	uses_charge = 1
	charge_costs = list(1)

/obj/item/stack/pipe_cleaner_coil/cyborg/attack_self(mob/user)
	var/selected_type = tgui_input_list(usr, "Pick new colour.", "Pipe Cleaner Color", GLOB.possible_cable_coil_colours)
	set_pipecable_color(selected_type, usr)

/obj/item/stack/pipe_cleaner_coil/Initialize(mapload, new_amount = null, param_color = null)
	. = ..()
	pixel_x = rand(-2,2)
	pixel_y = rand(-2,2)
	update_icon()

///////////////////////////////////
// General procedures
///////////////////////////////////


/obj/item/stack/pipe_cleaner_coil/update_icon()
	icon_state = "[initial(item_state)][amount < 3 ? amount : ""]"
	name = "pipe cleaner [amount < 3 ? "piece" : "coil"]"
	if (!color)	//should only be for randomly gen'd coils.
		var/colorpick = pick(GLOB.possible_cable_coil_colours)
		set_pipecable_color(colorpick)

/obj/item/stack/pipe_cleaner_coil/proc/set_pipecable_color(var/selected_color, var/user)
	if(!selected_color)
		return

	var/final_color = GLOB.possible_cable_coil_colours[selected_color]
	if(!final_color)
		final_color = GLOB.possible_cable_coil_colours["Red"]
		selected_color = "red"
	color = final_color
	to_chat(user, "<span class='notice'>You change \the [src]'s color to [lowertext(selected_color)].</span>")

/obj/item/stack/pipe_cleaner_coil/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	var/obj/item/stack/pipe_cleaner_coil/new_pipe_cleaner = ..()
	if(istype(new_pipe_cleaner))
		new_pipe_cleaner.color = color
		new_pipe_cleaner.update_icon()

//add pipe_cleaners to the stack
/obj/item/stack/pipe_cleaner_coil/proc/give(extra)
	if(amount + extra > max_amount)
		amount = max_amount
	else
		amount += extra
	update_icon()



///////////////////////////////////////////////
// Cable laying procedures
//////////////////////////////////////////////

/obj/item/stack/pipe_cleaner_coil/proc/get_new_pipe_cleaner(location)
	var/path = /obj/structure/pipe_cleaner
	return new path(location, item_color)

// called when pipe_cleaner_coil is clicked on a turf
/obj/item/stack/pipe_cleaner_coil/proc/place_turf(turf/T, mob/user, dirnew)
	if(!isturf(user.loc))
		return

	if(!isturf(T) || !T.can_have_cabling())
		to_chat(user, "<span class='warning'>You can only lay pipe cleaners on a solid floor!</span>")
		return

	if(get_amount() < 1) // Out of pipe_cleaner
		to_chat(user, "<span class='warning'>There is no pipe cleaner left!</span>")
		return

	if(get_dist(T,user) > 1) // Too far
		to_chat(user, "<span class='warning'>You can't lay pipe cleaner at a place that far away!</span>")
		return

	var/dirn
	if(!dirnew) //If we weren't given a direction, come up with one! (Called as null from catwalk.dm and floor.dm)
		if(user.loc == T)
			dirn = user.dir //If laying on the tile we're on, lay in the direction we're facing
		else
			dirn = get_dir(T, user)
	else
		dirn = dirnew

	for(var/obj/structure/pipe_cleaner/LC in T)
		if(LC.d2 == dirn && LC.d1 == 0)
			to_chat(user, "<span class='warning'>There's already a pipe leaner at that position!</span>")
			return

	var/obj/structure/pipe_cleaner/C = get_new_pipe_cleaner(T)

	//set up the new pipe_cleaner
	C.d1 = 0 //it's a O-X node pipe_cleaner
	C.d2 = dirn
	C.add_fingerprint(user)
	C.update_icon()

	use(1)

	return C

// called when pipe_cleaner_coil is click on an installed obj/pipe_cleaner
// or click on a turf that already contains a "node" pipe_cleaner
/obj/item/stack/pipe_cleaner_coil/proc/pipe_cleaner_join(obj/structure/pipe_cleaner/C, mob/user, var/showerror = TRUE, forceddir)
	var/turf/U = user.loc
	if(!isturf(U))
		return

	var/turf/T = C.loc

	if(!isturf(T))		// sanity check
		return

	if(get_dist(C, user) > 1)		// make sure it's close enough
		to_chat(user, "<span class='warning'>You can't lay pipe cleaner at a place that far away!</span>")
		return


	if(U == T && !forceddir) //if clicked on the turf we're standing on and a direction wasn't supplied, try to put a pipe_cleaner in the direction we're facing
		place_turf(T,user)
		return

	var/dirn = get_dir(C, user)
	if(forceddir)
		dirn = forceddir

	// one end of the clicked pipe_cleaner is pointing towards us and no direction was supplied
	if((C.d1 == dirn || C.d2 == dirn) && !forceddir)
		if(!U.can_have_cabling())						//checking if it's a plating or catwalk
			if (showerror)
				to_chat(user, "<span class='warning'>You can only lay pipe cleaners on catwalks and plating!</span>")
			return
		else
			// pipe_cleaner is pointing at us, we're standing on an open tile
			// so create a stub pointing at the clicked pipe_cleaner on our tile

			var/fdirn = turn(dirn, 180)		// the opposite direction

			for(var/obj/structure/pipe_cleaner/LC in U)		// check to make sure there's not a pipe_cleaner there already
				if(LC.d1 == fdirn || LC.d2 == fdirn)
					if (showerror)
						to_chat(user, "<span class='warning'>There's already a pipe cleaner at that position!</span>")
					return

			var/obj/structure/pipe_cleaner/NC = get_new_pipe_cleaner(U)

			NC.d1 = 0
			NC.d2 = fdirn
			NC.add_fingerprint(user)
			NC.update_icon()

			use(1)

			return

	// exisiting pipe_cleaner doesn't point at our position or we have a supplied direction, so see if it's a stub
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
				if (showerror)
					to_chat(user, "<span class='warning'>There's already a pipe cleaner at that position!</span>")

				return


		C.update_icon()

		C.d1 = nd1
		C.d2 = nd2

		//updates the stored pipe_cleaner coil
		C.update_stored(2, color)

		C.add_fingerprint(user)
		C.update_icon()

		use(1)

		return

//////////////////////////////
// Misc.
/////////////////////////////

/obj/item/stack/pipe_cleaner_coil/red
	color = COLOR_RED

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

/obj/item/stack/pipe_cleaner_coil/random
	color = null

/obj/item/stack/pipe_cleaner_coil/random/five
	amount = 5

/obj/item/stack/pipe_cleaner_coil/cut
	amount = null
	icon_state = "pipecleaner2"

/obj/item/stack/pipe_cleaner_coil/cut/Initialize(mapload)
	. = ..()
	if(!amount)
		amount = rand(1,2)
	pixel_x = rand(-2,2)
	pixel_y = rand(-2,2)
	update_icon()

/obj/item/stack/pipe_cleaner_coil/cut/red
	color = COLOR_RED

/obj/item/stack/pipe_cleaner_coil/cut/yellow
	color = COLOR_YELLOW

/obj/item/stack/pipe_cleaner_coil/cut/blue
	color = COLOR_BLUE

/obj/item/stack/pipe_cleaner_coil/cut/green
	color = COLOR_GREEN

/obj/item/stack/pipe_cleaner_coil/cut/pink
	color = COLOR_PINK

/obj/item/stack/pipe_cleaner_coil/cut/orange
	color = COLOR_ORANGE

/obj/item/stack/pipe_cleaner_coil/cut/cyan
	color = COLOR_CYAN

/obj/item/stack/pipe_cleaner_coil/cut/white
	color = COLOR_WHITE

/obj/item/stack/pipe_cleaner_coil/cut/random
	color = null
