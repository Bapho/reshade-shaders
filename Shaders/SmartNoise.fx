//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// SmartNoise by Bapho - https://github.com/Bapho https://www.shadertoy.com/user/Bapho
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// I created this shader because i did not liked the the noise 
// behaviour of most shaders. Time based noise shaders, which are 
// changing the noise pattern every frame, are very noticeable when the 
// "image isn't moving". "Static shaders", which are never changing 
// the noise pattern, are very noticeable when the "image is moving". 
// So i was searching a way to bypass those disadvantages. I used the 
// unique position of the current texture in combination with the color
// to get a unique seed for the noise function. The result is a noise 
// pattern that is only changing if the color of the position is changing.
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

uniform float noise <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 4.0;
	ui_label = "Amount of noise";
> = 1.5;

uniform bool lessNoiseOnRed <
	ui_label = "Use less noise on red";
> = true;

#include "ReShade.fxh"

//precision lowp float;
static const float PHI = 1.61803398874989484820459 * 00000.1; // Golden Ratio   
static const float PI  = 3.14159265358979323846264 * 00000.1; // PI
static const float SQ2 = 1.41421356237309504880169 * 10000.0; // Square Root of Two

float gold_noise(float2 coordinate, float seed){
    return frac(tan(distance(coordinate*(seed+PHI), float2(PHI, PI)))*SQ2);
}

float3 applyNoise(float3 color, float2 uv, float uq, float colorSum, float amount){
    colorSum /= 3.0;
    amount *= colorSum > 0.5 ? (0.5 / colorSum) : (colorSum / 0.5);
    float sub = (0.5 * amount);
    
	if (colorSum - sub < 0.0){
	   amount *= (colorSum / sub);
	   sub *= (colorSum / sub);
	} else if (colorSum + sub > 1.0){
		if (colorSum > sub){
			amount *= (sub / colorSum);
			sub *= (sub / colorSum);
		} else {
		   amount *= (colorSum / sub);
		   sub *= (colorSum / sub);
		}
	}
    
    float ran = gold_noise(uv, uq);
    float add = ran * amount;
    return color + (add - sub);
}

float3 SmartNoise(float4 pos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
	float colorSum1 = color.r + color.g + color.b;
	float uniquePos1 = (ReShade::ScreenSize.x * (texcoord.y - 1.0)) + texcoord.x;
	
	// black or white pixels will get less noise than colored ones
	float amount;
	if (colorSum1 < 1.5){
		amount = noise * (colorSum1 / 1.5);
	} else {
		amount = noise * ((3.0 - colorSum1) / 1.5);
	}
	if (lessNoiseOnRed){
		// red pixels will get less noise 
		amount *= (1.0 - (color.r * 0.5));
	} else {
		amount *= 0.5;
	}
	
	if (amount > 0.0){
		float unique = (colorSum1 + uniquePos1) * 0.000001;
		color = applyNoise(color, pos.xy, unique, colorSum1, amount * 0.15);
	}
	
	return color;
}

technique SmartNoise
{
        pass
	{
		VertexShader = PostProcessVS;
		PixelShader  = SmartNoise;
	}
}
