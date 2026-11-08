//////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star November 2026: Drink Memories //
//////////////////////////////////////////////////////////////////

// RS Add: Drink Memories (Lira, November 2026)
/datum/reagents/distilling
	var/datum/weakref/drink_maker
	var/list/remembered_drinks = list()

// RS Add: Drink Memories (Lira, November 2026)
/datum/reagents/distilling/proc/begin_drink_batch(var/mob/user)
	drink_maker = isliving(user) ? WEAKREF(user) : null
	remembered_drinks = list()

// RS Edit: Drink Memories (Lira, November 2026)
/datum/reagents/distilling/handle_reactions(var/mob/mixer = null)
	if(QDELETED(my_atom))
		return FALSE
	if(my_atom.flags & NOREACT)
		return FALSE
	if(mixer)
		drink_maker = WEAKREF(mixer)
	if(!total_volume)
		remembered_drinks.Cut()
	var/reaction_occurred
	var/list/eligible_reactions = list()
	var/list/effect_reactions = list()
	do
		reaction_occurred = FALSE
		for(var/datum/reagent/R as anything in reagent_list)
			if(SSchemistry.distilled_reactions_by_reagent[R.id])
				eligible_reactions |= SSchemistry.distilled_reactions_by_reagent[R.id]

		for(var/decl/chemical_reaction/C as anything in eligible_reactions)
			if(C.can_happen(src) && C.process(src))
				effect_reactions |= C
				reaction_occurred = TRUE
		eligible_reactions.len = 0
	while(reaction_occurred)
	for(var/decl/chemical_reaction/C as anything in effect_reactions)
		C.post_reaction(src)
	update_total()
	record_mixed_drinks(drink_maker?.resolve(), effect_reactions, remembered_drinks)
