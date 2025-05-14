//RS FILE
/mob/living/proc/chameleon_blend()
	set name = "Blend In"
	set category = "Abilities"
	set desc = "Stand still to blend in!"

	if(world.time < last_special)
		to_chat(src, "<span class='warning'>You can't do that yet!</span>")
		return

	if(stat || paralysis || weakened || stunned)
		to_chat(src, "<span class='warning'>You can't do that in your current state.</span>")
		return

	if(alpha < 255)
		var/dunnit = FALSE
		for(var/datum/modifier/M in modifiers)
			if(M.type == /datum/modifier/blend_in)
				var/datum/modifier/blend_in/B = M
				B.expire()
				dunnit = TRUE
		if(!dunnit)
			to_chat(src, "<span class='warning'>You can't do that in your current state.</span>")
		return

	last_special = world.time + 5 SECONDS	//Please do not spam ty ilu

	if(!istype(src, /mob/living))	//How did you get here!!!
		to_chat(src, "<span class='warning'>It doesn't work that way.</span>")
		return

	add_modifier(/datum/modifier/blend_in)	//The meat happens with a modifier baby!!!
	playsound(src, 'sound/effects/basscannon.ogg', 5, 1)
	return TRUE

/datum/modifier/blend_in	//The magic happens here
	name = "Blend In"
	desc = "Blending in!"

	on_created_text = "<span class='notice'>Your body's color changes to blend in with your surroundings! As long as you stay still, you should blend in!</span>"
	on_expired_text = "<span class='notice'>Your body's colors return to normal!</span>"

	stacks = MODIFIER_STACK_FORBID	//Don't blend while blending pls and thank you
	var/chargup = 0

/datum/modifier/blend_in/New()
	. = ..()
	var/turf/T = get_turf(holder)
	animate(holder, (5 * T.get_lumcount()) SECONDS ,alpha = 10)	//Animate uses the client to interpolate, so this saves server power~
	RegisterSignal(holder, COMSIG_MOVABLE_MOVED, PROC_REF(expire), TRUE)	//Let's listen for our mob to say it moved! If it does, then we expire!
	RegisterSignal(holder, COMSIG_MOB_APPLY_DAMGE, PROC_REF(expire), TRUE)	//Let's listen for our mob to take damage! If it does, then we expire!
	RegisterSignal(holder, COMSIG_GET_ATTACK_SPEED, PROC_REF(expire), TRUE)	//Don't move!!!
	RegisterSignal(holder, COMSIG_ITEM_PRE_ATTACK, PROC_REF(expire), TRUE)	//Don't move!!!
	RegisterSignal(holder, COMSIG_MOB_FIRED_GUN, PROC_REF(expire), TRUE)	//Stop blending in when you shoot people
	holder.plane = -26

/datum/modifier/blend_in/tick()
	. = ..()
	holder.last_special = world.time + 5 SECONDS	//Update the cooldown! This happens every 2 seconds or so~
	chargup ++

/datum/modifier/blend_in/expire()
	. = ..()
	animate(holder, 1 SECOND , alpha = 255)	//Animate your alpha back to normal
	UnregisterSignal(holder, COMSIG_MOVABLE_MOVED)	//Cleanup your signals!
	UnregisterSignal(holder, COMSIG_MOB_APPLY_DAMGE)	//Cleanup your signals!
	UnregisterSignal(holder, COMSIG_GET_ATTACK_SPEED)	//Cleanup your signals!
	UnregisterSignal(holder, COMSIG_ITEM_PRE_ATTACK)	//Cleanup your signals!
	UnregisterSignal(holder, COMSIG_MOB_FIRED_GUN)	//Cleanup your signals!
	holder.plane = initial(holder.plane)

/datum/modifier/olfaction_track
	name = "Tracking"
	desc = "You are tracking someone!"

	stacks = MODIFIER_STACK_ALLOWED
	var/obj/screen/compass
	var/mob/living/tracked
	var/tracked_name

/datum/modifier/olfaction_track/New(new_holder, new_origin)
	. = ..()
	RegisterSignal(holder,COMSIG_MOB_SMELLED,PROC_REF(expire))
	RegisterSignal(new_origin,COMSIG_PARENT_QDELETING,PROC_REF(expire))
	RegisterSignal(new_origin,COMSIG_MOB_WASHED,PROC_REF(expire))

	tracked = new_origin
	tracked_name = tracked.name

	to_chat(holder, SPAN_NOTICE("You remember the scent of [tracked_name]..."))
	holder.visible_message(runemessage = "sniff sniff...")

	give_compass()

/datum/modifier/olfaction_track/expire()
	. = ..()
	to_chat(holder,SPAN_WARNING("You have lost \the [tracked_name]'s scent..."))
	UnregisterSignal(holder, COMSIG_MOB_SMELLED)
	UnregisterSignal(tracked,COMSIG_PARENT_QDELETING)
	UnregisterSignal(tracked,COMSIG_MOB_WASHED)
	tracked = null
	kill_compass()

/datum/modifier/olfaction_track/tick()
	. = ..()
	if(compass)	//You can turn this off, so we only want it to happen when we're actually tracking
		if(tracked.is_incorporeal())	//If they're incorporeal don't even bother with the rest
			compass.icon_state = "smells-who-knows"
			return
		var/turf/h_turf = get_turf(holder)	//We compare turfs because mobs can be in silly places like bellies or lockers
		var/turf/t_turf = get_turf(tracked)
		if(h_turf.z == t_turf.z)	//We're on the same Z, so we can give more direct instructions
			compass.icon_state = "smells"
			compass.dir = get_dir(h_turf, t_turf)
		else	//We are not on the same Z, so let's figure out if we can give instructions
			var/list/our_zs = GetConnectedZlevels(h_turf.z)	//We need to see if their Z is connected to our Z!
			if(t_turf.z in our_zs)	//It is! So we can tell them if it's up or down!
				if(t_turf.z > h_turf.z)
					compass.icon_state = "smells-up"
				else if(t_turf.z < h_turf.z)
					compass.icon_state = "smells-down"
			else	//It's not connected, sorry bro!
				compass.icon_state = "smells-who-knows"

/datum/modifier/olfaction_track/proc/kill_compass()
	if(!compass) return
	holder.client.screen -= compass
	var/obj/screen/M = compass
	compass = null
	qdel(M)

/datum/modifier/olfaction_track/proc/give_compass()
	if(compass) return

	compass = new()
	compass.mouse_opacity = FALSE
	compass.name = tracked_name
	compass.icon = 'icons/rogue-star/misc96x96.dmi'
	compass.icon_state = "smells-who-knows"

	compass.screen_loc = "CENTER-1,CENTER-1"
	compass.layer = BELOW_MOB_LAYER
	compass.plane = MOB_PLANE - 2

	holder.client.screen += compass

/mob/living/proc/track_target()
	set name = "Track Target"
	set category = "Abilities"
	set desc = "Track the last creature you smelled!"

	var/mob/living/tracked
	var/datum/modifier/olfaction_track/OT
	for(var/datum/modifier/O in modifiers)
		if(O.type != /datum/modifier/olfaction_track)
			continue
		OT = O
		tracked = OT.origin.resolve()
		break
	if(!OT)
		to_chat(src,SPAN_WARNING("You aren't tracking anything! Try smelling something first!"))
		return
	if(!tracked)
		to_chat(src,SPAN_WARNING("You can't smell it anymore... It must have gotten away! You will need to pick up a new scent."))
		OT.expire()
		return
	if(OT.compass)
		to_chat(src,SPAN_DANGER("You stop paying attention to \the [OT.tracked_name]'s smell for now."))
		OT.kill_compass()
		return
	else
		visible_message(runemessage = "sniff sniff...")
		to_chat(src,SPAN_NOTICE("You start paying attention to the smell of \the [OT.tracked_name] again!"))
		OT.give_compass()
		return

	/*

	var/feedback = list()
	feedback += "There are noises of movement "
	var/direction = get_dir(src, tracked)
	if(direction)
		feedback += "towards the [dir2text(direction)], "
		switch(get_dist(src, tracked) / 50)
			if(0 to 0.1)
				feedback += "very close by."
			if(0.1 to 0.2)
				feedback += "close by."
			if(0.2 to 0.4)
				feedback += "some distance away."
			if(0.4 to 0.8)
				feedback += "further away."
			else
				feedback += "far away."
	else // No need to check distance if they're standing right on-top of us
		feedback += "right on top of you."
	to_chat(src,jointext(SPAN_NOTICE(feedback),null))
	*/
