//RS FILE
/obj/joke/doglinizer
	name = "doglinizer"
	desc = "It turns everyone into doglins."
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "notifier"
	plane = PLANE_ADMIN_SECRET
	anchored = TRUE
	alpha = 125

	var/active = FALSE
	var/reversable = FALSE

/obj/joke/doglinizer/attack_ghost(mob/user)
	. = ..()

	if(!user?.client?.holder) return

	var/list/choices = list()
	if(active)
		choices += "Deactivate"
	else
		choices += "Activate"

	if(reversable)
		choices += "Disable Reversable"
	else
		choices += "Enable Reversable"

	var/choice = tgui_alert(user,"This turns every player into a doglin, are you sure you want to click this?","Doglinizer",choices)

	switch(choice)
		if("Deactivate")
			STOP_PROCESSING(SSobj,src)
			active = FALSE
			to_chat(user,SPAN_DANGER("\The [src] has been disabled."))
		if("Activate")
			START_PROCESSING(SSobj,src)
			active = TRUE
			to_chat(user,SPAN_DANGER("\The [src] has been enabled."))
		if("Disable Reversable")
			to_chat(user,SPAN_DANGER("Any new doglins will not be able to be changed back."))
			reversable = FALSE
		if("Enable Reversable")
			to_chat(user,SPAN_NOTICE("Any new doglins will be able to be changed back."))
			reversable = TRUE
		else
			return

/obj/joke/doglinizer/Destroy()
	STOP_PROCESSING(SSobj,src)
	. = ..()

/obj/joke/doglinizer/process()
	for(var/mob/living/L in player_list)
		if(!isliving(L))
			continue
		if(!L.client)
			continue
		if(istype(L,/mob/living/simple_mob/vore/doglin))
			continue
		if(L.transforming)
			continue
		L.doglinize(reversable)

/mob/living/proc/doglinize(var/reversable = TRUE)
	make_jittery(999999)
	if(client)
		animate(client,8 SECONDS,color = "#ff0000")
	transforming = TRUE
	canmove = FALSE
	spawn(10 SECONDS)
		var/turf/where = get_turf(loc)
		var/mob/living/simple_mob/vore/doglin/basic/our_doglin = new(where)
		our_doglin.invisibility = 101
		our_doglin.lay_down()
		ISay("*scream")
		var/ourcolor
		var/obj/item/weapon/card/id/our_id
		if(client)
			ourcolor = rgb(client.prefs.r_skin,client.prefs.g_skin,client.prefs.b_skin)
		if(ishuman(src))
			for(var/obj/item/W in src)
				drop_from_inventory(W)
				if(istype(W,/obj/item/weapon/card/id))
					our_id = W
			regenerate_icons()
		our_doglin.name = real_name
		our_doglin.real_name = real_name
		our_doglin.faction = faction
		if(ourcolor)
			our_doglin.color = ourcolor
			our_doglin.update_icon()
		if(our_id)
			our_id.forceMove(our_doglin)
			our_doglin.myid = our_id
		our_doglin.resize(size_multiplier)
		for(var/obj/belly/B in our_doglin.vore_organs)
			our_doglin.vore_organs -= B
			qdel(B)
		our_doglin.vore_selected = vore_selected
		for(var/obj/belly/B in vore_organs)
			B.forceMove(our_doglin)
			our_doglin.vore_organs |= B
		client.color = null
		our_doglin.ckey = ckey
		our_doglin.invisibility = 0
		if(reversable)
			transforming = FALSE
			canmove = TRUE
			our_doglin.tf_mob_holder = src
		spawn(1)
			forceMove(our_doglin)
		jitteriness = 1
		to_chat(our_doglin, SPAN_OCCULT("Somehow... you're a doglin..."))
		our_doglin.forceMove(where)
