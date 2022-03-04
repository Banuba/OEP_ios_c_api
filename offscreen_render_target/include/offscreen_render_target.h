#pragma once

#include <bnb/common_types.h>

#include <interfaces/offscreen_render_target.hpp>
#include "program.hpp"

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>
#import <OpenGLES/EAGLDrawable.h>

#import <CoreMedia/CoreMedia.h>

namespace bnb
{
    class ort_frame_surface_handler;

class offscreen_render_target : public oep::interfaces::offscreen_render_target
    {
    public:
        offscreen_render_target();

        ~offscreen_render_target();

        void* get_image();
        
        void init(int32_t width, int32_t height) override;
        void deinit() override;
        void surface_changed(int32_t width, int32_t height) override;
        void activate_context() override;
        void deactivate_context() override;
        void prepare_rendering() override;
        void orient_image(bnb::oep::interfaces::rotation orient) override;
        pixel_buffer_sptr read_current_buffer(bnb::oep::interfaces::image_format format) override;
        rendered_texture_t get_current_buffer_texture() override;

    private:
        void cleanupRenderBuffers();
        void cleanPostProcessRenderingTargets();

        void createContext();

        std::tuple<int, int> getWidthHeight(bnb::oep::interfaces::rotation orient);

        void setupTextureCache();
        void setupRenderBuffers();

        void setupOffscreenPixelBuffer(CVPixelBufferRef& pb);
        void setupOffscreenRenderTarget(CVPixelBufferRef& pb, CVOpenGLESTextureRef& texture);

        void preparePostProcessingRendering(bnb::oep::interfaces::rotation orient);
        
//        pixel_buffer_sptr read_current_buffer_bpc8(bnb::oep::interfaces::image_format format_hint);
//        pixel_buffer_sptr read_current_buffer_i420(bnb::oep::interfaces::image_format format_hint);


        uint32_t m_width{0};
        uint32_t m_height{0};

        CVOpenGLESTextureCacheRef m_videoTextureCache{nullptr};

        GLuint m_framebuffer{0};
        GLuint m_postProcessingFramebuffer{0};

        CVPixelBufferRef m_offscreenRenderPixelBuffer{nullptr};
        CVPixelBufferRef m_offscreenPostProcessingPixelBuffer{nullptr};

        CVOpenGLESTextureRef m_offscreenRenderTexture{nullptr};
        CVOpenGLESTextureRef m_offscreenPostProcessingRenderTexture{nullptr};

        bool m_oriented{false};

        std::unique_ptr<program> m_program;
        std::unique_ptr<ort_frame_surface_handler> m_frameSurfaceHandler;
        
        bnb::oep::interfaces::rotation m_prev_orientation{0};
    };
} // bnb
