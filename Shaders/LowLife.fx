//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// LowLife by Bapho - https://github.com/Bapho https://www.shadertoy.com/view/3tBGzw
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Can be used to display a red warning screen when being on low life in a video game with a life bar.
// Please don't use this shader to cheat in a competetive multiplayer game ;)
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

uniform float red <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
    ui_label = " Red amount of warning screen";
    ui_tooltip = "Defines how reddish the triggered warning screen is displayed.";
    > = 0.4;
    
uniform bool blinkingWarningScreen <
    ui_type = "bool";
    ui_label = "Blinking warning screen";
> = true;
    
uniform float horizontalPosLifeCap <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.001;
    ui_label = " Horizontal life bar warning positon";
    ui_tooltip = "Triggers the warning screen when this point loses it's reddish color.";
> = 0.05;
    
uniform float verticalPosLifeCap <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.001;
    ui_label = " Vertical life bar warning positon";
    ui_tooltip = "Triggers the warning screen when this point loses it's reddish color.";
> = 0.86;

uniform bool enableOneLifePoint <
    ui_spacing = 2;
    ui_type = "bool";
    ui_label = "Enable false-positive point (close to 1 life)";
    ui_tooltip = "The warning screen will not be triggered when this point is not reddish. Can be used to eliminate false-positives, for example when being in the game menu where no life bar is displayed.";
> = false;

uniform float horizontalPosOneLife <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.001;
    ui_label = " Horizontal posisiton close to 1 life";
    ui_tooltip = "The warning screen will not be triggered when this point is not reddish.";
> = 0.068;
    
uniform float verticalPosOneLife <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.001;
    ui_label = " Vertical posisiton close to 1 life";
    ui_tooltip = "The warning screen will not be triggered when this point is not reddish.";
> = 0.97;

uniform bool displayPos <
    ui_spacing = 1;
    ui_type = "bool";
    ui_label = "Display life bar warning and false-positive points";
    ui_tooltip = "Life bar warning position is displayed red. False-positive point is displayed blue.";
> = true;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#include "ReShade.fxh"

uniform float2 pingpong < source = "pingpong"; min = 1; max = 2; step = 1; >;

static const float redCap = 0.25;
static const float greenBlueCap = 0.6;

float4 LowLife(float4 pos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
    float4 color = tex2D(ReShade::BackBuffer, texcoord);
    float4 lifeCapColor = tex2D(ReShade::BackBuffer, float2(horizontalPosLifeCap, verticalPosLifeCap));
    float4 oneLifeColor = tex2D(ReShade::BackBuffer, float2(horizontalPosOneLife, verticalPosOneLife));
    
    if ((!enableOneLifePoint || (oneLifeColor.r >= redCap && oneLifeColor.g <= greenBlueCap && oneLifeColor.b <= greenBlueCap)) 
            && (lifeCapColor.r < redCap || lifeCapColor.g > greenBlueCap || lifeCapColor.b > greenBlueCap)) {
            
        color.r = lerp(color.r, 1.0, red / 2.0 * (blinkingWarningScreen ? pingpong.x : 2.0));
    }
    
    if (displayPos) {
        if (abs(texcoord.x - horizontalPosLifeCap) < 0.002 && abs(texcoord.y - verticalPosLifeCap) < 0.003) {
            color = float4(0.0, 1.0, 0.0, 1.0);
            
        } else if (abs(texcoord.x - horizontalPosOneLife) < 0.002 && abs(texcoord.y - verticalPosOneLife) < 0.003) {
            color = float4(0.0, 0.0, 1.0, 1.0);
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
