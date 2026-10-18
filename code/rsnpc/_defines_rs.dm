#define NPC_CONFIG_DIR "config/rsnpc/"
#define NPC_CHARACTER_DIR "config/rsnpc/npcs/"

#define NPC_TRACE_LIFE "LIFE"
#define NPC_TRACE_WALK "WALK"
#define NPC_TRACE_TASK "TASK"
#define NPC_TRACE_KNOW "KNOW"
#define NPC_TRACE_PLAN "PLAN"
#define NPC_TRACE_HANDS "HANDS"
#define NPC_TRACE_TALK "TALK"
#define NPC_TRACE_WITNESS "WITNESS"

#define NPC_TRACE(ai_mind, channel, text) if(npc_tracing(ai_mind)) {npc_trace_write(ai_mind, channel, text)}

#define NPC_PLACE_ARRIVAL "Any arrival point"
#define NPC_PLACE_WORKPLACE "Workplace"
#define NPC_PLACE_HERE "Right here"
#define NPC_GENERIC_WORKER "Somebody generic..."

#define NPC_PATH_SEARCHING 0
#define NPC_PATH_FOUND 1
#define NPC_PATH_NO_WAY 2
#define NPC_PATH_NOT_YET 3

#define NPC_LINK_DOOR 1
#define NPC_LINK_STAIRS 2
#define NPC_LINK_LADDER 3
#define NPC_LINK_OPEN 4
#define NPC_LINK_PORTAL 5

#define NPC_TIER_IDLE 1
#define NPC_TIER_FULFILLMENT 2
#define NPC_TIER_SOCIAL 3
#define NPC_TIER_NEEDS 4
#define NPC_TIER_SURVIVAL 5

#define NPC_RUNNING 0
#define NPC_DONE 1
#define NPC_NOT_YET 2
#define NPC_NOT_THERE 3
#define NPC_CANT_REACH 4
#define NPC_CANT_DO 5

#define NPC_PLAN_SEARCHING 0
#define NPC_PLAN_FOUND 1
#define NPC_PLAN_NONE 2
#define NPC_PLAN_ALREADY_DONE 3

#define NPC_FACT_HAVE(kind) "have:[kind]"
#define NPC_FACT_HOLDING(I) "holding:\ref[I]"
#define NPC_FACT_FED "fed"
#define NPC_FACT_WORKED "worked"
#define NPC_FACT_STROLLED "strolled"
#define NPC_FACT_RESTED "rested"
#define NPC_FACT_NEAR(M) "near:\ref[M]"
#define NPC_FACT_IN(A) "in:\ref[A]"
#define NPC_FACT_GREETED(M) "greeted:\ref[M]"
#define NPC_FACT_INTERNALS "internals"
#define NPC_FACT_INTERNALS_OFF "internals_off"
#define NPC_FACT_UNCUFFED "uncuffed"
#define NPC_FACT_MASKED "masked"
#define NPC_FACT_SAFE "safe"
#define NPC_FACT_BANDAGED "bandaged"
#define NPC_FACT_SALVED "salved"
#define NPC_FACT_TREATED "treated"
#define NPC_FACT_DRANK "drank"
#define NPC_FACT_MOUTH_FREE "mouth_free"
#define NPC_FACT_SHUTTERS_UP "shutters_up"
#define NPC_FACT_GEAR(G) "gear:\ref[G]"
#define NPC_FACT_EATEN(M) "eaten:\ref[M]"
#define NPC_FACT_AGREED_PREY(M) "agreed_prey:\ref[M]"
#define NPC_FACT_STOMACH_HANDLED "stomach_handled"
#define NPC_FACT_RESPONDED(A) "responded:\ref[A]"
#define NPC_FACT_GIVEN(A) "given:\ref[A]"
#define NPC_FACT_HAND_FREE "hand_free"
#define NPC_FACT_OUT_OF_AIRLOCK "out_of_airlock"
#define NPC_FACT_RECEIVED(A) "received:\ref[A]"

#define NPC_NEED_REST "rest"
#define NPC_NEED_HUNGER "hunger"
#define NPC_NEED_HEALTH "health"

#define NPC_SOURCE_HELD 1
#define NPC_SOURCE_IN_SIGHT 2
#define NPC_SOURCE_SEEN 3
#define NPC_SOURCE_KEPT 4

#define NPC_PROMISE_ASKED 1
#define NPC_PROMISE_AGREED 2
#define NPC_PROMISE_KEPT 3
#define NPC_PROMISE_BROKEN 4
#define NPC_PROMISE_REFUSED 5
#define NPC_PROMISE_LAPSED 6
#define NPC_PROMISE_DROPPED 7

#define NPC_ANSWER_YES "yes"
#define NPC_ANSWER_NO "no"
#define NPC_ANSWER_HELLO "hello"
#define NPC_ANSWER_BYE "bye"
#define NPC_ANSWER_GOODBYE "goodbye"

#define NPC_WARY 10
#define NPC_DANGEROUS 25

#define NPC_EVENT_JUSTIFIED_FIGHT 1
#define NPC_EVENT_FIGHT 2
#define NPC_EVENT_DEATH 3

#define NPC_FIGHT 1
#define NPC_FLIGHT 2
