#include "offscreen_render_target.h"

#include "opengl.hpp"
#include "utils.h"

namespace bnb
{

const char* vs_default_base =
        " precision highp float; \n "
        " layout (location = 0) in vec3 aPos; \n"
        " layout (location = 1) in vec2 aTexCoord; \n"
        "out vec2 vTexCoord;\n"
        "void main()\n"
        "{\n"
            " gl_Position = vec4(aPos, 1.0); \n"
            " vTexCoord = aTexCoord; \n"
        "}\n";

const char* ps_default_base =
        "precision mediump float;\n"
        "in vec2 vTexCoord;\n"
        "out vec4 FragColor;\n"
        "uniform sampler2D uTexture;\n"
        "void main()\n"
        "{\n"
            "FragColor = texture(uTexture, vTexCoord);\n"
        "}\n";



    class ort_frame_surface_handler
    {
    private:
        static const auto v_size = static_cast<uint32_t>(bnb::oep::interfaces::rotation::deg270) + 1;

    public:
        /**
        * First array determines texture orientation for vertical flip transformation
        * Second array determines texture's orientation
        * Third one determines the plane vertices` positions in correspondence to the texture coordinates
        */
        static const float vertices[2][v_size][5 * 4];

        explicit ort_frame_surface_handler(bnb::oep::interfaces::rotation orientation, bool is_y_flip)
            : m_orientation(static_cast<uint32_t>(orientation))
            , m_y_flip(static_cast<uint32_t>(is_y_flip))
        {
            glGenVertexArrays(1, &m_vao);
            glGenBuffers(1, &m_vbo);
            glGenBuffers(1, &m_ebo);

            glBindVertexArray(m_vao);

            glBindBuffer(GL_ARRAY_BUFFER, m_vbo);
            glBufferData(GL_ARRAY_BUFFER, sizeof(vertices[m_y_flip][m_orientation]), vertices[m_y_flip][m_orientation], GL_STATIC_DRAW);

            // clang-format off

            unsigned int indices[] = {
                // clang-format off
                0, 1, 3, // first triangle
                1, 2, 3  // second triangle
                // clang-format on
            };

            // clang-format on

            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_ebo);
            glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);

            // position attribute
            glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*) 0);
            glEnableVertexAttribArray(0);
            // texture coord attribute
            glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*) (3 * sizeof(float)));
            glEnableVertexAttribArray(1);

            glBindVertexArray(0);
            glBindBuffer(GL_ARRAY_BUFFER, 0);
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
        }

        virtual ~ort_frame_surface_handler() final
        {
            if (m_vao != 0)
                glDeleteVertexArrays(1, &m_vao);

            if (m_vbo != 0)
                glDeleteBuffers(1, &m_vbo);

            if (m_ebo != 0)
                glDeleteBuffers(1, &m_ebo);

            m_vao = 0;
            m_vbo = 0;
            m_ebo = 0;
        }

        ort_frame_surface_handler(const ort_frame_surface_handler&) = delete;
        ort_frame_surface_handler(ort_frame_surface_handler&&) = delete;

        ort_frame_surface_handler& operator=(const ort_frame_surface_handler&) = delete;
        ort_frame_surface_handler& operator=(ort_frame_surface_handler&&) = delete;

        void update_vertices_buffer()
        {
            glBindBuffer(GL_ARRAY_BUFFER, m_vbo);
            glBufferData(GL_ARRAY_BUFFER, sizeof(vertices[m_y_flip][m_orientation]), vertices[m_y_flip][m_orientation], GL_STATIC_DRAW);
            glBindBuffer(GL_ARRAY_BUFFER, 0);
        }

        void set_orientation(bnb::oep::interfaces::rotation orientation)
        {
            if (m_orientation != static_cast<uint32_t>(orientation)) {
                m_orientation = static_cast<uint32_t>(orientation);
            }
        }

        void set_y_flip(bool y_flip)
        {
            if (m_y_flip != static_cast<uint32_t>(y_flip)) {
                m_y_flip = static_cast<uint32_t>(y_flip);
            }
        }

        void draw()
        {
            glBindVertexArray(m_vao);
            glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, nullptr);
            glBindVertexArray(0);
        }

    private:
        uint32_t m_orientation = 0;
        uint32_t m_y_flip = 0;
        unsigned int m_vao = 0;
        unsigned int m_vbo = 0;
        unsigned int m_ebo = 0;
    };

    const float ort_frame_surface_handler::vertices[2][ort_frame_surface_handler::v_size][5 * 4] =
    {{ /* verical flip 0 */
    {
            // positions        // texture coords
            1.0f,  1.0f, 0.0f, 1.0f, 0.0f, // top right
            1.0f, -1.0f, 0.0f, 1.0f, 1.0f, // bottom right
            -1.0f, -1.0f, 0.0f, 0.0f, 1.0f, // bottom left
            -1.0f,  1.0f, 0.0f, 0.0f, 0.0f,  // top left
    },
    {
            // positions        // texture coords
            1.0f,  1.0f, 0.0f, 0.0f, 0.0f, // top right
            1.0f, -1.0f, 0.0f, 1.0f, 0.0f, // bottom right
            -1.0f, -1.0f, 0.0f, 1.0f, 1.0f, // bottom left
            -1.0f,  1.0f, 0.0f, 0.0f, 1.0f,  // top left
    },
    {
            // positions        // texture coords
            1.0f,  1.0f, 0.0f, 0.0f, 1.0f, // top right
            1.0f, -1.0f, 0.0f, 0.0f, 0.0f, // bottom right
            -1.0f, -1.0f, 0.0f, 1.0f, 0.0f, // bottom left
            -1.0f,  1.0f, 0.0f, 1.0f, 1.0f,  // top left
    },
    {
            // positions        // texture coords
            1.0f,  1.0f, 0.0f, 1.0f, 1.0f, // top right
            1.0f, -1.0f, 0.0f, 0.0f, 1.0f, // bottom right
            -1.0f, -1.0f, 0.0f, 0.0f, 0.0f, // bottom left
            -1.0f,  1.0f, 0.0f, 1.0f, 0.0f,  // top left
    }
    },
    { /* verical flip 1 */
    {
            // positions        // texture coords
            1.0f, -1.0f, 0.0f, 1.0f, 1.0f, // top right
            1.0f,  1.0f, 0.0f, 1.0f, 0.0f, // bottom right
            -1.0f,  1.0f, 0.0f, 0.0f, 0.0f, // bottom left
            -1.0f, -1.0f, 0.0f, 0.0f, 1.0f,  // top left
    },
    {
            // positions        // texture coords
            1.0f, -1.0f, 0.0f, 1.0f, 0.0f, // top right
            1.0f,  1.0f, 0.0f, 0.0f, 0.0f, // bottom right
            -1.0f,  1.0f, 0.0f, 0.0f, 1.0f, // bottom left
            -1.0f, -1.0f, 0.0f, 1.0f, 1.0f,  // top left
    },
    {
            // positions        // texture coords
            1.0f, -1.0f, 0.0f, 0.0f, 0.0f, // top right
            1.0f,  1.0f, 0.0f, 0.0f, 1.0f, // bottom right
            -1.0f,  1.0f, 0.0f, 1.0f, 1.0f, // bottom left
            -1.0f, -1.0f, 0.0f, 1.0f, 0.0f,  // top left
    },
    {
            // positions        // texture coords
            1.0f, -1.0f, 0.0f, 0.0f, 1.0f, // top right
            1.0f,  1.0f, 0.0f, 1.0f, 1.0f, // bottom right
            -1.0f,  1.0f, 0.0f, 1.0f, 0.0f, // bottom left
            -1.0f, -1.0f, 0.0f, 0.0f, 0.0f,  // top left
    }
    }};
} // bnb

EAGLContext* m_GLContext{nullptr};

namespace bnb
{
    offscreen_render_target::offscreen_render_target() {}
    offscreen_render_target::~offscreen_render_target() {}

    void offscreen_render_target::init(int32_t width, int32_t height)
    {
        m_width = width;
        m_height = height;

        createContext();
        activate_context();

        setupTextureCache();
        setupRenderBuffers();

        m_program = std::make_unique<program>("OrientationChange", vs_default_base, ps_default_base);
        m_frameSurfaceHandler = std::make_unique<ort_frame_surface_handler>(bnb::oep::interfaces::rotation::deg0, false);
    }

    void offscreen_render_target::deinit(){
        activate_context();

        m_program.reset();
        m_frameSurfaceHandler.reset();
        if (m_videoTextureCache) {
            CFRelease(m_videoTextureCache);
            m_videoTextureCache = nullptr;
        }
        cleanupRenderBuffers();

        deactivate_context();
    }

    void offscreen_render_target::activate_context()
    {
        if ([EAGLContext currentContext] != m_GLContext) {
            if (m_GLContext != nil) {
                [EAGLContext setCurrentContext:m_GLContext];
            } else {
                NSLog(@"Error: The OpenGLES context has not been created yet");
            }
        }
    }

    void offscreen_render_target::deactivate_context()
    {
        if ([EAGLContext currentContext] == m_GLContext) {
            [EAGLContext setCurrentContext:nil];
        }
    }

    void offscreen_render_target::prepare_rendering()
    {
        GL_CALL(glBindFramebuffer(GL_FRAMEBUFFER, m_framebuffer));
        GL_CALL(glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                                       CVOpenGLESTextureGetTarget(m_offscreenRenderTexture),
                                       CVOpenGLESTextureGetName(m_offscreenRenderTexture), 0));

        if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
            GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
            std::cout << "[ERROR] Failed to make complete framebuffer object " << status << std::endl;
            return;
        }
    }

    void offscreen_render_target::surface_changed(int32_t width, int32_t height)
    {
        m_width = width;
        m_height = height;

        cleanupRenderBuffers();
        setupRenderBuffers();
    }

    void offscreen_render_target::orient_image(bnb::oep::interfaces::rotation orientation)
    {
        glFlush();
        if (orientation != bnb::oep::interfaces::rotation::deg0) {
            if (m_prev_orientation != orientation) {
                if (m_offscreenPostProcessingPixelBuffer != nullptr) {
                    cleanPostProcessRenderingTargets();
                }
                m_prev_orientation = orientation;
            }

            if (m_offscreenPostProcessingPixelBuffer == nullptr) {
                setupOffscreenPostProcessingPixelBuffer(orientation);
                setupOffscreenPostProcessingRenderTarget(orientation);
            }

            preparePostProcessingRendering(orientation);
            m_program->use();
            m_frameSurfaceHandler->set_orientation(orientation);
            m_frameSurfaceHandler->set_y_flip(false);
            // Call once for perf
            m_frameSurfaceHandler->update_vertices_buffer();
            m_frameSurfaceHandler->draw();
            m_program->unuse();
            m_oriented = true;
            glFlush();
        }
    }

    pixel_buffer_sptr offscreen_render_target::read_current_buffer(bnb::oep::interfaces::image_format format)
    {
        // Not implemented. See conversion in BNBOffscreenEffectPlayer.
        return nullptr;
    }

    rendered_texture_t offscreen_render_target::get_current_buffer_texture() {
        return get_image();
    }

    void offscreen_render_target::setupRenderBuffers()
    {
        GL_CALL(glGenFramebuffers(1, &m_framebuffer));
        GL_CALL(glGenFramebuffers(1, &m_postProcessingFramebuffer));

        GL_CALL(glBindFramebuffer(GL_FRAMEBUFFER, m_framebuffer));

        setupOffscreenPixelBuffer();
        setupOffscreenRenderTarget();
    }

    void offscreen_render_target::cleanupRenderBuffers()
    {
        if (m_offscreenRenderPixelBuffer) {
            CFRelease(m_offscreenRenderPixelBuffer);
            m_offscreenRenderPixelBuffer = nullptr;
        }
        if (m_offscreenRenderTexture) {
            CFRelease(m_offscreenRenderTexture);
            m_offscreenRenderTexture = nullptr;
        }
        if (m_framebuffer != 0) {
            glDeleteFramebuffers(1, &m_framebuffer);
            m_framebuffer = 0;
        }
        cleanPostProcessRenderingTargets();
        if (m_postProcessingFramebuffer != 0) {
            glDeleteFramebuffers(1, &m_postProcessingFramebuffer);
            m_postProcessingFramebuffer = 0;
        }
    }

    void offscreen_render_target::createContext()
    {
        if (m_GLContext != nil) {
            return;
        }
            
        m_GLContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
        if (m_GLContext == nil) {
            NSLog(@"Unable to create an OpenGLES context. The GPUImage framework requires OpenGLES support to work.");
        }
        [EAGLContext setCurrentContext:m_GLContext];
    }

    std::tuple<int, int> offscreen_render_target::getWidthHeight(bnb::oep::interfaces::rotation orientation)
    {
        auto width = orientation == bnb::oep::interfaces::rotation::deg90 || orientation == bnb::oep::interfaces::rotation::deg270 ? m_height : m_width;
        auto height = orientation == bnb::oep::interfaces::rotation::deg90 || orientation == bnb::oep::interfaces::rotation::deg270  ? m_width : m_height;
        return {width, height};
    }

    void offscreen_render_target::setupTextureCache()
    {
        if (m_videoTextureCache != NULL) {
            return;
        }
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, nil, m_GLContext, nil, &m_videoTextureCache);

        if (err != noErr) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException
                    reason:@"Cannot initialize texture cache"
                    userInfo:nil];
        }
    }

    void offscreen_render_target::setupOffscreenPixelBuffer()
    {
        CFDictionaryRef empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        CFMutableDictionaryRef attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
        CVReturn err = CVPixelBufferCreate(kCFAllocatorDefault, m_width, m_height, kCVPixelFormatType_32BGRA, attrs, &m_offscreenRenderPixelBuffer);

        if (err != noErr) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException
                            reason:@"Cannot create offscreen pixel buffer"
                            userInfo:nil];
        }
        CFRelease(empty);
        CFRelease(attrs);
    }

    void offscreen_render_target::setupOffscreenRenderTarget()
    {
        CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, m_videoTextureCache, m_offscreenRenderPixelBuffer, NULL, GL_TEXTURE_2D, GL_RGBA, (GLsizei) m_width, (GLsizei) m_height, GL_RGBA, GL_UNSIGNED_BYTE, 0, &m_offscreenRenderTexture);

        if (err != noErr) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException
                    reason:@"Cannot create GL texture from pixel buffer"
                    userInfo:nil];
        }
    }

    void offscreen_render_target::setupOffscreenPostProcessingPixelBuffer(bnb::oep::interfaces::rotation orientation){
        auto [width, height] = getWidthHeight(orientation);
        CFDictionaryRef empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        CFMutableDictionaryRef attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
        CVReturn err = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, attrs, &m_offscreenPostProcessingPixelBuffer);
        if (err != noErr) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                           reason:@"Cannot create offscreen pixel buffer 2 for the class BNBOffscreenEffectPlayer"
                                         userInfo:nil];
        }
        CFRelease(empty);
        CFRelease(attrs);
    }

    void offscreen_render_target::setupOffscreenPostProcessingRenderTarget(bnb::oep::interfaces::rotation orientation){
        auto [width, height] = getWidthHeight(orientation);
        CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, m_videoTextureCache, m_offscreenPostProcessingPixelBuffer, NULL, GL_TEXTURE_2D, GL_RGBA, (GLsizei) width, (GLsizei) height, GL_RGBA, GL_UNSIGNED_BYTE, 0, &m_offscreenPostProcessingRenderTexture);

        if (err != noErr) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                           reason:@"Cannot create GL texture 2 from pixel buffer for the class BNBOffscreenEffectPlayer"
                                         userInfo:nil];
        }
    }

    void offscreen_render_target::cleanPostProcessRenderingTargets()
    {
        if (m_offscreenPostProcessingPixelBuffer) {
            CFRelease(m_offscreenPostProcessingPixelBuffer);
            m_offscreenPostProcessingPixelBuffer = nullptr;
        }
        if (m_offscreenPostProcessingRenderTexture) {
            CFRelease(m_offscreenPostProcessingRenderTexture);
            m_offscreenPostProcessingRenderTexture = nullptr;
        }
    }

    void offscreen_render_target::preparePostProcessingRendering(bnb::oep::interfaces::rotation orientation)
    {
        GL_CALL(glBindFramebuffer(GL_FRAMEBUFFER, m_postProcessingFramebuffer));
        GL_CALL(glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                                       CVOpenGLESTextureGetTarget(m_offscreenPostProcessingRenderTexture),
                                       CVOpenGLESTextureGetName(m_offscreenPostProcessingRenderTexture), 0));

        if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
            GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
            std::cout << "[ERROR] Failed to make complete post processing framebuffer object " << status << std::endl;
            return;
        }

        auto width = CVPixelBufferGetWidth(m_offscreenPostProcessingPixelBuffer);
        auto height = CVPixelBufferGetHeight(m_offscreenPostProcessingPixelBuffer);

        GL_CALL(glViewport(0, 0, GLsizei(width), GLsizei(height)));

        GL_CALL(glActiveTexture(GLenum(GL_TEXTURE0)));

        GL_CALL(glBindTexture(CVOpenGLESTextureGetTarget(m_offscreenRenderTexture), CVOpenGLESTextureGetName(m_offscreenRenderTexture)));
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR);
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR);
        glTexParameterf(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GLfloat(GL_CLAMP_TO_EDGE));
        glTexParameterf(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GLfloat(GL_CLAMP_TO_EDGE));
    }

    void* offscreen_render_target::get_image()
    {
        if (m_oriented) {
            m_oriented = false;
            CVPixelBufferRetain(m_offscreenPostProcessingPixelBuffer);
            return (void*)m_offscreenPostProcessingPixelBuffer;
        }
        CVPixelBufferRetain(m_offscreenRenderPixelBuffer);
        return (void*)m_offscreenRenderPixelBuffer;
    }
} // bnb
