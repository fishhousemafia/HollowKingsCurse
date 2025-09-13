#ifdef GL_ES
precision mediump float;
#endif

// ---- Parameters (send these from Lua) ----
extern float CURVATURE_X;            // e.g. 0.10
extern float CURVATURE_Y;            // e.g. 0.15
extern float MASK_BRIGHTNESS;        // e.g. 0.70
extern float SCANLINE_WEIGHT;        // e.g. 6.0  (higher = thinner)
extern float SCANLINE_GAP_BRIGHTNESS;// e.g. 0.12
extern float BLOOM_FACTOR;           // e.g. 1.5
extern float INPUT_GAMMA;            // e.g. 2.4
extern float OUTPUT_GAMMA;           // e.g. 2.2
extern float MASK_TYPE;              // 0.0 = none, 1.0 = green/magenta, 2.0 = trinitron-ish
extern float ENABLE_SCANLINES;       // 0.0/1.0
extern float ENABLE_GAMMA;           // 0.0/1.0
extern float ENABLE_FAKE_GAMMA;      // 0.0/1.0
extern float ENABLE_CURVATURE;       // 0.0/1.0
extern float ENABLE_SHARPER;         // 0.0/1.0
extern float ENABLE_MULTISAMPLE;     // 0.0/1.0

// Sizes (send from Lua)
extern vec2  texSize;   // source canvas size in pixels (InputSize == TextureSize for LÖVE)
extern vec2  outSize;   // window size in pixels

// Precomputed in Lua: (InputSize.y / OutputSize.y) / 3.0
extern float filterWidth;

// ---- Helpers from crt-pi, adapted to LÖVE ----

vec2 distort(vec2 uv) {
    // Barrel distortion in screen space
    vec2 CURV = vec2(CURVATURE_X, CURVATURE_Y);
    vec2 screenScale = texSize / texSize; // == (1,1) in this mapping
    vec2 c = uv * 2.0 - 1.0;
    float rsq = dot(c, c);
    c += c * (CURV * rsq);
    // compensate for shrink
    vec2 barrelScale = 1.0 - (0.23 * CURV);
    c *= barrelScale;
    vec2 warped = c * 0.5 + 0.5;

    // out-of-bounds -> mark invalid
    if (any(lessThan(warped, vec2(0.0))) || any(greaterThan(warped, vec2(1.0)))) {
        return vec2(-1.0);
    }
    return warped;
}

float calcScanLineWeight(float dist) {
    return max(1.0 - dist * dist * SCANLINE_WEIGHT, SCANLINE_GAP_BRIGHTNESS);
}

float scanline(float dy) {
    float w = calcScanLineWeight(dy);
    if (ENABLE_MULTISAMPLE > 0.5) {
        w += calcScanLineWeight(dy - filterWidth);
        w += calcScanLineWeight(dy + filterWidth);
        w *= 0.3333333;
    }
    return w;
}

// LÖVE fragment entry point
vec4 effect(vec4 color, Image tex, vec2 texCoord, vec2 screenCoord)
{
    vec2 uv = texCoord;

    if (ENABLE_CURVATURE > 0.5) {
        // apply curvature in screen space, then map back to texture uv
        vec2 suv = screenCoord / outSize;
        vec2 warped = distort(suv);
        if (warped.x < 0.0) return vec4(0.0);
        uv = warped;
    }

    // Pixel snapping / “sharper” path uses vertical neighbor logic from crt-pi
    vec3 col;
    float slW;
    if (ENABLE_SHARPER > 0.5) {
        vec2 texcoordInPixels = uv * texSize;
        vec2 tempCoord = floor(texcoordInPixels) + 0.5;
        vec2 baseUV = tempCoord / texSize;
        vec2 deltas = texcoordInPixels - tempCoord;
        slW = scanline(deltas.y);
        vec2 signs = sign(deltas);
        deltas.x *= 2.0;
        deltas = deltas * deltas;
        deltas.y = deltas.y * deltas.y;
        deltas.x *= 0.5;
        deltas.y *= 8.0;
        deltas /= texSize;
        deltas *= signs;
        vec2 tc = baseUV + deltas;
        col = Texel(tex, tc).rgb;
    } else {
        vec2 texcoordInPixels = uv * texSize;
        float tempY = floor(texcoordInPixels.y) + 0.5;
        float yCoord = tempY / texSize.y;
        float dy = texcoordInPixels.y - tempY;
        slW = scanline(dy);
        float signY = sign(dy);
        dy = dy * dy;
        dy = dy * dy;
        dy *= 8.0;
        dy /= texSize.y;
        dy *= signY;
        vec2 tc = vec2(uv.x, yCoord + dy);
        col = Texel(tex, tc).rgb;
    }

    // Gamma in
    if (ENABLE_GAMMA > 0.5) {
        if (ENABLE_FAKE_GAMMA > 0.5) col *= col;
        else                        col  = pow(col, vec3(INPUT_GAMMA));
    }

    // Shadow mask (use gl_FragCoord.x for triads)
    if (MASK_TYPE > 0.5) {
        float whichMask;
        vec3 mask = vec3(1.0);
        if (MASK_TYPE < 1.5) {
            // green/magenta stripes
            whichMask = fract(gl_FragCoord.x * 0.5);
            if (whichMask < 0.5) mask = vec3(MASK_BRIGHTNESS, 1.0,           MASK_BRIGHTNESS);
            else                 mask = vec3(1.0,           MASK_BRIGHTNESS, 1.0);
        } else {
            // trinitron-ish RGB
            whichMask = fract(gl_FragCoord.x * 0.3333333);
            mask = vec3(MASK_BRIGHTNESS);
            if      (whichMask < 0.3333333) mask.r = 1.0;
            else if (whichMask < 0.6666666) mask.g = 1.0;
            else                             mask.b = 1.0;
        }
        col *= mask;
    }

    // Gamma out (after mask, like original comment suggests)
    if (ENABLE_GAMMA > 0.5) {
        if (ENABLE_FAKE_GAMMA > 0.5) col = sqrt(col);
        else                         col = pow(col, vec3(1.0 / OUTPUT_GAMMA));
    }

    // Scanlines & bloom factor (keep outside gamma, like original)
    if (ENABLE_SCANLINES > 0.5) {
        col *= slW * BLOOM_FACTOR;
    }

    return vec4(col, 1.0) * color;
}

