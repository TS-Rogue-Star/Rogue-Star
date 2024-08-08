//RS ADD
GLOBAL_VAR_INIT(vore_game,0)
GLOBAL_LIST_EMPTY(mega_vore_list)	//Global raw score
GLOBAL_LIST_EMPTY(mega_pred_list)	//Global unique pred interaction score
GLOBAL_LIST_EMPTY(mega_prey_list)	//Global unique prey interaction score

/proc/vore_game(var/mob/living/pred,var/mob/living/prey)
	if(!GLOB.vore_game)
		return

	if(pred.ckey && pred.mind && !pred.is_preference_enabled(/datum/client_preference/game_toggle))
		return
	if(prey.ckey && prey.mind && !prey.is_preference_enabled(/datum/client_preference/game_toggle))
		return
	var/valid_pred
	var/valid_prey
	if(pred.ckey && pred.mind)
		GLOB.mega_vore_list[pred.name] = GLOB.mega_vore_list[pred.name] + 1
		to_chat(pred,"<span class = 'notice'>Raw score: [GLOB.mega_vore_list[pred.name]]</span>")

		if(prey.ckey && prey.mind)
			valid_prey = prey.name
		else if(ishuman(prey))
			var/mob/living/carbon/human/P = prey
			if(P.custom_species)
				valid_prey = P.custom_species
			else
				var/datum/species/S = P.species
				valid_prey = S.name
		else
			valid_prey = prey.type

	if(prey.ckey && prey.mind)
		GLOB.mega_vore_list[prey.name] = GLOB.mega_vore_list[prey.name] + 1
		to_chat(prey,"<span class = 'notice'>Raw score: [GLOB.mega_vore_list[prey.name]]</span>")

		if(pred.ckey && pred.mind)
			valid_pred = pred.name
		else if(ishuman(pred))
			var/mob/living/carbon/human/P = pred
			if(P.custom_species)
				valid_pred = P.custom_species
			else
				var/datum/species/S = P.species
				valid_pred = S.name
		else
			valid_pred = pred.type

	if(valid_pred)
		if(!(prey.name in GLOB.mega_prey_list))
			GLOB.mega_prey_list[prey.name] = list()

		var/list/ourlist = GLOB.mega_prey_list[prey.name]

		GLOB.mega_prey_list[prey.name] |= valid_pred
		ourlist = GLOB.mega_prey_list[prey.name]
		var/ournum = ourlist.len
		to_chat(prey,"<span class = 'notice'>Unique prey interaction score: [ournum]</span>")

	if(valid_prey)
		if(!(pred.name in GLOB.mega_pred_list))
			GLOB.mega_pred_list[pred.name] = list()

		var/list/ourlist = GLOB.mega_pred_list[pred.name]

		GLOB.mega_pred_list[pred.name] |= valid_prey
		ourlist = GLOB.mega_pred_list[pred.name]
		var/ournum = ourlist.len
		to_chat(pred,"<span class = 'notice'>Unique pred interaction score: [ournum]</span>")

/client/proc/activate_vore_game()
	set category = "Fun"
	set name = "Vore Game"
	set desc = "Vore scoreboard happen teehee"
	set popup_menu = FALSE

	if(GLOB.vore_game)
		if(tgui_alert(usr, "Do you want to print this global or just for yourself?", "Vore Scoreboard", list("Global", "Just for me")) == "Global")
			to_world(vore_game_scoreboard())
		else
			to_chat(usr, vore_game_scoreboard())

	else if(tgui_alert(usr, "Do you want to begin the vore game? This will be announced globally.", "Vore Scoreboard", list("Begin", "No")) == "Begin")
		GLOB.vore_game = TRUE
		var/dialogue = "<font size='5'><span class = 'danger'>THE VORE GAMES HAVE BEGUN!!!</span></font>\n<span class = 'notice'>Individual vore interactions are now being tracked.</span>"
		to_world(dialogue)

/proc/vore_game_scoreboard()
	var/data
	var/raw_list = ""
	var/pred_list = ""
	var/prey_list = ""

	raw_list = sort_vore_list(GLOB.mega_vore_list, TRUE)

	pred_list = sort_vore_list(GLOB.mega_pred_list)

	prey_list = sort_vore_list(GLOB.mega_prey_list)


	data = "<font size='5'><span class = 'danger'>VORESCORE VOARD START</span></font>\n\n"
	data += "<font size='2'><span class = 'danger'>-TOTALSCORE VOARD-</span></font>\n<span class = 'notice'>"
	data += raw_list
	data += "\n</span><font size='2'><span class = 'danger'>-PREDSCORE VOARD-</span></font>\n<span class = 'notice'>"
	data += pred_list
	data += "\n</span><font size='2'><span class = 'danger'>-PREYSCORE VOARD-</span></font>\n<span class = 'notice'>"
	data += prey_list
	data += "</span>\n"

	return data

/proc/sort_vore_list(var/list/ourlist,var/mode = FALSE)
	var/list/modlist = ourlist.Copy()
	var/list/return_list = list()

	for(var/ababa in ourlist)

		var/biggest
		for(var/thing in modlist)
			if(!biggest)
				biggest = thing
			else
				if(mode)
					var/newval = modlist[thing]
					var/biggestval = modlist[biggest]
					if(newval > biggestval)
						biggest = thing
				else
					var/list/newval = modlist[thing]
					var/list/biggestval = modlist[biggest]
					if(newval.len > biggestval.len)
						biggest = thing

		return_list.Add(biggest)
		modlist.Remove(biggest)
		biggest = null

	var/data = ""
	for(var/thing in return_list)
		if(mode)
			var/ournum = ourlist[thing]
			data += "[thing]: [ournum]\n"
		else
			var/list/ournum = ourlist[thing]
			data += "[thing]: [ournum.len]\n"

	return data

/mob/living/simple_mob/examine(mob/user)
	. = ..()

	if(GLOB.vore_game)
		if(ckey && mind && !is_preference_enabled(/datum/client_preference/game_toggle))
			. += "<span class = 'warning'>They are not participating in the game!</span>"
