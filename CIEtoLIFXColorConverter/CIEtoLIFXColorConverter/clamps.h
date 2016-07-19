

#define CLAMP(a,b,c) \
if (a<b ) \
{ a=b; } \
else \
{ \
	if (a>c ) { a=c;} \
}



#define ClampZero(a) if ( a < 0) {a = 0;}
#define ClampZerof(a) if ( a < 0.0f) {a = 0.0f;}

#define ClampToMax(a,b) if ( a > b) {a = b;}
#define ClampToMin(a,b) if ( a < b) {a = b;}

#define Clamp255(a) ClampToMax(a,255)

#define ClampToByte(a) CLAMP(a,0,255)

