/datum/map
	var/list/adj = list(
		"Aggro",
		"Breathless",
		"Calm",
		"Dauntless",
		"Daunted",
		"Dubious",
		"Enraged",
		"Enthusiastic",
		"Gronchy",
		"Gwumpy",
		"Immense",
		"Incredible",
		"Leggy",
		"Machismo",
		"Mischievous",
		"Pensive",
		"Powerful",
		"Rascally",
		"Rogue",
		"Scrungly",
		"Silly",
		"Soft",
		"Space",
		"Tranquil",
		"Weary",
		"Wise"
	)
	var/list/sub = list(
		"Doofs",
		"Dreamers",
		"Cheese Puffs",
		"Goobers",
		"Gremlins",
		"Kin",
		"Mischief",
		"Peebs",
		"Rascals",
		"Rogues",
		"Station",
		"Teppi"
	)

	var/list/suf = list(
		"of the Radicalscape",
		"in the Gloom",
		"upon the Wind",
		"among the Stars",
		"in the Lasagna",
		"around the Lasagna",
		"on the Lasagna",
		"of the Dark",
		"upon the Space Dog",
		"13",
		"of Horrors",
		"in Toyland",
		"of Terror",
		"from Outer Space",
		"across the 13th Dimension"
	)


/datum/map/proc/funny_name()
	GLOB.special_station_name = "[pick(adj)] [pick(sub)] [pick(suf)]"
	for(var/mob/living/L in player_list)
		if(L.client)
			L.client.update_special_station_name()
