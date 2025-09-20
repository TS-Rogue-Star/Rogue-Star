//	Observer Pattern Implementation: Stat Set
//		Registration type: /mob/living
//
//		Raised when: A /mob/living changes stat, using the set_stat() proc
//
//		Arguments that the called proc should expect:
//			/mob/living/stat_mob: The mob whose stat changed
//			/old_stat: Status before the change.
//			/new_stat: Status after the change.

GLOBAL_DATUM_INIT(stat_set_event, /decl/observ/stat_set, new)

/decl/observ/stat_set
	name = "Stat Set"
	expected_type = /mob/living

/****************
* Stat Handling *
****************/
/mob/living/set_stat(var/new_stat)
	var/old_stat = stat
	. = ..()
	var/msg	//RS ADD
	if(stat != old_stat)
		GLOB.stat_set_event.raise_event(src, old_stat, new_stat)
		if(isbelly(src.loc))	//RS ADD
			var/obj/belly/ourbelly = src.loc
			if(stat == CONSCIOUS)	//RS EDIT START
				msg = "<span class='notice'>\The [src.name] is awake.</span>"
			else if(stat == UNCONSCIOUS)
				msg = "<span class='red'>\The [src.name] has fallen unconscious!</span>"

			if(!ourbelly.owner.client)
				ourbelly.owner.prey_unconcious(src)
				return
			to_chat(ourbelly.owner, msg)	//RS EDIT END
