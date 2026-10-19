//RS FILE
/decl/emote/audible/multisound
	key = "0000000000000"

	var/list/soundlist = list()

/decl/emote/audible/multisound/get_emote_sound(var/mob/living/user)
	emote_sound = pick(soundlist)

	. = ..()

/decl/emote/audible/multisound/yip
	key = "yip"
	emote_message_1p = "You yip! Yip!"
	emote_message_3p = "yips!"

	emote_message_impaired = "makes a sound but you can't hear it."

	emote_message_1p_target = "You yip at TARGET! Yip!!!"
	emote_message_3p_target = "yips at TARGET!"

	emote_sound = null
	soundlist = list('sound/rogue-star/yip/yip1.ogg', 'sound/rogue-star/yip/yip2.ogg', 'sound/rogue-star/yip/yip3.ogg', 'sound/rogue-star/yip/yip4.ogg', 'sound/rogue-star/yip/yip5.ogg', 'sound/rogue-star/yip/yip6.ogg', 'sound/rogue-star/yip/yip7.ogg', 'sound/rogue-star/yip/yip8.ogg', 'sound/rogue-star/yip/yip9.ogg', 'sound/rogue-star/yip/yip10.ogg', 'sound/rogue-star/yip/yip11.ogg', 'sound/rogue-star/yip/yip12.ogg', 'sound/rogue-star/yip/yip13.ogg', 'sound/rogue-star/yip/yip14.ogg', 'sound/rogue-star/yip/yip15.ogg')
	sound_vary = TRUE

/decl/emote/audible/multisound/yap
	key = "yap"
	emote_message_1p = "You yap! Yap yap!"
	emote_message_3p = "yaps!"

	emote_message_impaired = "makes a sound but you can't hear it."

	emote_message_1p_target = "You yap at TARGET! Yap yap!!!"
	emote_message_3p_target = "yaps at TARGET!"
	soundlist = list('sound/rogue-star/yap/yap1.ogg', 'sound/rogue-star/yap/yap2.ogg', 'sound/rogue-star/yap/yap4.ogg', 'sound/rogue-star/yap/yap5.ogg', 'sound/rogue-star/yap/yap6.ogg', 'sound/rogue-star/yap/yap7.ogg', 'sound/rogue-star/yap/yap8.ogg', 'sound/rogue-star/yap/yap9.ogg', 'sound/rogue-star/yap/yap10.ogg', 'sound/rogue-star/yap/yap11.ogg', 'sound/rogue-star/yap/yap12.ogg', 'sound/rogue-star/yap/yap13.ogg', 'sound/rogue-star/yap/yap14.ogg')

/decl/emote/audible/multisound/awawa
	key = "awawa"
	emote_message_1p = "You awawa!"
	emote_message_3p = "awawas!"

	emote_message_impaired = "makes a sound but you can't hear it."

	emote_message_1p_target = "You awawa at TARGET."
	emote_message_3p_target = "awawas at TARGET."

	emote_sound = null
	soundlist = list(
			'sound/voice/awawa1.ogg',
			'sound/voice/awawa2.ogg',
			'sound/voice/awawa3.ogg'
			)
	sound_vary = TRUE

/decl/emote/audible/glub
	key = "glub"
	emote_message_1p = "You glub."
	emote_message_3p = "glubs."

	emote_message_impaired = "makes a sound but you can't hear it."

	emote_message_1p_target = "You glub at TARGET."
	emote_message_3p_target = "glubs at TARGET."

	emote_sound = 'sound/voice/glub.ogg'
	sound_vary = TRUE

/decl/emote/audible/multisound/poyo
	key = "poyo"
	emote_message_1p = "You go poyo!"
	emote_message_3p = "poyos!"

	emote_message_impaired = "makes a sound but you can't hear it."

	emote_message_1p_target = "You poyo at TARGET!!!"
	emote_message_3p_target = "poyos at TARGET!"

	emote_sound = null
	soundlist = list(
		'sound/rogue-star/poyo/poyo1.ogg', 'sound/rogue-star/poyo/poyo2.ogg', 'sound/rogue-star/poyo/poyo3.ogg', 'sound/rogue-star/poyo/poyo4.ogg',
		'sound/rogue-star/poyo/poyo5.ogg', 'sound/rogue-star/poyo/poyo6.ogg', 'sound/rogue-star/poyo/poyo7.ogg', 'sound/rogue-star/poyo/poyo8.ogg',
		'sound/rogue-star/poyo/poyo9.ogg', 'sound/rogue-star/poyo/poyo10.ogg', 'sound/rogue-star/poyo/poyo11.ogg', 'sound/rogue-star/poyo/poyo12.ogg',
		'sound/rogue-star/poyo/poyo13.ogg', 'sound/rogue-star/poyo/poyo14.ogg', 'sound/rogue-star/poyo/poyo15.ogg', 'sound/rogue-star/poyo/poyo16.ogg',
		'sound/rogue-star/poyo/poyo17.ogg', 'sound/rogue-star/poyo/poyo18.ogg', 'sound/rogue-star/poyo/poyo19.ogg', 'sound/rogue-star/poyo/poyo20.ogg',
		'sound/rogue-star/poyo/poyo21.ogg', 'sound/rogue-star/poyo/poyo22.ogg', 'sound/rogue-star/poyo/poyo23.ogg')
	sound_vary = TRUE

/decl/emote/audible/multisound/a
	key = "a"
	emote_message_1p = "You go A!"
	emote_message_3p = "makes a sharp A!"

	emote_message_impaired = "makes a sound but you can't hear it."

	emote_message_1p_target = "You A sharply at TARGET!!!"
	emote_message_3p_target = "makes a sharp A at TARGET!"

	emote_sound = null
	soundlist = list(
		'sound/rogue-star/a/a1.ogg', 'sound/rogue-star/a/a2.ogg', 'sound/rogue-star/a/a3.ogg', 'sound/rogue-star/a/a4.ogg',
		'sound/rogue-star/a/a5.ogg', 'sound/rogue-star/a/a6.ogg', 'sound/rogue-star/a/a7.ogg', 'sound/rogue-star/a/a8.ogg')
	sound_vary = TRUE

/decl/emote/audible/multisound/wawa
	key = "wawa"
	emote_message_1p = "You wawa!"
	emote_message_3p = "wawas!"

	emote_message_impaired = "makes a sound but you can't hear it."

	emote_message_1p_target = "You wawa at TARGET!!!"
	emote_message_3p_target = "wawas at TARGET!"

	emote_sound = null
	soundlist = list(
		'sound/rogue-star/wawa/wawa1.ogg', 'sound/rogue-star/wawa/wawa2.ogg', 'sound/rogue-star/wawa/wawa3.ogg', 'sound/rogue-star/wawa/wawa4.ogg',
		'sound/rogue-star/wawa/wawa5.ogg', 'sound/rogue-star/wawa/wawa6.ogg', 'sound/rogue-star/wawa/wawa7.ogg', 'sound/rogue-star/wawa/wawa8.ogg',
		'sound/rogue-star/wawa/wawa9.ogg', 'sound/rogue-star/wawa/wawa10.ogg', 'sound/rogue-star/wawa/wawa11.ogg', 'sound/rogue-star/wawa/wawa12.ogg',
		'sound/rogue-star/wawa/wawa13.ogg', 'sound/rogue-star/wawa/wawa14.ogg', 'sound/rogue-star/wawa/wawa15.ogg','sound/rogue-star/wawa/wawa16.ogg')
	sound_vary = TRUE

/decl/emote/audible/multisound/huff

	key = "huff"
	emote_message_1p = "You huff!"
	emote_message_3p = "huffs!"
	emote_message_1p_target = "You huff at TARGET!!!"
	emote_message_3p_target = "huffs at TARGET!"

	emote_sound = null
	soundlist = list("sound/rogue-star/huff/huff1.ogg","sound/rogue-star/huff/huff2.ogg","sound/rogue-star/huff/huff3.ogg","sound/rogue-star/huff/huff4.ogg")
	sound_vary = TRUE

/decl/emote/audible/multisound/huff/do_extra(atom/user, atom/target)
	if(ismob(user))
		var/mob/M = user
		huff_particles(M)

/proc/huff_particles(var/mob/M)
	if(!M || !ismob(M))
		return

	var/turf/current_turf = get_turf(M)

	var/obj/particle_emitter/belch/B
	switch(M.dir)
		if(NORTH)
			B = new /obj/particle_emitter/steam/huff/n(current_turf)
		if(SOUTH)
			B = new /obj/particle_emitter/steam/huff/s(current_turf)
		if(EAST)
			B = new /obj/particle_emitter/steam/huff/e(current_turf)
		if(WEST)
			B = new /obj/particle_emitter/steam/huff/w(current_turf)
	if(!B)
		return
	B.scale_to_character(M)
	if(M.client?.prefs_vr.huff_color)
		B.particles.color = M.client.prefs_vr.huff_color
	var/list/our_turfs = list()
	for(var/I = 1 to 3)
		our_turfs += current_turf
		current_turf = get_step(current_turf, M.dir)
	for(var/turf/T in our_turfs)
		for(var/mob/living/L in T.contents)
			if(!isliving(L))
				continue
			if(L == M)
				continue
			L.resolve_stimuli(M, STIM_HUFF)
