//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// DilationErosion by Bapho - https://github.com/Bapho https://www.shadertoy.com/user/Bapho
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

uniform int type <
    ui_type = "combo";
    ui_items = "Dilation" "\0"
               "Erosion" "\0";
    ui_label = "Choose a type";
> = 0;

uniform int amount <
    ui_type = "slider";
    ui_min = 0; ui_max = 30;
    ui_label = "Amount";
> = 10;

uniform int multiplier <
    ui_type = "slider";
    ui_min = 1; ui_max = 30;
    ui_label = "Multiplier";
> = 1;

uniform int steps <
    ui_type = "slider";
    ui_min = 1; ui_max = 3;
    ui_label = "Steps";
> = 3;

uniform int quality <
    ui_type = "combo";
    ui_items = "Low" "\0"
               "Medium" "\0"
               "High" "\0";
    ui_label = "Quality";
> = 1;

uniform float depthBalance <
    ui_type = "slider";
    ui_min = -1.0; ui_max = 1.0; ui_step = 0.01;
    ui_label = "Depth Balance";
    ui_tooltip = "Balancing between far and near objects";
> = 0;

uniform bool useInDepthOnly <
    ui_label = "Use in depth only";
    ui_tooltip = "Fully near areas like some UI elements will be skipped";
> = false;

#include "ReShade.fxh"

texture texOne { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };
texture texTwo { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };
texture texThree { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };
sampler2D samOne { Texture = texOne; };
sampler2D samTwo { Texture = texTwo; };
sampler2D samThree { Texture = texThree; };

float3 dilateErode(int stepCount, sampler sam, float2 texcoord)
{
    if (stepCount > steps || amount <= 0.0) {
        return tex2D(sam, texcoord).rgb;
    }
    
    float am = amount / 32.0 * multiplier / (stepCount * stepCount);
    
    float d = ReShade::GetLinearizedDepth(texcoord);
    if (useInDepthOnly && d == 1.0) {
        am = 0.0;
    } else if (depthBalance == 0.0) {
    
    } else {
        d = 1.0 - d;
        if (depthBalance > 0.5) {
            d = lerp(d, pow(d, 128.0), (depthBalance * 2.0) - 1.0);
        } else if (depthBalance > 0.0) {
            d = lerp(1.0, d, depthBalance * 2.0);
        } else if (depthBalance >= -0.5) {
            d = lerp(1.0, d, depthBalance * -2.0);
        } else {
            d = lerp(d, 1.0 - d, (depthBalance * -2.0) - 1.0);
        }
        am *= d;
    }
    
    float2 dz = float2(am / ReShade::ScreenSize.x, am / ReShade::ScreenSize.y);
    
    /*
    
    A | B | C
    D | E | F
    G | H | I
    
    */
    
    float3 A  = tex2D(sam, texcoord + float2(-1, -1) * dz).rgb;
    float3 B;
    float3 C  = tex2D(sam, texcoord + float2(+1, -1) * dz).rgb;
    float3 D;
    float3 E  = tex2D(sam, texcoord + float2(+0, +0) * dz).rgb;
    float3 F;
    float3 G  = tex2D(sam, texcoord + float2(-1, +1) * dz).rgb;
    float3 H;
    float3 I  = tex2D(sam, texcoord + float2(+1, +1) * dz).rgb;
    
    bool exacter = quality > 1 || (quality == 1 && am > 1.0);
    
    if (exacter){
        B  = tex2D(sam, texcoord + float2(+0, -1) * dz).rgb;
        D  = tex2D(sam, texcoord + float2(-1, +0) * dz).rgb;
        F  = tex2D(sam, texcoord + float2(+1, +0) * dz).rgb;
        H  = tex2D(sam, texcoord + float2(+0, +1) * dz).rgb;
    }
    
    float3 res;
    if (type <= 0){
        if (exacter){
            res = max(E, max(max(max(F, D), max(B, H)), max(max(A, I), max(C, G))));
        } else {
            res = max(E, max(max(A, I), max(C, G)));
        }
    } else {
        if (exacter){
            res = min(E, min(min(min(F, D), min(B, H)), min(min(A, I), min(C, G))));
        } else {
            res = min(E, min(min(A, I), min(C, G)));
        }
    }

    return res;
}

float3 DilationErosionStepOne(float4 pos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
    return dilateErode(1, ReShade::BackBuffer, texcoord);
}

float3 DilationErosionStepTwo(float4 pos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
    return dilateErode(2, samOne, texcoord);
}

float3 DilationErosionStepThree(float4 pos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
    return dilateErode(3, samTwo, texcoord);
}

technique DilationErosion
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = DilationErosionStepOne;
        RenderTarget = texOne;
    }
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = DilationErosionStepTwo;
        RenderTarget = texTwo;
    }
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = DilationErosionStepThree;
    }
}
