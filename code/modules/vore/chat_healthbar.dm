//Health bars in the game window would be pretty challenging and I don't know how to do that, so I thought this would be a good alternative

/mob/living/proc/chat_healthbar(var/mob/living/reciever, override = FALSE)
	set name = "Healthbar"
	set category = "TEST"
	if(!reciever)
		return
	if(!reciever.client)
		return
	if(!isbelly(src.loc))
		return
	if(!override)
		if(!reciever.client.is_preference_enabled(/datum/client_preference/vore_health_bars))
			return
	var/ourpercent =  (health / maxHealth) * 100
	var/ourbar = ""
	var/obj/belly/ourbelly = src.loc
	var/which_var = "Health"
	if(ourbelly.digest_mode == "Absorb" || ourbelly.digest_mode == "Drain")
		ourpercent = round(((nutrition - 100) / 500) * 100)
		which_var = "Nutrition"

	ourpercent = round(ourpercent)

	switch(ourpercent)
		if(100)
			ourbar = "|▓▓▓▓▓▓▓▓▓▓|"
		if(95 to 99)
			ourbar = "|▓▓▓▓▓▓▓▓▓▒|"
		if(90 to 94)
			ourbar = "|▓▓▓▓▓▓▓▓▓░|"
		if(85 to 89)
			ourbar = "|▓▓▓▓▓▓▓▓▒░|"
		if(80 to 84)
			ourbar = "|▓▓▓▓▓▓▓▓░░|"
		if(75 to 79)
			ourbar = "|▓▓▓▓▓▓▓▒░░|"
		if(70 to 74)
			ourbar = "|▓▓▓▓▓▓▓░░░|"
		if(65 to 69)
			ourbar = "|▓▓▓▓▓▓▒░░░|"
		if(60 to 64)
			ourbar = "|▓▓▓▓▓▓░░░░|"
		if(55 to 59)
			ourbar = "|▓▓▓▓▓▒░░░░|"
		if(50 to 54)
			ourbar = "|▓▓▓▓▓░░░░░|"
		if(45 to 49)
			ourbar = "|▓▓▓▓▒░░░░░|"
		if(40 to 44)
			ourbar = "|▓▓▓▓░░░░░░|"
		if(35 to 39)
			ourbar = "|▓▓▓▒░░░░░░|"
		if(30 to 34)
			ourbar = "|▓▓▓░░░░░░░|"
		if(25 to 29)
			ourbar = "|▓▓▒░░░░░░░|"
		if(20 to 24)
			ourbar = "|▓▓░░░░░░░░|"
		if(15 to 19)
			ourbar = "|▓▒░░░░░░░░|"
		if(10 to 14)
			ourbar = "|▓░░░░░░░░░|"
		if(5 to 9)
			ourbar = "|▒░░░░░░░░░|"
		if(0)
			ourbar = "|░░░░░░░░░░|"
		else
			ourbar = "!░░░░░░░░░░!"

	ourbar = "[ourbar] [which_var] - [src.name]"

	if(stat == UNCONSCIOUS)
		ourbar = "[ourbar] - UNCONSCIOUS"
	else if(stat == DEAD)
		ourbar = "[ourbar] - DEAD"
	if(absorbed)
		ourbar = "<font color='#cd45f0'>[ourbar] - ABSORBED</font>"
	else if(ourpercent > 80)
		ourbar = "<span class='green'>[ourbar] - [ourbelly.digest_mode]ing</span>"
	else if(ourpercent > 50)
		ourbar = "<span class='orange'>[ourbar] - [ourbelly.digest_mode]ing</span>"
	else if(ourpercent > 0)
		ourbar = "<span class='red'>[ourbar] - [ourbelly.digest_mode]ing</span>"
	else
		ourbar = "<span class = 'danger'>[ourbar] - [ourbelly.digest_mode]ing</span>"

	to_chat(reciever,ourbar)

/mob/living/verb/print_healthbars()
	set name = "Print Prey Healthbars"
	set category = "Abilities"

	var/nuffin = TRUE
	for(var/obj/belly/b in vore_organs)
		if(!b.contents.len)
			continue
		to_chat(src, "<span class='notice'>[b.digest_mode] - Within [b.name]:</span>")
		for(var/thing as anything in b.contents)
			if(!isliving(thing))
				continue
			var/mob/living/ourmob = thing
			ourmob.chat_healthbar(src, TRUE)
			nuffin = FALSE
	if(nuffin)
		to_chat(src, "<span class='warning'>There are no mobs within any of your bellies to print health bars for.</span>")
