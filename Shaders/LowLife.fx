//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// LowLife by Bapho - https://github.com/Bapho https://www.shadertoy.com/view/3tBGzw
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Can be used to display a red screen when being on low life in a video game with a life bar.
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

uniform float red <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Red amount of warning screen";
    > = 0.35;
    
uniform float horizontalPos <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.001;
    ui_label = "Horizontal life bar cap positon";
> = 0.05;
    
uniform float verticalPos <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.001;
    ui_label = "Vertical life bar cap positon";
> = 0.875;

uniform bool displayPos <
    ui_type = "bool";
    ui_label = "Display life bar cap position";
> = true;

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#include "ReShade.fxh"

float4 LowLife(float4 pos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
    float4 color = tex2D(ReShade::BackBuffer, texcoord);
    float4 capColor = tex2D(ReShade::BackBuffer, float2(horizontalPos, verticalPos));
    
    if (capColor.r < 0.6 || capColor.g > 0.4 || capColor.b > 0.4) {
        color.r = lerp(color.r, 1.0, red);
    }
    
    if (displayPos && abs(texcoord.x - horizontalPos) < 0.003 && abs(texcoord.y - verticalPos) < 0.003) {
        if (displayPos) {
            color = float4(0.0, 1.0, 0.0, 1.0);
        }
    }
    
    return color;
}

technique LowLife
{
        pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = LowLife;
    }
}
