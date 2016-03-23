

#if __has_feature(objc_arc)

#define SYNTHESIZE_SINGLETON_FOR_CLASS(classname)   \
+ (classname *)sharedInstance \
{ \
static classname *sharedInstance = nil; \
static dispatch_once_t onceToken = 0; \
dispatch_once(&onceToken, ^{ \
sharedInstance = [[classname alloc] init]; \
}); \
return sharedInstance; \
}


#else

#pragma message("SYNTHESIZE_SINGLETON_FOR_CLASS needs ARC")

#endif


/*

Use like this:

#import "SynthesizeSingleton.h"
 
@implementation MyClass
SYNTHESIZE_SINGLETON_FOR_CLASS(MyClass)
@end

*/

