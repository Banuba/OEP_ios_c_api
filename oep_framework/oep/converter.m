
#import <Foundation/Foundation.h>
#import "converter.h"

#import "libyuv.h"

@implementation Converter

- (CVPixelBufferRef)convertTo420:(CVPixelBufferRef)pixelBuffer {
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
         
    int width = CVPixelBufferGetWidth(pixelBuffer);
    int height = CVPixelBufferGetHeight(pixelBuffer);

    int half_width = (width + 1) / 2;
    int half_height = (height + 1) / 2;

    const int y_size = width * height;
    const int u_size = half_width * half_height;
    const int v_size = half_width * half_height;

    const size_t total_size = y_size + u_size + v_size;

    uint8_t* outputBytes = calloc(1,total_size);
    uint8_t *src_y = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    uint8_t *src_uv = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    int src_stride_y = CVPixelBufferGetBytesPerRowOfPlane (pixelBuffer, 0);
    int src_stride_uv =  CVPixelBufferGetBytesPerRowOfPlane (pixelBuffer, 1);

    NV12ToI420(src_y,
           src_stride_y,
           src_uv,
           src_stride_uv,
           outputBytes,
           half_width * 2,
           outputBytes + y_size,
           half_width,
           outputBytes + y_size + u_size,
           half_width,
           width,
           height);
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    CVPixelBufferRef newPixelBuffer = NULL;
    
    CVPixelBufferCreate(kCFAllocatorDefault, width , height,
                        kCVPixelFormatType_420YpCbCr8Planar,
                     NULL, &newPixelBuffer);

    CVPixelBufferLockBaseAddress(newPixelBuffer, 0);

    uint8_t * plan_y = CVPixelBufferGetBaseAddressOfPlane(newPixelBuffer, 0);
    size_t  plan_y_height = CVPixelBufferGetHeightOfPlane(newPixelBuffer, 0);
    size_t  plan_y_sizePerRow = CVPixelBufferGetBytesPerRowOfPlane(newPixelBuffer, 0);
    size_t new_y_size = plan_y_height * plan_y_sizePerRow;
    memcpy(plan_y, outputBytes, new_y_size);

    uint8_t * plan_u = CVPixelBufferGetBaseAddressOfPlane(newPixelBuffer, 1);
    size_t  plan_u_height = CVPixelBufferGetHeightOfPlane(newPixelBuffer, 1);
    size_t  plan_u_sizePerRow = CVPixelBufferGetBytesPerRowOfPlane(newPixelBuffer, 1);
    size_t new_u_size = plan_u_height * plan_u_sizePerRow;
    memcpy(plan_u, outputBytes + new_y_size, new_u_size);

    uint8_t * plan_v = CVPixelBufferGetBaseAddressOfPlane(newPixelBuffer, 2);
    size_t  plan_v_height = CVPixelBufferGetHeightOfPlane(newPixelBuffer, 2);
    size_t  plan_v_sizePerRow = CVPixelBufferGetBytesPerRowOfPlane(newPixelBuffer, 2);
    size_t new_v_size = plan_v_height * plan_v_sizePerRow;
    memcpy(plan_v, outputBytes + new_y_size + new_u_size, new_v_size);

    CVPixelBufferUnlockBaseAddress(newPixelBuffer, 0);
    free(outputBytes);
    return newPixelBuffer;
}

@end
