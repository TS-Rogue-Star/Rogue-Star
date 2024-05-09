GLOBAL_VAR_INIT(ghost_mob_spawn_count, 0)
//Keep it organized!!!
GLOBAL_LIST_INIT(ghost_spawnable_mobs,list(
	"Bat - Giant" = /mob/living/simple_mob/vore/bat,
	"Bear - Space" = /mob/living/simple_mob/animal/space/bear,
	"Bumblebee" = /mob/living/simple_mob/vore/bee,
	"Catslug" = /mob/living/simple_mob/vore/alienanimals/catslug,
	"Corrupt Hound" = /mob/living/simple_mob/vore/aggressive/corrupthound,
	"Corrupt Corrupt Hound" = /mob/living/simple_mob/vore/aggressive/corrupthound/prettyboi,
	"Deathclaw" = /mob/living/simple_mob/vore/aggressive/deathclaw,
	"Deer" = /mob/living/simple_mob/vore/deer,
	"Defanged Xenomorph" = /mob/living/simple_mob/vore/xeno_defanged,
	"Doglin" = /mob/living/simple_mob/vore/doglin/basic,
	"Dragon" = /mob/living/simple_mob/vore/aggressive/dragon,
	"Dragon - V3b" = /mob/living/simple_mob/vore/aggressive/dragon/virgo3b,
	"Dragon - Giant" = /mob/living/simple_mob/vore/bigdragon/friendly/maintpred,
	"Dust Jumper" = /mob/living/simple_mob/vore/alienanimals/dustjumper,
	"Fennec" = /mob/living/simple_mob/vore/fennec,
	"Fennix" = /mob/living/simple_mob/vore/fennix,
	"Frog - Giant" = /mob/living/simple_mob/vore/aggressive/frog,
	"Jelly Blob" = /mob/living/simple_mob/vore/jelly,
	"Juvenile Solargrub" = /mob/living/simple_mob/vore/solargrub,
	"Leopardmander Selection" = list(
		"Leopardmander" = /mob/living/simple_mob/vore/leopardmander,
		"Leopardmander - Blue" = /mob/living/simple_mob/vore/leopardmander/blue,
		"Leopardmander - Exotic" = /mob/living/simple_mob/vore/leopardmander/exotic
	),
	"Morph" = /mob/living/simple_mob/vore/morph,
	"Otie Selection" = list(
		"Otie" = /mob/living/simple_mob/vore/otie,
		"Chubby Otie" = /mob/living/simple_mob/vore/otie/friendly/chubby,
		"Tamed Otie" = /mob/living/simple_mob/vore/otie/cotie,
		"Chubby Tamed Otie" = /mob/living/simple_mob/vore/otie/cotie/chubby,
		"Guard Otie" = /mob/living/simple_mob/vore/otie/security,
		"Chubby Guard Otie" = /mob/living/simple_mob/vore/otie/security/chubby,
		"Mutated Otie" =/mob/living/simple_mob/vore/otie/feral,
		"Chubby Mutated Feral Otie" = /mob/living/simple_mob/vore/otie/feral/chubby,
		"Mutated Guard Otie" = /mob/living/simple_mob/vore/otie/security/phoron,
		"Red Otie" = /mob/living/simple_mob/vore/otie/red,
		"Chubby Red Otie" = /mob/living/simple_mob/vore/otie/red/chubby,
		"Red Guard Otie" = /mob/living/simple_mob/vore/otie/security/phoron/red,
		"Chubby Red Guard Otie" = /mob/living/simple_mob/vore/otie/security/phoron/red/chubby
	),
	"Pakkun Selection" = list(
		"Pakkun" =/mob/living/simple_mob/vore/pakkun,
		"Pakkun - Snapdragon" =/mob/living/simple_mob/vore/pakkun/snapdragon,
		"Pakkun - Sand" = /mob/living/simple_mob/vore/pakkun/sand,
		"Pakkun - Fire" = /mob/living/simple_mob/vore/pakkun/fire,
		"Pakkun - Amethyst" = /mob/living/simple_mob/vore/pakkun/purple
	),
	"Panther" = /mob/living/simple_mob/vore/aggressive/panther,
	"Sect Queen" = /mob/living/simple_mob/vore/sect_queen,
	"Sect Drone" = /mob/living/simple_mob/vore/sect_drone,
	"Rabbit" = /mob/living/simple_mob/vore/rabbit,
	"Raptor" = /mob/living/simple_mob/vore/raptor,
	"Rat - Giant" = /mob/living/simple_mob/vore/aggressive/rat,
	"Red Panda" = /mob/living/simple_mob/vore/redpanda,
	"Seagull" = /mob/living/simple_mob/vore/seagull,
	"Scel Selection" = list(
		"Scel (Orange)" = /mob/living/simple_mob/vore/scel/orange,
		"Scel (Blue)" = /mob/living/simple_mob/vore/scel/blue,
		"Scel (Purple)" = /mob/living/simple_mob/vore/scel/purple,
		"Scel (Red)" = /mob/living/simple_mob/vore/scel/red,
		"Scel (Green)" = /mob/living/simple_mob/vore/scel/green
	),
	"Snake - Giant" = /mob/living/simple_mob/vore/aggressive/giant_snake,
	"Spider Selection" = list(
		"Spider - Hunter" = /mob/living/simple_mob/animal/giant_spider/hunter,
		"Spider - Lurker" = /mob/living/simple_mob/animal/giant_spider/lurker,
		"Spider - Pepper" = /mob/living/simple_mob/animal/giant_spider/pepper,
		"Spider - Thermic" = /mob/living/simple_mob/animal/giant_spider/thermic,
		"Spider - Webslinger" = /mob/living/simple_mob/animal/giant_spider/webslinger,
		"Spider - Frost" = /mob/living/simple_mob/animal/giant_spider/frost,
		"Spider - Nurse" = /mob/living/simple_mob/animal/giant_spider/nurse/eggless,
		"Spider - Queen" = /mob/living/simple_mob/animal/giant_spider/nurse/queen/eggless
	),
	"Squirrel" = /mob/living/simple_mob/vore/squirrel/big,
	"Teppi" = /mob/living/simple_mob/vore/alienanimals/teppi/customizable,
	"Voracious Lizard" = /mob/living/simple_mob/vore/aggressive/dino,
	"Weretiger" = /mob/living/simple_mob/vore/weretiger,
	"Wolf Selection" = list(
		"Wolf" = /mob/living/simple_mob/vore/wolf,
		"Wolf - Dire" = /mob/living/simple_mob/vore/wolf/direwolf,
		"Wolf - Dire - Sec" = /mob/living/simple_mob/vore/wolf/direwolf/sec,
		"Wolf - Dog" = /mob/living/simple_mob/vore/wolf/direwolf/dog,
		"Wolf - Dog - Sec" = /mob/living/simple_mob/vore/wolf/direwolf/dog/sec,
		"Wolf - Andrewsarchus" = /mob/living/simple_mob/vore/wolf/direwolf/andrews
	)
	))

/mob/observer/dead/verb/join_as_simplemob()	//Copypasta from join_as_drone()
	set category = "Ghost"
	set name = "Join As Mob"
	set desc = "Join as a simple mob if conditions are right!"

	if(ticker.current_state < GAME_STATE_PLAYING)
		to_chat(src, "<span class='danger'>The game hasn't started yet!</span>")
		return

	if(!(config.allow_ghost_mob_spawn))
		to_chat(src, "<span class='danger'>That verb is not currently permitted.</span>")
		return

	if (!src.stat)
		return

	if (usr != src)
		return 0 //something is terribly wrong

	if(jobban_isbanned(src, "GhostRoles"))
		to_chat(usr, "<span class='danger'>You are banned from playing as ghost roles, and so can not spawn as a mob.</span>")
		return

	if(GLOB.ghost_mob_spawn_count >= config.ghost_mob_count)
		to_chat(src, "<span class='danger'>Too many mobs have already been spawned, you can not spawn as a mob at this time.</span>")
		return

	if(!MayRespawn(1))
		return
	var/turf/ourturf = get_turf(src)

	if(ourturf.check_density())
		to_chat(src, "<span class='danger'>Something is in the way! Try somewhere else!</span>")
		return

	var/deathtime = world.time - src.timeofdeath
	var/deathtimeminutes = round(deathtime / (1 MINUTE))
	var/pluralcheck = "minute"
	if(deathtimeminutes == 0)
		pluralcheck = ""
	else if(deathtimeminutes == 1)
		pluralcheck = " [deathtimeminutes] minute and"
	else if(deathtimeminutes > 1)
		pluralcheck = " [deathtimeminutes] minutes and"
	var/deathtimeseconds = round((deathtime - deathtimeminutes * 1 MINUTE) / 10,1)

	if (deathtime < 5 MINUTES)
		to_chat(usr, "You have been dead for[pluralcheck] [deathtimeseconds] seconds.")
		to_chat(usr, "You must wait 5 minutes to spawn as a mob!")
		return

	var/mobtype
	var/choice = tgui_input_list(src, "What type of mob do you want to spawn as?", "Mob Choice", GLOB.ghost_spawnable_mobs)
	if(!choice)
		return

	if(islist(GLOB.ghost_spawnable_mobs[choice]))
		var/list/ourlist = GLOB.ghost_spawnable_mobs[choice]
		var/newchoice = tgui_input_list(src, "Which one?", "[choice]", ourlist)
		if(!newchoice)
			return
		choice = newchoice
		mobtype = ourlist[newchoice]
	else
		mobtype = GLOB.ghost_spawnable_mobs[choice]

	if(tgui_alert(src, "Are you sure you want to play as [choice]?","Confirmation",list("No","Yes")) != "Yes")
		return

	for(var/mob/living/sus in viewers(ourturf))	//We can spawn the mob literally anywhere,
		if(!isliving(sus))								//but let's make sure that people playing in the round can't see us when we spawn
			continue
		if(sus.ckey)
			to_chat(src, "<span class='danger'>\The [sus] can see you here, try somewhere more discreet!</span>")
			return

	var/mob/living/simple_mob/newPred = new mobtype(ourturf)
	qdel(newPred.ai_holder)
	newPred.ai_holder = null
	if(mind)
		mind.transfer_to(newPred)
	to_chat(src, "<span class='notice'>You are <b>[newPred]</b>, somehow having gotten aboard the station in search of food. \
	You are wary of environment around you, but you do feel rather peckish. Stick around dark, secluded places to avoid danger or, \
	if you are cute enough, try to make friends with this place's inhabitants.</span>")
	to_chat(src, "<span class='critical'>Please be advised, this role is NOT AN ANTAGONIST.</span>")
	to_chat(src, "<span class='warning'>You may be a spooky space monster, but your role is to facilitate spooky space monster roleplay, not to fight the station and kill people. You can of course eat and/or digest people as you like if OOC prefs align, but this should be done as part of roleplay. If you intend to fight the station and kill people and such, you need permission from the staff team. GENERALLY, this role should avoid well populated areas. You’re a weird spooky space monster, so the bar is probably not where you’d want to go if you intend to survive. Of course, you’re welcome to try to make friends and roleplay how you will in this regard, but something to keep in mind.</span>")

	log_and_message_admins("[newPred.ckey] used Join As Mob to become a [newPred].")
	GLOB.ghost_mob_spawn_count ++

	newPred.ckey = src.ckey
	newPred.visible_message("<span class='warning'>[newPred] emerges from somewhere!</span>")

	newPred.mob_radio = new /obj/item/device/radio/headset/mob_headset(newPred)
	newPred.mob_radio.frequency = PUB_FREQ
	newPred.sight |= SEE_SELF
	newPred.sight |= SEE_MOBS

/datum/admins/proc/add_ghost_mob_spawns()
	set category = "Fun"
	set name = "Adjust total ghost mob spawns"
	set desc = "Lets you adjust how many mobs ghosts can spawn as."

	if(!check_rights(R_ADMIN))
		return

	var/amount = tgui_input_number(usr, "How many mobs should ghosts be able to spawn as?", "How many mobs", config.ghost_mob_count)
	if(amount)
		config.ghost_mob_count = amount
	else
		to_chat(usr, "<span class='warning'>Cancelled. The value was not updated.</span>")
