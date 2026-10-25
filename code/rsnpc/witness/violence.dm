GLOBAL_DATUM(npc_violence, /datum/npc_violence)

/datum/npc_blow
	var/attacker_key
	var/victim_key
	var/attacker_job
	var/valid = FALSE
	var/lethal = FALSE
	var/points
	var/what
	var/at

/datum/npc_event
	var/kind
	var/name
	var/key
	var/other
	var/other_key
	var/at
	var/told = 0
	var/list/told_to = list()

/datum/npc_violence/New()
	..()
	RegisterSignal(SSdcs, COMSIG_GLOB_ATTACK_LOGGED, PROC_REF(attack_logged))

/datum/npc_violence/proc/attack_logged(datum/source, mob/living/user, mob/living/target, what_done, atom/weapon)
	if(user == target || !npc_is_person(target) || !npc_is_person(user) && !istype(user, /mob/living/simple_mob))
		return
	if(findtext(what_done, "Removed equipment from slot ") == 1 || findtext(what_done, "Stripped ") == 1 || findtext(what_done, "Adjusted suit sensor level") == 1)
		var/datum/ai_holder/rsnpc/stripped = npc_ai_mind(target)
		stripped?.stripped_by(user, what_done)
		return
	if(findtext(what_done, "Digested in") == 1)
		var/datum/ai_holder/rsnpc/pred = npc_ai_mind(user)
		pred?.prey_digested(target)
		return
	if(findtext(what_done, "Forced to eat") == 1)
		var/datum/ai_holder/rsnpc/fed = npc_ai_mind(target)
		fed?.note("fed_by", WEAKREF(user), 5 SECONDS)
		return
	var/points = npc_blow_points(user, target, what_done, weapon)
	if(!points)
		return
	var/datum/npc_blow/B = new
	B.attacker_key = npc_person_key(user)
	B.victim_key = npc_person_key(target)
	B.attacker_job = npc_manifest_job(user)
	B.valid = npc_is_valid_attack(user, what_done, weapon) && !((findtext(what_done, "attacked with") == 1 || findtext(what_done, "Shot with") == 1) && (target.lying || target.stat || target.restrained()))
	B.lethal = npc_is_lethal_attack(user, what_done, weapon)
	B.points = points
	B.what = what_done
	B.at = world.time
	for(var/mob/living/W as anything in GLOB.npc_workers)
		var/datum/ai_holder/rsnpc/ai_mind = npc_ai_mind(W)
		if(ai_mind && W != user && (W == target || ai_mind.can_witness(target)) && ai_mind.sees(user))
			ai_mind.judge(B, user, target)

/proc/npc_blow_points(mob/living/user, mob/living/target, what_done, atom/weapon)
	var/points = 0
	if(findtext(what_done, "Disarmed") == 1)
		points = 1
	else if(findtext(what_done, "Melee attacked with fists") == 1)
		points = 3
	else if(findtext(what_done, "Aggressively grabbed") == 1 || findtext(what_done, "Handcuffed") == 1 || findtext(what_done, "Flashed") == 1)
		points = 10
	else if(findtext(what_done, "Neck grabbed") == 1 || findtext(what_done, "Strangled") == 1)
		points = 25
	else if(findtext(what_done, "Injected") == 1 || findtext(what_done, "Fed a pill") == 1)
		points = 1
	else if(findtext(what_done, "Shot with") == 1)
		var/obj/item/projectile/P = weapon
		points = (istype(P) && (P.nodamage || P.damage_type == HALLOSS)) ? 10 : 25
	else if(findtext(what_done, "attacked with") == 1 || findtext(what_done, "Hit with") == 1)
		points = npc_weapon_points(weapon || user.get_active_hand())
	else if(findtext(what_done, "Generic attack") == 1)
		var/mob/living/simple_mob/S = user
		points = istype(S) ? max(1, S.melee_damage_lower + S.melee_damage_upper) : 3
	if(points && (target.lying || target.stat))
		points *= 2
	return points

/proc/npc_is_valid_attack(mob/living/user, what_done, atom/weapon)
	if(findtext(what_done, "Aggressively grabbed") == 1 || findtext(what_done, "Handcuffed") == 1 || findtext(what_done, "Flashed") == 1)
		return TRUE
	if(findtext(what_done, "Shot with") == 1)
		var/obj/item/projectile/P = weapon
		return istype(P) && (P.nodamage || P.damage_type == HALLOSS)
	if(findtext(what_done, "attacked with") == 1)
		return istype(weapon || user.get_active_hand(), /obj/item/weapon/melee/baton) && user.a_intent != I_HURT && user.a_intent != I_GRAB
	return FALSE

/proc/npc_is_lethal_attack(mob/living/user, what_done, atom/weapon)
	if(findtext(what_done, "Neck grabbed") == 1 || findtext(what_done, "Strangled") == 1 || findtext(what_done, "Generic attack") == 1)
		return TRUE
	if(findtext(what_done, "Shot with") == 1)
		return !npc_is_valid_attack(user, what_done, weapon)
	if(findtext(what_done, "attacked with") == 1 || findtext(what_done, "Hit with") == 1)
		var/obj/item/I = weapon || user.get_active_hand()
		if(!istype(I) || !I.force || istype(I, /obj/item/device/flash) || istype(I, /obj/item/weapon/handcuffs))
			return FALSE
		return !npc_is_valid_attack(user, what_done, weapon)
	return FALSE

/proc/npc_weapon_points(obj/item/I)
	if(!istype(I) || !I.force)
		return 1
	if(istype(I, /obj/item/weapon/melee/baton) || istype(I, /obj/item/device/flash) || istype(I, /obj/item/weapon/handcuffs))
		return 10
	return I.force * 2

/proc/npc_next_step(points)
	for(var/step in list(1, 3, 10, 25))
		if(step > points)
			return step
	return points

/datum/ai_holder/rsnpc/proc/can_witness(mob/living/victim)
	if(holder.client || holder.stat != CONSCIOUS)
		return FALSE
	if(get_z(victim) != get_z(holder) || get_dist(victim, holder) > npc_psetting("witness_range"))
		return FALSE
	return victim in look()

/datum/ai_holder/rsnpc/proc/blow_agreed(datum/npc_blow/B, mob/living/victim)
	var/held_for = victim == holder ? holds_still_for(B.attacker_key) : noted("told_hold_still:[B.victim_key]:[B.attacker_key]")
	return findtext(B.what, "Aggressively grabbed") == 1 && (held_for || noted("agreed_eat:[B.victim_key]:[B.attacker_key]"))

/datum/ai_holder/rsnpc/proc/blow_excuse(datum/npc_blow/B, mob/living/victim)
	if(B.valid && SSjob.is_job_in_department(B.attacker_job, DEPARTMENT_SECURITY))
		return 1
	for(var/datum/npc_blow/O as anything in blows_seen)
		if(blows_seen[O] || O.attacker_key != B.victim_key)
			continue
		if(O.victim_key != B.attacker_key || B.points <= npc_next_step(O.points))
			return 1
	var/danger = danger_of(victim)
	if(danger >= NPC_DANGEROUS)
		return 1
	if(danger >= NPC_WARY)
		return 0.5
	return 0

/datum/ai_holder/rsnpc/proc/blow_forgiven(datum/npc_blow/B, mob/living/victim)
	if(victim == holder)
		return FALSE
	var/liking = opinion_of(B.attacker_key)
	if(opinion_of(victim) >= liking)
		return FALSE
	if(liking >= npc_setting("friend_ignores_all_at"))
		return TRUE
	return liking >= npc_setting("friend_ignores_blows_at") && !B.lethal

/datum/ai_holder/rsnpc/proc/judge(datum/npc_blow/B, mob/living/attacker, mob/living/victim)
	if(blow_forgiven(B, victim))
		NPC_TRACE(src, NPC_TRACE_WITNESS, "let [B.what] on [victim] go; [attacker] is my friend")
		return
	var/provoked = FALSE
	for(var/datum/npc_blow/O as anything in blows_seen.Copy())
		if(O.at < world.time - 45 SECONDS)
			blows_seen -= O
		else if(O.attacker_key == B.victim_key && O.victim_key == B.attacker_key)
			provoked = TRUE
	var/excuse = blow_agreed(B, victim) ? 1 : blow_excuse(B, victim) * npc_psetting("violence_excuse_share")
	blows_seen[B] = provoked
	var/crossed = add_danger(attacker, B.points * (1 - excuse), "[B.what] on [victim]")
	if(victim == holder)
		if(B.points >= 10 && excuse < 1)
			radio_attacked(attacker)
		return
	var/loss = (npc_psetting("witness_attack_opinion") + opinion_of(victim) * npc_psetting("friend_attack_penalty")) * (1 - excuse)
	if(loss > 0)
		change_opinion(attacker, -loss, "saw them hit [victim]")
	remember(excuse >= 1 ? NPC_EVENT_JUSTIFIED_FIGHT : NPC_EVENT_FIGHT, attacker, victim)
	var/list/blanks = list("name" = attacker.name, "other" = victim.name, "place" = "[get_area(victim)]")
	if(crossed && in_the_room())
		say_line("alarm_witness", blanks, radiochannels["Security"])
	if(world.time < when_remarked + npc_psetting("witness_speech_gap") SECONDS || !prob(npc_psetting("witness_speak_chance")))
		return
	when_remarked = world.time
	if(excuse >= 1)
		say_line("witness_violence_justified", blanks)
	else if(opinion_of(victim) >= npc_psetting("opinion_liked_at"))
		say_line("witness_violence_friend", blanks)
	else
		say_line("witness_violence", blanks)

/datum/ai_holder/rsnpc/proc/remember(kind, mob/living/M, mob/living/other)
	var/key = npc_person_key(M)
	var/other_key = npc_person_key(other)
	var/list/old = list()
	for(var/datum/npc_event/E as anything in witnessed)
		if(world.time > E.at + npc_psetting("witness_memory_minutes") MINUTES)
			old += E
		else if(E.kind == kind && E.key == key && E.other_key == other_key)
			E.at = world.time
			return
	witnessed -= old
	var/datum/npc_event/N = new
	N.kind = kind
	N.name = M.name
	N.key = key
	N.other = other?.name
	N.other_key = other_key
	N.at = world.time
	witnessed += N

/datum/ai_holder/rsnpc/proc/saw_body(mob/living/M)
	var/key = npc_person_key(M)
	var/datum/npc_event/fight
	for(var/datum/npc_event/E as anything in witnessed)
		if(E.kind == NPC_EVENT_DEATH && E.key == key)
			return
		if(E.kind == NPC_EVENT_FIGHT && E.other_key == key && world.time < E.at + 45 SECONDS)
			fight = E
	remember(NPC_EVENT_DEATH, M)
	NPC_TRACE(src, NPC_TRACE_WITNESS, "saw the body of [M]")
	if(fight)
		blame_killer(fight, M)
	if(world.time < when_body_remarked + npc_psetting("witness_body_gap") MINUTES)
		return
	when_body_remarked = world.time
	say_line("witness_body", list("name" = M.name))

/datum/ai_holder/rsnpc/proc/blame_killer(datum/npc_event/E, mob/living/victim)
	if(add_danger(E.key, 25, "[victim] died after they attacked them") && in_the_room())
		say_line("alarm_witness", list("name" = E.name, "other" = victim.name, "place" = "[get_area(victim)]"), radiochannels["Security"])
