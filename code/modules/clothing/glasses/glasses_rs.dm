/obj/item/clothing/glasses
	var/glasses_layer_above = FALSE


/obj/item/clothing/glasses/big_round
	name = "big round blue glasses"
	desc = "A set of glasses! They are big, round, and very reflective, catching the light and obscuring the eyes!"
	icon = 'icons/inventory/eyes/item_rs.dmi'
	icon_override = 'icons/inventory/eyes/mob_rs.dmi'
	icon_state = "bigroundglasses"
	slot_flags = SLOT_EYES | SLOT_EARS
	glasses_layer_above = TRUE

/obj/item/clothing/glasses/big_round/red
	name = "big round red glasses"
	icon_state = "bigroundglasses-red"
/obj/item/clothing/glasses/big_round/magenta
	name = "big round magenta glasses"
	icon_state = "bigroundglasses-magenta"
/obj/item/clothing/glasses/big_round/green
	name = "big round green glasses"
	icon_state = "bigroundglasses-green"
/obj/item/clothing/glasses/big_round/gold
	name = "big round gold glasses"
	icon_state = "bigroundglasses-gold"
/obj/item/clothing/glasses/big_round/cyan
	name = "big round cyan glasses"
	icon_state = "bigroundglasses-cyan"
