//Builds networks like power cables/atmos lines/etc
//Just a holder parent type for now..
/obj/effect/mapping_helpers/network_builder
	/// set var to true to not del on lateload
	var/custom_spawned = FALSE

	icon = 'icons/effects/mapping_helpers.dmi'

	late = TRUE

/obj/effect/mapping_helpers/network_builder/Initialize(mapload)
	. = ..()
	var/conflict = check_duplicates()
	if(conflict)
		stack_trace("WARNING: [type] network building helper found check_duplicates() conflict [conflict] in its location.!")
		return INITIALIZE_HINT_QDEL
	if(!mapload)
		if(GLOB.Debug2)
			custom_spawned = TRUE
			return INITIALIZE_HINT_NORMAL
		else
			return INITIALIZE_HINT_QDEL
	return INITIALIZE_HINT_LATELOAD

/// How this works: On LateInitialize, we simply tell our spawned wires to do their thing and then qdel from the map, leaving our results behind.
/// Formerly, we scanned directions first, but smart cables and layers negate that need and we don't do diagonals.
/obj/effect/mapping_helpers/network_builder/LateInitialize()
	build_network()
	if(!custom_spawned)
		qdel(src)

/obj/effect/mapping_helpers/network_builder/proc/check_duplicates()
	CRASH("Base abstract network builder tried to check duplicates.")

/obj/effect/mapping_helpers/network_builder/proc/scan_directions()
	CRASH("Base abstract network builder tried to scan directions.")

/obj/effect/mapping_helpers/network_builder/proc/build_network()
	CRASH("Base abstract network builder tried to build network.")
