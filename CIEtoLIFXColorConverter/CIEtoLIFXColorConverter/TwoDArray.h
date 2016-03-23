 
@import Foundation;

#if TARGET_OS_IPHONE
//for CGPoint
@import UIKit;
#endif



@interface TwoDArray : NSObject

@property NSMutableArray* backingStore;
@property size_t numRows;
@property size_t numCols;


-(id) objectAtX: (size_t)col Y:(size_t)row;

-(void) replaceObjectAtX:(int)col Y:(int)row withPoint:(CGPoint)p;

-(CGPoint) get_ramped_point_from_unitary:(CGPoint) unit; //needed

-(CGPoint)unitaryCoordatesForSlotX:(int)col Y:(int)row;

-(CGPoint)centralUnitaryCoordinatesForSlotX:(int)col Y:(int)row;

-(void) slotForUnitaryCoordinates:(CGPoint)zz i:(int*)i j:(int*)j;

/******************************************************************************************/

#define LOOP_OVER_WHOLE_TABLE for (ylooper = 0; ylooper < bigv; ylooper++) { for (x=0; x < bigh; x++) {

#define END_LOOP_OVER_WHOLE_TABLE  } }

@end
