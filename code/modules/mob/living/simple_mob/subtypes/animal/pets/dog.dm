/mob/living/simple_mob/animal/passive/dog
	name = "dog"
	real_name = "dog"
	desc = "It's a dog."
	tt_desc = "E Canis lupus familiaris"
	icon_state = "corgi"
	icon_living = "corgi"
	icon_dead = "corgi_dead"

	health = 20
	maxHealth = 20

	response_help  = "pets"
	response_disarm = "bops"
	response_harm   = "kicks"

	mob_size = MOB_SMALL

	has_langs = list("Dog")

	say_list_type = /datum/say_list/dog

	meat_amount = 3
	meat_type = /obj/item/weapon/reagent_containers/food/snacks/meat/corgi

	var/obj/item/inventory_head
	var/obj/item/inventory_back


/mob/living/simple_mob/animal/passive/dog/attackby(var/obj/item/O as obj, var/mob/user as mob)
	if(istype(O, /obj/item/weapon/newspaper))
		if(!stat)
			for(var/mob/M in viewers(user, null))
				if ((M.client && !( M.blinded )))
					M.show_message("<font color='blue'>[user] baps [name] on the nose with the rolled up [O]</font>")
			spawn(0)
				for(var/i in list(1,2,4,8,4,2,1,2))
					set_dir(i)
					sleep(1)
	else
		..()

// Update attributes based on the dog fashions of equipped items. (name is historical, works on all dogs)
/mob/living/simple_mob/animal/passive/dog/proc/update_corgi_fluff()
	// First, change back to defaults
	name = real_name
	desc = initial(desc)
	if(say_list_type)
		say_list = new say_list_type(src)
	set_light(0)
	min_oxy = initial(min_oxy)
	max_oxy = initial(max_oxy)
	min_tox = initial(min_tox)
	max_tox = initial(max_tox)
	min_co2 = initial(min_co2)
	max_co2 = initial(max_co2)
	min_n2 = initial(min_n2)
	max_n2 = initial(max_n2)
	minbodytemp = initial(minbodytemp)
	maxbodytemp = initial(maxbodytemp)

	// Next apply properties from equipped inventory items
	for(var/inventory_item in list(inventory_head, inventory_back))
		var/fashion_type
		if(inventory_item && (fashion_type = get_dog_fashion(inventory_item)))
			var/datum/dog_fashion/DF = new fashion_type(src)
			DF.apply(src)

/mob/living/simple_mob/animal/passive/dog/update_icon()
	. = ..()
	if(inventory_head)
		var/fashion_type = get_dog_fashion(inventory_head)
		if(fashion_type)
			var/datum/dog_fashion/DF = new fashion_type(src)
			var/image/head_icon
			if(health <= 0)
				// Old way was head_icon_state += "2"
				head_icon = DF.get_overlay(inventory_head, dir = EAST)
				head_icon.pixel_y = -8
				head_icon.transform = turn(head_icon.transform, 180)
			else
				head_icon = DF.get_overlay(inventory_head)

			add_overlay(head_icon)

	if(inventory_back)
		var/fashion_type = get_dog_fashion(inventory_back)
		if(fashion_type)
			var/image/back_icon
			var/datum/dog_fashion/DF = new fashion_type(src)

			if(health <= 0)
				// Old way was back_icon_state += "2"
				back_icon = DF.get_overlay(inventory_back, dir = EAST)
				back_icon.pixel_y = -11
				back_icon.transform = turn(back_icon.transform, 180)
			else
				back_icon = DF.get_overlay(inventory_back)
			add_overlay(back_icon)

	return


/mob/living/simple_mob/animal/passive/dog/show_inv(mob/user)
	if(user.incapacitated() || !Adjacent(user))
		return
	user.set_machine(src)

	var/dat = {"
	<div align='center'><b>Inventory of [name]</b></div><p>
	<br><B>Head:</B> <A href='?src=\ref[src];[inventory_head ? "remove_inv=head'>[inventory_head]" : "add_inv=head'>Nothing"]</A>
	<br><B>Back:</B> <A href='?src=\ref[src];[inventory_back ? "remove_inv=back'>[inventory_back]" : "add_inv=back'>Nothing"]</A>
	<br><A href='?src=\ref[user];refresh=1'>Refresh</A>
	<br><A href='?src=\ref[user];mach_close=mob[name]'>Close</A>
	<br>"}
	// user << browse(dat, text("window=dog\ref[src];size=325x500", name))
	// onclose(user, "dog\ref[src]")
	var/datum/browser/popup = new(user, "mob\ref[src]", "[src]", 440, 250)
	popup.set_content(dat)
	popup.open()
	return

// Lookup the dog fashion datum for an item. We do this instead of a variable on obj/item
/mob/living/simple_mob/animal/passive/dog/proc/get_dog_fashion(var/obj/item/clothing/I)
	if(istype(I)) 
		return I.dog_fashion
	if(istype(I))
		return /obj/item/weapon/paper
	// TODO - Put obj/item/var/dog_fashion_type
	if(istype(I, /obj/item/clothing/head/caphat/hop))
		return /datum/dog_fashion/head/hop;
	if(istype(I, /obj/item/clothing/head/that))
		return /datum/dog_fashion/head;
	return null

/mob/living/simple_mob/animal/passive/dog/Topic(href, href_list)
	if(!(iscarbon(usr) || isrobot(usr)) || usr.incapacitated() || !Adjacent(usr))
		usr << browse(null, "window=mob\ref[src]")
		usr.unset_machine()
		return

	//Removing from inventory
	if(href_list["remove_inv"])
		var/remove_from = href_list["remove_inv"]
		switch(remove_from)
			if("head")
				if(inventory_head)
					// TODO - Fix unEquip etc to work on all mobs.
					usr.put_in_hands(inventory_head)
					inventory_head = null
					update_corgi_fluff()
					update_icon()
				else
					to_chat(usr, "<span class='danger'>There is nothing to remove from its [remove_from].</span>")
					return
			if("back")
				// TODO - Fix unEquip etc to work on all mobs.
				if(inventory_back)
					usr.put_in_hands(inventory_back)
					inventory_back = null
					update_corgi_fluff()
					update_icon()
				else
					to_chat(usr, "<span class='danger'>There is nothing to remove from its [remove_from].</span>")
					return

		show_inv(usr)

	//Adding things to inventory
	else if(href_list["add_inv"])
		var/add_to = href_list["add_inv"]

		switch(add_to)
			if("head")
				if(place_on_head(usr.get_active_hand(), usr))
					update_corgi_fluff()
					update_icon()

			if("back")
				if(place_on_back(usr.get_active_hand(), usr))
					update_corgi_fluff()
					update_icon()

		show_inv(usr)
	else
		return ..()


//Corgis are supposed to be simpler, so only a select few objects are compatible with them.
/mob/living/simple_mob/animal/passive/dog/proc/place_on_head(obj/item/item_to_add, mob/user)
	if(inventory_head)
		to_chat(user, "<span class='warning'>You can't put more than one hat on [src]!</span>")
		return

	if(!item_to_add)
		user.visible_message("<span class='notice'>[user] pets [src].</span>", "<span class='notice'>You rest your hand on [src]'s head for a moment.</span>")
		return

	if(!user.unEquip(item_to_add))
		to_chat(user, "<span class='warning'>\The [item_to_add] is stuck to your hand, you cannot put it on [src]'s head!</span>")
		return

	var/fashion_type = get_dog_fashion(item_to_add)
	if(ispath(fashion_type, /datum/dog_fashion/head))
		to_chat(user, "<span class='notice'>You set [item_to_add] on [src]'s head.</span>")
		item_to_add.forceMove(src)
		inventory_head = item_to_add
		return TRUE
	else
		to_chat(user, "<span class='warning'>You set [item_to_add] on [src]'s head, but it falls off!</span>")
		item_to_add.forceMove(drop_location())
		if(prob(25))
			step_rand(item_to_add)
	return

/mob/living/simple_mob/animal/passive/dog/proc/place_on_back(obj/item/item_to_add, mob/user)
	if(inventory_back)
		to_chat(user, "<span class='warning'>[src] is already wearing something!</span>")
		return

	if(!item_to_add)
		user.visible_message("<span class='notice'>[user] pets [src].</span>", "<span class='notice'>You rest your hand on [src]'s back for a moment.</span>")
		return

	if(!user.unEquip(item_to_add))
		to_chat(user, "<span class='warning'>\The [item_to_add] is stuck to your hand, you cannot put it on [src]'s back!</span>")
		return

	//The objects that corgis can wear on their backs.
	var/fashion_type = get_dog_fashion(item_to_add)
	if(ispath(fashion_type, /datum/dog_fashion/back))
		to_chat(user, "<span class='notice'>You set [item_to_add] on [src]'s back.</span>")
		item_to_add.forceMove(src)
		inventory_back = item_to_add
		return TRUE
	else
		to_chat(user, "<span class='warning'>You set [item_to_add] on [src]'s back, but it falls off!</span>")
		item_to_add.forceMove(drop_location())
		if(prob(25))
			step_rand(item_to_add)
	return



/obj/item/weapon/reagent_containers/food/snacks/meat/corgi
	name = "corgi meat"
	desc = "Tastes like... well, you know..."




/datum/say_list/dog
	speak = list("YAP", "Woof!", "Bark!", "AUUUUUU")
	emote_hear = list("barks", "woofs", "yaps","pants")
	emote_see = list("shakes its head", "shivers")

// This exists so not every type of dog has to be a subtype of corgi, and in case we get more dog sprites
/mob/living/simple_mob/animal/passive/dog/corgi
	name = "corgi"
	real_name = "corgi"
	desc = "It's a corgi."
	tt_desc = "E Canis lupus familiaris"
	icon_state = "corgi"
	icon_living = "corgi"
	icon_dead = "corgi_dead"

/mob/living/simple_mob/animal/passive/dog/corgi/puppy
	name = "corgi puppy"
	real_name = "corgi"
	desc = "It's a corgi puppy."
	icon_state = "puppy"
	icon_living = "puppy"
	icon_dead = "puppy_dead"

//pupplies cannot wear anything.
/mob/living/simple_mob/animal/passive/dog/corgi/puppy/Topic(href, href_list)
	if(href_list["remove_inv"] || href_list["add_inv"])
		to_chat(usr, "<font color='red'>You can't fit this on [src]</font>")
		return
	..()

/mob/living/simple_mob/animal/passive/dog/corgi/puppy/Bockscar
	name = "Bockscar"
	real_name = "Bockscar"

//IAN! SQUEEEEEEEEE~
/mob/living/simple_mob/animal/passive/dog/corgi/Ian
	name = "Ian"
	real_name = "Ian"	//Intended to hold the name without altering it.
	gender = MALE
	desc = "It's a corgi."
	var/turns_since_scan = 0
	var/obj/movement_target
	makes_dirt = FALSE	//VOREStation edit: no more dirt

/mob/living/simple_mob/animal/passive/dog/corgi/Ian/Life()
	..()

	//Not replacing with SA FollowTarget mechanics because Ian behaves... very... specifically.

	//Feeding, chasing food, FOOOOODDDD
	if(!stat && !resting && !buckled)
		turns_since_scan++
		if(turns_since_scan > 5)
			turns_since_scan = 0
			if((movement_target) && !(isturf(movement_target.loc) || ishuman(movement_target.loc) ))
				movement_target = null
			if( !movement_target || !(movement_target.loc in oview(src, 3)) )
				movement_target = null
				for(var/obj/item/weapon/reagent_containers/food/snacks/S in oview(src,3))
					if(isturf(S.loc) || ishuman(S.loc))
						movement_target = S
						break
			if(movement_target)
				step_to(src,movement_target,1)
				sleep(3)
				step_to(src,movement_target,1)
				sleep(3)
				step_to(src,movement_target,1)

				if(movement_target)		//Not redundant due to sleeps, Item can be gone in 6 decisecomds
					if (movement_target.loc.x < src.x)
						set_dir(WEST)
					else if (movement_target.loc.x > src.x)
						set_dir(EAST)
					else if (movement_target.loc.y < src.y)
						set_dir(SOUTH)
					else if (movement_target.loc.y > src.y)
						set_dir(NORTH)
					else
						set_dir(SOUTH)

					if(isturf(movement_target.loc) )
						UnarmedAttack(movement_target)
					else if(ishuman(movement_target.loc) && prob(20))
						visible_emote("stares at the [movement_target] that [movement_target.loc] has with sad puppy eyes.")

		if(prob(1))
			visible_emote(pick("dances around","chases their tail"))
			spawn(0)
				for(var/i in list(1,2,4,8,4,2,1,2,4,8,4,2,1,2,4,8,4,2))
					set_dir(i)
					sleep(1)

//LISA! SQUEEEEEEEEE~
/mob/living/simple_mob/animal/passive/dog/corgi/Lisa
	name = "Lisa"
	real_name = "Lisa"
	gender = FEMALE
	desc = "It's a corgi with a cute pink bow."
	icon_state = "lisa"
	icon_living = "lisa"
	icon_dead = "lisa_dead"
	response_help  = "pets"
	response_disarm = "bops"
	response_harm   = "kicks"
	var/turns_since_scan = 0
	var/puppies = 0

//Lisa already has a cute bow!
/mob/living/simple_mob/animal/passive/dog/corgi/Lisa/Topic(href, href_list)
	if(href_list["remove_inv"] || href_list["add_inv"])
		to_chat(usr, "<font color='red'>[src] already has a cute bow!</font>")
		return
	..()

/mob/living/simple_mob/animal/passive/dog/corgi/Lisa/Life()
	..()

	if(!stat && !resting && !buckled)
		turns_since_scan++
		if(turns_since_scan > 15)
			turns_since_scan = 0
			var/alone = TRUE
			var/ian = FALSE
			for(var/mob/M in oviewers(7, src))
				if(istype(M, /mob/living/simple_mob/animal/passive/dog/corgi/Ian))
					if(M.client)
						alone = FALSE
						break
					else
						ian = M
				else
					alone = FALSE
					break
			if(alone && ian && puppies < 4)
				if(near_camera(src) || near_camera(ian))
					return
				new /mob/living/simple_mob/animal/passive/dog/corgi/puppy(loc)

		if(prob(1))
			visible_emote(pick("dances around","chases her tail"))
			spawn(0)
				for(var/i in list(1,2,4,8,4,2,1,2,4,8,4,2,1,2,4,8,4,2))
					set_dir(i)
					sleep(1)

// Tamaskans
/mob/living/simple_mob/animal/passive/dog/tamaskan
	name = "tamaskan"
	real_name = "tamaskan"
	desc = "It's a tamaskan."
	icon_state = "tamaskan"
	icon_living = "tamaskan"
	icon_dead = "tamaskan_dead"

/mob/living/simple_mob/animal/passive/dog/tamaskan/Spice
	name = "Spice"
	real_name = "Spice"	//Intended to hold the name without altering it.
	gender = FEMALE
	desc = "It's a tamaskan, the name Spice can be found on its collar."