/obj/effect/effect/kiss
	name = "kiss"
	icon = 'icons/effects/effects_rs.dmi'
	icon_state = "kissy" //Thanks to VerySoft for the sprite!
	mouse_opacity = 0
	pass_flags = PASSTABLE | PASSGRILLE | PASSBLOB

/obj/effect/effect/kiss/Initialize()
	. = ..()
	QDEL_IN(src, 15 SECONDS)

/obj/effect/effect/kiss/proc/set_up(var/mob/living/target, var/step_count = 7, var/delay = 5)
	if(!target)
		return
	for(var/i = 1 to step_count)
		if(!loc)
			return
		step_towards(src, target) //IT CHASES YOU. YOU WILL NOT ESCAPE LOVE.
		var/turf/T = get_turf(src)
		if(T == get_turf(target))
			visible_message("[src] leaves a smooch mark on [target]'s cheek!")
			target.adjustBruteLoss(-0.25)
			//TODO: Add a smooch sound here.
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
