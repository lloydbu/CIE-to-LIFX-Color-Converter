//
//  ViewController.h
//  CIEtoLIFXColorConverter
//
//  Created by Lloyd Burchill on 2015-07-14.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

- (IBAction)generatorTapped:(id)sender;

@property (strong, nonatomic) IBOutlet UILabel *philipsColors;

@property (strong, nonatomic) IBOutlet UILabel *LIFXColors;

@end

