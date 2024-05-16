#define CABLE 0
#define BRIDGE 1
#define MULTIZ 2

/// Automatically links on init to power cables and other cable builder helpers. Only supports cardinals.
/obj/effect/mapping_helpers/network_builder/power_cable
	name = "power line L2 autobuilder"
	icon_state = "L2powerlinebuilder"
	color = CABLELAYERTWOCOLOR
	/// default our layering to 2
	var/cable_layer = CABLE_LAYER_2

	/// Whether or not we forcefully make a knot. //I can't believe I had to remove knot code - Pooj
	//var/knot = NO_KNOT

	/// What's our specialty?
	var/cabletype = CABLE

/obj/effect/mapping_helpers/network_builder/power_cable/check_duplicates()
	var/obj/structure/cable/C = locate() in loc
	if(C)
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
	if(cabletype == CABLE)
		new /obj/structure/cable(loc,color,cable_layer)
	if(cabletype == MULTIZ)
		new /obj/structure/cable/multilayer/multiz(loc) //multizs have all three layers active at all times.
	if(cabletype == BRIDGE)
		new /obj/structure/cable/multilayer/connected(loc)	//as do bridges

/obj/effect/mapping_helpers/network_builder/power_cable/cablerelay
	name = "power multi-z cable relay autobuilder"
	icon_state = "cablerelay"
	cabletype = MULTIZ

/obj/effect/mapping_helpers/network_builder/power_cable/bridge
	name = "power bridge autobuilder"
	icon_state = "cable_bridge"
	cabletype = BRIDGE

/obj/effect/mapping_helpers/network_builder/power_cable/layer1
	name = "power line L1 autobuilder"
	icon_state = "L1powerlinebuilder"
	color = CABLELAYERONECOLOR
	cable_layer = CABLE_LAYER_1

/obj/effect/mapping_helpers/network_builder/power_cable/layer3
	name = "power line L3 autobuilder"
	icon_state = "L3powerlinebuilder"
	color = CABLELAYERTHREECOLOR
	cable_layer = CABLE_LAYER_3

/// I really didn't feel like doing a ton of copy/pasta for layer memes, so uh, yeah. I'm sure you can just dirty edit in mapmaker.
// Red
/obj/effect/mapping_helpers/network_builder/power_cable/red
	color = COLOR_RED

// White
/obj/effect/mapping_helpers/network_builder/power_cable/white
	color = COLOR_WHITE

// Cyan
/obj/effect/mapping_helpers/network_builder/power_cable/cyan
	color = COLOR_CYAN

// Orange
/obj/effect/mapping_helpers/network_builder/power_cable/orange
	color = COLOR_ORANGE

// Pink
/obj/effect/mapping_helpers/network_builder/power_cable/pink
	color = COLOR_PINK

// Blue
/obj/effect/mapping_helpers/network_builder/power_cable/blue
	color = COLOR_BLUE

// Green
/obj/effect/mapping_helpers/network_builder/power_cable/green
	color = COLOR_GREEN

// Yellow
/obj/effect/mapping_helpers/network_builder/power_cable/yellow
	color = COLOR_YELLOW


#undef CABLE
#undef BRIDGE
#undef MULTIZ
