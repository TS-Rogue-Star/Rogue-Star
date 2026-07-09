//RS FILE
/datum/modifier/sense
	stacks = MODIFIER_STACK_EXTEND
	var/list/flavor = list()

/datum/modifier/sense/New(new_holder, new_origin)
	if(isobj(new_origin))
		var/obj/O = new_origin
		flavor |= O.name
	. = ..()

/datum/modifier/sense/modifier_update(atom/updated_origin)
	flavor |= updated_origin.name

/datum/modifier/sense/taste
	name = "taste"

/datum/modifier/sense/smell
	name = "smell"
	desc = "It was a smelly smell..."
