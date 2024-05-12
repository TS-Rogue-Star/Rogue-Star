#define CABLE_LAYER_ALL (~0)
#define CABLE_LAYER_1 (1<<0)
	#define CABLE_LAYER_1_NAME "Red Power Line"
#define CABLE_LAYER_2 (1<<1)
	#define CABLE_LAYER_2_NAME "Yellow Power Line"
#define CABLE_LAYER_3 (1<<2)
	#define CABLE_LAYER_3_NAME "Blue Power Line"

#define SOLAR_TRACK_OFF 0
#define SOLAR_TRACK_TIMED 1
#define SOLAR_TRACK_AUTO 2

// Converts cable layer to its human readable name
GLOBAL_LIST_INIT(cable_layer_to_name, list(
	"[CABLE_LAYER_1]" = CABLE_LAYER_1_NAME,
	"[CABLE_LAYER_2]" = CABLE_LAYER_2_NAME,
	"[CABLE_LAYER_3]" = CABLE_LAYER_3_NAME
))

// Converts cable color name to its layer
GLOBAL_LIST_INIT(cable_name_to_layer, list(
	CABLE_LAYER_1_NAME = CABLE_LAYER_1,
	CABLE_LAYER_2_NAME = CABLE_LAYER_2,
	CABLE_LAYER_3_NAME = CABLE_LAYER_3
	))

/// Cable layer colors for easier editing later
/// IF YOU CHANGE THESE YOU NEED TO UPDATE THE RADIAL MENUS FOR RCL AND CABLES TO THOSE COLORS IN icons/hud/radial.dmi
#define CABLELAYERONECOLOR		COLOR_RED
#define CABLELAYERTWOCOLOR		COLOR_YELLOW
#define CABLELAYERTHREECOLOR	COLOR_BLUE

#define MAXCOIL 30

var/global/defer_powernet_rebuild = 0      // True if net rebuild will be called manually after an event.

#define CELLRATE 0.002 // Multiplier for watts per tick <> cell storage (e.g., 0.02 means if there is a load of 1000 watts, 20 units will be taken from a cell per second)
                       // It's a conversion constant. power_used*CELLRATE = charge_provided, or charge_used/CELLRATE = power_provided
#define SMESRATE 0.03333 // Same for SMESes. A different number for some reason.

#define KILOWATTS *1000
#define MEGAWATTS *1000000
#define GIGAWATTS *1000000000
