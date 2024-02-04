GLOBAL_VAR_INIT(ghost_mob_spawn_count, 0)
GLOBAL_LIST_INIT(ghost_spawnable_mobs,list(
	"Rabbit" = /mob/living/simple_mob/vore/rabbit,
	"Red Panda" = /mob/living/simple_mob/vore/redpanda,
	"Fennec" = /mob/living/simple_mob/vore/fennec,
	"Fennix" = /mob/living/simple_mob/vore/fennix,
	"Space Bumblebee" = /mob/living/simple_mob/vore/bee,
	"Space Bear" = /mob/living/simple_mob/animal/space/bear,
	"Voracious Lizard" = /mob/living/simple_mob/vore/aggressive/dino,
	"Giant Frog" = /mob/living/simple_mob/vore/aggressive/frog,
	"Giant Rat" = /mob/living/simple_mob/vore/aggressive/rat,
	"Jelly Blob" = /mob/living/simple_mob/vore/jelly,
	"Wolf" = /mob/living/simple_mob/vore/wolf,
	"Juvenile Solargrub" = /mob/living/simple_mob/vore/solargrub,
	"Sect Queen" = /mob/living/simple_mob/vore/sect_queen,
	"Sect Drone" = /mob/living/simple_mob/vore/sect_drone,
	"Defanged Xenomorph" = /mob/living/simple_mob/vore/xeno_defanged,
	"Panther" = /mob/living/simple_mob/vore/aggressive/panther,
	"Giant Snake" = /mob/living/simple_mob/vore/aggressive/giant_snake,
	"Deathclaw" = /mob/living/simple_mob/vore/aggressive/deathclaw,
	"Otie" = /mob/living/simple_mob/vore/otie,
	"Mutated Otie" =/mob/living/simple_mob/vore/otie/feral,
	"Red Otie" = /mob/living/simple_mob/vore/otie/red,
	"Corrupt Hound" = /mob/living/simple_mob/vore/aggressive/corrupthound,
	"Corrupt Corrupt Hound" = /mob/living/simple_mob/vore/aggressive/corrupthound/prettyboi,
	"Hunter Giant Spider" = /mob/living/simple_mob/animal/giant_spider/hunter,
	"Lurker Giant Spider" = /mob/living/simple_mob/animal/giant_spider/lurker,
	"Pepper Giant Spider" = /mob/living/simple_mob/animal/giant_spider/pepper,
	"Thermic Giant Spider" = /mob/living/simple_mob/animal/giant_spider/thermic,
	"Webslinger Giant Spider" = /mob/living/simple_mob/animal/giant_spider/webslinger,
	"Frost Giant Spider" = /mob/living/simple_mob/animal/giant_spider/frost,
	"Nurse Giant Spider" = /mob/living/simple_mob/animal/giant_spider/nurse/eggless,
	"Giant Spider Queen" = /mob/living/simple_mob/animal/giant_spider/nurse/queen/eggless,
	"Weretiger" = /mob/living/simple_mob/vore/weretiger,
	"Catslug" = /mob/living/simple_mob/vore/alienanimals/catslug,
	"Squirrel" = /mob/living/simple_mob/vore/squirrel/big,
	"Pakkun" =/mob/living/simple_mob/vore/pakkun,
	"Snapdragon" =/mob/living/simple_mob/vore/pakkun/snapdragon,
	"Sand pakkun" = /mob/living/simple_mob/vore/pakkun/sand,
	"Fire pakkun" = /mob/living/simple_mob/vore/pakkun/fire,
	"Amethyst pakkun" = /mob/living/simple_mob/vore/pakkun/purple,
	"Raptor" = /mob/living/simple_mob/vore/raptor,
	"Giant Bat" = /mob/living/simple_mob/vore/bat,
	"Scel (Orange)" = /mob/living/simple_mob/vore/scel/orange,
	"Scel (Blue)" = /mob/living/simple_mob/vore/scel/blue,
	"Scel (Purple)" = /mob/living/simple_mob/vore/scel/purple,
	"Scel (Red)" = /mob/living/simple_mob/vore/scel/red,
	"Scel (Green)" = /mob/living/simple_mob/vore/scel/green
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

	var/choice = tgui_input_list(src, "What type of mob do you want to spawn as?", "Mob Choice", GLOB.ghost_spawnable_mobs)
	if(!choice)
		return

	for(var/mob/living/sus in viewers(get_turf(src)))	//We can spawn the mob literally anywhere,
		if(!isliving(sus))								//but let's make sure that people playing in the round can't see us when we spawn
			continue
		if(sus.ckey)
			to_chat(src, "<span class='danger'>\The [sus] can see you here, try somewhere more discreet!</span>")
			return

	var/mobtype = GLOB.ghost_spawnable_mobs[choice]
	var/mob/living/simple_mob/newPred = new mobtype(get_turf(src))
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
