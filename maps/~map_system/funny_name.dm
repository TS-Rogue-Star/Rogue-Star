/datum/map
	var/list/adj = list(
		"Breathless",
		"Dauntless",
		"Daunted",
		"Enthusiastic"
	)
	var/list/sub = list(
		"Rascals",
		"Peebs",
		"Cheese Puffs",
		"Dreamers"
	)
	var/list/suf = list(
		"of the Radicalscape",
		"in the Gloom",
		"upon the Wind",
		"among the Stars"
	)


/datum/map/proc/funny_name()
	GLOB.special_station_name = "[pick(adj)] [pick(sub)] [pick(suf)]"
	for(var/mob/living/L in player_list)
		if(L.client)
			L.client.update_special_station_name()
