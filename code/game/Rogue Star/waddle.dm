//This file contains a (heavily) modified version of the Bubberstation waddle.

/atom/movable
	var/waddling = 0
	var/waddle_z = 0.5
	var/waddle_min = -4
	var/waddle_max = 4
	var/waddle_time = 2

/mob/living
	var/waddler = 0 //Off by default.
/*
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

//NOTES: If you want it to be preference based, uncomment this segment and add
// "if(client && client.is_preference_enabled(/datum/client_preference/waddling))""
// Inside of living_movement.dm in the /mob/living/Move() proc!


*/

/mob/living/silicon/robot/verb/robot_waddle_toggle()
	set name = "Toggle Waddling"
	set desc = "Allows you to toggle if you want to walk with a waddle or not!"
	set category = "Preferences"
	waddler = !waddler
	to_chat(src, "You will [ (waddler) ? "now" : "no longer"] waddle.")

/mob/living/silicon/robot/verb/robot_waddle_adjust()
	set name = "Waddle Adjust"
	set desc = "Allows you to adjust your waddling."
	set category = "Preferences"
	waddle_adjust()

/mob/living/proc/waddle_debug() //Debug tool to debug waddling.
	set name = "WADDLE DEBUG"
	set desc = "Allows you to debug waddling!!"
	set category = "Preferences"

	var/Z = input("Desired Z.", "Set Z", 0.5) as num
	waddle_z = Z
	var/min = input("Desired min.", "Set min", -4) as num
	waddle_min = min
	var/max = input("Desired max.", "Set max", 4) as num
	waddle_max = max
	var/time = input("Desired time.", "Set time", 2) as num
	waddle_time = time
	to_chat(usr, "z = [Z] min = [min] max = [max] time = [time]")

/mob/living/proc/waddle_adjust()
	set name = "Waddle Adjust"
	set desc = "Allows you to adjust your waddling."
	set category = "Preferences"

	var/Z_height = tgui_input_number(usr, "Put the desired waddle height. (0.5 is default. 0 min 4 max)", "Set Height", 0.5, 4, 0)
	if(Z_height > 4 || Z_height < 0 )
		to_chat(usr, "<span class='notice'>Invalid height!</span>")
		return
	waddle_z = Z_height

	var/min = tgui_input_number(usr, "Put the desired waddle backwards lean. (-4 is default. -12 min, 0 max)", "Set Back Lean", -4, 0, -12)
	if(min < -12 || min > 0 )
		to_chat(usr, "<span class='notice'>Invalid number!</span>")
		return
	waddle_min = min

	var/max = tgui_input_number(usr, "Put the desired waddle forwards lean. (4 is default. 0 min, 12 max)", "Set Forwards Lean", 4, 12, 0)
	if(max > 12 || max < 0 )
		to_chat(usr, "<span class='notice'>Invalid number!</span>")
		return
	waddle_max = max

	var/time = tgui_input_number(usr, "Put the desired waddle animation time. (2 is default. 1 min, 2 max)", "Set Time", 2, 2, 1)
	if(time > 2 || time < 1 )
		to_chat(usr, "<span class='notice'>Invalid number!</span>")
		return
	waddle_time = time
	to_chat(usr, "You have set your waddle height to [waddle_z], your back lean to [waddle_min], your forward lean to [waddle_max] and your waddle time to [waddle_time]")
	waddler = 1 //Activate it!

/mob/living/proc/waddling_animation(atom/movable/target) //Waddling code done here to cause less potential conflicts with base code.
	//NOTE: The defaults are set to their respective values as that's what feels realistic without being comical!
	var/prev_pixel_z = target.pixel_z
	var/waddle_z = target.waddle_z //Default is 0.5. You generally don't want to change this or the person will be bouncing!
	var/min = target.waddle_min //Default -4 How far back the sprite leans!
	var/max = target.waddle_max //Default 4 How far forward the sprite leans!
	var/wad_time = waddle_time //Default 2 How long it takes to for the animation to finish! Two is pretty good.
/* //Commented out. Code to enable drugs to affect waddle.
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
*/

	animate(target, pixel_z = target.pixel_z + waddle_z, time = 0)
	var/prev_transform = target.transform //The person's default state.
	animate(pixel_z = prev_pixel_z, transform = turn(target.transform, pick(min, 0, max)), time=wad_time)
	animate(transform = prev_transform, time = 0)
