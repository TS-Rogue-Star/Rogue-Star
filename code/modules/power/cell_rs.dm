/obj/item/weapon/cell/attack_self(mob/living/user as mob)
	var/coefficient = 1 // Available to adjust later if needed, adding in a loss on top of how much it drains from the battery feels like a bit much.
// User must be an Electrovore, the cell must have power, and the intent must be set to harm or help when used in hand
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/batterylicker = user
	if(!batterylicker.species.electrovore)
		return
	if(!maxcharge)
		return
	if(batterylicker.a_intent == I_HELP)
		// Charge the battery
		var/totransfer = batterylicker.adjust_nutrition(min(max(100, (batterylicker.nutrition * 0.2)), ((maxcharge - charge) / 15)))
		give(min((totransfer * 15), maxcharge))
		update_icon()

	if(!charge) // May need conditionals for low power situations
		batterylicker.show_message("<span class='warning'>You take a look at \the [src] and notice it has nothing in it!</span>")
		return
	if(batterylicker.a_intent == I_HURT)
		var/totransfer = min(charge,1500)
		batterylicker.adjust_nutrition((totransfer / 15) * coefficient)
		use(totransfer)
		update_icon()
