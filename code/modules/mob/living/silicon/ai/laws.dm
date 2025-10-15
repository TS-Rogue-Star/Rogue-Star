/mob/living/silicon/ai/proc/show_laws_verb()
	set category = "AI Commands"
	set name = "Show Laws"
	src.show_laws()

/mob/living/silicon/ai/show_laws(var/everyone = 0)
	var/who

	if (everyone)
		who = world
	else
		who = src
		to_chat(who, "<span class='filter_notice'><b>Obey these laws:</b></span>")

	src.laws_sanity_check()
	src.laws.show_laws(who)

// RS Add: Sync shell law changes (Lira, October 2025)
/mob/living/silicon/ai/proc/sync_connected_synthetics(var/message)
	if(!connected_robots || !connected_robots.len)
		return

	var/notice = message
	if(isnull(notice))
		notice = "Law synchronization complete."

	for(var/mob/living/silicon/robot/R in connected_robots)
		if(QDELETED(R))
			continue
		if(!R.lawupdate)
			continue
		R.sync()
		R.notify_of_law_change(notice)

/mob/living/silicon/ai/add_ion_law(var/law)
	..()
	for(var/mob/living/silicon/robot/R in mob_list)
		if(R.lawupdate && (R.connected_ai == src))
			R.show_laws()

// RS Add: Sync shell law changes (Lira, October 2025)
/mob/living/silicon/ai/notify_of_law_change(message)
	..()
	sync_connected_synthetics(message)

/mob/living/silicon/ai/proc/ai_checklaws()
	set category = "AI Commands"
	set name = "State Laws"
	subsystem_law_manager()
