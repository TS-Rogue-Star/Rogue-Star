/obj/item/weapon/cell/attack_self(mob/living/user as mob)
	var/coefficient = 1 // Available to adjust later if needed, adding in a loss on top of how much it drains your nutrition to refill the battery feels like a bit much.
// User must be an Electrovore, the cell must have power, and the intent must be set to harm or help when used in hand
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/batterylicker = user
	if(!batterylicker.species.electrovore)
		return
	if(!maxcharge)
		return
	if(batterylicker.a_intent == I_HELP && batterylicker.species.organic_food_coeff == 0)
		// Charge the battery
		user.show_message("<span class='warning'>Power surges from your fingertips and flows into \the [src], increasing its charge!</span>")
		user.visible_message("<font color='white'>[user] squeezes \the [src] tightly, and charges it!</font>")
		var/totransfer = batterylicker.adjust_nutrition(-(min(max(100, (batterylicker.nutrition * 0.2)), ((maxcharge - charge) / 15))))
		give(min(abs(totransfer * 15), maxcharge))
		update_icon()
		return

	if(!charge) // May need conditionals for low power situations
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
