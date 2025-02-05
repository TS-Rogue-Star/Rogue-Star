/obj/item/clothing/suit/talon/capcoat
	name = "Talon captain's coat"
	desc = "A heavy coat worn by the ITV Talon's commanding officer, it has a nametag and ITV Talon logo on the breasts, it's incredibly snug to wear. The collar consists of genuine fur."
	icon = 'icons/inventory/suit/item_rs.dmi'
	default_worn_icon = 'icons/inventory/suit/mob_rs.dmi'
	icon_state = "talon_capcoat"
	item_state = "talon_capcoat"
	body_parts_covered = UPPER_TORSO|LOWER_TORSO|ARMS
	flags_inv = HIDEHOLSTER

/obj/item/clothing/suit/storage/toggle/bomber/pilot/talon
	name = "Talon bomber jacket"
	desc = "A blue bomber jacket worn by the ITV Talon's piloting personnel, it has a nametag on the breast, it's incredibly warm, and comfortable. The collar and wrists consists of synthetic fur."
	icon = 'icons/inventory/suit/item_rs.dmi'
	default_worn_icon = 'icons/inventory/suit/mob_rs.dmi'
	icon_state = "talon_pilotjacket"
	item_state = "talon_pilotjacket"

/obj/item/clothing/suit/storage/toggle/labcoat/talon
	name = "Talon labcoat"
	desc = "A large, and extremely sterile labcoat that protects the wearer from chemical spills. This one has ITV Talon colored patterns along the labcoat, the designated shapes list it as a medical officer's labcoat."
	icon = 'icons/inventory/suit/item_rs.dmi'
	default_worn_icon = 'icons/inventory/suit/mob_rs.dmi'
	icon_state = "talon_labcoat"
	item_state_slots = list(slot_r_hand_str = "talon_labcoat", slot_l_hand_str = "talon_labcoat")

/obj/item/clothing/suit/storage/hooded/wintercoat/talon/refreshed
	name = "Talon winter coat"
	desc = "A cozy winter coat, covered in thick fur and baring the colors of ITV Talon."
	icon = 'icons/inventory/suit/item_rs.dmi'
	default_worn_icon = 'icons/inventory/suit/mob_rs.dmi'
	hoodtype = /obj/item/clothing/head/hood/winter/talon/refreshed

/obj/item/clothing/head/hood/winter/talon/refreshed
	name = "Talon winter hood"
	desc = "A cozy winter hood attached to a heavy winter jacket."
	icon = 'icons/inventory/head/item_rs.dmi'
	default_worn_icon = 'icons/inventory/head/mob_rs.dmi'
	icon_state = "winterhood_talon"
