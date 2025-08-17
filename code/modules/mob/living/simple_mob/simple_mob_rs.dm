//RS FILE
/mob/living/proc/feed_from_target(var/mob/living/food)
	if(!isliving(food))
		return
	if(faction == food.faction)
		return
	if(food.pips <= 0)	//Has it already been eaten?
		return	//IT HAS NOOO
	add_modifier(/datum/modifier/feeding, origin = food)

/mob/living/proc/reduce_pips(var/amount)
	if(QDELING(src)) return FALSE	//Don't do it if you're deleting
	if(pips <= 0) return FALSE	//don't do it if you're already gone
	if(amount >= 0)
		pips -= amount
	if(pips <= 0)
		new /obj/effect/decal/cleanable/blood(get_turf(src))
		Destroy()
	return TRUE

/datum/modifier/feeding
	name = "feeding"

	var/feeding_rate = 10		//This number * 5 equals the total pip usage! (50%)
	var/nutrition_rate = 100	//This number * 5 equals the total nutrition gain! (500)
	var/mob/living/prey
	var/bites

/datum/modifier/feeding/New(new_holder, new_origin)
	. = ..()
	if(isliving(new_origin))
		prey = new_origin
	else
		expire()
		return
	holder.ai_holder.set_busy(TRUE)
	holder.ai_holder.remove_target()
	RegisterSignal(holder, COMSIG_MOVABLE_MOVED, PROC_REF(expire))	//Let's listen for our mob to say it moved! If it does, then we expire!
	RegisterSignal(holder, COMSIG_MOB_APPLY_DAMGE, PROC_REF(expire))	//Let's listen for our mob to take damage! If it does, then we expire!
	RegisterSignal(prey, COMSIG_PARENT_QDELETING, PROC_REF(expire))
	holder.visible_message(SPAN_DANGER("\The [holder] feeds from \the [prey]."))

	var/howmany = prey.mob_size - holder.mob_size
	if(howmany < -10)			//Significantly smaller things are worth less, and faster to eat! Worth only one feeding!
		feeding_rate = 20		//100%
		nutrition_rate = 50		//250 nutrition
	else if(howmany > 10)		//Significantly bigger things are worth more, and slower to eat! Worth 3 feedings!
		feeding_rate = 7		//35%
		nutrition_rate = 200	//1000 max per feed

/datum/modifier/feeding/tick()
	. = ..()
	if(bites >= 5)	//Only 5 bites per feeding!!!
		expire()
		return
	if(!prey?.reduce_pips(feeding_rate))	//Reduce and/or check the pips!
		expire()
		return
	holder.nutrition += nutrition_rate	//Apply da nutrition
	bites ++	//Nom
	holder.visible_message(runemessage = pick(list("nom","hom","om","nomp","snarf","homph")))

/datum/modifier/feeding/expire(silent)
	. = ..()
	prey = null
	UnregisterSignal(prey, COMSIG_PARENT_QDELETING)	//Clean dis up real fast
	UnregisterSignal(holder, COMSIG_MOVABLE_MOVED)
	UnregisterSignal(holder, COMSIG_MOB_APPLY_DAMGE)
	holder.ai_holder.set_busy(FALSE)
	if(bites >= 3)	//Only gulp if you actually got a bite!!!
		holder.visible_message(runemessage = pick(list("gulp","gllp","gllrk","glugg","gllrtch","ulp")))

/datum/modifier/bleeding
	name = "Simplemob Bleeding"
	var/idle_time = 0

/datum/modifier/bleeding/tick()
	. = ..()
	if(holder.stat)
		expire()
		return
	if(isbelly(holder.loc))
		expire()
		return
//new /obj/effect/decal/cleanable/blood/drip(get_turf(holder))
	blood_splatter(holder,holder,mob_source = holder)
	holder.adjustOxyLoss(2)
	if(holder.resting)
		expire()
	if(holder.player_login_key_log)
		return
	if(holder.ai_holder)
		if(holder.ai_holder.stance == STANCE_IDLE)
			idle_time ++
		else
			idle_time = 0
	if(idle_time >= 30)
		expire()

var/mob/living/simple_mob/simplemob_bleeds = TRUE

/mob/living/simple_mob/adjustBruteLoss(amount, include_robo)
	. = ..()
	if(simplemob_bleeds)
		add_modifier(/datum/modifier/bleeding)
