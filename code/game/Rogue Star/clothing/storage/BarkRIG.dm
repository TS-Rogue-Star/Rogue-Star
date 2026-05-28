//RS FILE
//
// All things commented out with a /* are -maybe- for the future
/obj/item/weapon/storage/rig
	parent_type = /obj/item/weapon/storage/backpack
	name = "R.I.G. module"
	desc = "A R.I.G. link, displaying user health on the back."
	icon = 'code/game/Rogue Star/icons/clothing/storage/RigAcc.dmi'
	icon_state = "itemsprite"
	item_state = "base_onmob"
	item_icons = list(slot_back_str = 'code/game/Rogue Star/icons/clothing/storage/RigAcc.dmi',
		slot_l_hand_str = 'icons/mob/items/lefthand_storage.dmi',
		slot_r_hand_str = 'icons/mob/items/righthand_storage.dmi',
		)
	item_state_slots = list(
		slot_l_hand_str = "backpack",
		slot_r_hand_str = "backpack"
		)
	armor = list(melee = 0, bullet = 0, laser = 0, energy = 0, bomb = 0, bio = 0, rad = 0)
	w_class = ITEMSIZE_LARGE
	slot_flags = SLOT_BACK
	max_w_class = ITEMSIZE_LARGE
	max_storage_space = INVENTORY_STANDARD_SPACE



/obj/item/weapon/storage/rig/New()
	..()
	START_PROCESSING(SSobj, src)


/obj/item/weapon/storage/rig/process()
	var/mob/living/carbon/human/owner = loc
	if(!owner || !ishuman(owner)) //We are not worn by anyone, don't process.
		cut_overlays()
		return
	owner.update_inv_back()




/obj/item/weapon/storage/rig/make_worn_icon(var/body_type,var/slot_name,var/inhands,var/default_icon,var/default_layer = 0,var/icon/clip_mask = null)
	var/image/standing = ..()
	var/mob/living/carbon/human/owner = loc
	if(!owner || !ishuman(owner)) //We are not worn by anyone.
		cut_overlays()
		return
	//Overlay start
	var ohealth = owner.health
	cut_overlays()
	if(!inhands)
		var/effective_max_health = owner.getMaxHealth()
		if(ohealth == (effective_max_health))
			//to_chat(owner, "<span class='notice'>health100</span>")
			standing.add_overlay(image(icon, "onmob_100"))
			add_overlay(image(icon, "item_100"))
		else if(ohealth < (effective_max_health) && ohealth >= (effective_max_health *0.5))
			//to_chat(owner, "<span class='notice'>health75</span>")
			standing.add_overlay(image(icon, "onmob_75"))
			add_overlay(image(icon, "item_75"))
		else if(ohealth < (effective_max_health *0.5) && ohealth >= (effective_max_health * 0.0))
			//to_chat(owner, "<span class='notice'>health50</span>")
			standing.add_overlay(image(icon, "onmob_50"))
			add_overlay(image(icon, "item_50"))
		else if(ohealth < (effective_max_health *0.0) && (ohealth >= effective_max_health * -0.5))
			//to_chat(owner, "<span class='notice'>health25</span>")
			standing.add_overlay(image(icon, "onmob_25"))
			add_overlay(image(icon, "item_25"))
		else
			//to_chat(owner, "<span class='notice'>health0</span>")
			standing.add_overlay(image(icon, "onmob_0"))
			add_overlay(image(icon, "item_0"))
	return standing
