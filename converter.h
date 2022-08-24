
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface Converter : NSObject

-(CVPixelBufferRef)convertTo420:(CVPixelBufferRef)pixelBuffer;

@end
