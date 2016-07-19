# CIE-to-LIFX-Color-Converter
Converts colors from the [CIE 1931 x,y system](https://en.wikipedia.org/wiki/CIE_1931_color_space) to the [HSBK colorspace](http://api.developer.lifx.com/docs/colors) used by LIFX bulbs, and to the RGB space used by Osram Lightify bulbs.

I needed to add support for LIFX and Lightify bulbs to a current iOS project for Philips Hue which handles colors in the CIE 1931 system. Since LIFX and Lightify each require colors in non-CIE color spaces, I wrote a converter.

## Simple usage


```objective-c

CGPoint hue_sat = [[LIFXConvert sharedInstance] HSfromX:CIE.x Y:CIE.y];

LFXHSBKColor *result = [LFXHSBKColor colorWithHue:hue_sat.x*360.0  saturation:hue_sat.y brightness:brightness kelvin:6500];

float R,G,B;

[[LIFXConvert sharedInstance] OsramR:&R G:&G B:&B fromX:CIE.x Y:CIE.y];

	
```


## Details

LIFX: From CIE x,y coordinates the converter produces a CGPoint where x = hue in [0..1]
and y = saturation in [0..1]. You'll want to multiply the hue by 360 before passing it to LIFX. The color temperature is always 6500.

Lightify: The converter produces an RGB tuple where each component is in [0..1] and one of the components is always 1.0.

If you request a color outside the device's gamut, the result will be clamped to the nearest in-gamut point.


## Sample Project

![LIFX Converter screenshot](http://www.flamingpear.com/images/lifxconverter-screenshot3.png "LIFX Converter screenshot")


The sample iOS project lets you generate random CIE colors and see the HSBK and RGB equivalents. It doesn't contain any network code that talks to smart bulbs.

## Customization

The conversion lookup data in LIFXData50 x 50.plist and OsramData 40 x 40.plist was created with a consumer-grade colorimeter, so it's acceptable but not perfect. If you want to replace it with your own data, here's the format:

The data is stored in a TwoDArray object. It's a 2D lookup table that can be addressed with coordinates in [0..1],[0..1].

TwoDArray isn't addressed with raw CIE xy values, but with [barycentric coordinates](https://en.wikipedia.org/wiki/Barycentric_coordinate_system) of the triangular LIFX gamut. The mapping is

```sh
kLIFXRedX,   kLIFXRedY     ->   (1,0)
kLIFXGreenX, kLIFXGreenY   ->   (0,1)
kLIFXBlueX,  kLIFXBlueY    ->   (0,0)
```
 
 

Since only a triangular half of the TwoDArray contains meaningful data, you should pad
the other half with copies of nearby valid values. Otherwise weird interpolation artifacts
can arise along the diagonal.

Each element in the TwoDArray is a CGPoint encoded as an NSValue. point.x = hue in [0..1]
	and point.y = saturation in [0..1].

get_ramped_point_from_unitary gives linearly-interpolated results and it's smart enough to
	correctly handle the 0°/360° hue wraparound problem.


## Requirements
* iOS 8.0 or later
* Xcode 7.2

## Author
lloydbu, lloyd@flamingpear.com

## License

CIE to LIFX Color Converter is available under the MIT license. See the LICENSE file for more info.

 
