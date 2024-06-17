// The old emitter sprite
/obj/machinery/power/emitter/antique
	name = "antique emitter"
	desc = "An old fashioned heavy duty industrial laser."
	icon_state = "emitter"

/obj/machinery/power/emitter/antique/update_icon()
	if(powered && powernet && avail(active_power_usage) && active)
		icon_state = "emitter_+a"
	else
		icon_state = "emitter"
