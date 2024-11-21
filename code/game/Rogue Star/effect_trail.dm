//Effect trails! Ported from /tg/ and modified to work here.
//Currently (11/23/24) only used for the goliath tendrils. But if you wanted to have an effect that goes to X location or chases Y person and spawns XYZ effects
//This is what ya should use!

//The trail
/obj/effect/temp_visual/effect_trail
	name = "effect trail"
	desc = "An invisible effect, how did you examine this?"
	icon = 'icons/mob/eye.dmi'
	icon_state = "default-eye"
	alpha = 0 //INVIS
	duration = 15 SECONDS
	/// Typepath of our spawned effect
	var/spawned_effect
	/// How often do we spawn our other effect?
	var/spawn_interval = 0.5 SECONDS
	/// How fast we are moving!
	var/movement_delay = 5
	/// What are we chasing?
	var/atom/target
	///Who is firing it, if anyone?
	var/atom/user
	/// Stop spawning if we have this many effects already
	var/max_spawned = 20
	///How many effects we have currently spawned
	var/current_spawned
	/// How far can we go when we are fired?
	var/max_range = 7
	/// Do we home in after we started moving?
	//var/homing = FALSE //Simply do this by setting the target to whoever you want it to home towards.
	/// When should we spawn another effect?
	var/next_spawn_time

/obj/effect/temp_visual/effect_trail/Initialize(loc, target, user)
	. = ..()
	set_up(target, user)

/obj/effect/temp_visual/effect_trail/proc/set_up(target, user)
	if(!target)
		return
	for(var/i = 1 to max_range)
		if(!loc)
			return
		step_towards(src, target) //This is set to the turf higher up so it's not homing!

		if(spawned_effect && (world.time >= next_spawn_time))
			new spawned_effect(src.loc, user)
			next_spawn_time = (world.time + spawn_interval) //If time is currently
			current_spawned += 1 //Add 1 to the current spawned effects.
			if(current_spawned >= max_spawned)
				break

		var/turf/T = get_turf(src)
		if(T == get_turf(target))
			if(spawned_effect) //Always get an effect on the final tile!
				new spawned_effect(src.loc, user)
			break
		sleep(movement_delay)
	sleep(10)
	qdel(src)