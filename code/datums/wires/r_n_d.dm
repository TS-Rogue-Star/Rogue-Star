/datum/wires/rnd
	wire_count = 8		// 5 dummy wires
	holder_type = /obj/machinery/rnd
	random = TRUE

#define WIRE_HACK		(1<<0)
#define WIRE_DISABLE	(1<<1)
#define WIRE_SHOCK		(1<<2)

/datum/wires/rnd/CanUse(mob/user)
	var/obj/machinery/rnd/R = holder
	if(R.panel_open)
		return TRUE
	return FALSE

/datum/wires/rnd/GetInteractWindow()
	var/obj/machinery/rnd/R = holder
	. += ..()
	. += show_hint(0x1, R.disabled,	"The red light is off.", "The red light is on.")
	. += show_hint(0x2, R.hacked,	"The blue light is off.", "The blue light is on.")

/datum/wires/rnd/UpdatePulsed(index)
	set waitfor = FALSE
	var/obj/machinery/rnd/R = holder
	switch(index)
		if(WIRE_HACK)
			R.hacked = !R.hacked
		if(WIRE_SHOCK)
			if(istype(usr, /mob/living))
				R.shock(usr, 50)
		if(WIRE_DISABLE)
			R.disabled = !R.disabled

/datum/wires/rnd/on_cut(index, mended)
	var/obj/machinery/rnd/R = holder
	switch(index)
		if(WIRE_HACK)
			R.hacked = !mended
		if(WIRE_DISABLE)
			R.disabled = !mended

#undef WIRE_HACK
#undef WIRE_DISABLE
#undef WIRE_SHOCK
