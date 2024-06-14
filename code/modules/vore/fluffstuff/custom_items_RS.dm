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
	icon = 'icons/vore/custom_items_rs.dmi'
	icon_state = "ena_head"
	force = 1
	throwforce = 1
	throw_speed = 4
	throw_range = 20

/obj/item/toy/plushie/snakeplushie/fluff/river
	name = "Vivid's River"
	desc = "An aquatic noodle that Vivid uses to showcase the actions of their blue wyrm"
	icon = 'icons/vore/custom_items_rs.dmi'
	icon_state = "river"
	drop_sound = "generic_drop"

/obj/item/toy/plushie/snakeplushie/fluff/jyen
	name = "Vivid's Jyen"
	desc = "A fluffy noodle that Vivid uses to showcase the actions of their white wyrm"
	icon = 'icons/vore/custom_items_rs.dmi'
	icon_state = "jyen"
	drop_sound = "generic_drop"

/obj/item/toy/plushie/snakeplushie/fluff/raye
	name = "Vivid's Raye"
	desc = "An acid noodle that Vivid uses to showcase the actions of their green wyrm"
	icon = 'icons/vore/custom_items_rs.dmi'
	icon_state = "raye"
	drop_sound = "generic_drop"

/obj/item/toy/plushie/snakeplushie/fluff/zoey
	name = "Vivid's Zoey"
	desc = "A hypnotic noodle that Vivid uses to showcase the actions of their yellow wyrm"
	icon = 'icons/vore/custom_items_rs.dmi'
	icon_state = "zoey"
	drop_sound = "generic_drop"

/obj/item/clothing/under/permit/fluff/tracking_implant
	name = "embedded tracker implant"
	desc = "A small, spherical black device. Emblazoned with a crimson Y-like logo on one side and the numbers 53799 stamped on the back."
	icon = 'icons/vore/custom_items_rs.dmi'
	icon_state = "anoscetiaImplant"
	var/obj/item/device/gps/gps_tracker		//It has a secret GPS device in it

/obj/item/clothing/under/permit/fluff/tracking_implant/Initialize()
	. = ..()
	gps_tracker = new(src)
	gps_tracker.gps_tag = "Syne"
	gps_tracker.tracking = TRUE

/obj/item/clothing/under/permit/fluff/tracking_implant/Destroy()
	gps_tracker = null
	return ..()
