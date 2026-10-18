SUBSYSTEM_DEF(npc_steps)
	name = "RSNPC steps"
	init_order = INIT_ORDER_AI_FAST
	priority = FIRE_PRIORITY_AI
	wait = 1
	flags = SS_NO_INIT | SS_TICKER
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME
	var/list/currentrun = list()

/datum/controller/subsystem/npc_steps/fire(resumed = 0)
	if(!resumed)
		src.currentrun = GLOB.npc_workers.Copy()
	var/list/currentrun = src.currentrun
	while(length(currentrun))
		var/mob/living/W = currentrun[length(currentrun)]
		currentrun.len--
		if(QDELETED(W))
			continue
		var/datum/ai_holder/rsnpc/A = npc_ai_mind(W)
		if(A && !A.busy && length(A.path) && isturf(W.loc) && W.checkMoveCooldown() && A.can_act())
			A.walk_tick()
		if(MC_TICK_CHECK)
			return
