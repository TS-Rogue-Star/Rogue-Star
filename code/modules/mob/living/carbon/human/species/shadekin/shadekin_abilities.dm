/datum/power/shadekin

/mob/living/carbon/human/is_incorporeal()
	if(ability_flags & AB_PHASE_SHIFTED) //Shadekin
		return TRUE
	return ..()

/////////////////////
///  PHASE SHIFT  ///
/////////////////////
//Visual effect for phase in/out
/obj/effect/temp_visual/shadekin
	randomdir = FALSE
	duration = 5
	icon = 'icons/mob/vore_shadekin.dmi'

/obj/effect/temp_visual/shadekin/phase_in
	icon_state = "tp_in"

/obj/effect/temp_visual/shadekin/phase_out
	icon_state = "tp_out"

/datum/power/shadekin/phase_shift
	name = "Phase Shift (100)"
	desc = "Shift yourself out of alignment with realspace to travel quickly to different areas."
	verbpath = /mob/living/carbon/human/proc/phase_shift
	ability_icon_state = "tech_passwall"

/mob/living/carbon/human/proc/phase_shift()
	set name = "Phase Shift (100)"
	set desc = "Shift yourself out of alignment with realspace to travel quickly to different areas."
	set category = "Shadekin"

	var/area/A = get_area(src)	//RS ADD START
	if(!client?.holder)
		if(A.magic_damp || A.block_phase_shift)
			to_chat(src, "<span class='warning'>You can't do that here!</span>")
			return					//RS ADD END

	var/ability_cost = 100

	var/darkness = 1
	var/turf/T = get_turf(src)
	if(!T)
		to_chat(src,"<span class='warning'>You can't use that here!</span>")
		return FALSE

	if(ability_flags & AB_PHASE_SHIFTING)
		return FALSE

	var/brightness = T.get_lumcount() //Brightness in 0.0 to 1.0
	darkness = 1-brightness //Invert

	var/watcher = 0
	for(var/mob/living/carbon/human/watchers in oview(7,src ))	// If we can see them...
		if(watchers in oviewers(7,src))	// And they can see us...
			if(!(watchers.stat) && !isbelly(watchers.loc) && !istype(watchers.loc, /obj/item/weapon/holder))	// And they are alive and not being held by someone...
				watcher++	// They are watching us!

	ability_cost = CLAMP(ability_cost/(0.01+darkness*2),50, 80)//This allows for 1 watcher in full light
	if(watcher>0)
		ability_cost = ability_cost + ( 15 * watcher )
	if(!(ability_flags & AB_PHASE_SHIFTED))
		log_debug("[src] attempted to shift with [watcher] visible Carbons with a  cost of [ability_cost] in a darkness level of [darkness]")

	var/datum/species/shadekin/SK = species
	if(!istype(SK))
		to_chat(src, "<span class='warning'>Only a shadekin can use that!</span>")
		return FALSE
	else if(stat)
		to_chat(src, "<span class='warning'>Can't use that ability in your state!</span>")
		return FALSE
	else if(shadekin_get_energy() < ability_cost && !(ability_flags & AB_PHASE_SHIFTED))
		to_chat(src, "<span class='warning'>Not enough energy for that ability!</span>")
		return FALSE

	if(!(ability_flags & AB_PHASE_SHIFTED))
		shadekin_adjust_energy(-ability_cost)
	playsound(src, 'sound/effects/stealthoff.ogg', 75, 1)

	if(!T.CanPass(src,T) || loc != T)
		to_chat(src,"<span class='warning'>You can't use that here!</span>")
		return FALSE

	forceMove(T)
	var/original_canmove = canmove
	SetStunned(0)
	SetWeakened(0)
	if(buckled)
		buckled.unbuckle_mob()
	if(pulledby)
		pulledby.stop_pulling()
	stop_pulling()
	stop_aiming(no_message=1)	//RS ADD - no shooting guns while phased out
	emp_act(5)	//RS ADD - do a mostly harmless EMP to turn any communicators and radios off
	canmove = FALSE

	//Shifting in
	if(ability_flags & AB_PHASE_SHIFTED)	//RS EDIT START
		phase_in()
	//Shifting out
	else
		ability_flags |= AB_PHASE_SHIFTED
		ability_flags |= AB_PHASE_SHIFTING
		mouse_opacity = 0
		custom_emote(1,"phases out!")
		name = get_visible_name()

		for(var/obj/belly/B as anything in vore_organs)
			B.escapable = FALSE

		var/obj/effect/temp_visual/shadekin/phase_out/phaseanim = new /obj/effect/temp_visual/shadekin/phase_out(src.loc)
		//RS Add | Chomp port #8267
		phaseanim.pixel_y = (src.size_multiplier - 1) * 16 // Pixel shift for the animation placement
		phaseanim.adjust_scale(src.size_multiplier, src.size_multiplier)
		//Rs Add end
		phaseanim.dir = dir
		alpha = 0
		add_modifier(/datum/modifier/shadekin_phase_vision)
		sleep(5)
		invisibility = INVISIBILITY_SHADEKIN
		see_invisible = INVISIBILITY_SHADEKIN
		see_invisible_default = INVISIBILITY_SHADEKIN //RS Add Chomp port #7484 | CHOMPEdit - Allow seeing phased entities while phased.
		//cut_overlays()
		update_icon()
		alpha = 127

		canmove = original_canmove
		incorporeal_move = TRUE
		density = FALSE
		force_max_speed = TRUE
		ability_flags &= ~AB_PHASE_SHIFTING

//RS EDIT START - Breaking up phase shift so areas can tell shadekin to phase in
/mob/living/carbon/human/proc/phase_in()
	var/original_canmove = canmove			//RS EDIT END

	if(ability_flags & AB_PHASE_SHIFTED)
		ability_flags &= ~AB_PHASE_SHIFTED
		ability_flags |= AB_PHASE_SHIFTING
		mouse_opacity = 1
		name = get_visible_name()
		for(var/obj/belly/B as anything in vore_organs)
			B.escapable = initial(B.escapable)

		//cut_overlays()
		invisibility = initial(invisibility)
		see_invisible = initial(see_invisible)
		see_invisible_default = initial(see_invisible_default)	//RS EDIT
		incorporeal_move = initial(incorporeal_move)
		density = initial(density)
		force_max_speed = initial(force_max_speed)
		update_icon()

		//Cosmetics mostly
		var/obj/effect/temp_visual/shadekin/phase_in/phaseanim = new /obj/effect/temp_visual/shadekin/phase_in(src.loc)
		//RS Add | Chomp port #8267
		phaseanim.pixel_y = (src.size_multiplier - 1) * 16 // Pixel shift for the animation placement
		phaseanim.adjust_scale(src.size_multiplier, src.size_multiplier)
		//Rs Add end
		phaseanim.dir = dir
		alpha = 0
		custom_emote(1,"phases in!")
		sleep(5) //The duration of the TP animation
		canmove = original_canmove
		alpha = initial(alpha)
		remove_modifiers_of_type(/datum/modifier/shadekin_phase_vision)

		//Potential phase-in vore
		if(can_be_drop_pred) //Toggleable in vore panel
			var/list/potentials = living_mobs(0)
			if(potentials.len)
				for(var/mob/living/target in potentials)	//RS EDIT START
					if(istype(target) && spont_pref_check(src,target,SPONT_PRED))
						target.forceMove(vore_selected)
						to_chat(target,"<span class='warning'>\The [src] phases in around you, [vore_selected.vore_verb]ing you into their [vore_selected.name]!</span>")
															//RS EDIT END
		ability_flags &= ~AB_PHASE_SHIFTING

		//Affect nearby lights

		for(var/obj/machinery/light/L in machines)
			if(L.z != z || get_dist(src,L) > 10)
				continue

			if(prob(flicker_break_chance))
				spawn(rand(5,25))
					L.broken()
			else
				if(flicker_time)
					L.flicker(flicker_time, flicker_color) //RS edit - Variable Flicker!

		//Yes. I could do a 'for(var/atom/movable/AM in range(effectrange, turf))' but that would take so much processing power the old gods would come down and smite me. So instead we will check for specific things.

		for(var/obj/item/device/flashlight/flashlights in range(7, src)) //Find any flashlights near us and make them flicker too!
			if(istype(flashlights,/obj/item/device/flashlight/glowstick) ||istype(flashlights,/obj/item/device/flashlight/flare)) //No affecting glowsticks or flares...As funny as that is
				continue
			flashlights.flicker(flicker_time, flicker_color, TRUE)

		for(var/mob/living/creatures in range(7, src))
			for(var/obj/item/device/flashlight/held_lights in creatures.contents)
				if(istype(held_lights,/obj/item/device/flashlight/glowstick) ||istype(held_lights,/obj/item/device/flashlight/flare) ) //No affecting glowsticks or flares...As funny as that is
					continue
				held_lights.flicker(flicker_time, flicker_color, TRUE)

				//do the flicker here
//RS EDIT END

/datum/modifier/shadekin_phase_vision
	name = "Shadekin Phase Vision"
	vision_flags = SEE_THRU

//////////////////////////
///  REGENERATE OTHER  ///
//////////////////////////
/datum/power/shadekin/regenerate_other
	name = "Regenerate Other (50)"
	desc = "Spend energy to heal physical wounds in another creature. Only works while they are alive."	//RS EDIT
	verbpath = /mob/living/carbon/human/proc/regenerate_other
	ability_icon_state = "tech_biomedaura"

/mob/living/carbon/human/proc/regenerate_other()
	set name = "Regenerate Other (50)"
	set desc = "Spend energy to heal physical wounds in another creature."
	set category = "Shadekin"

	var/area/A = get_area(src)	//RS ADD START
	if(A.magic_damp)
		to_chat(src, "<span class='warning'>You can't do that here!</span>")
		return					//RS ADD END

	var/ability_cost = 50

	var/datum/species/shadekin/SK = species
	if(!istype(SK))
		to_chat(src, "<span class='warning'>Only a shadekin can use that!</span>")
		return FALSE
	else if(stat)
		to_chat(src, "<span class='warning'>Can't use that ability in your state!</span>")
		return FALSE
	else if(shadekin_get_energy() < ability_cost)
		to_chat(src, "<span class='warning'>Not enough energy for that ability!</span>")
		return FALSE
	else if(ability_flags & AB_PHASE_SHIFTED)
		to_chat(src, "<span class='warning'>You can't use that while phase shifted!</span>")
		return FALSE

	var/list/viewed = oview(1)
	var/list/targets = list()
	for(var/mob/living/L in viewed)
		if(L.stat != DEAD)	//RS ADD - This was modelled after healbelly in its ability originally, and healbelly can't heal corpses, so, this probably shouldn't either.
			targets += L	//RS ADD
	if(!targets.len)
		to_chat(src,"<span class='warning'>Nobody nearby to mend!</span>")
		return FALSE

	var/mob/living/target = tgui_input_list(src,"Pick someone to mend:","Mend Other", targets)
	if(!target)
		return FALSE

	target.add_modifier(/datum/modifier/shadekin/heal_boop,1 MINUTE)
	playsound(src, 'sound/effects/EMPulse.ogg', 75, 1)
	shadekin_adjust_energy(-ability_cost)
	visible_message("<span class='notice'>\The [src] gently places a hand on \the [target]...</span>")
	face_atom(target)
	return TRUE

/datum/modifier/shadekin/heal_boop
	name = "Shadekin Regen"
	desc = "You feel serene and well rested."
	mob_overlay_state = "green_sparkles"

	on_created_text = "<span class='notice'>Sparkles begin to appear around you, and all your ills seem to fade away.</span>"
	on_expired_text = "<span class='notice'>The sparkles have faded, although you feel much healthier than before.</span>"
	stacks = MODIFIER_STACK_EXTEND

/datum/modifier/shadekin/heal_boop/tick()
	if(!holder.getBruteLoss() && !holder.getFireLoss() && !holder.getToxLoss() && !holder.getOxyLoss() && !holder.getCloneLoss()) // No point existing if the spell can't heal.
		expire()
		return
	holder.adjustBruteLoss(-2)
	holder.adjustFireLoss(-2)
	holder.adjustToxLoss(-2)
	holder.adjustOxyLoss(-2)
	holder.adjustCloneLoss(-2)


//////////////////////
///  CREATE SHADE  ///
//////////////////////
/datum/power/shadekin/create_shade
	name = "Create Shade (25)"
	desc = "Create a field of darkness that follows you."
	verbpath = /mob/living/carbon/human/proc/create_shade
	ability_icon_state = "tech_dispelold"

/mob/living/carbon/human/proc/create_shade()
	set name = "Create Shade (25)"
	set desc = "Create a field of darkness that follows you."
	set category = "Shadekin"

	var/area/A = get_area(src)	//RS ADD START
	if(A.magic_damp)
		to_chat(src, "<span class='warning'>You can't do that here!</span>")
		return					//RS ADD END

	var/ability_cost = 25

	var/datum/species/shadekin/SK = species
	if(!istype(SK))
		to_chat(src, "<span class='warning'>Only a shadekin can use that!</span>")
		return FALSE
	else if(stat)
		to_chat(src, "<span class='warning'>Can't use that ability in your state!</span>")
		return FALSE
	else if(shadekin_get_energy() < ability_cost)
		to_chat(src, "<span class='warning'>Not enough energy for that ability!</span>")
		return FALSE
	else if(ability_flags & AB_PHASE_SHIFTED)
		to_chat(src, "<span class='warning'>You can't use that while phase shifted!</span>")
		return FALSE

	playsound(src, 'sound/effects/bamf.ogg', 75, 1)

	add_modifier(/datum/modifier/shadekin/create_shade,20 SECONDS)
	shadekin_adjust_energy(-ability_cost)
	return TRUE

/datum/modifier/shadekin/create_shade
	name = "Shadekin Shadegen"
	desc = "Darkness envelops you."
	mob_overlay_state = ""

	on_created_text = "<span class='notice'>You drag part of The Dark into realspace, enveloping yourself.</span>"
	on_expired_text = "<span class='warning'>You lose your grasp on The Dark and realspace reasserts itself.</span>"
	stacks = MODIFIER_STACK_EXTEND
	var/mob/living/my_kin // RS Edit: Both simple and carbon (Lira, October 2025)
	// RS Add Start: Track lighting (Lira, October 2025)
	var/old_glow_toggle
	var/old_glow_range
	var/old_glow_intensity
	var/old_glow_color
	var/old_light_range
	var/old_light_power
	var/old_light_color
	var/old_light_on
	// RS Add End

// RS Edit: Ensure ability ends on phase (Lira, October 2025)
/datum/modifier/shadekin/create_shade/tick()
	if(!my_kin)
		my_kin = holder
	if(my_kin && !QDELETED(my_kin) && hasvar(my_kin, "ability_flags") && (my_kin:ability_flags & AB_PHASE_SHIFTED))
		expire()

/datum/modifier/shadekin/create_shade/on_applied()
	my_kin = holder
	// RS Add Start: Track lighting (Lira, October 2025)
	old_glow_toggle = holder.glow_toggle
	old_glow_range = holder.glow_range
	old_glow_intensity = holder.glow_intensity
	old_glow_color = holder.glow_color
	old_light_range = holder.light_range
	old_light_power = holder.light_power
	old_light_color = holder.light_color
	old_light_on = holder.light_on
	// RS Add End
	holder.glow_toggle = TRUE
	holder.glow_range = 8
	holder.glow_intensity = -10
	holder.glow_color = "#FFFFFF"
	holder.set_light(8, -10, "#FFFFFF")

/datum/modifier/shadekin/create_shade/on_expire()
	// RS Edit: Track lighting (Lira, October 2025)
	if(holder)
		holder.glow_toggle = old_glow_toggle
		holder.glow_range = old_glow_range
		holder.glow_intensity = old_glow_intensity
		holder.glow_color = old_glow_color
		var/restore_range = old_light_range
		var/restore_power = old_light_power
		var/restore_color = old_light_color
		var/restore_on = old_light_on
		if(isnull(restore_range))
			restore_range = initial(holder.light_range)
		if(isnull(restore_power))
			restore_power = initial(holder.light_power)
		if(isnull(restore_color))
			restore_color = initial(holder.light_color)
		if(isnull(restore_on))
			restore_on = initial(holder.light_on)
		holder.set_light(restore_range, restore_power, restore_color, restore_on)
	my_kin = null

/// Light flicker adjusments! Allows you to change three things:
/// Flicker Length || Flicker Light Break Chance || Flicker colors
/mob/living/carbon/human/proc/adjust_flicker()
	set name = "Adjust Light Flicker"
	set desc = "Allows you to adjust the settings of the light flicker when you phase in!"
	set category = "Shadekin"

	var/flicker_timer = tgui_input_number(usr, "Adjust how long lights flicker when you phase in! (Min 10 Max 15 in seconds!)", "Set Flicker", 10, 15, 10)
	if(flicker_timer > 15 || flicker_timer < 10)
		to_chat(usr,"<span class='warning'>You must choose a number between 10 and 15</span>")
		return
	flicker_time = flicker_timer
	to_chat(usr,"<span class='warning'>Flicker timer set to [flicker_time] seconds!</span>")

	var/set_new_color = input(src,"Select a color you wish the lights to flicker as (Default is #E0EFF0)","Flicker Color",flicker_color) as color
	if(set_new_color)
		flicker_color = set_new_color
	to_chat(usr,"<span class='warning'>Flicker color set to [flicker_color]!</span>")

	var/break_chance = tgui_input_number(usr, "Adjust the % chance for lights to break when you phase in! (Default 0. Min 0. Max 25)", "Set Break Chance", 0, 25, 0)
	if(break_chance > 25 || break_chance < 0)
		to_chat(usr,"<span class='warning'>You must choose a number between 0 and 25</span>")
		return
	flicker_break_chance = break_chance
	to_chat(usr,"<span class='warning'>Break chance set to [flicker_break_chance]%</span>")

//RS Edit End
