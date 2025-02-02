/obj/item/clothing/head/fluff/sari
	name = "fancy parade hat"
	desc = "A truly fancy parade hat, for those with excellence in captaincy, and definately didnt get their license out of a box of cap'n crumch's cereal"
	icon = 'code/game/Rogue Star/icons/fluff/sari_adjusted.dmi'
	icon_state = "hat"
	icon_override = 'code/game/Rogue Star/icons/fluff/sari_adjusted.dmi'
	item_state = "hat_mob"

/obj/item/clothing/under/fluff/sari
	name = "Captains R.I.G. jacket"
	desc = "A set of clothes and jacket with an integrated R.I.G. link, displaying user health on the back."
	icon = 'code/game/Rogue Star/icons/fluff/sari_adjusted.dmi'
	icon_override = 'code/game/Rogue Star/icons/fluff/sari_adjusted.dmi'
	icon_state = "undershirt"
	worn_state = "undershirt_mob"
	item_state = "undershirt_mob"
	item_icons = list(slot_wear_suit_str = 'code/game/Rogue Star/icons/fluff/sari_adjusted.dmi')
	var/jacket_toggled = TRUE
	var/open_state = FALSE

/obj/item/clothing/under/fluff/sari/New()
	..()
	START_PROCESSING(SSobj, src)

/obj/item/clothing/under/fluff/sari/process()
	var/mob/living/carbon/human/owner = loc
	if(!owner || !ishuman(owner)) //We are not worn by anyone, don't process.
		return
	owner.update_inv_wear_suit()

/obj/item/clothing/under/fluff/sari/make_worn_icon(var/body_type,var/slot_name,var/inhands,var/default_icon,var/default_layer = 0,var/icon/clip_mask = null)
	var/image/standing = ..()
	var/mob/living/carbon/human/owner = loc
	if(!owner || !ishuman(owner)) //We are not worn by anyone.
		return

	if(!inhands && jacket_toggled)
		name = "Captains R.I.G. jacket"
		desc = "A set of clothes and jacket with an integrated R.I.G. link, displaying user health on the back."
		if(!open_state)
			standing.add_overlay(image('code/game/Rogue Star/icons/fluff/sari_adjusted.dmi', "jacket_mob"))
		else
			standing.add_overlay(image('code/game/Rogue Star/icons/fluff/sari_adjusted.dmi', "jacket-open_mob"))
		var/sensors = getsensorlevel(owner)
		if(sensors)
			if(owner.health == (owner.maxHealth))
				standing.add_overlay(image('code/game/Rogue Star/icons/fluff/sari_adjusted.dmi', "jacket-overlay-100"))
			else if(owner.health < (owner.maxHealth) && owner.health >= (owner.maxHealth *0.5))
				standing.add_overlay(image('code/game/Rogue Star/icons/fluff/sari_adjusted.dmi', "jacket-overlay-75"))
			else if(owner.health < (owner.maxHealth *0.5) && owner.health >= (owner.maxHealth * 0.0))
				standing.add_overlay(image('code/game/Rogue Star/icons/fluff/sari_adjusted.dmi', "jacket-overlay-50"))
			else if(owner.health < (owner.maxHealth *0.0) && (owner.health >= owner.maxHealth * -0.5))
				standing.add_overlay(image('code/game/Rogue Star/icons/fluff/sari_adjusted.dmi', "jacket-overlay-25"))
			else
				standing.add_overlay(image('code/game/Rogue Star/icons/fluff/sari_adjusted.dmi', "jacket-overlay-0"))
	else if(!inhands && !jacket_toggled)
		name = "basic clothes"
		desc = "A basic undershirt and pair of shorts"
	return standing

/obj/item/clothing/under/fluff/sari/ui_action_click(mob/user, actiontype)
	ToggleJacket()

/obj/item/clothing/under/fluff/sari/verb/ToggleJacket()
	set name = "Toggle Jacket Overlay"
	set category = "Object"

	if(ishuman(loc))
		var/mob/living/carbon/human/H = src.loc
		if(!jacket_toggled)
			if(H.w_uniform != src)
				to_chat(H, span_warning("You must be wearing [src] to wear the jacket!"))
				return
			jacket_toggled = TRUE
			update_icon()
			H.update_inv_wear_suit()
		else
			jacket_toggled = FALSE
			update_icon()
			H.update_inv_wear_suit()

/obj/item/clothing/under/fluff/sari/verb/ToggleJacketOpen()
	set name = "Open Jacket"
	set category = "Object"

	if(ishuman(loc))
		var/mob/living/carbon/human/H = src.loc
		if(!open_state)
			name = "Close Jacket"
			open_state = TRUE
			update_icon()
			H.update_inv_wear_suit()
		else
			name = "Open Jacket"
			open_state = FALSE
			update_icon()
			H.update_inv_wear_suit()
