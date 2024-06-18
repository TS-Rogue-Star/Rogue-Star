//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:33


/*
field_generator power level display
   The icon used for the field_generator need to have 'num_power_levels' number of icon states
   named 'Field_Gen +p[num]' where 'num' ranges from 1 to 'num_power_levels'

   The power level is displayed using overlays. The current displayed power level is stored in 'powerlevel'.
   The overlay in use and the powerlevel variable must be kept in sync.  A powerlevel equal to 0 means that
   no power level overlay is currently in the overlays list.
   -Aygar
*/

#define field_generator_max_power 250

//field generator activity defines
#define FG_OFFLINE 0
#define FG_CHARGING 1
#define FG_ONLINE 2

//field generator construction/state defines
#define FG_UNSECURED 0
#define FG_SECURED 1
#define FG_WELDED 2

/obj/machinery/field_generator
	name = "Field Generator"
	desc = "A large thermal battery that projects a high amount of energy when powered."
	icon = 'icons/obj/machines/power/singularity/field_generator.dmi'
	icon_state = "Field_Gen"
	anchored = FALSE
	density = TRUE
	use_power = USE_POWER_OFF
	var/const/num_power_levels = 6	// Total number of power level icon has
	///Adminbus starting
	var/Varedit_start = FALSE
	var/Varpower = 0
	///Amount of energy stored, used for visual overlays (over 9000?)
	var/power_level = 0
	///Current power mode of the machine, between FG_OFFLINE, FG_CHARGING, FG_ONLINE
	var/active = FG_OFFLINE
	/// Current amount of power
	var/power = 20
	///Current state of the machine, between FG_UNSECURED, FG_SECURED, FG_WELDED
	var/state = FG_UNSECURED
	///Timer between 0 and 3 before the field gets made
	var/warming_up = 0
	///List of every containment fields connected to this generator
	var/list/obj/machinery/containment_field/fields = list()
	///List of every field generators connected to this one
	var/list/obj/machinery/field_generator/connected_gens = list()
	///Check for asynk cleanups for this and the connected gens
	var/clean_up = FALSE


	//If keeping field generators powered is hard then increase the emitter active power usage.
	var/gen_power_draw = 5.5 KILOWATTS	//power needed per generator
	var/field_power_draw = 2 KILOWATTS	//power needed per field object

	var/light_range_on = 3
	var/light_power_on = 1
	light_color = "#5BA8FF"

/obj/machinery/field_generator/examine()
	. = ..()
	switch(state)
		if(FG_UNSECURED)
			. += span_warning("It is not secured in place!")
		if(FG_SECURED)
			. += span_warning("It has been bolted down securely, but not welded into place.")
		if(FG_WELDED)
			. += span_notice("It has been bolted down securely and welded down into place.")

/obj/machinery/field_generator/update_icon()
	cut_overlays()
	if(warming_up)
		add_overlay("+a[warming_up]")
	if(LAZYLEN(fields))
		add_overlay("+on")
	if(power_level)
		add_overlay("+p[power_level]")

/obj/machinery/field_generator/Initialize(mapload)
	. = ..()

/obj/machinery/field_generator/process()
	if(Varedit_start == TRUE)
		if(active == FG_OFFLINE)
			active = FG_CHARGING
			state = FG_WELDED
			power = field_generator_max_power
			anchored = TRUE
			warming_up = 3
			start_fields()
			update_icon()
		Varedit_start = FALSE

	if(active == FG_ONLINE)
		calc_power()
		update_icon()
	return


/obj/machinery/field_generator/attack_hand(mob/user as mob)
	if(state != FG_WELDED)
		to_chat(user, span_warning("[src] needs to be firmly secured to the floor first!"))
		return
	if(get_dist(src, user) > 1)//Need to actually touch the thing to turn it on
		return
	if(active >= FG_CHARGING)
		to_chat(user, span_warning("You are unable to turn off [src] once it is online!"))
		return TRUE

	user.visible_message(
		span_notice("[user] turns on [src]."),
		span_notice("You turn on [src]."),
		span_notice("You hear heavy droning."))
	turn_on()
	log_game("FIELDGEN([COORD(src)]) Activated by [key_name(user)]")
	investigate_log("<font color='green'>activated</font> by [user.key].","singulo")

	add_fingerprint(user)

/obj/machinery/field_generator/attackby(obj/item/W, mob/user)
	if(active)
		to_chat(user, span_notice("The [src] needs to be off."))
		return
	if(W.has_tool_quality(TOOL_WRENCH))
		switch(state)
			if(FG_UNSECURED)
				playsound(src, W.usesound, 75, 1)
				user.visible_message("[user.name] secures [src] to the floor.", \
					"You secure the external reinforcing bolts to the floor.", \
					"You hear ratchet")
				anchored = TRUE
				state = FG_SECURED
			if(FG_SECURED)
				playsound(src, W.usesound, 75, 1)
				user.visible_message("[user.name] unsecures [src] reinforcing bolts from the floor.", \
					"You undo the external reinforcing bolts.", \
					"You hear ratchet")
				anchored = FALSE
				state = FG_UNSECURED
			if(FG_WELDED)
				to_chat(user, span_warning("The [src] needs to be unwelded from the floor."))
				return
	if(W.has_tool_quality(TOOL_WELDER))
		var/obj/item/weapon/weldingtool/WT = W
		switch(state)
			if(FG_UNSECURED)
				to_chat(user, span_warning("The [src] needs to be wrenched to the floor."))
				return
			if(FG_SECURED)
				if (WT.remove_fuel(0,user))
					playsound(src, WT.usesound, 50, 1)
					user.visible_message("[user.name] starts to weld the [src] to the floor.", \
						"You start to weld the [src] to the floor.", \
						"You hear welding")
					if (do_after(user,20 * WT.toolspeed))
						if(!src || !WT.isOn()) return
						state = FG_WELDED
						to_chat(user, span_notice("You weld the field generator to the floor."))
				else
					return
			if(FG_WELDED)
				if (WT.remove_fuel(0,user))
					playsound(src, WT.usesound, 50, 1)
					user.visible_message("[user.name] starts to cut the [src] free from the floor.", \
						"You start to cut the [src] free from the floor.", \
						"You hear welding")
					if (do_after(user,20 * WT.toolspeed))
						if(!src || !WT.isOn()) return
						state = FG_SECURED
						to_chat(user, "You cut the [src] free from the floor.")
				else
					return
	else
		..()
		return


/obj/machinery/field_generator/emp_act()
	return FALSE

/obj/machinery/field_generator/bullet_act(var/obj/item/projectile/Proj)
	if(istype(Proj, /obj/item/projectile/beam))
		power = min(power + Proj.damage, field_generator_max_power)	// each emitter shot is worth ~67 power. this should fix abnormal power issues
		check_power_level()
	return 0


/obj/machinery/field_generator/Destroy()
	cleanup()
	. = ..()

/obj/machinery/field_generator/proc/check_power_level()
	var/new_level = round(6 * power / field_generator_max_power)
	if(new_level != power_level)
		power_level = new_level
		update_icon()

/obj/machinery/field_generator/proc/turn_off()
	active = FG_OFFLINE
	INVOKE_ASYNC(src, PROC_REF(cleanup))
	addtimer(CALLBACK(src, PROC_REF(cool_down)), 5 SECONDS)
	set_light(0)
	update_icon()

/obj/machinery/field_generator/proc/cool_down()
	if(active || warming_up <= 0)
		return
	warming_up--
	update_icon()
	if(warming_up > 0)
		addtimer(CALLBACK(src, PROC_REF(cool_down)), 5 SECONDS)

/obj/machinery/field_generator/proc/turn_on()
	active = FG_CHARGING
	addtimer(CALLBACK(src, PROC_REF(warm_up)), 5 SECONDS)

/obj/machinery/field_generator/proc/warm_up()
	if(!active)
		return
	warming_up++
	update_icon()
	if(warming_up >= 3)
		start_fields()
		set_light(light_range_on, light_power_on)
	else
		addtimer(CALLBACK(src, PROC_REF(warm_up)), 5 SECONDS)

/obj/machinery/field_generator/proc/calc_power(set_power_draw)
	if(Varpower)
		return TRUE

	var/power_draw = 2 + fields.len
	if(set_power_draw)
		power_draw = set_power_draw

	if(draw_power(round(power_draw * 0.5, 1)))
		check_power_level()
		update_icon()
		return TRUE
	else
		visible_message(span_danger("The [name] shuts down!"), span_notice("You hear something shutting down."))
		turn_off()
		log_game("FIELDGEN([COORD(src)]) Lost power and was ON. Expecting [draw_power(round(power_draw * 0.5, 1))] actual: [power]")
		investigate_log("ran out of power and <font color='red'>deactivated</font> expecting [draw_power(round(power_draw * 0.5, 1))] actual: [power]","singulo")
		power = 0
		check_power_level()
		update_icon()
		return FALSE

//Tries to draw the needed power from our own power reserve, or connected generators if we can. Returns the amount of power we were able to get.
/obj/machinery/field_generator/proc/draw_power(draw = 0, failsafe = FALSE, obj/machinery/field_generator/other_generator = null, obj/machinery/field_generator/last = null)
	if((other_generator && (other_generator == src)) || (failsafe >= 8))//Loopin, set fail
		return FALSE
	else
		failsafe++

	if(power >= draw)//We have enough power
		power -= draw
		return TRUE

	//Need more power
	draw -= power
	power = 0
	for(var/connected_generator in connected_gens)
		var/obj/machinery/field_generator/considered_generator = connected_generator
		if(considered_generator == last)//We just asked you
			continue
		if(other_generator)//Another gen is askin for power and we dont have it
			if(considered_generator.draw_power(draw, failsafe, other_generator, src))//Can you take the load
				return TRUE
			return FALSE
		//We are askin another for power
		if(considered_generator.draw_power(draw, failsafe, src, src))
			return TRUE
		return FALSE

/obj/machinery/field_generator/proc/start_fields()
	if(state != FG_WELDED || !anchored)
		turn_off()
		return
	addtimer(CALLBACK(src, PROC_REF(setup_field), 1), 0.1 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(setup_field), 2), 0.2 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(setup_field), 4), 0.3 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(setup_field), 8), 0.4 SECONDS)
	addtimer(VARSET_CALLBACK(src, active, FG_ONLINE), 0.5 SECONDS)


/obj/machinery/field_generator/proc/setup_field(var/NSEW)
	var/turf/current_turf = loc
	if(!istype(current_turf))
		return FALSE

	var/obj/machinery/field_generator/found_generator = null
	var/steps = 0
	if(!NSEW)//Make sure its ran right
		return FALSE
	for(var/dist in 0 to 7) // checks out to 8 tiles away for another generator
		current_turf = get_step(current_turf, NSEW)
		if(current_turf.density)//We cant shoot a field though this
			return FALSE

		found_generator = locate(/obj/machinery/field_generator) in current_turf
		if(found_generator)
			steps -= 1
			if(!found_generator.active)
				return FALSE
			break

		for(var/turf_content in current_turf.contents)
			var/atom/found_atom = turf_content
			if(ismob(found_atom))
				continue
			if(found_atom.density)
				return FALSE

		steps++

	if(!found_generator)
		return FALSE

	current_turf = loc
	for(var/dist in 0 to steps) // creates each field tile
		var/field_dir = get_dir(current_turf, get_step(found_generator.loc, NSEW))
		current_turf = get_step(current_turf, NSEW)
		if(!locate(/obj/machinery/containment_field) in current_turf)
			var/obj/machinery/containment_field/created_field = new(current_turf)
			created_field.set_master(src,found_generator)
			created_field.set_dir(field_dir)
			fields += created_field
			found_generator.fields += created_field
			for(var/mob/living/shocked_mob in current_turf)
				created_field.Crossed(shocked_mob)

	connected_gens |= found_generator
	found_generator.connected_gens |= src


/obj/machinery/field_generator/proc/cleanup()
	clean_up = TRUE
	for(var/obj/machinery/containment_field/F in fields)
		if(QDELETED(F))
			continue
		qdel(F)
	fields = list()
	for(var/connected_generator in connected_gens)
		var/obj/machinery/field_generator/considered_generator = connected_generator
		considered_generator.connected_gens -= src
		if(!considered_generator.clean_up)//Makes the other gens clean up as well
			considered_generator.cleanup()
		connected_gens -= considered_generator
	clean_up = FALSE
	update_icon()

	//This is here to help fight the "hurr durr, release singulo cos nobody will notice before the
	//singulo eats the evidence". It's not fool-proof but better than nothing.
	//I want to avoid using global variables.
	spawn(1)
		var/temp = 1 //stops spam
		for(var/obj/singularity/O in machines)
			if(O.last_warning && temp)
				if((world.time - O.last_warning) > 50) //to stop message-spam
					temp = 0
					admin_chat_message(message = "SINGUL/TESLOOSE!", color = "#FF2222") //VOREStation Add
					message_admins("A singulo exists and a containment field has failed.",1)
					investigate_log("has <font color='red'>failed</font> whilst a singulo exists.","singulo")
					log_game("FIELDGEN [COORD(src)] Containment failed while singulo/tesla exists.")
			O.last_warning = world.time

#undef FG_UNSECURED
#undef FG_SECURED
#undef FG_WELDED

#undef FG_OFFLINE
#undef FG_CHARGING
#undef FG_ONLINE
