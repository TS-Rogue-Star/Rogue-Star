/decl/emote/audible/yip
	key = "yip"
	emote_message_1p = "You yip! Yip!"
	emote_message_3p = "yips!"

	emote_message_impaired = "makes a sound but you can't hear it."

	emote_message_1p_target = "You yip at TARGET! Yip!!!"
	emote_message_3p_target = "yips at TARGET!"

	emote_sound = null
	var/list/soundlist = list('sound/rogue-star/yip/yip1.ogg', 'sound/rogue-star/yip/yip2.ogg', 'sound/rogue-star/yip/yip3.ogg', 'sound/rogue-star/yip/yip4.ogg', 'sound/rogue-star/yip/yip5.ogg', 'sound/rogue-star/yip/yip6.ogg', 'sound/rogue-star/yip/yip7.ogg', 'sound/rogue-star/yip/yip8.ogg', 'sound/rogue-star/yip/yip9.ogg', 'sound/rogue-star/yip/yip10.ogg', 'sound/rogue-star/yip/yip11.ogg', 'sound/rogue-star/yip/yip12.ogg', 'sound/rogue-star/yip/yip13.ogg', 'sound/rogue-star/yip/yip14.ogg', 'sound/rogue-star/yip/yip15.ogg')
	sound_vary = TRUE

/decl/emote/audible/yip/get_emote_sound(var/mob/living/user)
	emote_sound = pick(soundlist)

	. = ..()

/decl/emote/audible/yip/yap
	key = "yap"
	emote_message_1p = "You yap! Yap yap!"
	emote_message_3p = "yaps!"

	emote_message_impaired = "makes a sound but you can't hear it."

	emote_message_1p_target = "You yap at TARGET! Yap yap!!!"
	emote_message_3p_target = "yaps at TARGET!"
	soundlist = list('sound/rogue-star/yap/yap1.ogg', 'sound/rogue-star/yap/yap2.ogg', 'sound/rogue-star/yap/yap4.ogg', 'sound/rogue-star/yap/yap5.ogg', 'sound/rogue-star/yap/yap6.ogg', 'sound/rogue-star/yap/yap7.ogg', 'sound/rogue-star/yap/yap8.ogg', 'sound/rogue-star/yap/yap9.ogg', 'sound/rogue-star/yap/yap10.ogg', 'sound/rogue-star/yap/yap11.ogg', 'sound/rogue-star/yap/yap12.ogg', 'sound/rogue-star/yap/yap13.ogg', 'sound/rogue-star/yap/yap14.ogg')

/decl/emote/audible/awawa
	key = "awawa"
	emote_message_1p = "You awawa!"
	emote_message_3p = "awawas!"

	emote_message_impaired = "makes a sound but you can't hear it."

	emote_message_1p_target = "You awawa at TARGET."
	emote_message_3p_target = "awawas at TARGET."

	emote_sound = null
	var/list/soundlist = list(
			'sound/voice/awawa1.ogg',
			'sound/voice/awawa2.ogg',
			'sound/voice/awawa3.ogg'
			)
	sound_vary = TRUE

/decl/emote/audible/awawa/get_emote_sound(var/mob/living/user)
	emote_sound = pick(soundlist)
	. = ..()

/decl/emote/audible/glub
	key = "glub"
	emote_message_1p = "You glub."
	emote_message_3p = "glubs."

	emote_message_impaired = "makes a sound but you can't hear it."

	emote_message_1p_target = "You glub at TARGET."
	emote_message_3p_target = "glubs at TARGET."

	emote_sound = null
	var/list/soundlist = list(
			'sound/voice/glub.ogg',
			)
	sound_vary = TRUE

/decl/emote/audible/glub/get_emote_sound(var/mob/living/user)
	emote_sound = pick(soundlist)
	. = ..()
