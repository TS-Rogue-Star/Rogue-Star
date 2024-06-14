//RS CUSTOM FLUFF ITEMS BEGIN

/obj/item/clothing/head/fluff/dulahan_fire		//hiddenname1702 fluff item	- Sprites by VerySoft
	name = "dulahan's fire"
	desc = "This Dulahan's head appears to be missing, and a fire rests in it's place."
	icon = 'icons/rogue-star/hats.dmi'
	icon_state = "d_fire"
	icon_override = 'icons/rogue-star/hats.dmi'
	item_state = "d_fire"
	body_parts_covered = HEAD
	plane = PLANE_LIGHTING_ABOVE
	light_range = 2
	light_overlay = null
	light_system = MOVABLE_LIGHT

/obj/item/clothing/head/fluff/dulahan_fire/Initialize()
	. = ..()
	update_flashlight()

/obj/item/clothing/head/fluff/dulahan_fire/update_flashlight(mob/user)
	light_color = color
	return ..()

/obj/item/weapon/fluff/ena_head
	name = "Ena's Head"
	desc = "The head of a Dulahan, careful it doesn't bite you!"
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "ena_head"
	force = 1
	throwforce = 1
	throw_speed = 4
	throw_range = 20
