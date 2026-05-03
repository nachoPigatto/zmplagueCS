#if defined _DEBUG_ON
#define _debug(%0,%1,%2) log_amx(%1, %2)
#else
#define _debug(%0,%1,%2)
#endif

stock _debug_draw() { }
