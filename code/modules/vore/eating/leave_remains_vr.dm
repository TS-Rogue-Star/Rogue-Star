/datum/species
	var/skull_type = /obj/item/weapon/digestion_remains/organic/skull	//RS EDIT
/datum/species/tajaran
	skull_type = /obj/item/weapon/digestion_remains/organic/skull/tajaran	//RS EDIT
/datum/species/unathi
	skull_type = /obj/item/weapon/digestion_remains/organic/skull/unathi	//RS EDIT
/datum/species/skrell
	skull_type = /obj/item/weapon/digestion_remains/organic/skull/skrell	//RS EDIT
/datum/species/spider
	skull_type = /obj/item/weapon/digestion_remains/organic/skull/vasilissan	//RS EDIT
/datum/species/akula
	skull_type = /obj/item/weapon/digestion_remains/organic/skull/akula	//RS EDIT
/datum/species/harpy
	skull_type = /obj/item/weapon/digestion_remains/organic/skull/rapala	//RS EDIT
/datum/species/vulpkanin
	skull_type = /obj/item/weapon/digestion_remains/organic/skull/vulpkanin	//RS EDIT
/datum/species/sergal
	skull_type = /obj/item/weapon/digestion_remains/organic/skull/sergal	//RS EDIT
/datum/species/hi_zorren
	skull_type = /obj/item/weapon/digestion_remains/organic/skull/zorren	//RS EDIT
/datum/species/nevrean
	skull_type = /obj/item/weapon/digestion_remains/organic/skull/nevrean	//RS EDIT
/datum/species/teshari
	skull_type = /obj/item/weapon/digestion_remains/organic/skull/teshari	//RS EDIT
/datum/species/vox
	skull_type = /obj/item/weapon/digestion_remains/organic/skull/vox	//RS EDIT

/obj/belly/proc/handle_remains_leaving(var/mob/living/M)
	if(!ishuman(M) && !isrobot(M))	//Are we even humanoid or a borg?
		return
	//Moving some vars here for both borgs and carbons to use
	var/bones_amount = rand(2,4) //some random variety in amount of bones left
	if(isrobot(M)) //If borg, handle differently
		//var/mob/living/silicon/robot/R = M // Not Needed at the moment. Uncomment if you need borg stuff

		var/list/borg_bones = list( //Borg bones are the same at this point. might change in the future if borgs or synths get
			/obj/item/weapon/digestion_remains/synth, // different remains in the future.
			/obj/item/weapon/digestion_remains/synth/variant1,
			/obj/item/weapon/digestion_remains/synth/variant2,
			/obj/item/weapon/digestion_remains/synth/variant3
		)
		for(var/i = 1, i <= bones_amount, i++)	//Just fill them with bones. Borgs dont have anything special.
			var/new_bone = pick(borg_bones)
			new new_bone(src,owner)
		return //Dont need to do carbon stuff after this

	var/mob/living/carbon/human/H = M

	if((H.species.name in remainless_species))	//Don't leave anything if there is nothing to leave
		return

	if(prob(20) && !H.isSynthetic())	//ribcage surviving whole is some luck //Edit: no robor
		new /obj/item/weapon/digestion_remains/organic/ribcage(src,owner)	//RS EDIT
		bones_amount--

	var/list/organic_bones = list( //Generic bone variation system
		/obj/item/weapon/digestion_remains/organic,		//RS EDIT START
		/obj/item/weapon/digestion_remains/organic/variant1,
		/obj/item/weapon/digestion_remains/organic/variant2,
		/obj/item/weapon/digestion_remains/organic/variant3	//RS EDIT END
	)
	var/list/synthetic_bones = list(
		/obj/item/weapon/digestion_remains/synth,
		/obj/item/weapon/digestion_remains/synth/variant1,
		/obj/item/weapon/digestion_remains/synth/variant2,
		/obj/item/weapon/digestion_remains/synth/variant3
	)
	for(var/i = 1, i <= bones_amount, i++)	//throw in the rest
		var/new_bone = H.isSynthetic() ? pick(synthetic_bones) : pick(organic_bones)
		new new_bone(src,owner)

	if(H.isSynthetic()) // Synths dont have skulls, atleast not any that survive digestion.
		return			// TODO: add synth skulls and remove this.
	var/skull_amount = 1
	if(H.species.skull_type)
		new H.species.skull_type(src, owner)
		skull_amount--

	if(skull_amount && H.species.selects_bodytype)
		// We still haven't found correct skull...
		if(H.species.base_species == SPECIES_HUMAN)
			new /obj/item/weapon/digestion_remains/organic/skull/unknown(src,owner)	//RS EDIT
		else
			new /obj/item/weapon/digestion_remains/organic/skull/unknown/anthro(src,owner)	//RS EDIT
	else if(skull_amount)
		// Something entirely different...
		new /obj/item/weapon/digestion_remains/organic/skull/unknown(src,owner)	//RS EDIT


/obj/item/weapon/digestion_remains
	name = "bone"
	desc = "A bleached bone. It's very non-descript and its hard to tell what species or part of the body it came from."
	icon = 'icons/obj/bones_vr.dmi'
	icon_state = "generic-1"
	drop_sound = 'sound/items/drop/wooden.ogg'   //sounds kinda like a bone
	pickup_sound = 'sound/items/pickup/woodweapon.ogg'
	force = 0
	throwforce = 0
	item_state = "bone"
	w_class = ITEMSIZE_SMALL
	var/pred_ckey
	var/pred_name

/obj/item/weapon/digestion_remains/organic

/obj/item/weapon/digestion_remains/synth
	name = "ruined component"
	desc = "A ruined component. It seems to have come from some sort of robotic entity, but there's no telling what kind."
	icon_state = "synth-1"
	drop_sound = 'sound/items/drop/device.ogg'   //not organic bones, so they get different sounds
	pickup_sound = 'sound/items/pickup/device.ogg'

/obj/item/weapon/digestion_remains/Initialize(var/mapload, var/mob/living/pred)
	. = ..()
	if(!mapload)
		pred_ckey = pred?.ckey
		pred_name = pred?.name

/obj/item/weapon/digestion_remains/attack_self(var/mob/user)
	if(user.a_intent == I_HURT)
		to_chat(user,"<span class='warning'>As you squeeze the [name], it crumbles into dust and falls apart into nothing!</span>")
		qdel(src)

/obj/item/weapon/digestion_remains/organic/ribcage	//RS EDIT
	name = "ribcage"
	desc = "A bleached ribcage. It's very white and definitely has seen better times. Hard to tell what it belonged to."
	icon_state = "ribcage"

/obj/item/weapon/digestion_remains/organic/variant1 //Generic bone variations	//RS EDIT
	icon_state = "generic-2"

/obj/item/weapon/digestion_remains/organic/variant2	//RS EDIT
	icon_state = "generic-3"

/obj/item/weapon/digestion_remains/organic/variant3	//RS EDIT
	icon_state = "generic-4"

/obj/item/weapon/digestion_remains/synth/variant1 //synthbones start
	icon_state = "synth-2"

/obj/item/weapon/digestion_remains/synth/variant2
	icon_state = "synth-3"

/obj/item/weapon/digestion_remains/synth/variant3
	icon_state = "synth-4"

/obj/item/weapon/digestion_remains/organic/skull	//RS EDIT
	name = "skull"
	desc = "A bleached skull. It looks very weakened. Seems like it belonged to a human."
	icon_state = "skull"

/obj/item/weapon/digestion_remains/organic/skull/tajaran	//RS EDIT
	desc = "A bleached skull. It looks very weakened. Seems like it belonged to a tajara."
	icon_state = "skull_taj"

/obj/item/weapon/digestion_remains/organic/skull/unathi	//RS EDIT
	desc = "A bleached skull. It looks very weakened. Seems like it belonged to an unathi."
	icon_state = "skull_unathi"

/obj/item/weapon/digestion_remains/organic/skull/skrell	//RS EDIT
	desc = "A bleached skull. It looks very weakened. Seems like it belonged to a skrell."
	icon_state = "skull"

/obj/item/weapon/digestion_remains/organic/skull/vasilissan	//RS EDIT
	desc = "A bleached skull. It looks very weakened. Seems like it belonged to a vasilissan."
	icon_state = "skull"

/obj/item/weapon/digestion_remains/organic/skull/akula	//RS EDIT
	desc = "A bleached skull. It looks very weakened. Seems like it belonged to an akula."
	icon_state = "skull_unathi"

/obj/item/weapon/digestion_remains/organic/skull/rapala	//RS EDIT
	desc = "A bleached skull. It looks very weakened. Seems like it belonged to a rapala."
	icon_state = "skull"

/obj/item/weapon/digestion_remains/organic/skull/vulpkanin	//RS EDIT
	desc = "A bleached skull. It looks very weakened. Seems like it belonged to a vulpkanin."
	icon_state = "skull_taj"

/obj/item/weapon/digestion_remains/organic/skull/sergal	//RS EDIT
	desc = "A bleached skull. It looks very weakened. Seems like it belonged to a sergal."
	icon_state = "skull_taj"

/obj/item/weapon/digestion_remains/organic/skull/zorren	//RS EDIT
	desc = "A bleached skull. It looks very weakened. Seems like it belonged to a zorren."
	icon_state = "skull_taj"

/obj/item/weapon/digestion_remains/organic/skull/nevrean	//RS EDIT
	desc = "A bleached skull. It looks very weakened. Seems like it belonged to a nevrean."
	icon_state = "skull_taj"

/obj/item/weapon/digestion_remains/organic/skull/teshari	//RS EDIT
	desc = "A bleached skull. It looks very weakened. Seems like it belonged to a teshari."
	icon_state = "skull_taj"

/obj/item/weapon/digestion_remains/organic/skull/vox	//RS EDIT
	desc = "A bleached skull. It looks very weakened. Seems like it belonged to a vox."
	icon_state = "skull_taj"

/obj/item/weapon/digestion_remains/organic/skull/unknown	//RS EDIT
	desc = "A bleached skull. It looks very weakened. You can't quite tell what species it belonged to."
	icon_state = "skull"

/obj/item/weapon/digestion_remains/organic/skull/unknown/anthro	//RS EDIT
	icon_state = "skull_taj"
