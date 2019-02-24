//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// SmartNoise by Bapho - https://github.com/Bapho 
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
	ui_min = 0.0; ui_max = 3.0;
	ui_label = "Amount of noise";
> = 1.5;

#include "ReShade.fxh"

float2 random(float2 p){
	p = frac(p * float2(443.897, 441.423));
    p += dot(p, p.yx+19.19);
    return frac((p.xx+p.yx)*p.xy);
}

float3 applyNoise(float3 color, float2 uv, float noiseAmount){

	// Blue Noise
	float2 blueNoise = random(uv);
	blueNoise = float2(sin(blueNoise.x), cos(blueNoise.x)) * sqrt(blueNoise.y);
	float add = (blueNoise.g * noiseAmount * 0.2);
	float sub = (0.55 * noiseAmount * 0.2); // 0.5 instead of 0.55 for even brightness
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
	// red pixels will get less noise 
	amount *= (1.0 - color.r);
	
	if (amount > 0.0){	
		float unique = colorSum1 + uniquePos1;
		color = applyNoise(color, float2(unique, unique * 0.01), amount);
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
