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
	if(ishuman(holder))
		var/mob/living/carbon/human/H = holder
		name = H.get_visible_name()

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
	if(ishuman(holder))
		var/mob/living/carbon/human/H = holder
		name = H.get_visible_name()
