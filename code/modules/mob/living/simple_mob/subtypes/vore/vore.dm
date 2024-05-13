/mob/living/simple_mob/vore
	mob_class = MOB_CLASS_ANIMAL
	mob_bump_flag = 0

	softfall = TRUE		//RS EDIT

/mob/living/simple_mob
	var/nameset
	var/limit_renames = TRUE
	var/copy_prefs_to_mob = TRUE

/mob/living/simple_mob/Login()
	. = ..()
	verbs |= /mob/living/simple_mob/proc/set_name
	verbs |= /mob/living/simple_mob/proc/set_desc

	if(copy_prefs_to_mob)
		login_prefs()

/mob/living/proc/login_prefs()

	ooc_notes = client.prefs.metadata
	ooc_notes_likes = client.prefs.metadata_likes
	ooc_notes_dislikes = client.prefs.metadata_dislikes
	digestable = client.prefs_vr.digestable
	devourable = client.prefs_vr.devourable
	absorbable = client.prefs_vr.absorbable
	feeding = client.prefs_vr.feeding
	can_be_drop_prey = client.prefs_vr.can_be_drop_prey
	can_be_drop_pred = client.prefs_vr.can_be_drop_pred
	throw_vore = client.prefs_vr.throw_vore
	food_vore = client.prefs_vr.food_vore
	allow_inbelly_spawning = client.prefs_vr.allow_inbelly_spawning
	allow_spontaneous_tf = client.prefs_vr.allow_spontaneous_tf
	digest_leave_remains = client.prefs_vr.digest_leave_remains
	allowmobvore = client.prefs_vr.allowmobvore
	permit_healbelly = client.prefs_vr.permit_healbelly
	noisy = client.prefs_vr.noisy
	selective_preference = client.prefs_vr.selective_preference
	eating_privacy_global = client.prefs_vr.eating_privacy_global

	drop_vore = client.prefs_vr.drop_vore
	stumble_vore = client.prefs_vr.stumble_vore
	slip_vore = client.prefs_vr.slip_vore

	resizable = client.prefs_vr.resizable
	show_vore_fx = client.prefs_vr.show_vore_fx
	step_mechanics_pref = client.prefs_vr.step_mechanics_pref
	pickup_pref = client.prefs_vr.pickup_pref

	ssd_vore = client.prefs_vr.ssd_vore	//RS ADD


/mob/living/carbon/human/login_prefs()	//RS ADD START
	. = ..()

	allow_contaminate = client.prefs_vr.allow_contaminate
	allow_stripping = client.prefs_vr.allow_stripping

	//RS ADD END

/mob/living/simple_mob/proc/set_name()
	set name = "Set Name"
	set desc = "Sets your mobs name. You only get to do this once."
	set category = "Abilities"
	if(limit_renames && nameset)
		to_chat(src, "<span class='userdanger'>You've already set your name. Ask an admin to toggle \"nameset\" to 0 if you really must.</span>")
		return
	var/newname
	newname = sanitizeSafe(tgui_input_text(src,"Set your name. You only get to do this once. Max 52 chars.", "Name set","", MAX_NAME_LEN), MAX_NAME_LEN)
	if (newname)
		name = newname
		voice_name = newname
		nameset = 1

/mob/living/simple_mob/proc/set_desc()
	set name = "Set Description"
	set desc = "Set your description."
	set category = "Abilities"
	var/newdesc
	newdesc = sanitizeSafe(tgui_input_text(src,"Set your description. Max 4096 chars.", "Description set","", prevent_enter = TRUE), MAX_MESSAGE_LEN)
	if(newdesc)
		desc = newdesc

/mob/living/simple_mob/vore/aggressive
	mob_bump_flag = HEAVY

//The stuff we want to be revivable normally
/mob/living/simple_mob/animal
	ic_revivable = TRUE
/mob/living/simple_mob/vore/otie
	ic_revivable = TRUE
/mob/living/simple_mob/vore
	ic_revivable = TRUE
//The stuff that would be revivable but that we don't want to be revivable
/mob/living/simple_mob/animal/giant_spider/nurse //no you can't revive the ones who can lay eggs and get webs everywhere
	ic_revivable = FALSE
/mob/living/simple_mob/animal/giant_spider/carrier //or the ones who fart babies when they die
	ic_revivable = FALSE

//RS ADD START
/mob/living/verb/toggle_ssd_vore()
	set name = "Vore: Toggle SSD Vore"
	set desc = "Toggles whether or not you can be eaten while SSD."
	set category = "Preferences"

	client.prefs_vr.ssd_vore = !client.prefs_vr.ssd_vore
	ssd_vore = client.prefs_vr.ssd_vore
	to_chat(src, "<span class='notice'>SSD Vore is now [ssd_vore ? "<font color='green'>enabled</font>" : "<font color='red'>disabled</font>"].</span>")

/mob/living/carbon/human/verb/toggle_stripping()
	set name = "Vore: Toggle Stripping"
	set desc = "Toggles whether or not bellies can strip your clothes off of you."
	set category = "Preferences"

	client.prefs_vr.allow_stripping = !client.prefs_vr.allow_stripping
	allow_stripping = client.prefs_vr.allow_stripping
	to_chat(src, "<span class='notice'>Stripping is now [allow_stripping ? "<font color='green'>allowed</font>" : "<font color='red'>disallowed</font>"].</span>")

/mob/living/carbon/human/verb/toggle_contaminate()
	set name = "Vore: Toggle Contaminate"
	set desc = "Toggles whether or not bellies can contaminate or digest items you are presentl wearing."
	set category = "Preferences"

	client.prefs_vr.allow_contaminate = !client.prefs_vr.allow_contaminate
	allow_contaminate = client.prefs_vr.allow_contaminate
	to_chat(src, "<span class='notice'>Contamination is now [allow_contaminate ? "<font color='green'>allowed</font>" : "<font color='red'>disallowed</font>"].</span>")

//RS ADD END
