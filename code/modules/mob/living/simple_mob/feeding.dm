/mob/living/simple_mob/proc/handle_food(var/obj/item/weapon/reagent_containers/food/snacks/O as obj, var/mob/user as mob)
	if(!istype(O, /obj/item/weapon/reagent_containers/food/snacks))
		return ..()
	if(resting)
		to_chat(user, "<span class='notice'>\The [src] is napping, and doesn't respond to \the [O].</span>")
		return
	if(nutrition >= max_nutrition)
		if(user == src)
			to_chat(src, "<span class='notice'>You're too full to eat another bite.</span>")
			return
		to_chat(user, "<span class='notice'>\The [src] seems too full to eat.</span>")
		return

	if(stat)
		return ..()

	user.setClickCooldown(user.get_attack_speed(O))
	if(O.reagents)
		O.reagents.trans_to_mob(src, O.bitesize, CHEM_INGEST)
		adjust_nutrition(O.bitesize * 20)
	O.bitecount ++
	O.On_Consume(src)
	if(O)
		to_chat(user, "<span class='notice'>\The [src] takes a bite of \the [O].</span>")
		if(user != src)
			to_chat(src, "<span class='notice'>\The [user] feeds \the [O] to you.</span>")
	playsound(src, 'sound/items/eatfood.ogg', 75, 1)
