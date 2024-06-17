/obj/machinery/power/emitter
	name = "emitter"
	desc = "It is a heavy duty industrial laser."
	icon = 'icons/obj/machines/power/singularity/singularity.dmi'
	icon_state = "emitter0"
	anchored = FALSE
	density = TRUE
	unacidable = TRUE
	req_access = list(access_engine_equip)
	var/id = null

	use_power = USE_POWER_OFF			//uses powernet power, not APC power
	active_power_usage = 30 KILOWATTS	//30 kW laser. I guess that means 30 kJ per shot.
	can_change_cable_layer = TRUE

	///Is the machine active?
	var/active = FALSE
	///Does the machine have power?
	var/powered = FALSE
	///Sanity checking to stop dumb stuff, this should be a machine level var but here we are.
	var/welded = FALSE
	///Seconds before the next shot
	var/fire_delay = 10 SECONDS
	///Max delay before firing
	var/maximum_fire_delay = 10 SECONDS
	///Min delay before firing
	var/minimum_fire_delay = 2 SECONDS
	///When was the last shot
	var/last_shot = 0
	///Number of shots made (gets reset every few shots)
	var/shot_number = 0
	///What state is our emitter in?
	var/state = EMITTER_STATE_UNSECURED
	///What was it before? (Used for animations)
	var/previous_state = EMITTER_STATE_UNSECURED
	///did someone in Engineering do their job?
	var/locked = FALSE
	///What projectile type are we shooting?
	var/projectile_type = /obj/item/projectile/beam/emitter
	///What's the projectile sound?
	var/projectile_sound = 'sound/weapons/emitter.ogg'
	///Amount of power inside
	var/charge = 0
	///stores the direction and orientation of the last projectile
	var/last_projectile_params
	///Physical health remaining
	var/integrity = 80

/obj/machinery/power/emitter/should_have_node()
	return welded

/obj/machinery/power/emitter/verb/rotate_clockwise()
	set name = "Rotate Emitter Clockwise"
	set category = "Object"
	set src in oview(1)

	if (src.state == EMITTER_STATE_BOLTED || usr:stat)
		to_chat(usr, "It is fastened to the floor!")
		return FALSE
	src.set_dir(turn(src.dir, 270))
	return 1

/obj/machinery/power/emitter/verb/rotate_counterclockwise()
	set name = "Rotate Emitter Counter-Clockwise"
	set category = "Object"
	set src in oview(1)

	if (src.state == EMITTER_STATE_BOLTED || usr:stat)
		to_chat(usr, "It is fastened to the floor!")
		return FALSE
	src.set_dir(turn(src.dir, 90))
	return TRUE

/obj/machinery/power/emitter/Initialize()
	. = ..()
	connect_to_network()
	update_cable_icons_on_turf(get_turf(src))

/obj/machinery/power/emitter/preset
	anchored = TRUE
	state = EMITTER_STATE_WELDED
	previous_state = EMITTER_STATE_WELDED
	welded = TRUE

/obj/machinery/power/emitter/preset/Initialize()
	. = ..()
	if(state == EMITTER_STATE_WELDED && !anchored)
		anchored = TRUE
		welded = TRUE
		connect_to_network()

/obj/machinery/power/emitter/Destroy()
	message_admins("Emitter deleted at [COORD(src)] - [ADMIN_JMP(loc)]",0,1)
	log_game("EMITTER [COORD(src)] Destroyed/deleted.")
	investigate_log("<font color='red'>deleted</font> at [COORD(src)]","singulo")
	..()

/obj/machinery/power/emitter/update_icon()
	cut_overlays()
	icon_state = "emitter[state]"
	if(state != previous_state)
		flick("emitterflick-[previous_state][state]",src)
		previous_state = state

	if(powered && powernet && avail(active_power_usage) && active)
		var/image/emitterbeam = image(icon,"emitter-beam")
		emitterbeam.plane = PLANE_LIGHTING_ABOVE
		add_overlay(emitterbeam)

	if(locked)
		var/image/emitterlock = image(icon,"emitter-lock")
		emitterlock.plane = PLANE_LIGHTING_ABOVE
		add_overlay(emitterlock)

/obj/machinery/power/emitter/attack_hand(mob/user as mob)
	add_fingerprint(user)
	activate(user)

/obj/machinery/power/emitter/proc/activate(mob/user as mob)
	if(state == EMITTER_STATE_WELDED)
		if(!powernet)
			to_chat(user, "\The [src] isn't connected to a wire.")
			return FALSE
		if(!locked)
			active = !active
			if(!active)
				to_chat(user, "You turn off [src].")
				message_admins("Emitter turned off by [key_name(user, user.client)] [ADMIN_QUE(user)], [ADMIN_JMP(src)]",0,1)
				log_game("EMITTER [COORD(src)] OFF by [key_name(user)]")
				investigate_log("turned <font color='red'>off</font> by [user.key] at [COORD(src)]","singulo")
			else
				to_chat(user, "You turn on [src].")
				shot_number = 0
				message_admins("Emitter turned on by [key_name(user, user.client)] [ADMIN_QUE(user)], [ADMIN_JMP(src)]",0,1)
				log_game("EMITTER [COORD(src)] ON by [key_name(user)]")
				investigate_log("turned <font color='green'>on</font> by [user.key] at [COORD(src)]","singulo")
			update_icon()
		else
			to_chat(user, span_warning("The controls are locked!"))
	else
		to_chat(user, span_warning("\The [src] needs to be firmly secured to the floor first."))
		return FALSE


/obj/machinery/power/emitter/emp_act(var/severity)//Emitters are hardened but still might have issues
	return TRUE

/obj/machinery/power/emitter/process()
	if(stat & (BROKEN))
		return
	if(state != EMITTER_STATE_WELDED || (!powernet && active_power_usage))
		active = FALSE
		update_icon()
		return
	if(!active)
		return
	if(active_power_usage && surplus() < active_power_usage)
		if(powered)
			powered = FALSE
			update_icon()
			log_game("EMITTER [COORD(src)] Lost power and was ON. Available power: [DisplayPower(powernet.avail)] / [DisplayPower(active_power_usage)] needed")
			investigate_log("lost power and turned <font color='red'>off</font> Available power: [DisplayPower(powernet.avail)] / [DisplayPower(active_power_usage)] needed","singulo")
		return
	draw_power(active_power_usage)
	if(!powered)
		powered = TRUE
		update_icon()
		log_game("EMITTER [COORD(src)] Regained power and is ON. Available power: [DisplayPower(powernet.avail)] / [DisplayPower(active_power_usage)] needed")
		investigate_log("regained power and turned <font color='green'>on</font> Available power: [DisplayPower(powernet.avail)] / [DisplayPower(active_power_usage)] needed","singulo")
	if(!check_delay())
		return FALSE
	fire_beam()

/obj/machinery/power/emitter/proc/check_delay()
	if((last_shot + fire_delay) <= world.time)
		return TRUE
	return FALSE

/obj/machinery/power/emitter/proc/fire_beam_pulse()
	if(!check_delay())
		return FALSE
	if(state != EMITTER_STATE_WELDED)
		return FALSE
	if(surplus() >= active_power_usage)
		draw_power(active_power_usage)
		fire_beam()

/obj/machinery/power/emitter/proc/fire_beam()
	var/obj/item/projectile/projectile = new projectile_type(get_turf(src))
	playsound(src, 'sound/weapons/emitter.ogg', 25, 1)
	if(prob(35))
		var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
		s.set_up(5, 1, src)
		s.start()
	projectile.firer = src
	projectile.damage = round(active_power_usage/EMITTER_DAMAGE_POWER_TRANSFER)
	projectile.fire(dir2angle(dir))
	last_shot = world.time
	if(shot_number < 3)
		fire_delay = 2 SECONDS
		shot_number ++
	else
		fire_delay = rand(minimum_fire_delay,maximum_fire_delay)
		shot_number = 0
	return projectile

/obj/machinery/power/emitter/attackby(obj/item/W, mob/user)
	if(W.has_tool_quality(TOOL_WRENCH))
		if(active)
			to_chat(user, span_notice("Turn off [src] first."))
			return
		switch(state)
			if(EMITTER_STATE_UNSECURED)
				state = EMITTER_STATE_BOLTED
				playsound(src, W.usesound, 75, 1)
				user.visible_message("[user.name] secures [src] to the floor.", \
					"You secure the external reinforcing bolts to the floor.", \
					"You hear a ratchet.")
				anchored = TRUE
			if(EMITTER_STATE_BOLTED)
				state = EMITTER_STATE_UNSECURED
				playsound(src, W.usesound, 75, 1)
				user.visible_message("[user.name] unsecures [src] reinforcing bolts from the floor.", \
					"You undo the external reinforcing bolts.", \
					"You hear a ratchet.")
				anchored = FALSE
				disconnect_from_network()
			if(EMITTER_STATE_WELDED)
				to_chat(user, span_warning("\The [src] needs to be unwelded from the floor."))
		update_icon() // VOREStation Add
		return

	if(W.has_tool_quality(TOOL_WELDER))
		var/obj/item/weapon/weldingtool/WT = W
		if(active)
			to_chat(user, span_notice("Turn off [src] first."))
			return
		switch(state)
			if(EMITTER_STATE_UNSECURED)
				to_chat(user, span_warning("\The [src] needs to be wrenched to the floor."))
			if(EMITTER_STATE_BOLTED)
				if (WT.remove_fuel(0,user))
					playsound(src, WT.usesound, 50, 1)
					user.visible_message("[user.name] starts to weld [src] to the floor.", \
						"You start to weld [src] to the floor.", \
						"You hear welding")
					if (do_after(user,20 * WT.toolspeed))
						if(!src || !WT.isOn()) return
						state = EMITTER_STATE_WELDED
						to_chat(user, "You weld [src] to the floor.")
						welded = TRUE
						connect_to_network()

				else
					to_chat(user, span_warning("You need more welding fuel to complete this task."))
			if(EMITTER_STATE_WELDED)
				if (WT.remove_fuel(0,user))
					playsound(src, WT.usesound, 50, 1)
					user.visible_message("[user.name] starts to cut [src] free from the floor.", \
						"You start to cut [src] free from the floor.", \
						"You hear welding")
					if (do_after(user,20 * WT.toolspeed))
						if(!src || !WT.isOn()) return
						state = EMITTER_STATE_BOLTED
						to_chat(user, span_notice("You cut [src] free from the floor."))
						welded = FALSE
						disconnect_from_network()
				else
					to_chat(user, span_warning("You need more welding fuel to complete this task."))
		update_icon() // VOREStation Add
		return

	if(istype(W, /obj/item/stack/material) && W.get_material_name() == MAT_STEEL)
		var/amt = CEILING(( initial(integrity) - integrity)/10, 1)
		if(!amt)
			to_chat(user, span_notice("\The [src] is already fully repaired."))
			return
		var/obj/item/stack/P = W
		if(!P.can_use(amt))
			to_chat(user, span_warning("You don't have enough sheets to repair this! You need at least [amt] sheets."))
			return
		to_chat(user, span_notice("You begin repairing \the [src]..."))
		if(do_after(user, 30))
			if(P.use(amt))
				to_chat(user, span_notice("You have repaired \the [src]."))
				integrity = initial(integrity)
				return
			else
				to_chat(user, span_warning("You don't have enough sheets to repair this! You need at least [amt] sheets."))
				return

	if(istype(W, /obj/item/weapon/card/id) || istype(W, /obj/item/device/pda))
		if(emagged)
			to_chat(user, span_warning("The lock seems to be broken."))
			return
		if(allowed(user))
			locked = !locked
			to_chat(user, span_notice("The controls are now [locked ? "locked." : "unlocked."]"))
			update_icon() // VOREStation Add
		else
			to_chat(user, span_warning("Access denied."))
		return
	..()
	return

/obj/machinery/power/emitter/emag_act(var/remaining_charges, var/mob/user)
	if(!emagged)
		locked = FALSE
		emagged = TRUE
		user.visible_message("[user.name] emags [src].",span_warning("You short out the lock."))
		return TRUE

/obj/machinery/power/emitter/bullet_act(var/obj/item/projectile/P)
	if(!P || !P.damage || P.get_structure_damage() <= 0 )
		return

	adjust_integrity(-P.get_structure_damage())

/obj/machinery/power/emitter/blob_act()
	adjust_integrity(-1000) // This kills the emitter.

/obj/machinery/power/emitter/proc/adjust_integrity(amount)
	integrity = between(0, integrity + amount, initial(integrity))
	if(integrity == 0)
		if(powernet && avail(active_power_usage)) // If it's powered, it goes boom if killed.
			visible_message(src, span_danger("\The [src] explodes violently!"), span_danger("You hear an explosion!"))
			explosion(get_turf(src), 1, 2, 4)
		else
			visible_message(span_danger("\The [src] crumples apart!"), span_warning("You hear metal collapsing."))
		if(src)
			qdel(src)

/obj/machinery/power/emitter/examine(mob/user)
	. = ..()
	switch(state)
		if(EMITTER_STATE_UNSECURED)
			. += span_warning("It is not secured in place!")
		if(EMITTER_STATE_BOLTED)
			. += span_warning("It has been bolted down securely, but not welded into place.")
		if(EMITTER_STATE_WELDED)
			. += span_notice("It has been bolted down securely and welded down into place.")
	var/integrity_percentage = round((integrity / initial(integrity)) * 100)
	switch(integrity_percentage)
		if(0 to 30)
			. += span_danger("It is close to falling apart!")
		if(31 to 70)
			. += span_danger("It is damaged.")
		if(77 to 99)
			. += span_warning("It is slightly damaged.")
