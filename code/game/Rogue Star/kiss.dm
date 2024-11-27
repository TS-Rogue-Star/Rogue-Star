/obj/effect/effect/kiss
	name = "kiss"
	icon = 'icons/effects/effects_rs.dmi'
	icon_state = "kissy" //Thanks to VerySoft for the sprite!
	mouse_opacity = 0
	pass_flags = PASSTABLE | PASSGRILLE | PASSBLOB

/obj/effect/effect/kiss/Initialize()
	. = ..()
	QDEL_IN(src, 15 SECONDS)

/obj/effect/effect/kiss/proc/set_up(var/mob/living/target, var/mob/living/user, var/vore_smooch, var/step_count = 7, var/delay = 5)
	if(!target)
		return
	for(var/i = 1 to step_count)
		if(!loc)
			return
		step_towards(src, target) //IT CHASES YOU. YOU WILL NOT ESCAPE LOVE.
		var/turf/T = get_turf(src)
		if(T == get_turf(target))
			if(!vore_smooch)
				visible_message("[src] leaves a smooch mark on [target]'s cheek!")
				target.adjustBruteLoss(-0.25)
				qdel(src)
			else //vorny version
				visible_message("[src] suddenly opens its lips wide, engulfing [target]")
				//icon_state = "kissy_vore" //Add a sprite change to an animated 'lips opening to engulf the tile' sprite
				user.perform_the_nom(user,target,user,user.vore_selected,1, TRUE) //VORE Variant
				//Add a sleep(30) here of a few seconds to let the sprite go through
				qdel(src)
			break
		sleep(delay)
	sleep(10)
	qdel(src)

/obj/effect/effect/kiss/Move(turf/newloc)
	if(newloc.density)
		return 0
	. = ..()

/obj/effect/effect/kiss/Bump(atom/A)
	return ..()
