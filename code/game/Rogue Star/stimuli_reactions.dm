//RS FILE

/datum/modifier/slowly_shrinking
	name = "Slowly Shrinking"
	stacks = MODIFIER_STACK_ALLOWED

/datum/modifier/slowly_shrinking/tick()
	. = ..()
	holder.resize((holder.size_multiplier - 0.02), uncapped = holder.has_large_resize_bounds())

/mob/living/proc/belch_react(var/mob/living/L)
	return

/mob/living/carbon/human/belch_react(var/mob/living/L)
	if(!client)
		return
	var/do_shrink = FALSE
	var/do_stun = FALSE
	var/do_sleep = FALSE
	for(var/T in client.prefs.neg_traits)
		switch(T)
			if(/datum/trait/negative/stim_react)
				do_shrink = TRUE
				continue
			if(/datum/trait/negative/stim_react/belch_stun)
				do_stun = TRUE
				continue
			if(/datum/trait/negative/stim_react/belch_sleep)
				do_sleep = TRUE
				continue
	if(do_shrink)
		if(spont_pref_check(L,src,RESIZING))
			add_modifier(/datum/modifier/slowly_shrinking,10 SECONDS)
	if(do_stun)
		Stun(30)
		Weaken(30)
	if(do_sleep)
		sleeping = 30

/mob/living/proc/intent_react(var/mob/living/L, var/our_intent)
	return

/mob/living/carbon/human/intent_react(var/mob/living/L, var/our_intent)
	if(!client)
		return
	if(L.a_intent != our_intent)
		return
	var/do_shrink = FALSE
	var/do_stun = FALSE
	var/do_sleep = FALSE
	for(var/T in client.prefs.neg_traits)
		if(!islist(client.prefs.neg_traits[T]))
			continue
		var/list/data = client.prefs.neg_traits[T]
		if(data["target"] != L.zone_sel.selecting)
			continue
		if(our_intent == I_HELP)
			switch(T)
				if(/datum/trait/negative/stim_react/intent_touch)
					do_shrink = TRUE
					continue
				if(/datum/trait/negative/stim_react/intent_touch/ft_stun)
					do_stun = TRUE
					continue
				if(/datum/trait/negative/stim_react/intent_touch/ft_sleep)
					do_sleep = TRUE
					continue
		if(our_intent == I_DISARM)
			switch(T)
				if(/datum/trait/negative/stim_react/intent_touch/dis_shrink)
					do_shrink = TRUE
					continue
				if(/datum/trait/negative/stim_react/intent_touch/dis_stun)
					do_stun = TRUE
					continue
				if(/datum/trait/negative/stim_react/intent_touch/ft_sleep)
					do_sleep = TRUE
					continue

	if(do_shrink)
		if(spont_pref_check(L,src,RESIZING))
			add_modifier(/datum/modifier/slowly_shrinking,10 SECONDS)
	if(do_stun)
		Stun(30)
		Weaken(30)
	if(do_sleep)
		sleeping = 30
