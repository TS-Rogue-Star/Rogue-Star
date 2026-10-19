//RS FILE
#define STIM_BELCH	"belch"
#define STIM_HUFF	"huff"
#define STIM_KISS	"kiss"
#define STIM_HELP	"help"
#define STIM_DISARM	"disarm"

/mob/living/proc/resolve_stimuli(var/mob/living/source, var/stimuli)
	return

/mob/living/carbon/human/resolve_stimuli(var/mob/living/source, stimuli)
	if(!source || !stimuli)
		return
	if(!species || !islist(species.traits))
		return

	var/do_shrink = FALSE
	var/do_stun = FALSE
	var/do_sleep = FALSE
	var/do_attract = FALSE

	switch(stimuli)
		if(STIM_BELCH)
			if(/datum/trait/negative/stim_react in species.traits)
				do_shrink = TRUE
			if(/datum/trait/negative/stim_react/belch_stun in species.traits)
				do_stun = TRUE
			if(/datum/trait/negative/stim_react/belch_sleep in species.traits)
				do_sleep = TRUE
			if(/datum/trait/negative/stim_react/belch_attract in species.traits)
				do_attract = TRUE

		if(STIM_HUFF)
			if(/datum/trait/negative/stim_react/huff_shrink in species.traits)
				do_shrink = TRUE
			if(/datum/trait/negative/stim_react/huff_stun in species.traits)
				do_stun = TRUE
			if(/datum/trait/negative/stim_react/huff_sleep in species.traits)
				do_sleep = TRUE
			if(/datum/trait/negative/stim_react/huff_attract in species.traits)
				do_attract = TRUE

		if(STIM_KISS)
			if(/datum/trait/negative/stim_react/kiss_shrink in species.traits)
				do_shrink = TRUE
			if(/datum/trait/negative/stim_react/kiss_stun in species.traits)
				do_stun = TRUE
			if(/datum/trait/negative/stim_react/kiss_sleep in species.traits)
				do_sleep = TRUE
			if(/datum/trait/negative/stim_react/kiss_attract in species.traits)
				do_attract = TRUE

		if(STIM_HELP)
			if(/datum/trait/negative/stim_react/intent_touch in species.traits)
				var/list/data = species.traits[/datum/trait/negative/stim_react/intent_touch]
				if(data && data["target"] == source.zone_sel.selecting)
					do_shrink = TRUE
			if(/datum/trait/negative/stim_react/intent_touch/ft_stun in species.traits)
				var/list/data = species.traits[/datum/trait/negative/stim_react/intent_touch/ft_stun]
				if(data && data["target"] == source.zone_sel.selecting)
					do_stun = TRUE
			if(/datum/trait/negative/stim_react/intent_touch/ft_sleep in species.traits)
				var/list/data = species.traits[/datum/trait/negative/stim_react/intent_touch/ft_sleep]
				if(data && data["target"] == source.zone_sel.selecting)
					do_sleep = TRUE

		if(STIM_DISARM)
			if(/datum/trait/negative/stim_react/intent_touch/dis_shrink in species.traits)
				var/list/data = species.traits[/datum/trait/negative/stim_react/intent_touch/dis_shrink]
				if(data && data["target"] == source.zone_sel.selecting)
					do_shrink = TRUE
			if(/datum/trait/negative/stim_react/intent_touch/dis_stun in species.traits)
				var/list/data = species.traits[/datum/trait/negative/stim_react/intent_touch/dis_stun]
				if(data && data["target"] == source.zone_sel.selecting)
					do_stun = TRUE
			if(/datum/trait/negative/stim_react/intent_touch/dis_sleep in species.traits)
				var/list/data = species.traits[/datum/trait/negative/stim_react/intent_touch/dis_sleep]
				if(data && data["target"] == source.zone_sel.selecting)
					do_sleep = TRUE

	if(do_shrink)
		if(spont_pref_check(source,src,RESIZING))
			add_modifier(/datum/modifier/slowly_shrinking,10 SECONDS)
	if(do_stun)
		Stun(30)
		Weaken(30)
	if(do_sleep)
		Sleeping(30)
	if(do_attract)
		var/datum/modifier/wander_toward/wt = add_modifier(/datum/modifier/wander_toward, 10 SECONDS)
		wt.attractor = source

///// MODIFIERS /////

/datum/modifier/slowly_shrinking
	name = "Slowly Shrinking"
	stacks = MODIFIER_STACK_ALLOWED

/datum/modifier/slowly_shrinking/tick()
	. = ..()
	holder.resize(max(holder.size_multiplier - 0.02, RESIZE_MINIMUM_DORMS), uncapped = holder.has_large_resize_bounds())

/datum/modifier/wander_toward
	name = "Wander toward"
	stacks = MODIFIER_STACK_EXTEND

	var/atom/attractor

/datum/modifier/wander_toward/tick()
	. = ..()
	if(holder.stat)
		expire()
	var/dist = get_dist(holder,attractor)
	if(dist > world.view)
		expire()
	else if(dist > 1)
		if(!step_towards(holder, attractor))
			holder.face_atom(attractor)
