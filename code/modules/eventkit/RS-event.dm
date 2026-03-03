GLOBAL_VAR(special_station_name)

/client/proc/toggle_event_verb()
	set category = "Fun"
	set name = "Toggle Event Verb"
	set desc = "Add or remove an event verb from someone"
	set popup_menu = FALSE

	if(!check_rights(R_FUN))
		return
	var/list/possible_verbs = list(
		/mob/living/proc/blue_shift,
		/mob/living/proc/vore_leap_attack,
		/mob/living/proc/sense_ghosts,
		/mob/living/proc/set_size,
		/mob/living/proc/pomf,
		/mob/living/proc/register_home
		)

	var/choice = tgui_input_list(usr, "Which verb would you like to add/remove?", "Event Verb", possible_verbs)

	if(!choice)
		return

	var/list/targets = list()

	for(var/mob/living/l in player_list)
		if(!isliving(l))
			continue
		targets |= l

	var/mob/living/target = tgui_input_list(usr, "Who's verb will you adjust?", "Target", targets)

	if(!target)
		return

	if(choice in target.verbs)
		if(tgui_alert(usr, "[target] has access to [choice] already. Would you like to remove this verb from them?", "Remove Verb",list("No","Yes")) == "Yes")
			target.verbs.Remove(choice)
			if(choice == /mob/living/proc/register_home)
				var/datum/modifier/return_home/mod = target.get_modifier_of_type(/datum/modifier/return_home)
				if(mod)
					mod.expire()
			to_chat(usr,"<span class = 'warning'>Removed [choice] from [target].</span>")
	else
		if(tgui_alert(usr, "Would you like to add [choice] to [target]?", "Add Verb",list("No","Yes")) == "Yes")
			target.verbs.Add(choice)
			to_chat(usr,"<span class = 'warning'>Added [choice] to [target].</span>")

/mob/living/proc/blue_shift()
	set name = "Blue Shift"
	set category = "Abilities"
	set desc = "Toggles ghost-like invisibility (Don't abuse this)"

	if(invisibility == INVISIBILITY_OBSERVER)
		invisibility = initial(invisibility)
		to_chat(src, "<span class='notice'>You are now visible.</span>")
		alpha = max(alpha + 100, 255)
	else
		invisibility = INVISIBILITY_OBSERVER
		to_chat(src, "<span class='danger'><b>You are now as invisible.</b></span>")
		alpha = max(alpha - 100, 0)

	var/datum/effect/effect/system/spark_spread/sparks = new /datum/effect/effect/system/spark_spread()
	sparks.set_up(5, 0, src)
	sparks.attach(loc)
	sparks.start()
	visible_message("<span class='warning'>Electrical sparks manifest from nowhere around \the [src]!</span>")
	qdel(sparks)

/mob/living/proc/vore_leap_attack()
	set name = "Leap"
	set desc = "Leap at a target, eating or stunning them!"
	set category = "Abilities"
	set waitfor = FALSE

	var/list/targets = list()
	for(var/mob/living/L in view(world.view, get_turf(src)))
		if(L == src)
			continue
		if(!isliving(L))
			continue
		if(!L.devourable || !L.throw_vore)
			continue
		targets += L

	if(!targets.len)
		to_chat(src, span("warning","There are no valid targets in range."))

	var/mob/living/choice = tgui_input_list(src, "Pick a target! (Only those with viable mechanical prefs are included)", "Target Choice", targets)

	if(!choice)
		return

	visible_message(span("warning","\The [src]tenses up in preparation to leap!"))
	to_chat(choice, span("danger","\The [src] focuses on you!"))
	// Telegraph, since getting stunned suddenly feels bad.
	do_windup_animation(choice, 1 SECOND)
	sleep(1 SECOND) // For the telegraphing.

	if(choice.z != z)	//Make sure you haven't disappeared to somewhere we can't go
		return FALSE

	// Do the actual leap.
	status_flags |= LEAPING // Lets us pass over everything.
	visible_message(span("critical","\The [src] leaps at \the [choice]!"))
	throw_at(get_step(choice, get_turf(src)), 7, 1, src)
	playsound(src, 'sound/weapons/spiderlunge.ogg', 75, 1)

	sleep(5) // For the throw to complete. It won't hold up the AI ticker due to waitfor being false.

	if(status_flags & LEAPING)
		status_flags &= ~LEAPING // Revert special passage ability.

	if(Adjacent(choice))	//We leapt at them but we didn't manage to hit them, let's see if we're next to them
		choice.Weaken(2)	//get knocked down, idiot

/mob/living/proc/sense_ghosts()
	set name = "Sense Incorporeal Beings"
	set desc = "Sense if there is a ghost nearby!"

	if(stat || paralysis || weakened || stunned) //Can't focus on ghosts if you're weakened/occupied
		to_chat(src, "<span class='warning'>You can't do that in your current state.</span>")
		return

	var/mob/observer/dead/spook = locate() in range(src, 3) //Locate any ghosts in 3 tiles
	if(spook)
		var/turf/T = get_turf(spook)
		var/list/visible = list()
		for(var/obj/O in T.contents)
			if(!O.invisibility && O.name)
				visible += O
		if(visible.len)
			var/atom/A = pick(visible) //Pick a ghost that has something nearby
			to_chat(src, "<span class='notice'>You sense something is[istype(A) ? " near [A]":""].</span>")
		else //Otherwise, you are merely in the presence of something spooky
			to_chat(src, "<span class='notice'>You sense something is nearby.</span>")
	else 	//Nothing spooky here!
		to_chat(src, "<span class='notice'>Nothing seems to be nearby.</span>")

/client/proc/change_station_name()
	set category = "Fun"
	set name = "Change Station Name"
	set desc = "Change what it says in the top left of everyone's client"

	if(!check_rights(R_FUN))
		return

	var/newname = input(usr,"What would you like to change the name to?", "Name change",GLOB.special_station_name)

	if(newname)
		if(tgui_alert(usr, "Are you sure you want to change the name to Rogue Star: [newname]?", "Change Station name",list("Yes","No")) == "Yes")
			log_and_message_admins("[key_name_admin(usr)] changed the station name from \"[GLOB.special_station_name]\" to \"[newname]\".")
			GLOB.special_station_name = newname
			for(var/mob/M in player_list)
				if(M.client)
					M.client.update_special_station_name()

/mob/living/proc/pomf()
	set name = "Pomf"
	set desc = "Pomf them!"
	set category = "Abilities"
	set waitfor = FALSE

	visible_message(SPAN_DANGER("\The [src] cries out!!!"))
	playsound(src, 'sound/effects/bang.ogg', 75, 1)

	for(var/mob/living/L in view(world.view, get_turf(src)))
		if(!isliving(L))
			continue
		if(L == usr)
			continue

		L.AdjustStunned(3)
		L.AdjustWeakened(3)
		to_chat(L,SPAN_WARNING("\The [src]'s call knocks you to the ground!"))

/client/proc/summon()
	set name = "Summon"
	set desc = "Summon them!"
	set category = "Fun"
	set waitfor = FALSE

	if(!check_rights(R_ADMIN|R_MOD|R_DEBUG|R_EVENT))
		return
	if(!config.allow_admin_jump)
		to_chat(usr, "Admin jumping disabled")
		return

	var/choice = tgui_alert(usr, "What range do you want to summon people at?","Summoning",list("Cancel","This Z","Global"))

	if(!choice || choice == "Cancel") return

	var/turf/T = get_turf(usr)
	playsound(mob, 'sound/effects/genetics.ogg', 75, 1)
	for(var/mob/living/L in player_list)
		if(!isliving(L))	//Don't summon ghosts or whatever
			continue
		if(L == usr)		//Don't summon yourself
			continue
		if(isbelly(L.loc))	//their pred will get asked instead
			continue
		if(choice == "This Z")	//Extra logic for only affecting people on the same Z
			var/turf/ourturf = get_turf(L)	//In case someone is hidden in a state where they are not technically on a turf, such as closets, reagent containers, etc
			if(T.z != ourturf.z)
				continue

		SEND_SOUND(src, sound('sound/misc/server-ready.ogg'))
		tgui_alert_async(L, "\The [usr] is summoning you to their location. Would you like to join them?", "Summoning", list("Yes", "No"), CALLBACK(src, PROC_REF(summon_reply),L,T), null)

/client/proc/summon_reply(var/mob/living/L,var/turf/T,response)
	if(!response) return
	if(response != "Yes") return
	if(!L) return
	if(!T) return
	L.forceMove(T)

/obj/item/weapon/material/sword/wind_blade
	name = "wind blade"
	desc = "A beautiful elegant blade covered in impossibly intricate designs and polished to a mirror shine. It is extremely sharp."
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "wind_blade"
	applies_material_colour = FALSE
	slot_flags = SLOT_BELT | SLOT_BACK
	can_cleave = TRUE

	item_icons = list(
			slot_l_hand_str = 'icons/mob/items/lefthand_melee_rs.dmi',
			slot_r_hand_str = 'icons/mob/items/righthand_melee_rs.dmi',
			slot_back_str = 'icons/rogue-star/custom_onmob_back.dmi',
			slot_belt_str = 'icons/rogue-star/custom_onmob_belt.dmi'
			)

	var/obj/item/projectile/projectile_type = /obj/item/projectile/sword_beam
	var/next_fire_time = 0
	var/shoot_cooldown = 3

/obj/item/weapon/material/sword/wind_blade/pre_attack(mob/living/target, mob/living/user)
	. = ..()
	if(user.a_intent == I_HELP)
		return
	shoot_beam(target,user,shoot_cooldown)

/obj/item/weapon/material/sword/wind_blade/proc/shoot_beam(mob/living/target, mob/living/user, var/cooldown)

	if(!user || !target) return
	if(target.z != user.z) return

	add_fingerprint(user)

	user.break_cloak()

	if(world.time < next_fire_time)
		if (world.time % 3) //to prevent spam
			to_chat(user, "<span class='warning'>[src] is not ready to fire again!</span>")
		return


	if(cooldown)
		next_fire_time = world.time + cooldown SECONDS

	user.face_atom(target)

	var/obj/item/projectile/P = new projectile_type(get_turf(src))
	if(!P)
		return

	P.launch_projectile(target = target, target_zone = null, user = src, params = null, angle_override = null, forced_spread = 0)

/obj/item/projectile/sword_beam
	name = "sword beam"
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "sword_slash"
	fire_sound = 'sound/effects/bang.ogg'
	damage = 8
	damage_type = BRUTE
	check_armour = "melee"

	impact_effect_type = /obj/effect/temp_visual/impact_effect/blue_laser
	hitsound_wall = 'sound/effects/bang.ogg'
	speed = 2

/client/proc/add_trait()
	set name = "Add Trait"
	set category = "Fun"

	if(!check_rights(R_FUN)) return

	var/choice = tgui_input_list(usr,"Who will you apply the trait to?","Apply Trait",player_list)
	if(!choice) return
	if(!ishuman(choice))
		to_chat(usr,SPAN_WARNING("\The [choice] can't take traits."))
		return
	var/mob/living/carbon/human/H = choice
	choice = null
	//var/list/ourtraits = subtypesof(/datum/trait)
	choice = tgui_input_list(usr, "What trait will you apply to [H]?","Apply Trait",all_traits)
	if(!choice) return

	var/datum/trait/ourtrait = new choice()
	ourtrait.apply(H.species,H,H.species.traits[ourtrait])

	log_and_message_admins("has applied trait: [ourtrait] ([choice]) to [H].")

/obj/trait_adder
	name = "trait_adder"
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "crystal_key"

	plane = PLANE_ADMIN_SECRET

	var/trait

/obj/trait_adder/Crossed(O)
	. = ..()
	if(!trait) return
	if(!ishuman(O)) return

	var/mob/living/carbon/human/H = O
	var/datum/trait/ourtrait = new trait()
	ourtrait.apply(H.species,H,H.species.traits[ourtrait])
	log_debug("\The [src] has applied trait: [ourtrait] ([trait]) to [H].")
	to_chat(H,SPAN_NOTICE("[ourtrait] was added to your traits! You feel your abilities expand!! You get the feeling this change will fade later."))
	H << 'sound/effects/ding.ogg'

/atom/movable/notifier
	name = "notifier"
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "notifier"
	plane = PLANE_ADMIN_SECRET
	anchored = TRUE
	alpha = 125
	var/list/notify_who = list()

/atom/movable/notifier/attack_ghost(mob/user)
	. = ..()

	if(!user?.client?.holder) return

	if(user.ckey in notify_who)
		remove_notification(user)
	else
		add_notification(user)

/atom/movable/notifier/proc/add_notification(var/mob/M)
	if(!M) return
	if(!M.ckey) return

	notify_who.Add(M.ckey)
	to_chat(M,SPAN_NOTICE("Added you to the notification list."))

/atom/movable/notifier/proc/remove_notification(var/mob/M)
	if(!M) return
	if(!M.ckey) return

	notify_who.Remove(M.ckey)
	to_chat(M,SPAN_WARNING("Removed you from the notification list."))

/atom/movable/notifier/Crossed(O)
	. = ..()
	if(isobserver(O)) return	//Let's not trigger on ghosts
	for(var/mob/M in player_list)
		if(M.ckey in notify_who)
			M << 'sound/rogue-star/misc/ghost_alert.ogg'
			to_chat(M,SPAN_WARNING("[O] HAS CROSSED [src]"))
