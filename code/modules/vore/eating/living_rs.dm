//RS ADD
/mob/living
	var/vore_unconcious_eject_chance = 0

/mob/living/proc/prey_unconcious(var/mob/living/L)
	if(vore_unconcious_eject_chance <= 0)
		return FALSE
	if(ckey)
		return FALSE
	if(!L)
		return FALSE
	if(L.stat != UNCONSCIOUS)
		return FALSE
	if(!isbelly(L.loc))
		return FALSE
	var/obj/belly/B = L.loc
	if(B.owner != src)
		return FALSE
	if(prob(vore_unconcious_eject_chance))
		B.release_specific_contents(L)
		to_chat(L,SPAN_NOTICE("As you slip into unconsciousness, you can feel the flesh tighen, squeezing you out of \the [B.owner]'s [B], saving you from being claimed entirely!"))
		return TRUE
	else
		to_chat(L,SPAN_WARNING("As you slip into unconsciousness, you can feel \the [B.owner]'s [B] press in heavier, squeezing you deeper, greedier... smothering you close and keeping you... oh dear. It doesn't seem like you're getting away this time..."))
		return FALSE
