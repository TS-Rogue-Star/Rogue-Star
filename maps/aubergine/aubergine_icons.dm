/obj/item/frame/apc
	icon = 'icons/obj/bay/apc_repair.dmi'

/obj/machinery/alarm //Air alarm
	icon = 'icons/obj/bay/monitors.dmi'

/obj/machinery/power/apc
	icon = 'icons/obj/bay/apc.dmi'

/obj/machinery/power/apc/Initialize()
	. = ..()
	pixel_x = (src.dir & 3) ? 0 : (src.dir == 4 ? 24 : -24)
	pixel_y = (src.dir & 3) ? (src.dir == 1 ? 22 : -22) : 0

/obj/machinery/firealarm
	icon = 'icons/obj/bay/firealarm.dmi'

/obj/item/device/radio/intercom
	icon = 'icons/obj/bay/radio.dmi'

/obj/machinery/recharger/wallcharger
	icon = 'icons/obj/bay/stationobjs.dmi'

/obj/structure/window
	icon = 'icons/obj/bay/window.dmi'

/obj/machinery/vending
	icon = 'icons/obj/bay/vending.dmi'

/obj/machinery/vending/boozeomat
	icon_state = "fridge_dark"
	icon_deny = "fridge_dark-deny"

/obj/machinery/chemical_dispenser
	icon = 'icons/obj/bay/chemical.dmi'

/////// Smartfridges ///////
/obj/machinery/smartfridge
	icon = 'icons/obj/bay/vending.dmi'
	icon_state = "fridge_sci"
	var/icon_base = "fridge_sci"
	var/icon_contents = "chem"

/obj/machinery/smartfridge/seeds
	name = "\improper MegaSeed Servitor"
	desc = "When you need seeds fast!"

/obj/machinery/smartfridge/secure/extract
	name = "\improper Slime Extract Storage"
	desc = "A refrigerated storage unit for slime extracts."
	icon_contents = "slime"

/obj/machinery/smartfridge/secure/medbay
	name = "\improper Refrigerated Medicine Storage"
	desc = "A refrigerated storage unit for storing medicine and chemicals."
	icon_contents = "chem"

/obj/machinery/smartfridge/secure/virology
	name = "\improper Refrigerated Virus Storage"
	desc = "A refrigerated storage unit for storing viral material."
	icon_contents = "chem"

/obj/machinery/smartfridge/chemistry
	name = "\improper Smart Chemical Storage"
	desc = "A refrigerated storage unit for medicine and chemical storage."
	icon_contents = "chem"

/obj/machinery/smartfridge/chemistry/virology
	name = "\improper Smart Virus Storage"
	desc = "A refrigerated storage unit for volatile sample storage."

/obj/machinery/smartfridge/drinks
	name = "\improper Drink Showcase"
	desc = "A refrigerated storage unit for tasty tasty alcohol."
	icon_state = "fridge_dark"
	icon_base = "fridge_dark"
	icon_contents = "drink"

/obj/machinery/smartfridge/foods
	name = "\improper Hot Foods Display"
	desc = "A heated storage unit for piping hot meals."
	icon_state = "fridge_food"
	icon_state = "fridge_food"
	icon_contents = "food"

/obj/machinery/smartfridge/drying_rack
	name = "drying rack"
	desc = "A machine for drying plants."
	icon_state = "drying_rack"

/obj/machinery/smartfridge/update_icon()
	cut_overlays()
	if(stat & (BROKEN|NOPOWER))
		icon_state = "[icon_base]-off"
	else
		icon_state = icon_base

	if(is_secure)
		add_overlay("[icon_base]-sidepanel")

	if(panel_open)
		add_overlay("[icon_base]-panel")

	var/is_off = ""
	if(inoperable())
		is_off = "-off"

	// Fridge contents
	switch(contents.len)
		if(0)
			add_overlay("empty[is_off]")
		if(1 to 2)
			add_overlay("[icon_contents]-1[is_off]")
		if(3 to 5)
			add_overlay("[icon_contents]-2[is_off]")
		if(6 to 8)
			add_overlay("[icon_contents]-3[is_off]")
		else
			add_overlay("[icon_contents]-4[is_off]")

	// Fridge top
	var/image/I = image(icon, "[icon_base]-top")
	I.pixel_z = 32
	I.layer = ABOVE_WINDOW_LAYER
	add_overlay(I)
