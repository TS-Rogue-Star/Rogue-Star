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