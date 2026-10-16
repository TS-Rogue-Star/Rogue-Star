GLOBAL_LIST_INIT(npc_held_moods, list(
	"active_happy" = list("gap" = 45, "struggle" = 0),
	"neutral_happy" = list("gap" = 0, "struggle" = 0),
	"inactive_happy" = null,
	"active_neutral" = list("gap" = 30, "struggle" = 0),
	"neutral_neutral" = list("gap" = 0, "struggle" = 0),
	"inactive_neutral" = null,
	"active_upset" = list("gap" = 12, "struggle" = 5),
	"neutral_upset" = list("gap" = 24, "struggle" = 15),
	"inactive_upset" = list("gap" = 30, "struggle" = 20),
))

/datum/npc_held
	var/datum/weakref/by
	var/by_name
	var/by_key
	var/in_belly = FALSE
	var/start_mood = 0
	var/since = 0
	var/activity = 0.3
	var/tired = 0
	var/effects_at = 0
	var/said_at = 0
	var/list/once_said = list()
	var/asked_at = 0
	var/asks_ignored = 0
	var/struggled_at = 0
	var/betrayed = FALSE

/datum/ai_holder/rsnpc/handle_eaten()
	clear_task()
	held_tick()

/datum/ai_holder/rsnpc/proc/held_by()
	var/obj/belly/B = holder.loc
	if(istype(B))
		return B.owner
	for(var/obj/item/weapon/grab/G in holder.grabbed_by)
		if(G.state >= GRAB_AGGRESSIVE)
			return G.assailant
	return null

/datum/ai_holder/rsnpc/proc/held_tick()
	var/mob/living/M = held_by()
	if(held && held.by?.resolve() != M)
		end_held()
	if(!M)
		return
	if(!held)
		start_held(M)
	if(!held.in_belly && isbelly(holder.loc))
		held.in_belly = TRUE
		NPC_TRACE(src, NPC_TRACE_WITNESS, "now inside [M]")
	held_effects(M)
	if(holder.stat != CONSCIOUS)
		return
	var/mood = held_mood(M)
	var/list/entry = GLOB.npc_held_moods[mood]
	var/asks = !findtext(mood, "_happy")
	if(held.asked_at && world.time > held.asked_at + 45 SECONDS)
		held.asked_at = 0
		held.asks_ignored++
	if(!entry)
		return
	var/quiet = asks && agreed(holder, M, TRUE) && danger_of(M) < NPC_WARY && opinion_of(M) > npc_psetting("opinion_disliked_at")
	if(!quiet && (entry["gap"] ? world.time > held.said_at + entry["gap"] SECONDS : !(mood in held.once_said)))
		held.said_at = world.time
		held.once_said |= mood
		if(asks)
			held.asked_at = world.time
		say_line("held_[held.in_belly ? "belly" : "grab"]_[mood]", list("name" = M.name))
	if(entry["struggle"] && world.time > held.struggled_at + (held.in_belly ? entry["struggle"] SECONDS : RESIST_COOLDOWN))
		held.struggled_at = world.time
		held.tired += 0.04
		INVOKE_ASYNC(src, PROC_REF(start_resist))

/datum/ai_holder/rsnpc/proc/start_held(mob/living/M)
	held = new
	held.by = WEAKREF(M)
	held.by_name = M.name
	held.by_key = npc_person_key(M)
	held.in_belly = isbelly(holder.loc)
	held.since = world.time
	held.effects_at = world.time
	if(agreed(holder, M, FALSE) || agreed(holder, M, TRUE))
		held.start_mood = 0.6
	else if(noted("refused_eat:[held.by_key]") || noted("refused_digest:[held.by_key]"))
		held.start_mood = -0.8
		if(held.in_belly)
			change_opinion(M, -15, "ate me after I said no")
			add_danger(M, 10, "ate me after I said no")
	else
		held.start_mood = -0.4
	NPC_TRACE(src, NPC_TRACE_WITNESS, "held by [M] ([held.in_belly ? "inside them" : "in a firm grab"])")

/datum/ai_holder/rsnpc/proc/end_held()
	var/mob/living/M = held.by?.resolve()
	if(M && holder.stat == CONSCIOUS && world.time > held.since + 5 SECONDS)
		var/mood = held_mood(M)
		say_line("held_released_[copytext(mood, findtext(mood, "_") + 1)]", list("name" = held.by_name))
	NPC_TRACE(src, NPC_TRACE_WITNESS, "no longer held by [held.by_name]")
	held = null

/datum/ai_holder/rsnpc/proc/held_effects(mob/living/M)
	if(world.time < held.effects_at + 10 SECONDS)
		return
	var/minutes = (world.time - held.effects_at) / (1 MINUTE)
	held.effects_at = world.time
	held.activity = clamp(held.activity + 0.05 * minutes, 0, 1)
	held.tired = max(0, held.tired - 0.2 * minutes)
	var/obj/belly/B = holder.loc
	if(!istype(B))
		return
	if(B.digest_mode == DM_HEAL)
		change_opinion(M, npc_psetting("heal_belly_opinion_per_minute") * minutes, "healing me")
	if(!(B.digest_mode in list(DM_DIGEST, DM_ABSORB, DM_DRAIN)) || agreed(holder, M, TRUE))
		return
	if(agreed(holder, M, FALSE) && !held.betrayed)
		held.betrayed = TRUE
		say_line("held_betrayed", list("name" = M.name))
		change_opinion(M, -npc_psetting("held_betrayed_opinion"), "betrayed me")
		add_danger(M, 10, "betrayed me")
		return
	change_opinion(M, -8 * minutes, "harming me inside them")
	add_danger(M, 10 * minutes, "harming me inside them")

/datum/ai_holder/rsnpc/proc/held_mood(mob/living/M)
	var/happy = held.start_mood + 1.5 * opinion_of(M) / 100 - min(1, danger_of(M) / NPC_DANGEROUS) - 0.2 * held.asks_ignored + npc_psetting("prey_desire")
	var/obj/belly/B = holder.loc
	if(istype(B) && B.digest_mode == DM_HEAL)
		happy += 0.3
	if(istype(B) && (B.digest_mode in list(DM_DIGEST, DM_ABSORB, DM_DRAIN)) && !agreed(holder, M, TRUE))
		happy -= 1
	var/band = npc_psetting("prey_inside_enjoyment")
	var/mood = happy >= band ? "happy" : (happy <= -band ? "upset" : "neutral")
	var/active = held.activity - held.tired
	return "[active >= 0.66 ? "active" : (active <= 0.33 ? "inactive" : "neutral")]_[mood]"
