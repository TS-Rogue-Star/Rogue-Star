/datum/npc_role
	var/name = "worker"
	var/list/known_kinds = list(
		/obj/machinery/vending/wallmed1,
		/obj/machinery/vending/wallmed2,
		/obj/machinery/vending/wallmed_airlock,
		/obj/item/weapon/storage/firstaid,
		/obj/machinery/vending/snack,
		/obj/machinery/vending/cola,
		/obj/machinery/vending/coffee,
		/obj/machinery/vending/sovietsoda,
		/obj/machinery/vending/snix,
		/obj/machinery/vending/sol,
		/obj/machinery/vending/weeb,
		/obj/machinery/vending/hotfood,
		/obj/machinery/vending/emergencyfood,
		/obj/structure/closet/emcloset,
		/obj/structure/bed/chair,
	)
	var/list/task_types = list(
		/datum/npc_task/answer,
		/datum/npc_task/work/workplace,
		/datum/npc_task/stroll,
		/datum/npc_task/take_break,
		/datum/npc_task/consume/eat,
		/datum/npc_task/consume/eat/starving,
		/datum/npc_task/consume/drink,
		/datum/npc_task/treat_wounds,
		/datum/npc_task/get_treated,
		/datum/npc_task/get_out,
		/datum/npc_task/get_my_things,
		/datum/npc_task/raise_shutters,
		/datum/npc_task/eat_prey,
		/datum/npc_task/handle_stomach,
		/datum/npc_task/respond_stomach,
		/datum/npc_task/follow,
		/datum/npc_task/give,
		/datum/npc_task/receive,
		/datum/npc_task/summons,
		/datum/npc_task/hold_still,
		/datum/npc_task/talk,
		/datum/npc_task/start_talk,
		/datum/npc_task/internals,
		/datum/npc_task/internals_off,
		/datum/npc_task/vacate_airlock,
		/datum/npc_task/houdini_cuffs,
		/datum/npc_task/get_out_of_danger,
	)
	var/list/action_types = list(
		/datum/npc_action/stand_at_workplace,
		/datum/npc_action/stroll,
		/datum/npc_action/sit_down,
		/datum/npc_action/look_around,
		/datum/npc_action/answer,
		/datum/npc_action/fetch,
		/datum/npc_action/eat,
		/datum/npc_action/drink,
		/datum/npc_action/uncover_mouth,
		/datum/npc_action/dress_wounds,
		/datum/npc_action/dress_wounds/salve,
		/datum/npc_action/get_back,
		/datum/npc_action/replace_gear,
		/datum/npc_action/give,
		/datum/npc_action/shuffle_inventory,
		/datum/npc_action/received,
		/datum/npc_action/press_shutter_button,
		/datum/npc_action/ask_to_eat,
		/datum/npc_action/swallow,
		/datum/npc_action/handle_stomach,
		/datum/npc_action/respond_stomach,
		/datum/npc_action/ask,
		/datum/npc_action/go_near,
		/datum/npc_action/go_into,
		/datum/npc_action/greet,
		/datum/npc_action/internals_on,
		/datum/npc_action/internals_off,
		/datum/npc_action/vacate_airlock,
		/datum/npc_action/houdini_cuffs,
		/datum/npc_action/put_on_mask,
		/datum/npc_action/seen_safe_spot,
	)

/datum/npc_role/service
	name = "service"

/datum/npc_role/engineering
	name = "engineering"

/datum/npc_role/medical
	name = "medical"

/datum/npc_role/security
	name = "security"

/datum/npc_role/science
	name = "science"

/datum/npc_role/cargo
	name = "cargo"

GLOBAL_LIST_INIT(npc_job_roles, list(
	/datum/job/chef = /datum/npc_role/service,
	/datum/job/bartender = /datum/npc_role/service,
	/datum/job/hydro = /datum/npc_role/service,
	/datum/job/janitor = /datum/npc_role/service,
	/datum/job/librarian = /datum/npc_role/service,
	/datum/job/chaplain = /datum/npc_role/service,
	/datum/job/engineer = /datum/npc_role/engineering,
	/datum/job/atmos = /datum/npc_role/engineering,
	/datum/job/chief_engineer = /datum/npc_role/engineering,
	/datum/job/doctor = /datum/npc_role/medical,
	/datum/job/paramedic = /datum/npc_role/medical,
	/datum/job/chemist = /datum/npc_role/medical,
	/datum/job/psychiatrist = /datum/npc_role/medical,
	/datum/job/cmo = /datum/npc_role/medical,
	/datum/job/officer = /datum/npc_role/security,
	/datum/job/warden = /datum/npc_role/security,
	/datum/job/detective = /datum/npc_role/security,
	/datum/job/hos = /datum/npc_role/security,
	/datum/job/scientist = /datum/npc_role/science,
	/datum/job/roboticist = /datum/npc_role/science,
	/datum/job/xenobiologist = /datum/npc_role/science,
	/datum/job/rd = /datum/npc_role/science,
	/datum/job/cargo_tech = /datum/npc_role/cargo,
	/datum/job/mining = /datum/npc_role/cargo,
	/datum/job/qm = /datum/npc_role/cargo,
))

/proc/title_to_npc_role(job_title)
	var/datum/job/J = SSjob.get_job(job_title)
	var/role_type = (J && GLOB.npc_job_roles[J.type]) || /datum/npc_role
	return new role_type
