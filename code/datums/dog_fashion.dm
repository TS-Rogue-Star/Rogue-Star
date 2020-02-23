/datum/dog_fashion
	var/name
	var/desc
	var/say_list_type
	// Legacy - Probably should be replaced with say_list datums
	var/emote_see
	var/emote_hear
	var/speak

	// This isn't applied to the dog, but are used to override the overlay icon's properties.
	// By default the overlay icon will use the same icon_state/alpha/color as the actual object
	// but if these are non-null they will override.
	var/icon_file
	var/obj_icon_state
	var/obj_alpha
	var/obj_color

/datum/dog_fashion/New(mob/M)
	name = replacetext(name, "REAL_NAME", M.real_name)
	desc = replacetext(desc, "NAME", name)

/datum/dog_fashion/proc/apply(mob/living/simple_mob/animal/passive/dog/D)
	if(name)
		D.name = name
	if(desc)
		D.desc = desc
	if(say_list_type)
		D.say_list = new say_list_type(D)
	if(D.say_list)
		if(emote_see)
			D.say_list.emote_see = emote_see
		if(emote_hear)
			D.say_list.emote_hear = emote_hear
		if(speak)
			D.say_list.speak = speak

/datum/dog_fashion/proc/get_overlay(var/obj/item/item, var/dir)
	var/icon_state = obj_icon_state ? obj_icon_state : item?.icon_state
	var/alpha = obj_alpha ? obj_alpha : item?.alpha
	var/color = obj_color ? obj_color : item?.color
	if(icon_file && icon_state)
		var/image/corgI = image(icon_file, icon_state, dir = dir)
		corgI.alpha = alpha
		corgI.color = color
		return corgI

/datum/dog_fashion/head
	icon_file = 'icons/mob/corgi_head.dmi'

/datum/dog_fashion/back
	icon_file = 'icons/mob/corgi_back.dmi'

/datum/dog_fashion/head/hardhat/apply(mob/living/simple_mob/animal/passive/dog/D)
	..()
	D.set_light(4)

/datum/dog_fashion/head/helmet
	name = "Sergeant REAL_NAME"
	desc = "The ever-loyal, the ever-vigilant."

/datum/dog_fashion/head/chef
	name = "Sous chef REAL_NAME"
	desc = "Your food will be taste-tested.  All of it."

/datum/dog_fashion/head/captain
	name = "Captain REAL_NAME"
	desc = "Probably better than the last captain."

/datum/dog_fashion/head/kitty
	name = "Runtime"
	desc = "It's a cute little kitty-cat! ... wait ... what the hell?"
	say_list_type = /datum/say_list/cat

/datum/dog_fashion/head/rabbit
	name = "Hoppy"
	desc = "This is Hoppy. It's a corgi-...urmm... bunny rabbit."
	say_list_type = /datum/say_list/dog/rabbit_hat

/datum/say_list/dog/rabbit_hat
	emote_see = list("twitches its nose", "hops around a bit")

/datum/dog_fashion/head/beret
	name = "Yann"
	desc = "Mon dieu! C'est un chien!"
	speak = list("le woof!", "le bark!", "JAPPE!!")
	emote_see = list("cowers in fear.", "surrenders.", "plays dead.","looks as though there is a wall in front of him.")

/datum/dog_fashion/head/detective
	name = "Detective REAL_NAME"
	desc = "NAME sees through your lies..."
	emote_see = list("investigates the area.","sniffs around for clues.","searches for scooby snacks.","takes a candycorn from the hat.")

/datum/dog_fashion/head/nurse
	name = "Nurse REAL_NAME"
	desc = "NAME needs 100cc of beef jerky... STAT!"

/datum/dog_fashion/head/pirate
	name = "Pirate-title Pirate-name"
	desc = "Yaarghh!! Thar' be a scurvy dog!"
	emote_see = list("hunts for treasure.","stares coldly...","gnashes his tiny corgi teeth!")
	emote_hear = list("growls ferociously!", "snarls.")
	speak = list("Arrrrgh!!","Grrrrrr!")

/datum/dog_fashion/head/pirate/New(mob/M)
	..()
	name = "[pick("Ol'","Scurvy","Black","Rum","Gammy","Bloody","Gangrene","Death","Long-John")] [pick("kibble","leg","beard","tooth","poop-deck","Threepwood","Le Chuck","corsair","Silver","Crusoe")]"

/datum/dog_fashion/head/ushanka
	name = "Communist-title Realname"
	desc = "A follower of Karl Barx."
	say_list_type = /datum/say_list/dog/ushanka_hat

/datum/say_list/dog/ushanka_hat
	emote_see = list("contemplates the failings of the capitalist economic model.", "ponders the pros and cons of vanguardism.")

/datum/dog_fashion/head/ushanka/New(mob/M)
	..()
	name = "[pick("Comrade","Commissar","Glorious Leader")] [M.real_name]"

/datum/dog_fashion/head/warden
	name = "Officer REAL_NAME"
	desc = "Stop right there criminal scum!"

/datum/dog_fashion/head/blue_wizard
	name = "Grandwizard REAL_NAME"
	speak = list("YAP", "Woof!", "Bark!", "AUUUUUU", "EI  NATH!")

/datum/dog_fashion/head/red_wizard
	name = "Pyromancer REAL_NAME"
	speak = list("YAP", "Woof!", "Bark!", "AUUUUUU", "ONI SOMA!")

/datum/dog_fashion/head/cardborg
	name = "Borgi"
	speak = list("Ping!","Beep!","Woof!")
	emote_see = list("goes rogue.", "sniffs out non-humans.")
	desc = "Result of robotics budget cuts."

/datum/dog_fashion/head/ghost
	name = "\improper Ghost"
	speak = list("WoooOOOooo~","AUUUUUUUUUUUUUUUUUU")
	emote_see = list("stumbles around.", "shivers.")
	emote_hear = list("howls!","groans.")
	desc = "Spooky!"
	obj_icon_state = "sheet"

/datum/dog_fashion/head/santa
	name = "Santa's Corgi Helper"
	emote_hear = list("barks Christmas songs.", "yaps merrily!")
	emote_see = list("looks for presents.", "checks his list.")
	desc = "He's very fond of milk and cookies."

/datum/dog_fashion/head/cargo_tech
	name = "Corgi Tech REAL_NAME"
	desc = "The reason your yellow gloves have chew-marks."

/datum/dog_fashion/head/reindeer
	name = "REAL_NAME the red-nosed Corgi"
	emote_hear = list("lights the way!", "illuminates.", "yaps!")
	desc = "He has a very shiny nose."

/datum/dog_fashion/head/reindeer/apply(mob/living/simple_mob/animal/passive/dog/D)
	..()
	D.set_light(2, 2, LIGHT_COLOR_RED)

/datum/dog_fashion/head/sombrero
	name = "Segnor REAL_NAME"
	desc = "You must respect Elder Dogname"

/datum/dog_fashion/head/sombrero/New(mob/M)
	..()
	desc = "You must respect Elder [M.real_name]."

/datum/dog_fashion/head/hop
	name = "Lieutenant REAL_NAME"
	desc = "Can actually be trusted to not run off on his own."

/datum/dog_fashion/head/deathsquad
	name = "Trooper REAL_NAME"
	desc = "That's not red paint. That's real corgi blood."

/datum/dog_fashion/head/clown
	name = "REAL_NAME the Clown"
	desc = "Honkman's best friend."
	speak = list("HONK!", "Honk!")
	emote_see = list("plays tricks.", "slips.")

/datum/dog_fashion/back/deathsquad
	name = "Trooper REAL_NAME"
	desc = "That's not red paint. That's real corgi blood."

/datum/dog_fashion/head/not_ian
	name = "Definitely Not REAL_NAME"
	desc = "That's Definitely Not Dogname"

/datum/dog_fashion/head/not_ian/New(mob/M)
	..()
	desc = "That's Definitely Not [M.real_name]."

/datum/dog_fashion/back/hardsuit
	name = "Space Explorer REAL_NAME"
	desc = "That's one small step for a corgi. One giant yap for corgikind."

/datum/dog_fashion/back/hardsuit/apply(mob/living/simple_mob/animal/passive/dog/D)
	..()
	D.min_oxy = 0
	D.max_oxy = 0
	D.min_tox = 0
	D.max_tox = 0
	D.min_co2 = 0
	D.max_co2 = 0
	D.min_n2 = 0
	D.max_n2 = 0
	D.minbodytemp = 0
