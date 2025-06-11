//RS FILE
/*
VerySoft - 6/10/2025
Some neato on screen hud elements live here, for elements we want to update with some manner of regularity~
Primarily intended to be vore related, but may turn out to be more.
Just kind of experimenting with what's possible with regards to on screen hud elements.
*/
SUBSYSTEM_DEF(rs_ui)
	name = "Rogue Star UI"
	flags = SS_NO_INIT | SS_BACKGROUND
	var/list/tracked_rs_ui = list() //Anything added to this list will call update()!

/datum/controller/subsystem/rs_ui/fire(resumed)
	for(var/obj/screen/movable/rs_ui/ui in tracked_rs_ui)
		ui.update()

/datum/controller/subsystem/rs_ui/proc/register(var/obj/screen/movable/rs_ui/ui)
	if(ui.do_process)
		tracked_rs_ui.Add(ui)

/datum/controller/subsystem/rs_ui/proc/vore(var/obj/screen/movable/rs_ui/ui)
	tracked_rs_ui.Remove(ui)
	qdel(ui)

///// OBJECT BELOW HERE /////
/obj/screen/movable/rs_ui
	name = "UI"
	desc = null
	icon = null
	screen_loc = "CENTER,CENTER"
	var/do_process = TRUE

/obj/screen/movable/rs_ui/New()
	SSrs_ui.register(src)	//Make sure the subsystem knows about us!

/obj/screen/movable/rs_ui/proc/update()
	return

/obj/screen/movable/rs_ui/proc/cleanup()
	SSrs_ui.vore(src)

///// HEALTHBAR BELOW HERE /////

/obj/screen/movable/rs_ui/healthbar	//TBH this has become a bit more than just a health bar lol
	screen_loc = "CENTER+3,CENTER"
	var/mob/living/tracked					//Who the health bar is tracking
	var/mob/living/holder					//Who the health bar is being displayed to
	var/tracked_stat = 0					//How much of whatever stat we are tracking was last update - if changed we update the hud
	var/mode = DM_DIGEST					//The last recorded digest mode for the belly tracked is in - if changed we update the hud
	var/static/list/icon_cache = list()		//We cache the icons we have made so we don't have to make them again
	var/image/bar_frame						//The frame for the healthbar
	var/image/bar_frame_background			//The bar's background
	var/image/health_bar					//The bar itself
	var/image/overlay_fx					//The overlay foreground. This will appear in front of the tracked mob
	var/image/underlay_fx					//The overlay background. This will appear behind the tracked mob.
	var/overlay_theme						//The selected theme. We actually use the setting from the belly tracked is in, but if that is different than this, then we update the hud
	var/overlay_color						//Same as above but for the color
	var/matrix/original_transform			//We delete tracked's transform so they appear normal sized in the hud, but we store it and restore it to them when the hud dies.
	var/atom/movable/tummy_shadow/shadow	//This holds tracked's vis_contents and makes it so you can't click on it.

/obj/screen/movable/rs_ui/healthbar/New(loc, var/tracked_mob,var/holder_mob)
	if(!register_tummy_target(tracked_mob,holder_mob))
		qdel(src)	//Something in there was invalid, so let's just delete ourself
		return
	original_transform = tracked.transform	//We don't really want huge sprites or super small sprites, so let's store their transform and reset it to default
	tracked.transform = null

	return ..()

/obj/screen/movable/rs_ui/healthbar/proc/register_tummy_target(var/mob/living/tracked_mob,var/mob/living/holder_mob)
	if(!isliving(holder_mob))
		return FALSE			//Holder is who the UI goes on! Can't give a UI if we don't have a holder.
	if(!holder_mob.client)
		return FALSE				//The holder needs a client, can't give UIs to NPCs
	if(!isliving(tracked_mob))
		return FALSE		//This is the mob we're keeping track of, may be the same as the holder, but we need to check anyway
	if(!isbelly(tracked_mob.loc))
		return FALSE	//And since this is a vore health bar, they need to be in a tummy!
	for(var/obj/screen/movable/rs_ui/healthbar/our_ui in SSrs_ui.tracked_rs_ui)
		if(!istype(our_ui))
			continue
		if(our_ui.tracked == tracked_mob && our_ui.holder == holder_mob)	//You already have one! You don't need another!!!
			return FALSE

	tracked = tracked_mob
	RegisterSignal(tracked,COMSIG_PARENT_QDELETING,PROC_REF(cleanup),TRUE)		//Register signals immediately so we don't forget!
	RegisterSignal(tracked,COMSIG_MOB_LOGOUT,PROC_REF(cleanup),TRUE)			//We are making ourself visible to the client and when they log out the client dies! So let's clean up here too.
	holder = holder_mob
	RegisterSignal(holder,COMSIG_PARENT_QDELETING,PROC_REF(cleanup),TRUE)
	RegisterSignal(holder,COMSIG_MOB_LOGOUT,PROC_REF(cleanup),TRUE)

	//Setup the actual UI!!!
	name = tracked.name
	shadow = new(src,tracked)		//This is just a thing that holds tracked's vis contents but is not clickable by mouse!!!
	shadow.plane = plane
	shadow.layer = layer
	vis_contents += shadow			//We add the shadow to our vis contents so we can SEE but not TOUCH tracked!
	tracked_stat = tracked.health	//We'll just set up for digest and let update fix it if we're wrong.
	if(ishuman(tracked))			//Humans can go to -100 health before they die, so we'll just add 100
		tracked_stat+=100

	build_icon()	//Start building the icon!

	holder.client.screen += src	//And finally, we add the ui to the player's hud

	return TRUE	//Tell new that we're valid, yay for us!!

/obj/screen/movable/rs_ui/healthbar/cleanup()
	UnregisterSignal(tracked,COMSIG_PARENT_QDELETING)	//Clean up our signals
	UnregisterSignal(tracked,COMSIG_MOB_LOGOUT)
	UnregisterSignal(holder,COMSIG_PARENT_QDELETING)
	UnregisterSignal(holder,COMSIG_MOB_LOGOUT)
	holder.client?.screen -= src						//Remove ourself from the one peeking at us if they are around!
	tracked.transform = original_transform				//Give tracked back their transform
	tracked.update_transform()							//Update it so that they actually turn back
	tracked = null										//Tracked is no longer our best friend
	original_transform = null
	vis_contents -= shadow								//Get rid of the shadow too!
	QDEL_NULL(shadow)
	bar_frame = null									//And null out all our images. We don't delete them though because they live in the cache!
	bar_frame_background = null							//We did all that work to generate them! Let's hang on to it, someone else will need it.
	health_bar = null
	overlay_fx = null
	underlay_fx = null

	return ..()

/obj/screen/movable/rs_ui/healthbar/proc/build_icon()

	var/image/bg = icon_cache["bg"]
	if(!bg)
		bg = image('icons/rogue-star/vore_healthbar.dmi',null,"circle")
		bg.pixel_x = -32
		bg.pixel_y = -32
		bg.plane = plane
		bg.layer = layer + 9
		icon_cache["bg"] = bg
	add_overlay(bg)

	update_bar()

/obj/screen/movable/rs_ui/healthbar/proc/update_bar()
	cut_overlay(health_bar)
	health_bar = null
	var/obj/belly/our_belly = tracked.loc	//We need to know stuff about the belly our tracked mob is in!
	if(!isbelly(our_belly))					//If we're not in a belly then we don't need vore healthbars!
		cleanup()
		return
	var/ourmode = our_belly.return_effective_d_mode(tracked)	//Selective makes things annoying so I made it easy.
	apply_bar_frame(ourmode)	//This handles the frame AND the background for the healthbar.
	if(tracked.absorbed)		//While absorbed we ignore all the other digest modes so that's what we're gonna do.
		absorbed()
		return

	switch(ourmode)
		if(DM_DIGEST)
			digest()
		if(DM_ABSORB)
			absorbing()
		if(DM_DRAIN)
			absorbing(TRUE)
		else
			digest()	//If it's something else we just use digest mode just so we get the normal colored health bar, since we don't track the weird modes! (yet)((no promises))

/obj/screen/movable/rs_ui/healthbar/proc/apply_bar_frame(var/ourmode)
	cut_overlay(bar_frame)
	cut_overlay(bar_frame_background)
	bar_frame = null
	bar_frame_background = null
	var/ourcolor					//Color of the frame
	var/oursprite = "frame"			//The sprite we use for the frame
	var/bg_state = "draining"		//The sprite we use for the background of the healthbar
	var/bg_color = "#720000"		//The color we use for the background of the healthbar
	if(tracked.absorbed)		//Being absorbed makes us ignore other digest modes so we'll just pretend it's set to absorb, and give us a fancier sprite~
		ourmode = DM_ABSORB
		oursprite = "frame_pulse_b"
	switch(ourmode)
		if(DM_DIGEST)
			ourcolor = "#ff0000"
		if(DM_DRAIN)
			ourcolor = "#ffe600"
			bg_color = "#9e7941"
		if(DM_ABSORB)
			ourcolor = "#cc00ff"
			bg_color = "#703c7e"
		if(DM_HEAL)
			ourcolor = "#78ff74"
			if(tracked.health == tracked.maxHealth)		//Do different sprites for if tracked is damaged or full health!
				oursprite = "frame_pulse"
			else
				oursprite = "frame_pulse_c"				//If we're healing, let's make the sprite a little flashier!
			bg_state = "healing"
		else
			ourcolor = "#545094"	//We're using some other mode that we don't really care about! You aren't dying or draining!
			bg_state = "bar"


	/////BAR FRAME/////
	bar_frame = icon_cache["[ourcolor]-[oursprite]"]	//Try to pull from the cache
	if(!bar_frame)										//If we don't have it, then let's build it!
		bar_frame = image('icons/rogue-star/vore_healthbar.dmi',null,oursprite)	//These sprites are 96x96!
		bar_frame.pixel_x = -32				//Center it
		bar_frame.pixel_y = -70				//This makes it be pleasantly under the overlay!
		bar_frame.plane = plane
		bar_frame.layer = layer + 12		//The frame is on top of everything else! Nothing should go in front of the frame!
		bar_frame.color = ourcolor
		bar_frame.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
		icon_cache["[ourcolor]-[oursprite]"] = bar_frame	//Cache it so we don't have to make it again
	add_overlay(bar_frame)
	/////BAR BACKGROUND/////
	bar_frame_background = icon_cache["[bg_color]-[bg_state]"]	//Pull from cache!
	if(!bar_frame_background)
		bar_frame_background = image('icons/rogue-star/vore_healthbar.dmi',null,bg_state)
		bar_frame_background.pixel_x = -32
		bar_frame_background.pixel_y = -70
		bar_frame_background.plane = plane
		bar_frame_background.layer = layer + 10	//Behind the frame and the bar!
		bar_frame_background.color = bg_color
		bar_frame_background.alpha = 215
		bar_frame_background.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
		icon_cache["[bg_color]-[bg_state]"] = bar_frame_background	//Add to cache!
	add_overlay(bar_frame_background)

/obj/screen/movable/rs_ui/healthbar/proc/digest()
	var/curh = tracked.health
	var/maxh = tracked.maxHealth
	if(ishuman(tracked))	//Humans die at -100 health, so we just add 100 to whatever we got
		curh += 100
		maxh += 100
	var/ourstate = "bar"
	var/our_percent = round(curh/maxh,0.01)	//We're using decimal percentages here, and we use this number to generate and cache images. We round to avoid useless image processing
	if(our_percent < 0)		//We don't want negative numbers
		our_percent = 0

	var/ourcolor
	switch(our_percent*100)	//*100 for proper whole percentage numbers!
		if(33 to 66)
			ourcolor = "#fbff00"
		if(0 to 33)
			ourcolor = "#ff0000"
		else
			if(mode == DM_HEAL)			//Heal uses some different sprites, so while healing let's use a darker green to make them pop more
				ourcolor = "#1ba300"
			else
				ourcolor = "#25dd00"

	do_bar_icon(ourstate,ourcolor,our_percent)

/obj/screen/movable/rs_ui/healthbar/proc/absorbing(var/draining = FALSE)
	var/ourstate = "bar"
	var/our_percent = round(tracked.nutrition/2000,0.01)	//2000 being max is a bit arbatrary. You're technically full on nutrition at 500, but bigger number lets you see the bar go down for longer

	if(our_percent > 1)	//We don't want more than 100%
		ourstate = "draining"	//But we recognize that it is more than 100% by displaying an animation!
		our_percent = 1

	var/ourcolor
	if(draining)	//Drain and absorb are effectively the same thing mechanically as far as what we track, so we'll just set the color different!
		ourcolor = "#ff9900"
	else
		ourcolor = "#cd45f0"

	do_bar_icon(ourstate,ourcolor,our_percent)

/obj/screen/movable/rs_ui/healthbar/proc/do_bar_icon(var/ourstate,var/ourcolor,var/ourpercent)	//This actually builds the health bar itself

	if(ourpercent < 0)	//We don't want less than 0%
		ourpercent = 0

	var/iconkey = "[ourstate]-[ourcolor]-[ourpercent]"
	health_bar = icon_cache[iconkey]	//Check to see if we already made what we need

	if(!health_bar)	//If not, then we'll make it!
		if(ourpercent <= 1)	//I didn't want to make 100 icon states, so I made the computer do it
			var/icon/bar = new('icons/rogue-star/vore_healthbar.dmi',ourstate)	//The bar itself
			var/icon/mask = new('icons/rogue-star/vore_healthbar.dmi',"mask")	//A blank sprite we use as an alpha mask
			bar.Blend(mask,ICON_ADD,10+(77*ourpercent))	//We use our percent and a little math based on the sprites we're using to determine where we want to mask!
			health_bar = image(bar)	//And turn the icon we made into an image!
		else
			health_bar = image('icons/rogue-star/vore_healthbar.dmi',null,ourstate)	//We're full health so no need for mask!
		health_bar.pixel_x = -32	//Center it
		health_bar.pixel_y = -70	//Put it down low
		health_bar.color = ourcolor
		health_bar.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
		health_bar.plane = plane
		health_bar.layer = layer + 11	//Put it between the frame and the background

		icon_cache[iconkey] = health_bar	//Add it to the cache

	add_overlay(health_bar)




/*	TRY THIS AGAIN IDIOT YOU FUCKED UP THE ICON LAST TIME!!! IF THIS WORKS THE CLIENT WILL DO THE IMAGE PROCESSING AND THAT'S CHEAPER
		var/list/F = list("type" = "alpha")
		F["x"] = 9 + (86*our_percent)
		F["icon"] = mask
		F["flags"] = MASK_INVERSE

		var/list/flist = list()
		flist["depletion"] = F

		health_bar.filters += flist
*/





/obj/screen/movable/rs_ui/healthbar/proc/absorbed()	//Special icon for having been fully absorbed.
	health_bar = icon_cache["absorbed"]

	if(!health_bar)
		health_bar = image('icons/rogue-star/vore_healthbar.dmi',null,"absorbed")
		health_bar.pixel_x = -32
		health_bar.pixel_y = -70
		health_bar.color = null
		health_bar.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
		health_bar.plane = plane
		health_bar.layer = layer + 11

		icon_cache["absorbed"] = health_bar

	add_overlay(health_bar)

/obj/screen/movable/rs_ui/healthbar/update()
	if(!tracked)	//We can't work without tracked
		cleanup()
		return
	if(check_moved())	//We have tracked, but is tracked moving around? Then they aren't in a belly!!! No health bar for you!
		return
	var/obj/belly/B = tracked.loc
	if(!isbelly(B))	//Double check, is tracked in a belly?
		cleanup()
		return
	if(tracked != holder)	//If tracked is also the holder, that means they're the prey in the belly!
		if(holder.loc != B)	//If the holder is in the belly but isn't tracked, then they are another prey looking at their tummy roommate's healthbar!
			if(B.owner != holder)	//If the belly owner is is the holder, then they're the pred!
				cleanup()
				return

	if(B.belly_healthbar_overlay_theme != overlay_theme || B.belly_healthbar_overlay_color != overlay_color)	//This should be its own proc

		cut_overlay(underlay_fx)
		underlay_fx = null
		cut_overlay(overlay_fx)
		overlay_fx = null

		if(B.belly_healthbar_overlay_theme)
			var/ourkey = "[B.belly_healthbar_overlay_theme]-[B.belly_healthbar_overlay_color]"

			underlay_fx = icon_cache["underlay_fx_[ourkey]"]
			if(!underlay_fx)
				underlay_fx = image('icons/rogue-star/vore_healthbar.dmi',null,"[B.belly_healthbar_overlay_theme]_under")
				underlay_fx.pixel_x = -32
				underlay_fx.pixel_y = -32
				underlay_fx.layer = layer - 9
				underlay_fx.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
				underlay_fx.color = B.belly_healthbar_overlay_color

				icon_cache["underlay_fx_[ourkey]"] = underlay_fx
			add_overlay(underlay_fx)

			overlay_fx = icon_cache["overlay_fx_[ourkey]"]
			if(!overlay_fx)
				overlay_fx = image('icons/rogue-star/vore_healthbar.dmi',null,B.belly_healthbar_overlay_theme)
				overlay_fx.pixel_x = -32
				overlay_fx.pixel_y = -32
				overlay_fx.plane = plane
				overlay_fx.layer = layer + 8
				overlay_fx.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
				overlay_fx.color = B.belly_healthbar_overlay_color

				icon_cache["overlay_fx_[ourkey]"] = overlay_fx

			overlay_theme = B.belly_healthbar_overlay_theme
			overlay_color = B.belly_healthbar_overlay_color
			add_overlay(overlay_fx)

	var/update_anyway = FALSE
	if(consider_mode(B))
		update_anyway = TRUE

	switch(B.digest_mode)
		if(DM_DIGEST)
			update_digest(update_anyway)
		if(DM_ABSORB)
			update_absorb(update_anyway)
		if(DM_DRAIN)
			update_absorb(update_anyway)
		if(DM_SELECT)
			update_select(B,update_anyway)
		else
			update_digest(update_anyway)


/obj/screen/movable/rs_ui/healthbar/proc/consider_mode(var/obj/belly/B)
	if(mode != B.digest_mode)
		mode = B.digest_mode
		update_bar()
		return TRUE

/obj/screen/movable/rs_ui/healthbar/proc/update_digest(var/override = FALSE)
	var/our_health = tracked.health
	if(ishuman(tracked))
		our_health+=100
	if(tracked_stat != our_health)
		update_bar()
		tracked_stat = our_health
	else if(override)
		update_bar()

/obj/screen/movable/rs_ui/healthbar/proc/update_absorb(var/override = FALSE)
	if(tracked.nutrition != tracked_stat)
		update_bar()
		tracked_stat = tracked.nutrition
	else if(tracked.absorbed)
		update_bar()
	else if(override)
		update_bar()

/obj/screen/movable/rs_ui/healthbar/proc/update_select(var/obj/belly/B,var/override = FALSE)
	switch(B.return_effective_d_mode(tracked))
		if(DM_DIGEST)
			update_digest(override)
		if(DM_ABSORB)
			update_absorb(override)
		if(DM_DRAIN)
			update_absorb(override)
		else
			update_digest(override)

/obj/screen/movable/rs_ui/healthbar/proc/check_moved()
	if(!isbelly(tracked.loc))
		cleanup()
		return TRUE
	return FALSE

/obj/screen/movable/rs_ui/healthbar/Click(location, control, params)
	if(!tracked)
		cleanup()
	if(!isbelly(tracked.loc))
		cleanup()
	if(usr != holder && usr != tracked)
		return
	//Check before choice
	var/obj/belly/B = tracked.loc
	var/list/available_options = list("Examine")
	if(usr != tracked)
		available_options += "Advance"
		available_options += "Transfer"
		available_options += "Process"
		if(ishuman(tracked))
			available_options += "Transform"
		available_options += "Eject"
		available_options += "Customize"
	available_options += "Close"
	var/input = tgui_input_list(usr, "What will you do with this UI?", "Vore UI", available_options)
	//Also check after choice
	if(B != tracked.loc)
		return

	switch(input)
		if("Close")
			cleanup()
		if("Eject")
			B.eject_target(tracked)
		if("Advance")
			B.advance_target(tracked)
		if("Transfer")
			B.transfer_target(tracked)
		if("Examine")
			B.examine_target(tracked)
		if("Transform")
			B.transform_target(tracked)
		if("Process")
			B.process_target(tracked)
		if("Customize")
			customize()

/obj/screen/movable/rs_ui/healthbar/proc/customize()
	if(holder == tracked)	//Are we the prey?
		return	//Then it's not our belly!
	var/obj/belly/B = tracked.loc
	if(!isbelly(B))
		cleanup()
		return
	var/list/ourlist = list(
		"Inside",
		"Stomach",
		"Tight",
		"Mouth",
		"Tunnel",
		"Womb",
		"Between",
		"Pocket",
		"Hand",
		"Fist",
		"Remove"
	)
	var/selection = tgui_input_list(holder, "Select a style! Remember to go save your vore panel after you select one if you want it to stick!", "RS-UI Customization", ourlist,B.belly_healthbar_overlay_theme)
	if(!selection)
		return
	var/ourcolor = input(usr, "What color?", "RS-UI Coloration", overlay_color) as color|null
	if(selection == "Remove")
		selection = null
	B.belly_healthbar_overlay_theme = selection
	if(ourcolor)
		B.belly_healthbar_overlay_color = ourcolor
	if(holder.vorePanel)
		holder.vorePanel.unsaved_changes = TRUE

/////Related objects/////

/mob/living/verb/show_vore_healthbar()
	set name = "Vore Healthbar"
	set desc = "Shows your own vore healthbar!"
	set category = "IC"

	if(!isbelly(loc))
		to_chat(src,SPAN_WARNING("You're not in a belly you can't peek at your healthbar, silly!"))
		return

	new /obj/screen/movable/rs_ui/healthbar(src,src,src)

/atom/movable/tummy_shadow
	mouse_opacity = FALSE

/atom/movable/tummy_shadow/New(loc, var/mob/living/L)
	if(isliving(L))
		vis_contents += L

/atom/movable/tummy_shadow/Destroy()
	for(var/thing in vis_contents)
		vis_contents -= thing
	..()

/*
/////NA BEGIN/////

/obj/screen/movable/nobj_holder
	var/atom/navigable_object/tracked

/obj/screen/movable/nobj_holder/New(loc,var/to_track)
	. = ..()
	tracked = to_track
	vis_contents += tracked
	RegisterSignal(tracked,COMSIG_PARENT_QDELETING,PROC_REF(Destroy),TRUE)

/obj/screen/movable/nobj_holder/Destroy()
	UnregisterSignal(tracked,COMSIG_PARENT_QDELETING)

	vis_contents -= tracked
	tracked = null
	return ..()

/atom/navigable_object
	name = "level"
	desc = "A space that users can move around within."

/atom/navigable_object/proc/add_object(var/our_object)
	new /atom/movable/mobile_object_holder(src,our_object)

/atom/movable/mobile_object_holder/New(loc, var/our_object)
	if(isliving(our_object) || isobj(our_object))
		vis_contents += our_object
		return ..()
	qdel(src)
*/

/*
/proc/getIconMask(atom/A)//By yours truly. Creates a dynamic mask for a mob/whatever. /N
	var/icon/alpha_mask = new(A.icon,A.icon_state)//So we want the default icon and icon state of A.
	for(var/I in A.overlays)//For every image in overlays. var/image/I will not work, don't try it.
		if(I:layer>A.layer)	continue//If layer is greater than what we need, skip it.
		var/icon/image_overlay = new(I:icon,I:icon_state)//Blend only works with icon objects.
		//Also, icons cannot directly set icon_state. Slower than changing variables but whatever.
		alpha_mask.Blend(image_overlay,ICON_OR)//OR so they are lumped together in a nice overlay.
	return alpha_mask//And now return the mask.
*/
