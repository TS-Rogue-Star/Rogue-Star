/obj/machinery/power/smes/buildable/hybrid
	name = "hybrid power storage unit"
	desc = "A high-capacity superconducting magnetic energy storage (SMES) unit, modified with alien technology to generate small amounts of power from seemingly nowhere."
	icon = 'icons/obj/power_vr.dmi'
	var/recharge_rate = 10000
	var/overlay_icon = 'icons/obj/power_vr.dmi'

/obj/machinery/power/smes/buildable/hybrid/attackby(var/obj/item/weapon/W as obj, var/mob/user as mob)
	if(W.is_screwdriver() || W.is_wirecutter())
		to_chat(user,"<span class='warning'>\The [src] full of weird alien technology that's best not messed with.</span>")
		return 0

//removed update icon process, due to redundant code.

/obj/machinery/power/smes/buildable/hybrid/process()
	charge += min(recharge_rate, capacity - charge)
	..()
