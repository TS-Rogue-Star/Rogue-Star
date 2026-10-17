GLOBAL_LIST_INIT(npc_needs, list(
	NPC_NEED_REST = /datum/npc_need/rest,
	NPC_NEED_HUNGER = /datum/npc_need/hunger,
	NPC_NEED_HEALTH = /datum/npc_need/health,
))

/datum/npc_need
	var/datum/ai_holder/rsnpc/ai_mind
	var/level = 100
	var/at = 0
	var/start_key
	var/setpoint_key
	var/loss_key

/datum/npc_need/New(datum/ai_holder/rsnpc/ai_mind)
	src.ai_mind = ai_mind
	level = ai_mind.npc_psetting(start_key)
	at = world.time

/datum/npc_need/proc/now()
	level = clamp(level - (world.time - at) / (1 MINUTE) * ai_mind.npc_psetting(loss_key), 0, 100)
	at = world.time
	return level

/datum/npc_need/proc/add(amount)
	level = clamp(now() + amount, 0, 100)

/datum/npc_need/proc/set_level(value)
	level = clamp(value, 0, 100)
	at = world.time

/datum/npc_need/proc/pressure()
	var/setpoint = ai_mind.npc_psetting(setpoint_key)
	return clamp((setpoint - now()) / setpoint, 0, 1)

/datum/npc_need/rest
	start_key = "rest_start"
	setpoint_key = "rest_setpoint"
	loss_key = "rest_loss_per_minute"

/datum/npc_need/hunger
	start_key = "hunger_setpoint"
	setpoint_key = "hunger_setpoint"

/datum/npc_need/hunger/now()
	return ai_mind.holder.nutrition

/datum/npc_need/hunger/set_level(value)
	ai_mind.holder.adjust_nutrition(max(0, value) - ai_mind.holder.nutrition)

/datum/npc_need/health/now()
	return ai_mind.holder.health

/datum/npc_need/health/pressure()
	return 1 - ai_mind.health_share()

/datum/ai_holder/rsnpc/proc/need_pressure(name)
	var/datum/npc_need/N = needs[name]
	return N ? N.pressure() : 0
