// Basically see-through walls. Used for windows
// If nothing has been built on the low wall, you can climb on it

/obj/structure/wall_frame
	name = "low wall"
	desc = "A low wall section which serves as the base of windows, amongst other things."
	icon = 'icons/obj/bay/wall_frame.dmi'
	icon_state = "frame"

	//atom_flags = ATOM_FLAG_NO_TEMP_CHANGE | ATOM_FLAG_CLIMBABLE
	anchored = 1
	density = 1
	throwpass = 1
	//layer = TABLE_LAYER

	var/health = 100
	var/paint_color = null
	var/stripe_color = null
	//rad_resistance_modifier = 0.5

	var/list/blend_objects = list(/obj/machinery/door, /turf/simulated/wall) // Objects which to blend with
	var/list/noblend_objects = list(/obj/machinery/door/window)
	var/list/connections = list("0","0","0","0")
	var/list/other_connections = list("0","0","0","0")
	var/material/material = DEFAULT_WALL_MATERIAL

/obj/structure/wall_frame/New(var/new_loc, var/materialtype)
	..(new_loc)

	if(!materialtype)
		materialtype = DEFAULT_WALL_MATERIAL
	material = get_material_by_name(materialtype)
	health = material.integrity

/obj/structure/wall_frame/Initialize()
	..()
	return INITIALIZE_HINT_LATELOAD

/obj/structure/wall_frame/LateInitialize()
	. = ..()

	update_connections(1)
	update_icon()

/obj/structure/wall_frame/examine(mob/user)
	. = ..()

	if(health == material.integrity)
		to_chat(user, "<span class='notice'>It seems to be in fine condition.</span>")
	else
		var/dam = health / material.integrity
		if(dam <= 0.3)
			to_chat(user, "<span class='notice'>It's got a few dents and scratches.</span>")
		else if(dam <= 0.7)
			to_chat(user, "<span class='warning'>A few pieces of panelling have fallen off.</span>")
		else
			to_chat(user, "<span class='danger'>It's nearly falling to pieces.</span>")
	if(paint_color)
		to_chat(user, "<span class='notice'>It has a smooth coat of paint applied.</span>")

/obj/structure/wall_frame/attackby(var/obj/item/weapon/W, var/mob/user)
	src.add_fingerprint(user)

	//grille placing
	if(istype(W, /obj/item/stack/rods))
		for(var/obj/structure/window/WINDOW in loc)
			if(WINDOW.dir == get_dir(src, user))
				to_chat(user, "<span class='notice'>There is a window in the way.</span>")
				return
		place_grille(user, loc, W)
		return

	//window placing
	else if(istype(W,/obj/item/stack/material))
		var/obj/item/stack/material/ST = W
		if(ST.material.opacity > 0.7)
			return 0
		place_window(user, loc, SOUTHWEST, ST)

	if(W.is_wrench())
		for(var/obj/structure/S in loc)
			if(istype(S, /obj/structure/window))
				to_chat(user, "<span class='notice'>There is still a window on the low wall!</span>")
				return
			else if(istype(S, /obj/structure/grille))
				to_chat(user, "<span class='notice'>There is still a grille on the low wall!</span>")
				return
		playsound(src.loc, 'sound/items/Ratchet.ogg', 100, 1)
		to_chat(user, "<span class='notice'>Now disassembling the low wall...</span>")
		if(do_after(user, 40,src))
			to_chat(user, "<span class='notice'>You dissasembled the low wall!</span>")
			dismantle()

	/* No plasma cutter here
	else if(istype(W, /obj/item/weapon/gun/energy/plasmacutter))
		var/obj/item/weapon/gun/energy/plasmacutter/cutter = W
		if(!cutter.slice(user))
			return
		playsound(src.loc, 'sound/items/Welder.ogg', 100, 1)
		to_chat(user, "<span class='notice'>Now slicing through the low wall...</span>")
		if(do_after(user, 20,src))
			to_chat(user, "<span class='warning'>You have sliced through the low wall!</span>")
			dismantle()
	*/
	return ..()

/obj/structure/wall_frame/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	if(air_group || (height==0)) return 1
	if(istype(mover,/obj/item/projectile))
		return 1
	if(istype(mover) && mover.checkpass(PASSTABLE))
		return 1

/obj/structure/wall_frame/proc/update_connections(propagate = 0)
	var/list/dirs = list()
	var/list/other_dirs = list()

	for(var/obj/structure/S in orange(src, 1))
		if(can_visually_connect_to(S))
			if(S.can_visually_connect())
				if(propagate)
					//S.update_connections() //Not here
					S.update_icon()
				dirs += get_dir(src, S)

	if(!can_visually_connect())
		connections = list("0", "0", "0", "0")
		other_connections = list("0", "0", "0", "0")
		return FALSE

	for(var/direction in cardinal)
		var/turf/T = get_step(src, direction)
		var/success = 0
		for(var/b_type in blend_objects)
			if(istype(T, b_type))
				success = 1
				if(propagate)
					var/turf/simulated/wall/W = T
					if(istype(W))
						W.update_connections(1)
				if(success)
					break
			if(success)
				break
		if(!success)
			for(var/obj/O in T)
				for(var/b_type in blend_objects)
					if(istype(O, b_type))
						success = 1
						for(var/obj/structure/S in T)
							if(istype(S, src))
								success = 0
						for(var/nb_type in noblend_objects)
							if(istype(O, nb_type))
								success = 0

					if(success)
						break
				if(success)
					break

		if(success)
			dirs += get_dir(src, T)
			other_dirs += get_dir(src, T)

	refresh_neighbors()

	connections = dirs_to_corner_states(dirs)
	other_connections = dirs_to_corner_states(other_dirs)
	return TRUE

/obj/structure/wall_frame/proc/refresh_neighbors()
	for(var/thing in RANGE_TURFS(1, src))
		var/turf/T = thing
		T.update_icon()

// icon related
/obj/structure/wall_frame/update_icon()
	cut_overlays()
	var/image/I

	var/new_color = material.icon_colour // (paint_color ? paint_color : material.icon_colour)
	color = new_color

	for(var/i = 1 to 4)
		if(other_connections[i] != "0")
			I = image('icons/obj/bay/wall_frame.dmi', "frame_other[connections[i]]", dir = 1<<(i-1))
		else
			I = image('icons/obj/bay/wall_frame.dmi', "frame[connections[i]]", dir = 1<<(i-1))
		add_overlay(I)

	if(stripe_color)
		for(var/i = 1 to 4)
			if(other_connections[i] != "0")
				I = image('icons/obj/bay/wall_frame.dmi', "stripe_other[connections[i]]", dir = 1<<(i-1))
			else
				I = image('icons/obj/bay/wall_frame.dmi', "stripe[connections[i]]", dir = 1<<(i-1))
			I.color = stripe_color
			add_overlay(I)

/obj/structure/wall_frame/bullet_act(var/obj/item/projectile/Proj)
	var/proj_damage = Proj.get_structure_damage()
	var/damage = min(proj_damage, 100)
	take_damage(damage)
	return

/obj/structure/wall_frame/take_damage(damage)
	health -= damage
	if(health <= 0)
		dismantle()

/obj/structure/wall_frame/proc/dismantle()
	new /obj/item/stack/material/steel(get_turf(src), 3)
	qdel(src)

//Subtypes
/obj/structure/wall_frame/standard
	paint_color = COLOR_WALL_GUNMETAL

/obj/structure/wall_frame/titanium
	material = MAT_TITANIUM

/obj/structure/wall_frame/hull
	paint_color = COLOR_HULL







/obj/effect/wallframe_spawn
	name = "wall frame window grille spawner"
	icon = 'icons/obj/structures.dmi'
	icon_state = "wingrille"
	density = 1
	anchored = 1.0
	var/win_path = /obj/structure/window/basic/full
	var/frame_path = /obj/structure/wall_frame/standard
	var/grille_path = /obj/structure/grille
	var/activated = FALSE
	var/fulltile = TRUE

/obj/effect/wallframe_spawn/CanPass()
	return 0

/obj/effect/wallframe_spawn/attack_hand()
	attack_generic()

/obj/effect/wallframe_spawn/attack_ghost()
	attack_generic()

/obj/effect/wallframe_spawn/attack_generic()
	activate()

/obj/effect/wallframe_spawn/Initialize(mapload)
	. = ..()
	if(!win_path || !frame_path)
		return
	if(ticker && ticker.current_state < GAME_STATE_PLAYING)
		activate()

/obj/effect/wallframe_spawn/proc/activate()
	if(activated) return

	if(locate(frame_path) in loc)
		warning("Frame Spawner: A frame structure already exists at [loc.x]-[loc.y]-[loc.z]")
	else
		var/obj/structure/wall_frame/F = new frame_path(loc)
		handle_frame_spawn(F)

	if(locate(win_path) in loc)
		warning("Frame Spawner: A window structure already exists at [loc.x]-[loc.y]-[loc.z]")

	if(grille_path)
		if(locate(grille_path) in loc)
			warning("Frame Spawner: A grille already exists at [loc.x]-[loc.y]-[loc.z]")
		else
			var/obj/structure/grille/G = new grille_path (loc)
			handle_grille_spawn(G)

	var/list/neighbours = list()
	if(fulltile)
		var/obj/structure/window/new_win = new win_path(loc)
		handle_window_spawn(new_win)
	else
		for (var/dir in GLOB.cardinal)
			var/turf/T = get_step(src, dir)
			var/obj/effect/wallframe_spawn/other = locate(type) in T
			if(!other)
				var/found_connection
				if(locate(/obj/structure/grille) in T)
					for(var/obj/structure/window/W in T)
						if(W.type == win_path && W.dir == get_dir(T,src))
							found_connection = 1
							qdel(W)
				if(!found_connection)
					var/obj/structure/window/new_win = new win_path(loc)
					new_win.set_dir(dir)
					handle_window_spawn(new_win)
			else
				neighbours |= other
	activated = 1
	for(var/obj/effect/wallframe_spawn/other in neighbours)
		if(!other.activated) other.activate()

/obj/effect/wallframe_spawn/proc/handle_frame_spawn(var/obj/structure/wall_frame/F)
	for(var/direction in GLOB.cardinal)
		var/turf/T = get_step(src, direction)
		for(var/obj/O in T)
			if( istype(O, /obj/machinery/door))
				var/obj/machinery/door/D = O
				D.update_connections()
				D.update_icon()

/obj/effect/wallframe_spawn/proc/handle_window_spawn(var/obj/structure/window/W)
	return

/obj/effect/wallframe_spawn/proc/handle_grille_spawn(var/obj/structure/grille/G)
	return

/obj/effect/wallframe_spawn/no_grille
	name = "wall frame window spawner (no grille)"
	grille_path = null

/obj/effect/wallframe_spawn/reinforced
	name = "reinforced wall frame window spawner"
	icon_state = "r-wingrille"
	win_path = /obj/structure/window/reinforced/full

/obj/effect/wallframe_spawn/reinforced/no_grille
	name = "reinforced wall frame window spawner (no grille)"
	grille_path = null

/obj/effect/wallframe_spawn/reinforced/titanium
	name = "reinforced titanium wall frame window spawner"
	frame_path = /obj/structure/wall_frame/titanium

/obj/effect/wallframe_spawn/reinforced/hull
	name = "reinforced hull wall frame window spawner"
	frame_path = /obj/structure/wall_frame/hull

/obj/effect/wallframe_spawn/reinforced/bare //standard type is used most often so its in the master type, this one is for away sites etc with unpainted walls
	name = "bare metal reinforced wall frame window spawner"
	icon_state = "r-wingrille"
	frame_path = /obj/structure/wall_frame


/obj/effect/wallframe_spawn/phoron
	name = "phoron wall frame window spawner"
	icon_state = "p-wingrille"
	win_path = /obj/structure/window/phoronbasic/full


/obj/effect/wallframe_spawn/reinforced_phoron
	name = "reinforced phoron wall frame window spawner"
	icon_state = "pr-wingrille"
	win_path = /obj/structure/window/phoronreinforced/full

/obj/effect/wallframe_spawn/reinforced_phoron/titanium
	frame_path = /obj/structure/wall_frame/titanium

/obj/effect/wallframe_spawn/reinforced_phoron/hull
	frame_path = /obj/structure/wall_frame/hull


/obj/effect/wallframe_spawn/reinforced/polarized
	name = "polarized reinforced wall frame window spawner"
	color = "#444444"
	win_path = /obj/structure/window/reinforced/polarized/full
	var/id

/obj/effect/wallframe_spawn/reinforced/polarized/no_grille
	name = "polarized reinforced wall frame window spawner (no grille)"
	grille_path = null

/obj/effect/wallframe_spawn/reinforced/polarized/full//wtf it's the same as the other one, not gonna touch this cause I don't wanna remap a million things
	name = "polarized reinforced wall frame window spawner - full tile"
	win_path = /obj/structure/window/reinforced/polarized/full

/* We have no non-reinforced polarized windows
/obj/effect/wallframe_spawn/reinforced/polarized/no_grille/regular
	name = "polarized wall frame window spawner (no grille) (non reinforced)"
	win_path = /obj/structure/window/basic/full/polarized
*/

/obj/effect/wallframe_spawn/reinforced/polarized/handle_window_spawn(var/obj/structure/window/reinforced/polarized/P)
	if(id)
		P.id = id