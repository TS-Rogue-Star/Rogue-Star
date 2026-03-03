// Normal digestion modes
#define DM_DEFAULT								"Default"				// Not a real bellymode, used for handling on 'selective' bellymode prefs.
#define DM_HOLD									"Hold"
#define DM_HOLD_ABSORBED						"Hold Absorbed"			// Not a real bellymode, used for handling different idle messages for absorbed prey.
#define DM_DIGEST								"Digest"
#define DM_ABSORB								"Absorb"
#define DM_UNABSORB								"Unabsorb"
#define DM_DRAIN								"Drain"
#define DM_SHRINK								"Shrink"
#define DM_GROW									"Grow"
#define DM_SIZE_STEAL							"Size Steal"
#define DM_HEAL									"Heal"
#define DM_EGG 									"Encase In Egg"
#define DM_SELECT								"Selective"

//Addon mode flags
#define DM_FLAG_NUMBING			0x1
#define DM_FLAG_STRIPPING		0x2
#define DM_FLAG_LEAVEREMAINS	0x4
#define DM_FLAG_THICKBELLY		0x8
#define DM_FLAG_AFFECTWORN		0x10
#define DM_FLAG_JAMSENSORS		0x20
#define DM_FLAG_FORCEPSAY		0x40
#define DM_FLAG_SLOWBODY		0x80  //RS Edit || Ports CHOMPStation Pr 5161
#define DM_FLAG_SLOWBRUTAL		0x100 //RS Edit
#define DM_FLAG_DAMAGEICON		0x200 //RS ADD

//Item related modes
#define IM_HOLD									"Hold"
#define IM_DIGEST_FOOD							"Digest (Food Only)"
#define IM_DIGEST								"Digest"

//Stance for hostile mobs to be in while devouring someone.
#define HOSTILE_STANCE_EATING	99

// Defines for weight system
#define MIN_MOB_WEIGHT			70
#define MAX_MOB_WEIGHT			500
#define MIN_NUTRITION_TO_GAIN	450	// Above this amount you will gain weight
#define MAX_NUTRITION_TO_LOSE	50	// Below this amount you will lose weight
// #define WEIGHT_PER_NUTRITION	0.0285 // Tuned so 1050 (nutrition for average mob) = 30 lbs

//RS Edit || Adds VOREStation PR 15876
#define DR_NORMAL								"Normal"
#define DR_SLEEP 								"Sleep"
#define DR_FAKE									"False Sleep"
#define DR_WEIGHT								"Weight Drain"

//RS ADD START
#define SPONT_PREY "Spontaneous Prey"
#define SPONT_PRED "Spontaneous Pred"
#define DROP_VORE "Drop Vore"
#define DROP_VORE_ON_OTHER "Drop Vore (You Drop On Them)" // Split for spont vore prefs (Lira, January 2026)
#define DROP_VORE_ON_YOU "Drop Vore (They Drop On You)" // Split for spont vore prefs (Lira, January 2026)
#define STUMBLE_VORE "Stumble Vore"
#define BUCKLE_VORE "Buckle Vore" // Seperated out for spont vore prefs (Lira, January 2026)
#define SLIP_VORE "Slip Vore"
#define THROW_VORE "Throw Vore"
#define FOOD_VORE "Food Vore"
#define EMOTE_VORE "Emote Vore" // New emote spont vore (Lira, February 2026)
#define MICRO_PICKUP "Micro Pickup"
#define SPONT_TF "Spontaneous TF"
#define RESIZING "Resizing"

#define WL_PREY "Prey"
#define WL_PRED "Predator"
#define WL_BOTH "Both"

//RS ADD END
