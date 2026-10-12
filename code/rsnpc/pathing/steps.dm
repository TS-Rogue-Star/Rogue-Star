SUBSYSTEM_DEF(npc_steps)
	name = "RSNPC steps"
	init_order = INIT_ORDER_AI_FAST
	priority = FIRE_PRIORITY_AI
	wait = 1
	flags = SS_NO_INIT
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME

/datum/controller/subsystem/npc_steps/fire(resumed = 0)
	for(var/mob/living/W as anything in GLOB.npc_workers)
		var/datum/ai_holder/complex_npc/A = npc_ai_mind(W)
		if(A && !A.busy && length(A.path) && isturf(W.loc) && W.checkMoveCooldown() && A.can_act())
			A.walk_tick()
		if(MC_TICK_CHECK)
			return
