//RS ADD
/mob/living
	var/vore_unconcious_eject_chance = 0

/mob/living/proc/prey_unconcious(var/mob/living/L)
	if(vore_unconcious_eject_chance <= 0)
		return
	if(ckey)
		return
	if(!L)
		return
	if(L.stat != UNCONSCIOUS)
		return
	if(prob(vore_unconcious_eject_chance))
		if(isbelly(L.loc))
			var/obj/belly/B = L.loc
			if(B.owner == src)
				B.release_specific_contents(L)
				to_chat(L,"you got released lol")
	else
		to_chat(L,"you didn't get released, rip bozo")
