//RS add start || Ports CHOMPStation PR 8816
/obj/item/toy/plushie/teppi
	name = "teppi plushie"
	desc = "A soft, fluffy plushie made out of real teppi fur!"
	icon = 'icons/obj/toy_rs.dmi'
	icon_state = "teppi"
	pokephrase = "Gyooooooooh!"

/obj/item/toy/plushie/teppi/attack_self(mob/user as mob)
	if(user.a_intent == I_HURT || user.a_intent == I_GRAB)
		playsound(user, 'sound/voice/teppi/roar.ogg', 10, 0)
	else
		var/teppi_noise = pick(
			'sound/voice/teppi/whine1.ogg',
			'sound/voice/teppi/whine2.ogg')
		playsound(user, teppi_noise, 10, 0)
		src.visible_message(SPAN_NOTICE("Gyooooooooh!"))
	return ..()
//RS add end || Ports CHOMPStation PR 8816

/obj/item/toy/plushie/lasagna
	name = "lasagna plushie"
	desc = "Cuddly, soft-y, and probably not so ready to eat-y."
	icon = 'icons/obj/toy_rs.dmi'
	icon_state = "lasagna"
