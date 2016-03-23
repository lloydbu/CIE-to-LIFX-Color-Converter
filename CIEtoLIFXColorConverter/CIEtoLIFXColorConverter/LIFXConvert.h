//
//  LIFXConvert.h
//  CIEtoLIFXColorConverter
//
//  Created by Lloyd Burchill on 2015-07-14.
 

#import <Foundation/Foundation.h>
#import "TwoDArray.h"
#import "LIFX constants.h"
#import "complextype.h"

@interface LIFXConvert : NSObject
 
+ (LIFXConvert *) sharedInstance;

- (CGPoint) HSfromX:(float)x Y:(float)y;

+ (BOOL) point:(CGPoint)P inPoly:(NSArray *)colorPoints;

+ (NSArray *)colorPointsForLIFXModel:(NSString*)model;

@property TwoDArray * grid;

fcomplex Complex(tcfloat re, tcfloat im);

void XY_and_3points_to_barycentrics( fcomplex XY,  fcomplex w0, fcomplex w1, fcomplex w2,  double * b1,  double * b2,  double * b3 );

@end
