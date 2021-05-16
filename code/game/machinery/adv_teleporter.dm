/obj/machinery/computer/adv_teleporter
	name = "teleporter control console"
	desc = "Used to control a linked teleportation Hub and Station."
	icon_keyboard = "teleport_key"
	icon_screen = "teleport"
	circuit = /obj/item/weapon/circuitboard/teleporter
	dir = 4

	var/datum/tgui_module/adv_teleport/teleport_control

/obj/machinery/computer/adv_teleporter/Initialize()
	. = ..()
	teleport_control = new(src)

/obj/machinery/computer/adv_teleporter/Destroy()
	QDEL_NULL(teleport_control)
	return ..()

/obj/machinery/teleport/station/attack_ai()
	attack_hand()

/obj/machinery/computer/adv_teleporter/attack_ai(mob/user)
	teleport_control.tgui_interact(user)

/obj/machinery/computer/adv_teleporter/attack_hand(mob/user)
	add_fingerprint(user)
	if(stat & (BROKEN|NOPOWER))
		return
	teleport_control.tgui_interact(user)
