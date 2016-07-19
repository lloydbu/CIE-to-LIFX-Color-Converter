//
//  TwoDArray.m
//
//  Created by Lloyd Burchill on 2014-05-03.
//

#import "TwoDArray.h"
#import "lerpDefinition.h"
#import "clamps.h"


@implementation TwoDArray


/******************************************************************************************/


- (void)initCore {
	
	self.numRows = 1;
	self.numCols = 1;
	self.backingStore = [[NSMutableArray alloc] initWithCapacity:1];
	
}

/******************************************************************************************/

- (id)init {
	if ((self = [super init])) {
		
		[self initCore];
        
	}
	
	return self;
	
}


/******************************************************************************************/

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)a {
    self = [super init];
	
    if (self) {
		
		[self initCore];
		
		
		_numRows= [a decodeIntForKey:@"rows"];
		 		 
		_numCols = [a decodeIntForKey:@"cols"];
		 
		_backingStore	= [a decodeObjectForKey:@"backing"];
 		
    }
    return self;
}

/******************************************************************************************/

- (void)encodeWithCoder:(NSCoder *)a {
	
	[a encodeInt:_numRows forKey:@"rows"];
	[a encodeInt:_numCols forKey:@"cols"];
	[a encodeObject:_backingStore forKey:@"backing"];
	 	 
}

/******************************************************************************************/

#pragma mark -

/******************************************************************************************/


//-(id) objectAtRow: (size_t) row col: (size_t) col
-(id) objectAtX: (size_t) col Y: (size_t) row
{
    if (   (col < self.numCols) &&  (row < self.numRows))
		{
	   
		size_t index = row * self.numCols + col;
		id a = [self.backingStore objectAtIndex: index];
		return a;
		}

	return nil;
}


/******************************************************************************************/


-(CGPoint)unitaryCoordatesForSlotX:(int)col Y:(int)row
{
	return CGPointMake( (float)col / (float)self.numCols,   (float)row / (float)self.numRows	);
}


/******************************************************************************************/


-(CGPoint)centralUnitaryCoordinatesForSlotX:(int)col Y:(int)row
{
	
	CGPoint a = [self unitaryCoordatesForSlotX:col		Y :row];
	CGPoint b = [self unitaryCoordatesForSlotX:col+1	Y :row+1];
	
	 	
	return CGPointMake( (a.x+b.x)*0.5, (a.y+b.y)*0.5 	);
}


/******************************************************************************************/


-(void) slotForUnitaryCoordinates:(CGPoint)zz i:(int*)i j:(int*)j
{
	if (i) {*i = floor(zz.x * self.numCols); }
	if (j) {*j = floor(zz.y * self.numRows); }
	
}

/******************************************************************************************/


-(void) replaceObjectAtX:(int)col   Y:(int)row withPoint:(CGPoint)p
{
	
	
#if TARGET_OS_IPHONE
	
	if (   (col < self.numCols) &&  (row < self.numRows))
	{
		
		size_t index = row * self.numCols + col;
	 
		NSValue * value = [NSValue valueWithCGPoint: p];
 		
		[self.backingStore replaceObjectAtIndex:index withObject:value];
		 
	}

#endif
	
}

/******************************************************************************************/

-(CGPoint) safelyGetPointAtX:(int)col Y:(int)row
{
	
	
#if TARGET_OS_IPHONE
	CLAMP(row, 0, self.numCols-1);
	CLAMP(col, 0, self.numRows-1);
	
	NSValue * val =[self objectAtX:col Y:row];
	 
	return [val CGPointValue];
	 
#else
	return CGPointMake(0, 0);
#endif
	
}

/******************************************************************************************/


-(CGPoint) get_ramped_point_from_unitary:(CGPoint) unit fixWrapX:(BOOL)fixWrapX
{

	CLAMP(unit.x, 0, 1)
	CLAMP(unit.y, 0, 1)

	float xf = unit.x * (self.numCols-1);
	float yf = unit.y * (self.numRows-1);


	float 	x = floorf(xf);
	float 	y=  floorf(yf);

	float 	xfrac = xf-x;
	float 	yfrac = yf-y;


	CGPoint r1 = [self safelyGetPointAtX:x   Y:y  ];
	CGPoint r2 = [self safelyGetPointAtX:x+1 Y:y  ];
	CGPoint r3 = [self safelyGetPointAtX:x   Y:y+1];
	CGPoint r4 = [self safelyGetPointAtX:x+1 Y:y+1];


	if (fixWrapX)
	{
		/***************/
		//fix the hue wraparound problem

		double biggest  = MAX( MAX(r1.x, r2.x), MAX(r3.x, r4.x) );

		double smallest = MIN( MIN(r1.x, r2.x), MIN(r3.x, r4.x) );


		if ((biggest >= 0.75) && (smallest < 0.25) )  // points span the hue discontinuity line
		{
			if (r1.x < 0.25) {r1.x += 1.0;}
			if (r2.x < 0.25) {r2.x += 1.0;}
			if (r3.x < 0.25) {r3.x += 1.0;}
			if (r4.x < 0.25) {r4.x += 1.0;}
		}



		/***************/


	}

	float  noox =  lerp(yfrac, lerp(xfrac, r1.x, r2.x  )  , lerp(xfrac, r3.x , r4.x  ) ) ;
	float  nooy =  lerp(yfrac, lerp(xfrac, r1.y, r2.y  )  , lerp(xfrac, r3.y , r4.y  ) ) ;

	noox -= floor(noox);  //undo discontinuity offset


	return CGPointMake(noox, nooy);

}


/********************************************************/

@end
