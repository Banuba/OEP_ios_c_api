#include <bnb/glsl.frag>

BNB_DECLARE_SAMPLER_2D(0, 1, tex_warp);
BNB_DECLARE_SAMPLER_2D(2, 3, tex_frame);

BNB_IN(0)
vec2 var_uv;

void main()
{
    vec2 o = BNB_TEXTURE_2D(BNB_SAMPLER_2D(tex_warp), var_uv).xy;
#if defined(BNB_VK_1)
    o = vec2(o.x, -o.y);
#endif
    bnb_FragColor = BNB_TEXTURE_2D(BNB_SAMPLER_2D(tex_frame), var_uv + o);
}
