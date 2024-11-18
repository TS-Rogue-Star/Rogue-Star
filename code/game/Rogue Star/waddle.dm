//This file contains a (heavily) modified version of the Bubberstation waddle.

/atom/movable
	var/waddling = 0
	var/waddle_z = 0.5
	var/waddle_min = -4
	var/waddle_max = 4
	var/waddle_time = 2

/datum/client_preference/waddling
	description = "Waddling"
	key = "WADDLE_TOGGLE"
	enabled_description = "Enabled"
	disabled_description = "Disabled"

/client/verb/toggle_waddle()
	set name = "Toggle Waddling"
	set desc = "Allows you to toggle if you want to walk with a waddle or not!"
	set category = "Preferences"
	var/pref_path = /datum/client_preference/waddling
	toggle_preference(pref_path)
	to_chat(src, "You will [ (is_preference_enabled(pref_path)) ? "now" : "no longer"] waddle.")

	SScharacter_setup.queue_preferences_save(prefs)

	feedback_add_details("admin_verb","TWaddle")

/mob/living/proc/waddle_debug() //Debug tool to debug waddling.
	set name = "WADDLE DEBUG"
	set desc = "Allows you to debug waddling!!"
	set category = "Preferences"

	var/Z = input("Desired Z.", "Set Depth", 0.5) as num
	waddle_z = Z
	var/min = input("Desired min.", "Set Depth", -4) as num
	waddle_min = min
	var/max = input("Desired max.", "Set Depth", 4) as num
	waddle_max = max
	var/time = input("Desired time.", "Set Depth", 2) as num
	waddle_time = time
	to_chat(usr, "z = [Z] min = [min] max = [max] time = [time]")


/mob/living/proc/waddling_animation(atom/movable/target) //Waddling code done here to cause less potential conflicts with base code.
	//NOTE: The defaults are set to their respective values as that's what feels realistic without being comical!
	var/prev_pixel_z = target.pixel_z
	var/waddle_z = target.waddle_z //Default is 0.5. You generally don't want to change this or the person will be bouncing!
	var/min = target.waddle_min //Default -4 How far back the sprite leans!
	var/max = target.waddle_max //Default 4 How far forward the sprite leans!
	var/wad_time = waddle_time //Default 2 How long it takes to for the animation to finish! Two is pretty good.

	if(isliving(target))
		var/mob/living/waddler = target
		if(waddler.confused) //Confused? Lean forwards and back further!
			min -= 4
			max += 4
		if(waddler.druggy) //Druggy? Lean forwards and back even more! And movement animations a bit slower for you
			min -= 8
			max += 8
			wad_time += 1
		if(waddler.drowsyness) //Drowsy? Don't lean back at all, lean forwards much more, and take longer for animations to run!
			min += 4
			max += 16
			wad_time += 3
		if(waddler.hallucination) //Hallucinating? Shorter time to make you look twitchy!
			min -= 10
			max += 10
			wad_time -= 1
		for(var/datum/reagent/R in reagents.reagent_list)
			if(R.id in tachycardics)
				waddle_z += 3

	animate(target, pixel_z = target.pixel_z + waddle_z, time = 0)
	var/prev_transform = target.transform //The person's default state.
	animate(pixel_z = prev_pixel_z, transform = turn(target.transform, pick(min, 0, max)), time=wad_time)
	animate(transform = prev_transform, time = 0)
