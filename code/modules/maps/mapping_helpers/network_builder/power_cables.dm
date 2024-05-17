#define MAPPINGHELPERCABLE			0
#define MAPPINGHELPERBRIDGECABLE	1
#define MAPPINGHELPERMULTIZCABLE	2
#define MAPPINGHELPERHEAVYCABLE		4
#define MAPPINGHELPERENDERCABLE		5

/// Automatically links on init to power cables and other cable builder helpers. Only supports cardinals.
/obj/effect/mapping_helpers/network_builder/power_cable
	name = "base line autobuilder"
	icon_state = "L2powerlinebuilder"
	color = CABLELAYERTWOCOLOR
	/// default our layering to 2
	var/cable_layer = CABLE_LAYER_2

	/// Whether or not we forcefully make a knot. //I can't believe I had to remove knot code - Pooj
	//var/knot = NO_KNOT

	/// What's our specialty?
	var/cabletype = MAPPINGHELPERCABLE

/obj/effect/mapping_helpers/network_builder/power_cable/check_duplicates()
	var/obj/structure/cable/C = locate() in loc
	if(C && C.cable_layer == cable_layer)
		return C
	for(var/obj/effect/mapping_helpers/network_builder/power_cable/other in loc)
		if(other == src)
			continue
		if(other.cable_layer != src.cable_layer)
			continue
		return other

/// Directions should only ever have cardinals.
/// Smart Cables means we shouldn't have to worry about fiddling
/obj/effect/mapping_helpers/network_builder/power_cable/build_network()
	if(cabletype == MAPPINGHELPERCABLE)
		if(cable_layer == CABLE_LAYER_1)
			new /obj/structure/cable/layer1(loc)
		else if(cable_layer == CABLE_LAYER_3)
			new /obj/structure/cable/layer3(loc)
		else if(cable_layer == CABLE_LAYER_2)
			new /obj/structure/cable(loc)
		return

	if(cabletype == MAPPINGHELPERMULTIZCABLE)
		new /obj/structure/cable/multilayer/multiz(loc) //multizs have all three layers active at all times.
		return
	if(cabletype == MAPPINGHELPERBRIDGECABLE)
		new /obj/structure/cable/multilayer/connected(loc)	//as do bridges
		return
	if(cabletype == MAPPINGHELPERHEAVYCABLE)
		new /obj/structure/cable/heavyduty(loc)
		return
	if(cabletype == MAPPINGHELPERENDERCABLE)
		new /obj/structure/cable/heavyduty/ender(loc)
		return

/obj/effect/mapping_helpers/network_builder/power_cable/cablerelay
	name = "power multi-z cable relay autobuilder"
	icon_state = "cablerelay"
	cabletype = MAPPINGHELPERMULTIZCABLE

/obj/effect/mapping_helpers/network_builder/power_cable/bridge
	name = "power bridge autobuilder"
	icon_state = "cable_bridge"
	cabletype = MAPPINGHELPERBRIDGECABLE

/obj/effect/mapping_helpers/network_builder/power_cable/layer1
	name = "power line L1 autobuilder"
	icon_state = "L1powerlinebuilder"
	color = CABLELAYERONECOLOR
	cable_layer = CABLE_LAYER_1

/obj/effect/mapping_helpers/network_builder/power_cable/layer2
	name = "power line L2 autobuilder"
	icon_state = "L2powerlinebuilder"
	color = CABLELAYERTWOCOLOR
	cable_layer = CABLE_LAYER_2

/obj/effect/mapping_helpers/network_builder/power_cable/layer3
	name = "power line L3 autobuilder"
	icon_state = "L3powerlinebuilder"
	color = CABLELAYERTHREECOLOR
	cable_layer = CABLE_LAYER_3

/obj/effect/mapping_helpers/network_builder/power_cable/heavy
	name = "Heavy Powerline autobuilder"
	icon_state = "heavy"
	cable_layer = CABLE_LAYER_4
	color = COLOR_WHITE
	cabletype = MAPPINGHELPERHEAVYCABLE

/obj/effect/mapping_helpers/network_builder/power_cable/ender
	name = "Heavy Ender Transmit autobuilder"
	icon_state = "ender"
	cable_layer = CABLE_LAYER_4
	color = COLOR_WHITE
	cabletype = MAPPINGHELPERENDERCABLE


#undef MAPPINGHELPERCABLE
#undef MAPPINGHELPERBRIDGECABLE
#undef MAPPINGHELPERMULTIZCABLE
#undef MAPPINGHELPERHEAVYCABLE
#undef MAPPINGHELPERENDERCABLE
