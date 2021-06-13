#if DM_VERSION < 513

	#define ismovable(A) (istype(A, /atom/movable))

	#define islist(L) (istype(L, /list))

	#define CLAMP01(x) (CLAMP(x, 0, 1))

	#define CLAMP(CLVALUE,CLMIN,CLMAX) ( max( (CLMIN), min((CLVALUE), (CLMAX)) ) )

	#define ATAN2(x, y) ( !(x) && !(y) ? 0 : (y) >= 0 ? arccos((x) / sqrt((x)*(x) + (y)*(y))) : -arccos((x) / sqrt((x)*(x) + (y)*(y))) )

	#define TAN(x) (sin(x) / cos(x))

	#define arctan(x) (arcsin(x/sqrt(1+x*x)))

	#define typeless as()

//////////////////////////////////////////////////

#else

	#if DM_BUILD < 1540
		#define typeless as()
	#else
		#define typeless as anything
	#endif

	#define CLAMP01(x) clamp(x, 0, 1)

	#define CLAMP(CLVALUE, CLMIN, CLMAX) clamp(CLVALUE, CLMIN, CLMAX)

	#define TAN(x) tan(x)

	#define ATAN2(x, y) arctan(x, y)

#endif

#define TYPELESS_CRUTCH(varname, expectedtype) if(!istype(varname, expectedtype)){error("[__FILE__]:[__LINE__] - Typeless for() failure. Expected '[expectedtype]' got '[varname] - [varname?.type]'"); continue}
//#define TYPELESS_CRUTCH(varname, expectedtype)