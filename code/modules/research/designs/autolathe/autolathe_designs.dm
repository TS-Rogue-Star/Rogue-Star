
// TODO - Consider if any of these new variables should be pulled up to design proper
/datum/design/autolathe
	build_type = AUTOLATHE
	var/build_multiple = FALSE  // If a single queue entry can build multiple. (var/is_stack from autolathe recipes)
	var/max_stack = null		// Cached max stack size for stack type builds.
	var/no_scale = FALSE		// If machine efficiency should not apply (no ex nihilo matter)

// TODO - Leshana -Validate this here!
/datum/design/autolathe/InitializeMaterials()
	..()

	// Initialize max_stack at runtime to avoid duplicate definition on design and on item.
	if(ispath(build_path, /obj/item/stack))
		var/obj/item/stack/stack_type = build_path
		max_stack = initial(stack_type.max_amount)

