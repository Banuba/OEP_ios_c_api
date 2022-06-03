#include <bnb/glsl.vert>

BNB_LAYOUT_LOCATION(0)
BNB_IN vec2 attrib_v;

BNB_DECLARE_SAMPLER_2D(0, 1, tex_warp);

BNB_OUT(0)
vec2 var_uv;

void main()
{
    vec2 v = attrib_v * 0.5 + 0.5;

#if defined(BNB_VK_1)
    const float bottom_coord = 1.;
    const float top_coord = 0.;
#else
    const float bottom_coord = 0.;
    const float top_coord = 1.;
#endif

    float bottom_margin = 0.;
    bottom_margin = max(bottom_margin, -BNB_TEXTURE_2D(BNB_SAMPLER_2D(tex_warp), vec2(0.25, bottom_coord)).y);
    bottom_margin = max(bottom_margin, -BNB_TEXTURE_2D(BNB_SAMPLER_2D(tex_warp), vec2(0.50, bottom_coord)).y);
    bottom_margin = max(bottom_margin, -BNB_TEXTURE_2D(BNB_SAMPLER_2D(tex_warp), vec2(0.75, bottom_coord)).y);

    float top_margin = 0.;
    top_margin = max(top_margin, BNB_TEXTURE_2D(BNB_SAMPLER_2D(tex_warp), vec2(0.25, top_coord)).y);
    top_margin = max(top_margin, BNB_TEXTURE_2D(BNB_SAMPLER_2D(tex_warp), vec2(0.50, top_coord)).y);
    top_margin = max(top_margin, BNB_TEXTURE_2D(BNB_SAMPLER_2D(tex_warp), vec2(0.75, top_coord)).y);

    float left_margin = 0.;
    left_margin = max(left_margin, -BNB_TEXTURE_2D(BNB_SAMPLER_2D(tex_warp), vec2(0., 0.25)).x);
    left_margin = max(left_margin, -BNB_TEXTURE_2D(BNB_SAMPLER_2D(tex_warp), vec2(0., 0.50)).x);
    left_margin = max(left_margin, -BNB_TEXTURE_2D(BNB_SAMPLER_2D(tex_warp), vec2(0., 0.75)).x);

    float right_margin = 0.;
    right_margin = max(right_margin, BNB_TEXTURE_2D(BNB_SAMPLER_2D(tex_warp), vec2(1., 0.25)).x);
    right_margin = max(right_margin, BNB_TEXTURE_2D(BNB_SAMPLER_2D(tex_warp), vec2(1., 0.50)).x);
    right_margin = max(right_margin, BNB_TEXTURE_2D(BNB_SAMPLER_2D(tex_warp), vec2(1., 0.75)).x);

    float size_x = 1. - left_margin - right_margin;
    float size_y = 1. - bottom_margin - top_margin;

    float scale;
    if (size_x > size_y) {
        scale = 1. / size_y;
        left_margin += (size_x - size_y) * 0.5;
    } else {
        scale = 1. / size_x;
        bottom_margin += (size_y - size_x) * 0.5;
    }
    gl_Position = vec4((v - vec2(left_margin, bottom_margin)) * scale * 2. - 1., 0., 1.);

    var_uv = v;
#if defined(BNB_VK_1)
    var_uv.y = 1. - var_uv.y;
#endif
}