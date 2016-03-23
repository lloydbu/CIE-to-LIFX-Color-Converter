//
//  ViewController.m
//  CIEtoLIFXColorConverter
//
//  Created by Lloyd Burchill on 2015-07-14.
//

#import "ViewController.h"
#import "LIFXConvert.h"
#import "lerpDefinition.h"
#import "complextype.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}


/***************************************************************************************************************/

+(float) getRandom1
{
	
	return (arc4random() % 1000 ) * 0.001;
	
}


/***************************************************************************************************************/

+(CGPoint) getXYinLIFXGamut
{
	NSArray * LIFXgamut = [LIFXConvert colorPointsForLIFXModel:kStandardLIFXModel];
	
	CGPoint xy;
	
	for (int i=0; i<100; i++)
	{
		//make a random point in a rectangle bounding the LIFX gamut
		
		CGFloat  x =  lerp ( [ViewController getRandom1], kLIFXBlueX, kLIFXRedX );
		CGFloat  y =  lerp ( [ViewController getRandom1], kLIFXBlueY, kLIFXGreenY );
		
		
		CGPoint xy = CGPointMake(x, y) ;
		
		// accept only if inside the triangle.
		
		if ([LIFXConvert point:xy inPoly:LIFXgamut])
		{
			return xy;
		}
		
		
	}
	
	return xy;
	
}

/***************************************************************************************************************/

- (IBAction)generatorTapped:(id)sender {
	
	CGPoint CIE = [ViewController getXYinLIFXGamut];
	
	CGFloat brightness = [ViewController getRandom1];
	
	CGPoint hs = [[LIFXConvert sharedInstance] HSfromX:CIE.x Y:CIE.y];
	
	//To get LFXHSBKColor:
	//[LFXHSBKColor colorWithHue:hs.x*360.0  saturation:hs.y brightness:brightness kelvin:6500];
	
	
	self.philipsColors.text = [NSString stringWithFormat:@"\n\n%.2f\n%.2f\n%.2f", CIE.x, CIE.y, brightness];
	
	self.LIFXColors.text = [NSString stringWithFormat:@"\n\n%.2f\n%.2f\n%.2f\n%.2f", hs.x*360.0, hs.y, brightness, 6500.0];
	
}

/***************************************************************************************************************/


@end
