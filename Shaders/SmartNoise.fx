//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// SmartNoise by Bapho - https://github.com/Bapho https://www.shadertoy.com/view/3tBGzw
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// I created this shader because i did not liked the the noise behaviour
// of most shaders. Temporal noise shaders, which are changing the noise
// pattern every frame, are very noticeable when the "image isn't moving".
// Fixed pattern noise shaders, which are never changing the noise pattern,
// are very noticeable when the "image is moving". So i was searching a way
// to bypass those disadvantages. I used the unique position of the current
// texture in combination with the color and depth to get a unique seed
// for the noise function. The result is a noise pattern that is only
// changing when the color or depth of the position is changing.
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

static const float PHI = 1.61803398874989484820459 * 00000.1; // Golden Ratio   
static const float PI  = 3.14159265358979323846264 * 00000.1; // PI
static const float SQ2 = 1.41421356237309504880169 * 10000.0; // Square Root of Two
static const float SAT = 0.33333333333333333333334;
static const int TYPE_MIXED = 0;
static const int TYPE_GOLDEN = 1;
static const int TYPE_BLUE = 2;

uniform float noise <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 4.0;
    ui_step = 0.2;
    ui_label = "Amount of noise";
> = 1.0;

uniform int type <
    ui_type = "combo";
    ui_label = "Noise type";
    ui_items = "Mixed\0Dynamic golden noise\0Fixed blue noise\0";
    > = TYPE_MIXED;
    
uniform float balance <
    ui_type = "drag";
    ui_min = 1.0; ui_max = 6.0;
    ui_step = 0.1;
    ui_label = "Mix (golden - blue)";
> = 4.0;

uniform bool compensateSaturation <
    ui_type = "bool";
    ui_label = "Compensate saturation";
> = true;

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#include "ReShade.fxh"

texture texBlueNoise < source = "bluenoise.png"; > { Width = 256; Height = 256; Format = RGBA8; };
sampler samplerBlueNoise { Texture = texBlueNoise; };

float gold_noise(float2 coordinate, float seed){
    return frac(tan(distance(coordinate*(seed+PHI), float2(PHI, PI)))*SQ2);
}

float getLuminance( in float3 x )
{
    return dot( x, float3( 0.212656, 0.715158, 0.072186 ));
}

float3 sat( float3 res, float x )
{
    return min( lerp( getLuminance( res.xyz ), res.xyz, x + 1.0f ), 1.0f );
}

float4 SmartNoise(float4 pos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
    float amount = noise * 0.08;
    float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
    
    // the luminance/brightness
    float luminance = (0.2126 * color.r) + (0.7152 * color.g) + (0.0722 * color.b);
    
    // calculating a unique position
    float uniquePos = ((ReShade::ScreenSize.x * pos.y) + pos.x) * 0.001;
    
    // depth is also used
    float depthSeed = ReShade::GetLinearizedDepth(texcoord) * ReShade::ScreenSize.y;
    
    // adjusting "noise contrast"
    if (luminance < 0.5){
        amount *= (luminance / 0.5);
    } else {
        amount *= ((1.0 - luminance) / 0.5);
    }
    
    // reddish pixels will get less noise 
    float redDiff = color.r - ((color.g + color.b) / 2.0);
    if (redDiff > 0.0){
        amount *= (1.0 - (redDiff * 0.5));
    }

    // a very low unique seed will lead to slow noise pattern changes on slow moving color gradients
    float uniqueSeed = ((luminance * ReShade::ScreenSize.y) + uniquePos + depthSeed) *
    0.0001;
    //0.00000000500001;
    
    // using a fictive coordinate as a workaround to fix a pattern bug
    float2 coordinate = float2(pos.x, pos.y * 1.001253543);

    // average noise luminance to subtract
    float sub = (0.5 * amount);
    float add;
    float ran;
    
    // "noise clipping"
    if (luminance - sub < 0.0){
       amount *= (luminance / sub);
       sub *= (luminance / sub);
    } else if (luminance + sub > 1.0){
        if (luminance > sub){
            amount *= (sub / luminance);
            sub *= (sub / luminance);
        } else {
            amount *= (luminance / sub);
            sub *= (luminance / sub);
        }
    }
    
    // calculating and adding/subtracting the golden noise
    if (type != TYPE_BLUE) {
        ran = gold_noise(coordinate, uniqueSeed);
        float div = type == 1 ? 1 : balance;
        add = saturate(ran * amount / div);
        color.rgb += (add - sub / div);
    }
    
    // calculating and adding/subtracting the blue noise
    if (type != TYPE_GOLDEN) {
        int blueNoiseX = (texcoord.x * BUFFER_WIDTH) % 256;
        int blueNoiseY = (texcoord.y * BUFFER_HEIGHT) % 256;
        color.rgb += (tex2Dfetch(samplerBlueNoise, int4(blueNoiseX, blueNoiseY, 0, 0)).rgb * amount - sub.rrr);
    }
    
    // compensating the saturation since the noise is luma noise
    if (compensateSaturation) {
        color.rgb = sat(color.rgb, SAT * amount);
    }
    
    return float4(color, 1.0);
}

technique SmartNoise
{
        pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = SmartNoise;
    }
}
