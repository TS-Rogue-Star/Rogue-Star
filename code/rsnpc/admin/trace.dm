/proc/npc_tracing(datum/ai_holder/rsnpc/ai_mind)
	return ai_mind?.trace || npc_setting("trace_all")

/proc/npc_trace_write(datum/ai_holder/rsnpc/ai_mind, channel, text)
	WRITE_LOG(npc_trace_log, "## NPC_TRACE \[[world.time / 10]s\] [channel] \[[ai_mind.holder ? ai_mind.holder.real_name : "no body"]\] [text]")
