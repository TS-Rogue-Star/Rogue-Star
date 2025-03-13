//RS FILE
/mob/living/simple_mob/vore/doglin
	name = "doglin"
	desc = "A fluffy beastie. It looks something like a dog, or maybe a goblin. Who can say!"
	tt_desc = "doglin"

	icon_state = "doglin"
	icon_living = "doglin"
	icon_dead = "doglin_dead"
	icon_rest = "doglin_rest"	//DO a proper rest sprite later
	icon = 'icons/rogue-star/mobx32.dmi'

	faction = "dog"
	maxHealth = 100
	health = 100
	movement_cooldown = -1

	response_help = "pets"
	response_disarm = "rudely paps"
	response_harm = "punches"

	harm_intent_damage = 3
	melee_damage_lower = 5
	melee_damage_upper = 1
	catalogue_data = list(/datum/category_item/catalogue/fauna/doglin)

	attacktext = list("nipped", "chomped", "slapped", "gnaws on")
	attack_sound = 'sound/voice/bork.ogg'
	friendly = list("snoofs", "nuzzles", "yips at", "smooshes on")

	ai_holder_type = /datum/ai_holder/simple_mob/doglin

	mob_size = MOB_SMALL

	has_langs = list(LANGUAGE_ANIMAL, LANGUAGE_CANILUNZT)
	say_list_type = /datum/say_list/doglin

	has_hands = TRUE
	humanoid_hands = TRUE

	load_owner = "seriouslydontsavethis"	//they smort

	holder_type = /obj/item/weapon/holder/doglin

	var/static/list/overlays_cache = list()
	var/yip_cooldown = 0
	var/doglin_special = TRUE
	var/picked_color = FALSE

///// VORE RELATED /////
	vore_active = 1

	swallowTime = 2 SECONDS
	vore_capacity = 2
	vore_bump_chance = 5
	vore_bump_emote	= "greedily homms at"
	vore_digest_chance = 0
	vore_absorb_chance = 0
	vore_escape_chance = 10
	vore_pounce_chance = 5
	vore_ignores_undigestable = 0
	vore_default_mode = DM_SELECT
	vore_icons = SA_ICON_LIVING
	vore_stomach_name = "stomach"
	vore_stomach_flavor = "You have found yourself pumping on down, down, down into this extremely soft dog. The slick touches of pulsing walls roll over you in greedy fashion as you're swallowed away, the flesh forms to your figure as in an instant the world is replaced by the hot squeeze of canine gullet. And in another moment a heavy GLLRMMPTCH seals you away, the dog tossing its head eagerly, the way forward stretching to accommodate your shape as you are greedily guzzled down. The wrinkled, doughy walls pulse against you in time to the creature's steady heartbeat. The sounds of the outside world muffled into obscure tones as the wet, grumbling rolls of this soft creature's gut hold you, churning you tightly such that no part of you is spared from these gastric affections."
	vore_default_contamination_flavor = "Wet"
	vore_default_contamination_color = "grey"
	vore_default_item_mode = IM_DIGEST

/mob/living/simple_mob/vore/doglin/basic
	doglin_special = FALSE

/mob/living/simple_mob/vore/doglin/Initialize()
	. = ..()
	update_icon()
	if(name == "doglin")
		funny_name()
	if(!doglin_special)
		return
	if(!color && prob(50))
		color = random_color()
	if(prob(25))
		var/ournum = round(rand(50,150), 25) / 100
		resize(ournum)

/mob/living/simple_mob/vore/doglin/update_icon()
	. = ..()

	if(stat != CONSCIOUS || resting)
		return
	var/image/eye_image = overlays_cache["doglin-eyes"]
	if(!eye_image)
		eye_image = image(icon,null,"doglin-eyes")
		eye_image.color = "#FFFFFF"
		eye_image.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
		overlays_cache["doglin-eyes"] = eye_image
	add_overlay(eye_image)

/mob/living/simple_mob/vore/doglin/New()
	..()

	verbs += /mob/living/proc/hide


/mob/living/simple_mob/vore/doglin/Life()
	. = ..()

	if(client)
		return

	if(yip_cooldown)
		yip_cooldown --
	if(yip_cooldown < 0)
		yip_cooldown = 0

	if(resting && prob(1))
		lay_down()
		ai_holder.go_wake()

/mob/living/simple_mob/vore/doglin/say(message, datum/language/speaking, whispering)
	. = ..()
	if(stat == CONSCIOUS && !resting)
		flick(icon_state + "-y", src)

/mob/living/simple_mob/vore/doglin/proc/funny_name()
	var/list/adjectives = list(
		"zesty",
		"sweet",
		"sour",
		"bitter",
		"kind",
		"wise",
		"grouchy",
		"soft",
		"plump",
		"fluffy",
		"smirking",
		"dozey",
		"thin",
		"weird",
		"silly",
		"juicy",
		"frowning",
		"smiling",
		"spicy",
		"cool",
		"cute",
		"dubeous",
		"immense",
		"blepping",
		"mischieveous",
		"fussy",
		"pleasant",
		"unpleasant",
		"ugly",
		"elderly",
		"anxious",
		"carefree",
		"shy",
		"mesmerized",
		"hyper",
		"lethargic",
		"dwarf",
		"outrageous",
		"bodacious",
		"desperate",
		"moist",
		"clammy",
		"effeminate",
		"macho",
		"cute",
		"haunted",
		"distinguished",
		"evil",
		"pure",
		"cantankerous",
		"suspicious"
	)

	var/list/subject = list(
		"doglin",
		"forager",
		"hunter",
		"renegade",
		"farmer",
		"tunneller",
		"tender",
		"layabout",
		"vagabond",
		"looker",
		"watcher",
		"gazer",
		"breeder",
		"chopper",
		"chomper",
		"lust",
		"glutton",
		"greed",
		"sloth",
		"wrath",
		"pride",
		"need",
		"gofer",
		"actor",
		"worker",
		"leader",
		"teacher",
		"baker",
		"driver",
		"soldier",
		"plumber",
		"dresser",
		"diver",
		"delver",
		"maleficar",
		"gentledoglin"
	)

	var/list/suf = list(
		"ist",
		"kin",
		"ling",
		"chan",
		"kun",
		"ful",
		"y",
		"mancer",
		"lin"
	)

	name = "[pick(adjectives)] [pick(subject)]"

	if(prob(25))
		name = "[name][pick(suf)]"

/mob/living/simple_mob/vore/doglin/proc/yapyapyap(who, mob/living/speaker)
	if(prob(50))
		ai_holder.delayed_say("*yip[who]", speaker, max = 10)
	else
		ai_holder.delayed_say("*yap[who]", speaker, max = 10)
	yip_cooldown += rand(1,50)

/mob/living/simple_mob/vore/doglin/verb/dig()
	set name = "Dig"
	set category = "Abilities"

	if(!isturf(src.loc) || isspace(src.loc) || istype(src.loc, /turf/simulated/floor/water))
		to_chat(src, "<span class = 'warning'>You can't do that here!</span>")
		return
	var/turf/ourturf = get_turf(src)

	if(!(istype(src.loc, /turf/simulated/floor/outdoors) || istype(src.loc, /turf/simulated/floor/tiled) || istype(src.loc, /turf/simulated/floor)))
		to_chat(src, "<span class = 'warning'>You can't do that here!</span>")
		return

	if(!do_after(src, 10 SECONDS, src.loc, exclusive = TRUE))
		return
	if(ourturf.check_density(FALSE,TRUE))
		to_chat(src, "<span class = 'warning'>Something is in the way!</span>")
		return
	for(var/stuff in ourturf.contents)
		if(istype(stuff,/obj/structure/doglin_hole))
			to_chat(src, "<span class = 'warning'>There is already a hole here!</span>")
			return
	var/obj/structure/doglin_hole/hole = new(ourturf)

	hole.name = "[src.name] hole"

/datum/say_list/doglin
	speak = list("yip", "yap")
	emote_hear = list("barks", "woofs", "yaps", "yips", "pants", "sniffs","snoofs")
	emote_see = list("wags their tail", "stretches", "yawns", "swivels their ears", "wiggles around", "does a little dance")
	say_maybe_target = list("*growl")
	say_got_target = list("*roarbark")

/mob/living/simple_mob/vore/doglin/init_vore()
	..()
	var/obj/belly/B = vore_selected
	B.name = "stomach"
	B.desc = "You have found yourself pumping on down, down, down into this doglin. The slick touches of pulsing walls roll over you in greedy fashion as you're swallowed away, the flesh forms to your figure as in an instant the world is replaced by the hot squeeze of canine gullet. And in another moment a heavy GLLRMMPTCH seals you away, the doglin tossing its head eagerly, the way forward stretching to accommodate your shape as you are greedily guzzled down. The wrinkled, doughy walls pulse against you in time to the creature's steady heartbeat. The sounds of the outside world muffled into obscure tones as the wet, grumbling rolls of this soft creature's gut hold you, churning you tightly such that no part of you is spared from these gastric affections."

	B.emote_lists[DM_HOLD] = list(
		"You can feel yourself shift and sway as the doglin moves around. Your figure held tightly there had little room to move in that organic gloom, but every wandering step is another jostling quake that shakes through the canine frame and rocks you once again.",
		"It is hard to hear much of anything over the grumbling fleshy sounds of the stomach walls pressing to you. The wet sound of flesh gliding over you too was ever-present as the walls encroach upon your personal space. And beyond that, the steady booming of the doglin's heart throbs in your ears, a relaxing drone of excited thumping. Any sounds from the outside world are muffled such that they are hard to hear, as the canine walls hold on to you greedily.",
		"You can hear the vague dragging, creaking sounds of the flesh holding you stretching and compressing with the doglin's movements. Any time you press out, the walls seem to groan and flex in to smother you heavily for a few moments. ",
		"When you shift your weight to try to find a more comfortable position you can feel your weight stretch the chamber around you a little more, and it responds by collapsing in on you more tightly! Forming to you with heavily insistence, grinding against your curves. Holding you firmly for a few moments, before slowly relaxing...",
		"The heat of the doglin's body soaks into your form and relaxes your muscles. It's easy to let yourself go limp, to be squeezed and carried by this soft predator. The sway of its body, the swing of its gait, all enough to lull anyone who likes such things into a deeply relaxed state, as you're rocked and supported, squeezed deep within the gut of this woof. Possessively held, kept.",
		"Thick slime soaks your form as the doglin's insides churn over you. There is no part of you that is not totally soaked in it before too long as the steady gastric motions massage you from head to toe. Any pushes or squirms only get the affected flesh to cling more tightly, and to press back. It's very hard to get any personal space!",
		"Beyond the grumbling gurgles and the ever-present drumming of the doglin's heart, you can actually hear, more faintly, the whooshing of the canine's breath. The slow draw in coming with a vague tightening of your surroundings, while the doglin's soft, whooshing exhales make your surroundings more relaxed, easy to sink in against.")

	B.emote_lists[DM_ABSORB] = list(
		"You can feel the weight of the doglin shift as it moves around. Your figure held tightly there had absolutely no room to move in that organic gloom. Every moment those pumping walls seem to squeeze over you tighter, every wandering step the doglin takes is another jostling quake that seems to sink you that much deeper into the doglin's flesh, the doglin's body steadily collapsing in to claim you.",
		"It is hard to hear much of anything over the smothering press of stomach walls pressing to you, forming to your features. The tarry flesh you are slowly sinking into squelches here and there as it flows over your features. The sound of the doglin's body absorbing you is oddly quiet. No bubbling or glooping. Just one body slowly blending into and becoming one with another. And beyond all that, the steady booming of the doglin's heart throbs in your ears, moment by moment that sound seems to tug at you, coursing through you as much as the doglin you are steadily becoming a part of. Any sounds from the outside world are muffled such that they are hard to hear, as you sink into the walls of this canine predator.",
		"You can hear the vague dragging, creaking sounds of the flesh holding you stretching and compressing with the doglin's movements. Any time you press out, the walls seem to simply flow over you, and allow whatever pushed out to sink in that much more. The swell on the doglin's tummy shrinking that much faster... ",
		"When you shift your weight to try to get some space. you can feel your weight simply sink into that flesh, the folds forming around you tightly, and the deeper you sink, the harder it gets to move. The pressure never seems to let up as the tide of flesh holding you slowly overcomes your form.",
		"As the seemingly molten heat of this doglin's flesh flows over you, it's easy to let yourself go limp, to just give in and become one with this creature that so obviously wanted you, and indeed, unless something happened to stop this, you soon would be... The doglin tail swaying in a knowing arc as you are added to its figure. Squeezed, tucked away, kept.",
		"The thick slimes that coat your form do nothing to keep the molten flesh of this doglin's stomach from advancing across your figure and claiming you up. Soon there's not a single part of you that is not totally inundated in the deep press of a woof's  gastric massage. Any pushes or squirms only get the affected flesh to cling more tightly, and to press back, flowing over your form, deeper, deeper.",
		"Beyond the squelching, clinging tide of doglin flesh working to make the two of you one, and the ever-present drumming of the doglin's heart, you can actually hear, more faintly, the whooshing of the canine's breath. The slow draw in coming with a vague tightening of your surroundings, while the doglin's soft, whooshing exhales make your surroundings more relaxed. And you realize suddenly that the doglin's breathing seem to bring you relief even as you are totally smothered in the canine's insistent gastric affections!")

	B.emote_lists[DM_DIGEST] = list(
		"As the doglin goes about its business, you can feel the shift your weight sway on its tummy. The gurgling glorping sounds that come with the squeezing, kneading, massaging motions let you know that you're held tight, churned. Dog food.",
		"It is hard to hear much of anything over the roaring gurgles of stomach walls churning over you. The wet sound of flesh grinding heavily over you too was ever-present as the walls encroach upon your personal space, lathering you in tingly, syrupy thick slimes. And beyond that, the steady booming of the doglin's heart throbs in your ears, a drone of excited thumping. Any sounds from the outside world are muffled such that they are hard to hear, as the canine walls churn on to you greedily.",
		"You can hear the vague dragging, creaking sounds of the flesh holding you stretching and compressing with the doglin's movements. The walls seem to constantly flex and squeeze across you, pressing in against you, massaging thick slime into your figure, steadily trying to soften up your outer layers...",
		"When you try to shift your weight to try to find a more comfortable position, you find that those heavy walls pumping over you make it hard to move at all. You can feel the weight of the doglin pressing in all around you even without those muscles flexing and throbbing across your form. It forms to you with heavily insistence, grinding against your curves, churning that bubbling gloop into you. Holding you firm and heavy as that stomach does its work...",
		"The heat of the doglin's body soaks into your form and relaxes your muscles. It's easy to let yourself go limp, to just completely give in to this soft predator. The sway of its body, the swing of its gait, all enough to lull anyone who likes such things into a deeply relaxed state. Churned and slathered, massaged by doughy wrinkled walls deep within the gut of this woof. Possessively held within that needy chamber.",
		"Thick slime soaks your form as the doglin's insides churn over you. There is no part of you that is not totally soaked in it before too long as the steady gastric motions massage you from head to toe. Any pushes or squirms only get the affected flesh to cling more tightly, and to press back. It's very hard to get any personal space!",
		"Beyond the grumbling gurgles and the ever-present drumming of the doglin's heart, you can actually hear, more faintly, the whooshing of the canine's breath. The slow draw in coming with a vague tightening of your surroundings, while the doglin's soft, whooshing exhales make your surroundings more relaxed, easy to sink in against. Occasionally though everything would go all tight and cramped! And somewhere up above you can hear the doglin let out a dainty little belch...")

	B.digest_brute = 1
	B.digest_burn = 1
	B.colorization_enabled = TRUE
	B.mode_flags = DM_FLAG_THICKBELLY | DM_FLAG_NUMBING
	B.belly_fullscreen = "anibelly"
	B.struggle_messages_inside = list(
		"Your struggling only causes %pred's doughy gut to smother you against those wrinkled walls...",
		"As you squirm, %pred's %belly flexxes over you heavily, forming you back into a small ball...",
		"You push out at those heavy wrinkled walls with all your might and they collapse back in on you! Clinging and churning over you heavily for a few minutes!!!",
		"As you struggle against the gut of this doglin, you can feel a squeeze roll over you from the bottom to the top! The walls cling to you a little tighter then as the doglin emits a soft little burp...",
		"You try to squirm, but you can't even move as those heavy walls throb and pulse and churn around you.",
		"You paddle against the fleshy walls of %pred's %belly, making a little space for yourself for a moment, before the wrinkled surface bounces back against you.",
		"The slick walls are doughy, smushy under your fingers, and very difficult to grip!  The flesh pulses under your grip in time with %pred's heartbeat.",
		"Your hands slip and slide over the slick slimes of %pred's %belly as you struggle to escape! The walls pulse and squeeze around you greedily.",
		"%pred lets out a happy little awoo, rocking their hips to jostle you as you squirm, while the weight of those walls closes in on you, squeezing you tightly!",
		"%pred's %belly glorgles around you as you push and struggle within! The squashy walls are always reluctant to give ground, and the moment your struggles lax, they redouble their efforts in smothering all the fight out of you!")
	B.struggle_messages_outside = list(
		"A vague shape briefly swells on %pred's %belly as something moves inside...",
		"Something shifts within %pred's %belly.",
		"%pred urps as something shifts in their %belly.")
	B.examine_messages = list(
		"Their %belly is distended.",
		"Vague shapes swell their %belly.",
		"It looks like they have something solid in their %belly")

/mob/living/simple_mob/vore/doglin/attack_hand(mob/living/carbon/human/M as mob)

	if(stat == DEAD)
		return ..()

	if(M.a_intent != I_HELP)
		return ..()
	playsound(src, 'sound/weapons/thudswoosh.ogg', 50, 1, -1)

	if(M.zone_sel.selecting == BP_GROIN)
		M.visible_message( \
			"<span class='notice'>[M] rubs \the [src]'s tummy...</span>", \
			"<span class='notice'>You rub \the [src]'s tummy...</span>", )
		if(client)
			return
		if(resting)
			if(prob(10))
				visible_message("<span class='notice'>\The [src] pants and bleps its tongue out. It looks SO happy...</span>")
			return
		else
			visible_message("<span class='notice'>\The [src] wags happily and sprawls out for you!</span>")
			lay_down()
			ai_holder.go_sleep()
			playsound(src, pick(bodyfall_sound), 75, 1)
			return
	if(resting)
		M.visible_message("<span class='notice'>\The [M.name] shakes \the [src] awake from their nap.</span>","<span class='notice'>You shake \the [src] awake!</span>")
		lay_down()
		ai_holder.go_wake()
		return
	if(M.zone_sel.selecting == BP_HEAD)
		M.visible_message( \
			"<span class='notice'>[M] pats \the [src] on the head.</span>", \
			"<span class='notice'>You pat \the [src] on the head.</span>", )
		if(client)
			return
		if(prob(10))
			visible_message("<span class='notice'>\The [src] wags and excitedly bumps their head into [M]'s hand.</span>")
	else if(M.zone_sel.selecting == BP_R_HAND || M.zone_sel.selecting == BP_L_HAND)
		M.visible_message( \
			"<span class='notice'>[M] shakes \the [src]'s pawb.</span>", \
			"<span class='notice'>You shake \the [src]'s pawb.</span>", )
		if(client)
			return
		if(prob(10))
			visible_message("<span class='notice'>\The [src]'s looks a little distraught...</span>")
	else if(M.zone_sel.selecting == "mouth")
		M.visible_message( \
			"<span class='notice'>[M] boops \the [src]'s nose.</span>", \
			"<span class='notice'>You boop \the [src] on the nose.</span>", )
		if(client)
			return
		if(prob(10))
			visible_message("<span class='notice'>\The [src]'s eyes widen as they stare at [M]. After a moment they rub their prodded snoot.</span>")
	else if(M.zone_sel.selecting == BP_GROIN)
		M.visible_message( \
			"<span class='notice'>[M] rubs \the [src]'s tummy...</span>", \
			"<span class='notice'>You rub \the [src]'s tummy...</span>", )
		if(client)
			return
		visible_message("<span class='notice'>\The [src] wags happily and sprawls out for you!</span>")
		lay_down()
		ai_holder.go_sleep()
	else
		return ..()

/mob/living/simple_mob/vore/doglin/verb/doglin_color()
	set name = "Pick Color"
	set category = "Abilities"
	set desc = "You can set your color!"
	if(picked_color)
		to_chat(src, "<span class='notice'>You have already picked a color! If you picked the wrong color, ask an admin to change your picked_color variable to 0.</span>")
		return
	var/newcolor = input(usr, "Choose a color.", "", color) as color|null
	if(newcolor)
		color = newcolor
		picked_color = TRUE
	update_icon()

/datum/category_item/catalogue/fauna/doglin
	name = "Alien Wildlife - Doglin"
	desc = "An alien species similar in appearance to Vulpkanin. This species speaks in a barking, yipping language. \
	These typically bear a pure white coat, though they have been known to come in many colors. These beings are intelligent and advanced tool users, \
	known to work in groups. They are quite tolerant and accepting, though can be provoked to violence in response to violence. while canine in appearance, \
	doglins are omnivorous, and are known to grow mushrooms in the extensive tunnels they dig. While generally not a danger to people, doglins can cause issues \
	where they live with their tendancy to dig. It is possible for people to fall into doglin tunnels and get lost."
	value = CATALOGUER_REWARD_TRIVIAL

/datum/ai_holder/simple_mob/doglin
	hostile = FALSE
	cooperative = TRUE
	retaliate = TRUE
	speak_chance = 1
	wander = TRUE
	belly_attack = FALSE
	intelligence_level = AI_SMART
	threaten_delay = 30 SECONDS
	grab_hostile = FALSE

/datum/ai_holder/simple_mob/doglin/on_hear_say(mob/living/speaker, message)
	if(holder.client)
		return
	var/mob/living/simple_mob/vore/doglin/D = holder
	if(D.yip_cooldown)
		return
	if(findtext(message, "yip") || findtext(message, "yap"))
		var/who = null
		if(!istype(speaker,/mob/living/simple_mob/vore/doglin))
			who = " [speaker]"
		D.yapyapyap(who, speaker)

/datum/ai_holder/simple_mob/doglin/on_hear_emote(mob/living/speaker, message)
	if(holder.client)
		return
	var/mob/living/simple_mob/vore/doglin/D = holder
	if(D.yip_cooldown)
		return
	if(findtext(message, "yip") || findtext(message, "yap"))
		var/who = null
		if(!istype(speaker,/mob/living/simple_mob/vore/doglin))
			who = " [speaker]"
		D.yapyapyap(who, speaker)

/obj/structure/doglin_hole
	name = "hole"
	desc = "Someone dug a hole! Heehoo~"
	icon = 'icons/rogue-star/mobx32.dmi'
	icon_state = "heehoo"

	var/static/list/world_doglin_holes = list()
	var/zoop = FALSE

/obj/structure/doglin_hole/Initialize()
	. = ..()
	world_doglin_holes |= src
	if(istype(get_turf(src),/turf/simulated/floor/outdoors/))
		icon_state = "heehoo-d"

/obj/structure/doglin_hole/Destroy()
	world_doglin_holes -= src
	return ..()

/obj/structure/doglin_hole/attack_hand(mob/living/user)
	tunnel_travel(user)
	return ..()

/obj/structure/doglin_hole/attack_generic(mob/user, damage, attack_verb)
	tunnel_travel(user)
	return ..()

/obj/structure/doglin_hole/attack_robot(mob/living/user)
	var/turf/hole = get_turf(src)	//Borgs can click stuff from far away, let's make sure they're next to the hole
	var/turf/borg = get_turf(user)
	if(hole.AdjacentQuick(borg))
		tunnel_travel(user)
		return ..()

/obj/structure/doglin_hole/Crossed(O)
	. = ..()
	if(istype(O,/mob/living/simple_mob/vore/doglin))
		var/mob/living/simple_mob/vore/doglin/D = O
		if(D.ckey)
			return
		else if(prob(25))
			var/obj/structure/doglin_hole/dest = pick(world_doglin_holes)
			var/turf/dest_turf = get_turf(dest)
			if(dest_turf.z != z)
				return
			D.yapyapyap()
			D.visible_message("\The [D] begins to enter \the [src]...", runemessage = "...")
			if(!do_after(D, 3 SECONDS, src, max_distance = 1, exclusive = TRUE))
				return
			dest.zoop = TRUE
			D.dir = SOUTH
			D.forceMove(dest_turf)
			visible_message("\The [D] disappears into \the [src]!", runemessage = "scamper")
			D.visible_message("\The [D] appears from \the [src]!!!", runemessage = "scamper")
			spawn(1 SECOND)
				dest.zoop = FALSE

/obj/structure/doglin_hole/proc/tunnel_travel(mob/living/user)
	var/choice = tgui_input_list(user, "Which direction will you travel?", "Travel", list("North","South","East","West","Up","Down"))
	if(choice)
		find_tunnel_direction(choice, user)

/obj/structure/doglin_hole/proc/find_tunnel_direction(ourdir, mob/living/user)

	if(!istype(user, /mob/living/simple_mob/vore/doglin) || !ourdir)
		var/list/possible_holes = list()
		for(var/obj/structure/doglin_hole/hole in world_doglin_holes)
			if(hole == src)
				continue
			if(hole.z == user.z)
				possible_holes |= hole

		if(!possible_holes.len)
			to_chat(user, "<span class = 'warning'>You don't see anywhere to go.</span>")
			return
		user.visible_message("\The [user] begins to enter \the [src]...", runemessage = "...")
		if(!do_after(user, 3 SECONDS, src, max_distance = 1, exclusive = TRUE))
			return
		to_chat(user, "<span class = 'warning'>You get lost...</span>")
		var/turf/dest_turf = get_turf(pick(possible_holes))
		user.dir = SOUTH
		user.forceMove(dest_turf)
		visible_message("\The [user] disappears into \the [src]!", runemessage = "scamper")
		user.visible_message("\The [user] appears from \the [src]!!!", runemessage = "scamper")
		return

	var/obj/structure/doglin_hole/destination_hole
	switch(ourdir)
		if("North")
			for(var/obj/structure/doglin_hole/hole in world_doglin_holes)
				if(hole == src)
					continue
				if(hole.z != z)
					continue
				if(hole.y < y)
					continue
				var/ourdif = (hole.y - y) + 1
				if(hole.x <= x + ourdif && hole.x >= x - ourdif)
					if(!destination_hole)
						destination_hole = hole
					else if(hole.y < destination_hole.y)
						destination_hole = hole

		if("South")
			for(var/obj/structure/doglin_hole/hole in world_doglin_holes)
				if(hole == src)
					continue
				if(hole.z != z)
					continue
				if(hole.y > y)
					continue
				var/ourdif = (y - hole.y) + 1
				if(hole.x <= x + ourdif && hole.x >= x - ourdif)
					if(!destination_hole)
						destination_hole = hole
					else if(hole.y > destination_hole.y)
						destination_hole = hole

		if("East")
			for(var/obj/structure/doglin_hole/hole in world_doglin_holes)
				if(hole == src)
					continue
				if(hole.z != z)
					continue
				if(hole.x < x)
					continue
				var/ourdif = (hole.x - x) + 1
				if(hole.y >= y - ourdif && hole.y <= y + ourdif)
					if(!destination_hole)
						destination_hole = hole
					else if(hole.x < destination_hole.x)
						destination_hole = hole

		if("West")
			for(var/obj/structure/doglin_hole/hole in world_doglin_holes)
				if(hole == src)
					continue
				if(hole.z != z)
					continue
				if(hole.x > x)
					continue
				var/ourdif = (x - hole.x) + 1
				if(hole.y >= y - ourdif && hole.y <= y + ourdif)
					if(!destination_hole)
						destination_hole = hole
					else if(hole.x > destination_hole.x)
						destination_hole = hole

		if("Up")
			var/turf/above = GetAbove(get_turf(src.loc))
			if(!above)
				to_chat(user, "<span class = 'warning'>You can't go up here.</span>")
				return
			for(var/obj/structure/doglin_hole/hole in world_doglin_holes)
				if(hole.z != above.z)
					continue
				if((hole.y >= y - 5 && hole.y <= y + 5) && (hole.x >= x - 5 && hole.x <= x + 5))
					destination_hole = hole
					break
		if("Down")
			var/turf/below = GetBelow(get_turf(src.loc))
			if(!below)
				to_chat(user, "<span class = 'warning'>You can't go down here.</span>")
				return
			for(var/obj/structure/doglin_hole/hole in world_doglin_holes)
				if(hole.z != below.z)
					continue
				if((hole.y >= y - 5 && hole.y <= y + 5) && (hole.x >= x - 5 && hole.x <= x + 5))
					destination_hole = hole
					break

	if(destination_hole)
		user.visible_message("\The [user] begins to enter \the [src]...", runemessage = "...")

		if(!do_after(user, 3 SECONDS, src, max_distance = 1, exclusive = TRUE))
			return
		var/turf/dest_turf = get_turf(destination_hole.loc)
		user.dir = SOUTH
		user.forceMove(dest_turf)
		visible_message("\The [user] disappears into \the [src]!", runemessage = "scamper")
		user.visible_message("\The [user] appears from \the [src]!!!", runemessage = "scamper")

	else
		to_chat(user, "<span class = 'warning'>There isn't a tunnel in that direction.</span>")

/obj/item/weapon/holder/doglin
	icon_state = "doglin"
	item_icons = list(
		slot_head_str = 'icons/rogue-star/hat32x64.dmi',
		slot_l_hand_str = 'icons/rogue-star/lefthand_holder_rs.dmi',
		slot_r_hand_str = 'icons/rogue-star/righthand_holder_rs.dmi'
		)

/obj/item/weapon/holder/doglin/Initialize(mapload, mob/held)
	. = ..()
	color = held_mob.color
