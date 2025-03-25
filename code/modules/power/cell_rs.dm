/obj/item/weapon/cell/attack_self(mob/living/user as mob)
	var/coefficient = 0.9 // Available to adjust later if needed, adding in more than a 10% loss on top of how much it drains your nutrition to refill the battery feels like a bit much.
// User must be an Electrovore, the cell must have power, and the intent must be set to harm or help when used in hand
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/batterylicker = user
	if(!batterylicker.species.electrovore)
		return
	if(!maxcharge)
		return
	if(batterylicker.a_intent == I_HELP && batterylicker.species.organic_food_coeff == 0 && batterylicker.nutrition)
		// Charge the battery
		if(charge == maxcharge)
			return
		user.show_message("<span class='warning'>Power surges from you and flows into \the [src], increasing its charge!</span>")
		user.visible_message("<font color='white'>[user] squeezes \the [src] tightly, and charges it!</font>")
		var/totransfer = min(max(100, (batterylicker.nutrition * 0.2)), ((maxcharge - charge) / 15))
		var/todrain = max(100, (batterylicker.nutrition * 0.2))
		// Takes 20% of normal nutrition (100 of a total of 500 for normal characters) or 20% of current nutrition if above the normal cap
		// Minimum hardcaps at remaining space in the battery, converted to the nutrition equivalent for comparison
		batterylicker.adjust_nutrition(-todrain)
		give(min((totransfer * 15), (maxcharge - charge))) // Compares against remaining space in case of a rounding error
		update_icon()
		return

	if(!charge)
		batterylicker.show_message("<span class='warning'>You take a look at \the [src] and notice it has nothing in it!</span>")
		return
	if(batterylicker.a_intent == I_HURT)
		user.show_message("<span class='warning'>Sparks fly from \the [src] as you drain energy from it!</span>")
		user.visible_message("<font color='red'>[user] causes sparks to emit from \the [src] as it loses its charge!</font>")
		var/totransfer = min(charge,1500)
		batterylicker.adjust_nutrition((totransfer / 15) * coefficient)
		use(totransfer)
		update_icon()
		var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
		s.set_up(3, 0, src)
		s.start()
