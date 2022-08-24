#import "BNBOffscreenEffectPlayer.h"

#import <Accelerate/Accelerate.h>
#include <interfaces/offscreen_effect_player.hpp>

#include "libyuv/convert.h"  // For I420Copy

#include "effect_player.hpp"
#include "offscreen_render_target.h"
#include "utils.h"

#include <bnb/utility_manager.h>

@implementation BNBOffscreenEffectPlayer
{
    NSUInteger _width;
    NSUInteger _height;

    effect_player_sptr m_ep;
    offscreen_render_target_sptr m_ort;
    offscreen_effect_player_sptr m_oep;

    utility_manager_holder_t* m_utility;
}

- (id)init
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"-init is not a valid initializer for the class BNBOffscreenEffectPlayer"
                                 userInfo:nil];
}

- (instancetype)initWithWidth:(NSUInteger)width
                       height:(NSUInteger)height
                  manualAudio:(BOOL)manual
                        token:(NSString*)token
                resourcePaths:(NSArray<NSString *> *)resourcePaths;
{
    _width = width;
    _height = height;

    std::vector<std::string> path_to_resources;
    for (id object in resourcePaths) {
        path_to_resources.push_back(std::string([(NSString*)object UTF8String]));
    }
    std::unique_ptr<const char*[]> res_paths = std::make_unique<const char*[]>(path_to_resources.size() + 1);
    std::transform(path_to_resources.begin(), path_to_resources.end(), res_paths.get(), [](const auto& s) { return s.c_str(); });
    res_paths.get()[path_to_resources.size()] = nullptr;
    m_utility = bnb_utility_manager_init(res_paths.get(), [token UTF8String], nullptr);

    m_ep = bnb::oep::effect_player::create(width, height);
    m_ort = std::make_shared<bnb::offscreen_render_target>();
    m_oep = bnb::oep::interfaces::offscreen_effect_player::create(m_ep, m_ort, width, height);
    
    m_oep->surface_changed(width, height);
    return self;
}

- (void)processImage:(CVPixelBufferRef)pixelBuffer imageFormat:(NSString*)imageFormat inputOrientation:(EPOrientation)orientation completion:(BNBOEPImageReadyBlock _Nonnull)completion
{
    pixel_buffer_sptr pixelBuffer_sprt([self convertImage: pixelBuffer imageFormat:imageFormat]);
    if (pixelBuffer_sprt == nullptr) {
        return;
    }
//    auto image_format = bnb::oep::interfaces::image_format::i420_bt601_full;
    auto image_format = bnb::oep::interfaces::image_format::nv12_bt601_full;
    
    auto get_pixel_buffer_callback = [image_format, completion](image_processing_result_sptr result) {
        if (result != nullptr) {
            auto get_image_callback = [image_format, completion](pixel_buffer_sptr pb_image) {
                
                if(pb_image == nullptr) {
                    return;
                }
                
                if(image_format == bnb::oep::interfaces::image_format::nv12_bt601_full) {
                    // TODO NV12
                }
                
                if(image_format == bnb::oep::interfaces::image_format::i420_bt601_full) {
                    // i420
                    auto width = pb_image->get_width();
                    auto height = pb_image->get_height();
                    CVPixelBufferRef pixelBuffer = nullptr;
                    CVPixelBufferCreate(kCFAllocatorDefault, width, height,
                                        kCVPixelFormatType_420YpCbCr8Planar,
                                     NULL, &pixelBuffer);
                    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
                    
                    uint8_t* yDestPlane = (uint8_t*) CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
                    auto yWidth = (int) CVPixelBufferGetWidthOfPlane(pixelBuffer, 0);
                    auto yHeight = (int) CVPixelBufferGetHeightOfPlane(pixelBuffer, 0);
                    auto yBytesPerRow = (int) CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);

                    uint8_t* uDestPlane = (uint8_t*) CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
                    auto uWidth = (int) CVPixelBufferGetWidthOfPlane(pixelBuffer, 1);
                    auto uHeight = (int) CVPixelBufferGetHeightOfPlane(pixelBuffer, 1);
                    auto uBytesPerRow = (int) CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);

                    uint8_t* vDestPlane = (uint8_t*) CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 2);
                    auto vWidth = (int) CVPixelBufferGetWidthOfPlane(pixelBuffer, 2);
                    auto vHeight = (int) CVPixelBufferGetHeightOfPlane(pixelBuffer, 2);
                    auto vBytesPerRow = (int) CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 2);
                    
                    uint8_t* y_adress = pb_image->get_base_sptr_of_plane(0).get();
                    uint8_t* u_adress = pb_image->get_base_sptr_of_plane(1).get();
                    uint8_t* v_adress = pb_image->get_base_sptr_of_plane(2).get();
                    auto bytes_per_row = pb_image->get_bytes_per_row();
                    
                    libyuv::I420Copy(y_adress, bytes_per_row,
                                     u_adress, bytes_per_row,
                                     v_adress, bytes_per_row,
                                     yDestPlane, yBytesPerRow,
                                     uDestPlane, uBytesPerRow,
                                     vDestPlane, vBytesPerRow, width, height);

                    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
                    
                    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
                    if (completion) {
                        completion(pixelBuffer);
                        CVPixelBufferRelease(pixelBuffer);
                    }
                    return;
                }
                
            };
            result->get_image(image_format, get_image_callback);
        }
    };
    auto input_orientation = [self getInputOrientation:orientation];
    m_oep->process_image_async(pixelBuffer_sprt, input_orientation, true, get_pixel_buffer_callback, bnb::oep::interfaces::rotation::deg270);
}

- (pixel_buffer_sptr)convertImage:(CVPixelBufferRef)pixelBuffer imageFormat:(NSString*)imageFormat
{
    OSType pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer);
    pixel_buffer_sptr img;

    switch (pixelFormat) {
        case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
        case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange: {
            CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
            uint8_t* lumo = static_cast<uint8_t*>(CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0));
            uint8_t* chromo = static_cast<uint8_t*>(CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1));
            int bufferWidth = CVPixelBufferGetWidth(pixelBuffer);
            int bufferHeight = CVPixelBufferGetHeight(pixelBuffer);
            using ns = bnb::oep::interfaces::pixel_buffer;
            auto y_ptr = std::shared_ptr<uint8_t>(lumo, [pixelBuffer](uint8_t*) {
                CVPixelBufferRelease(pixelBuffer);
            });
            
            size_t y_size = bufferWidth  * bufferHeight;
            int32_t y_stride = static_cast<int32_t>(CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0));
            ns::plane_data y_plane{y_ptr, y_size, y_stride};
            
            if([imageFormat isEqualToString:i420Format]) {
                CVPixelBufferRetain(pixelBuffer);
                
                int u_size = bufferWidth * bufferHeight / 4;
                int v_size = bufferWidth * bufferHeight / 4;
                ns::plane_sptr u_plane_data(new ns::plane_sptr::element_type[u_size], [](uint8_t* ptr) { delete[] ptr; });
                ns::plane_sptr v_plane_data(new ns::plane_sptr::element_type[v_size], [](uint8_t* ptr) { delete[] ptr; });

                auto ptr_u = u_plane_data.get();
                auto ptr_v = v_plane_data.get();
                int uv_row_stride = static_cast<int32_t>(CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0));
                for (unsigned row = 0; row < bufferHeight * uv_row_stride / 2; row += 2) {
                    *ptr_u++ = chromo[row];
                    *ptr_v++ = chromo[row + 1];
                }
                int32_t u_stride = uv_row_stride / 2;
                int32_t v_stride = uv_row_stride / 2;
                ns::plane_data u_plane{std::move(u_plane_data), static_cast<size_t>(u_size), u_stride};
                ns::plane_data v_plane{std::move(v_plane_data), static_cast<size_t>(v_size), v_stride};

                std::vector<ns::plane_data> planes{y_plane, u_plane, v_plane};
                img = ns::create(planes, bnb::oep::interfaces::image_format::i420_bt601_full,
                                 bufferWidth, bufferHeight);
            } else {
                CVPixelBufferRetain(pixelBuffer);
                CVPixelBufferRetain(pixelBuffer);
                
                auto uv_ptr = std::shared_ptr<uint8_t>(chromo, [pixelBuffer](uint8_t*) {
                    CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
                    CVPixelBufferRelease(pixelBuffer);
                });
                size_t uv_size = bufferWidth * bufferHeight / 2;
                int32_t uv_stride = static_cast<int32_t>(CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1));
                ns::plane_data uv_plane{uv_ptr, uv_size, uv_stride};

                std::vector<ns::plane_data> planes{y_plane, uv_plane};
                img = ns::create(planes, pixelFormat == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange ?
                                 bnb::oep::interfaces::image_format::nv12_bt709_video :
                                 bnb::oep::interfaces::image_format::nv12_bt709_full,
                                 bufferWidth, bufferHeight);
            }
        } break;
        case kCVPixelFormatType_420YpCbCr8Planar:  {
            CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
            uint8_t* plane_y = static_cast<uint8_t*>(CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0));
            uint8_t* plane_u = static_cast<uint8_t*>(CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1));
            uint8_t* plane_v = static_cast<uint8_t*>(CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 2));
            int bufferWidth = CVPixelBufferGetWidth(pixelBuffer);
            int bufferHeight = CVPixelBufferGetHeight(pixelBuffer);
            using ns = bnb::oep::interfaces::pixel_buffer;
            
            CVPixelBufferRetain(pixelBuffer);
            CVPixelBufferRetain(pixelBuffer);
            CVPixelBufferRetain(pixelBuffer);
            
            auto y_ptr = std::shared_ptr<uint8_t>(plane_y, [pixelBuffer](uint8_t*) {
                CVPixelBufferRelease(pixelBuffer);
            });
            
            size_t y_size = bufferWidth  * bufferHeight;
            int32_t y_stride = static_cast<int32_t>(CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0));
            ns::plane_data y_plane{y_ptr, y_size, y_stride};
            
            auto u_ptr = std::shared_ptr<uint8_t>(plane_u, [pixelBuffer](uint8_t*) {
                CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
                CVPixelBufferRelease(pixelBuffer);
            });
            size_t u_size = bufferWidth / 2 * bufferHeight / 2;
            int32_t u_stride = static_cast<int32_t>(CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1));
            ns::plane_data u_plane{u_ptr, u_size, u_stride};
            
            auto v_ptr = std::shared_ptr<uint8_t>(plane_v, [pixelBuffer](uint8_t*) {
                CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
                CVPixelBufferRelease(pixelBuffer);
            });
            size_t v_size = bufferWidth / 2 * bufferHeight / 2;
            int32_t v_stride = static_cast<int32_t>(CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 2));
            ns::plane_data v_plane{v_ptr, v_size, v_stride};
            
            std::vector<ns::plane_data> planes{y_plane, u_plane, v_plane};
            auto format = bnb::oep::interfaces::image_format::i420_bt709_full;
            img = ns::create(planes, format, bufferWidth, bufferHeight);
        } break;
        default:
            NSLog(@"ERROR TYPE : %d", pixelFormat);
            return nil;
    }
        return std::move(img);
}

- (void)loadEffect:(NSString* _Nonnull)effectName
{
    NSAssert(self->m_oep != nil, @"No OffscreenEffectPlayer");
    m_oep->load_effect(std::string([effectName UTF8String]));
}

- (void)unloadEffect
{
    NSAssert(self->m_oep != nil, @"No OffscreenEffectPlayer");
    m_oep->unload_effect();
}

- (void)callJsMethod:(NSString* _Nonnull)method withParam:(NSString* _Nonnull)param
{
    NSAssert(self->m_oep != nil, @"No OffscreenEffectPlayer");
    m_oep->call_js_method(std::string([method UTF8String]), std::string([param UTF8String]));
}

- (void)dealloc
{
    if (m_ep) {
        m_ep->surface_destroyed();
    }
    if (m_utility) {
        bnb_utility_manager_release(m_utility, nullptr);
        m_utility = nullptr;
    }
}

- (void)surfaceChanged:(NSUInteger)width withHeight:(NSUInteger)height
{
    if (m_oep) {
        m_oep->surface_changed(width, height);
    }
}
- (bnb::oep::interfaces::rotation)getInputOrientation:(EPOrientation)orientation{
    switch (orientation) {
        case EPOrientationAngles0:      return bnb::oep::interfaces::rotation::deg0;
        case EPOrientationAngles90:     return bnb::oep::interfaces::rotation::deg90;
        case EPOrientationAngles180:    return bnb::oep::interfaces::rotation::deg180;
        case EPOrientationAngles270:    return bnb::oep::interfaces::rotation::deg270;
    }
}

@end
