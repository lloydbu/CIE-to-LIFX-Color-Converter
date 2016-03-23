//
//  LIFXConvert.m
//  CIEtoLIFXColorConverter
//
//  Created by Lloyd Burchill on 2015-07-14.
//
//  Converts CIE 1931 x,y colors to LIFX hue & saturation, with an implied white point of 6500°K.
//
//  The conversion lookup data in LIFXData50 x 50.plist is acceptable but not ideally accurate.
//  For a more accurate conversion, you can replace it with your own data.
//
//  The data is stored in a TwoDArray object. It's a 2D lookup table that can be addressed with
//	coordinates in [0..1].
//
//  TwoDArray isn't addressed with raw CIE xy values, but with barycentric coordinates of the
//	triangular LIFX gamut. The mapping is
//
//	kLIFXRedX,   kLIFXRedY     ->   (1,0)
//	kLIFXGreenX, kLIFXGreenY   ->   (0,1)
//	kLIFXBlueX,  kLIFXBlueY    ->   (0,0)
//
//	https://en.wikipedia.org/wiki/Barycentric_coordinate_system
//
//	Since only a triangular half of the TwoDArray contains meaningful data, you should pad
//	the other half with copies of nearby valid values. Otherwise weird interpolation artifacts
//	can arise along the diagonal.
//
//	Each element in the TwoDArray is a CGPoint encoded as an NSValue. point.x = hue in [0..1]
//	and point.y = saturation in [0..1].
//
//  get_ramped_point_from_unitary gives linearly-interpolated results and it's smart enough to
//	correctly handle the 0°/360° hue wraparound problem.


#import "LIFXConvert.h"
#import "lerpDefinition.h"
#import "SynthesizeSingleton.h"

@implementation LIFXConvert


SYNTHESIZE_SINGLETON_FOR_CLASS(LIFXConvert)


/*******************************************************************************/


- (id)init {
	if ((self = [super init])) {
		
		
		NSString *path= [[NSBundle mainBundle] pathForResource:@"LIFXData 50 x 50" ofType:@"plist"];
		
		BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:path];
		
		if (fileExists)
		{
			
			NSURL * url = [NSURL fileURLWithPath:path];
			
			if (url != nil && [url isFileURL])
			{
				self.grid = [ NSKeyedUnarchiver unarchiveObjectWithFile:[url path]];
			}  //url OK
			
		}
		
		return self;
		
	}
	
	return nil;
}

/********************************************************************************/

#pragma mark - packing points and rects in NSValue


//would be nice: replace with with a macro.

+(CGPoint) getPointFromValue:(id)thing
{
	
	//	if ([thing isKindOfClass:[NSValue class]])
	//	{
	return [thing CGPointValue];
	//	}
	
	
	return CGPointMake(0, 0);
	
}

/********************************************************************************/


+(CGRect) getRectFromValue:(id)thing
{
	
	//tk: if it's a cgpoint, act normal.
	// if it's a cg rect, return rect.origin
	
	
	
	if ([thing isKindOfClass:[NSValue class]])
	{
		return [thing CGRectValue];
	}
	
	
	return CGRectMake(0, 0, 0, 0);
	
}


/********************************************************************************/

#pragma mark - geometry

/********************************************************************************/



+(BOOL) point:(CGPoint)P inPoly:(NSArray *)colorPoints
//pnpoly(int nvert, double *vertx, double *verty, double testx, double testy)
{
	
	// Algorithm by W. Randolph Franklin
	// from http://www.ecse.rpi.edu/Homepages/wrf/Research/Short_Notes/pnpoly.html
	
	
	NSUInteger nvert = [colorPoints count];
	
	
	if (nvert < 3)  //I need a triangle at least
	{
		return NO;
	}
	
	
	CGFloat testx = P.x;
	CGFloat testy = P.y;
	
	CGPoint vertj = [LIFXConvert getPointFromValue:[colorPoints objectAtIndex:nvert-1]];
	
	int i, j, c = 0;
	
	for (i = 0, j = nvert-1; i < nvert; j = i++) {
		
		CGPoint verti = [LIFXConvert getPointFromValue:[colorPoints objectAtIndex:i]];
		//	CGPoint vertj = [GamutMath getPointFromValue:[colorPoints objectAtIndex:j]];
		
		
		if ( ((verti.y>testy) != (vertj.y>testy)) &&
			(testx < (vertj.x-verti.x) * (testy-verti.y) / (vertj.y-verti.y) + verti.x) )
			c = !c;
		
   		vertj = verti;
		
	}
	
	if (c==0)
	{
		return NO;
	}
	
	return YES;
}


/*******************************************************************************/


+(CGPoint) point:(CGPoint)P movedToEdgeOfPoly:(NSArray *)colorPoints
{
	return [LIFXConvert point:P movedToEdgeOfPoly:colorPoints closed:YES winning_abscissa:nil];
}

/********************************************************************************/

+ (CGPoint)getClosestPointToPointsYieldingParameter:(CGPoint)A point2:(CGPoint)B point3:(CGPoint)P param:(float*)param
{
	
	// param is the distance along the segment from A to B
	
	CGPoint AP = CGPointMake(P.x - A.x, P.y - A.y);
	CGPoint AB = CGPointMake(B.x - A.x, B.y - A.y);
	float ab2 = AB.x * AB.x + AB.y * AB.y;
	float ap_ab = AP.x * AB.x + AP.y * AB.y;
	
	float t = ap_ab / ab2;
	
	if (t < 0.0f) {
		t = 0.0f;
	}
	else if (t > 1.0f) {
		t = 1.0f;
	}
	
	if (param)
	{*param = t;}
	
	CGPoint newPoint = CGPointMake(A.x + AB.x * t, A.y + AB.y * t);
	return newPoint;
}

/********************************************************************************/

+ (CGFloat)getDistanceBetweenTwoPoints:(CGPoint)one point2:(CGPoint)two
{
	CGFloat dx = one.x - two.x;
	CGFloat dy = one.y - two.y;
	return  sqrt(dx * dx + dy * dy);
}

/********************************************************************************/


+(CGPoint) point:(CGPoint)P movedToEdgeOfPoly:(NSArray *)colorPoints closed:(BOOL)closed winning_abscissa:(CGFloat *)winning_abscissa
{
	
	NSUInteger n = [colorPoints count];
	
	
	if (n <3)	//need at least a triangle
	{
		return P;
	}
	
	
	
	
	double winning_distance = 100000.0;
	CGPoint winning_point = P;
	float param, Aabscissa=0, Babscissa=0;
	CGPoint A,B;
	CGRect Arect, Brect;
	
	if (winning_abscissa)
	{
		
		Brect = [LIFXConvert getRectFromValue:[colorPoints objectAtIndex:n-1]];
		B = Brect.origin;
		Babscissa = Brect.size.width;
		
	}
	else
	{
		B   = [LIFXConvert getPointFromValue:[colorPoints objectAtIndex:n-1]];
	}
	
	
	for (int i=0; i<n; i++)
	{
		
		if (winning_abscissa)
		{
			Arect = [LIFXConvert getRectFromValue:[colorPoints objectAtIndex:i]];
			A = Arect.origin;
			Aabscissa = Arect.size.width;
			
			
		}
		else
		{
			A  = [LIFXConvert getPointFromValue:[colorPoints objectAtIndex:i]];
		}
		
		
		
		if ((closed) || (i!=0))  //if polygon is unclosed, then ignore the closure line at i==0
		{
			
			
			CGPoint nearest_point_on_line = [LIFXConvert getClosestPointToPointsYieldingParameter:A point2:B point3:P param:&param];
			
			
			double this_distance = [LIFXConvert getDistanceBetweenTwoPoints:P point2:nearest_point_on_line];
			
			if ((this_distance < winning_distance) || (i==0) )
			{
				winning_distance = this_distance ;
				winning_point = nearest_point_on_line;
				
				
				if (winning_abscissa)
				{
					*winning_abscissa = lerp(param, Aabscissa, Babscissa);
				}
				
			}
			
		}
		
		B = A;
		Babscissa = Aabscissa;
	}
	
	
	return winning_point;
}



/******************************************************************************************/

+(CGPoint) xy:(CGPoint)P pinnedForPolygon:(NSArray *)pointsArray
{
	
	if ([LIFXConvert point:P inPoly:pointsArray])
	{return P;}
	
	return [LIFXConvert point:P movedToEdgeOfPoly:pointsArray];
	
}


/********************************************************************************/

+ (NSArray *)colorPointsForLIFXModel:(NSString*)model
{
	//only supported model is kStandardLIFXModel
	
	NSMutableArray *colorPoints = [NSMutableArray array];
	 
	[colorPoints addObject:[NSValue valueWithCGPoint:CGPointMake(kLIFXRedX, kLIFXRedY)]];     // Red
	[colorPoints addObject:[NSValue valueWithCGPoint:CGPointMake(kLIFXGreenX, kLIFXGreenY)]];     // Green
	[colorPoints addObject:[NSValue valueWithCGPoint:CGPointMake(kLIFXBlueX, kLIFXBlueY)]];     // Blue
	
	return colorPoints;
}


/******************************************************************************************/

+(CGPoint) xy:(CGPoint)P xyPinnedForLIFXModel:(NSString*)model
{
 
	return [LIFXConvert xy:P pinnedForPolygon: [LIFXConvert colorPointsForLIFXModel:model]];
 
}

/************************************************************************************/


void XY_and_3points_to_barycentrics( fcomplex XY,  fcomplex w0, fcomplex w1, fcomplex w2,  double * b1,  double * b2,  double * b3 )
{
	
	double x0,y0, x1,x2,x3,y1,y2,y3, b0, invb0;

	x0 = XY.x;
	y0 = XY.y;
	
	x1 = w0.x;
	y1 = w0.y;
	
	x2 = w1.x;
	y2 = w1.y;
	
	x3 = w2.x;
	y3 = w2.y;
	
	
	b0 =  (x2 - x1) * (y3 - y1) - (x3 - x1) * (y2 - y1);
	
	invb0 = 1.0 / b0;
	
	*b1 = ((x2 - x0) * (y3 - y0) - (x3 - x0) * (y2 - y0)) * invb0 ;
	
	*b2 = ((x3 - x0) * (y1 - y0) - (x1 - x0) * (y3 - y0)) * invb0 ;
	
	*b3 = ((x1 - x0) * (y2 - y0) - (x2 - x0) * (y1 - y0)) * invb0 ;
	
}


/************************************************************************************/


fcomplex Complex(tcfloat re, tcfloat im)
{
	//builds a complex number from two components.

	fcomplex c;
	
	c.x = re;
	c.y = im;
	
	return c;
}


/************************************************************************************/



#pragma mark - color conversion

-(CGPoint) HSfromX:(float)x Y:(float)y
{
	
	//This conversion to HS uses the D65 white point for saturation==0.
	
	//result.x = hue in 0..1
	//result.y = sat in 0..1
	
	//To get LFXHSBKColor:
	//[LFXHSBKColor colorWithHue:hs.x*360.0  saturation:hs.y brightness:myBrightness kelvin:6500];
	
	
	if (!self.grid)
	{
		NSLog(@"LIFXConvert: color lookup table is missing");
		return CGPointMake(0, 0);
	}
	
	double b1, b2, b3;
	
	CGPoint clamped = [LIFXConvert xy:CGPointMake(x, y) xyPinnedForLIFXModel:kStandardLIFXModel];
	
	XY_and_3points_to_barycentrics( Complex(clamped.x, clamped.y),
								    Complex(kLIFXRedX,		kLIFXRedY),
								    Complex(kLIFXGreenX,	kLIFXGreenY),
								    Complex(kLIFXBlueX,		kLIFXBlueY),
								    &b1, &b2, &b3);
	
	
	CGPoint hs = [self.grid get_ramped_point_from_unitary:CGPointMake(b1, b2)];
 
	return hs;
}
  

@end
