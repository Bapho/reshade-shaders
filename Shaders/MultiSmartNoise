//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// MultiSmartNoise by Mario V. aka Bapho
// https://github.com/Bapho 
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Interleaved Gradient Noise by Jorge Jimenez
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// UI variables and constants
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

uniform float noise <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 3.0;
	ui_label = "Amplifies noise/grain/details";
> = 1.0;

static const float3 VibranceRGBBalance = float3(1.0, 1.0, 1.0);
static const float maxDark = 2.0;
static const float minDark = 0.4;
static const float mdiff = 0.2;

#include "ReShade.fxh"

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Functions
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

float pseudoNoise(float2 co)
{
	return frac(sin(dot(co.xy, float2(12.9898,78.233))) * 43758.5453)*2.0-0.5;
}

// interleaved gradient noise function from: http://www.iryoku.com/next-generation-post-processing-in-call-of-duty-advanced-warfare
float interleavedGradientNoise(float2 uv, float2 screen)
{
    uv = floor(uv * screen.xy);
    float f = dot(float2(0.06711056f, 0.00583715f), uv);
    return frac(52.9829189f * frac(f));
}

float3 changeSaturation(float3 color, float colourfulness){
	const float3 coefLuma = float3(0.212656, 0.715158, 0.072186);
	float luma = dot(coefLuma, color);


	float max_color = max(color.r, max(color.g, color.b)); // Find the strongest color
	float min_color = min(color.r, min(color.g, color.b)); // Find the weakest color

	float color_saturation = max_color - min_color; // The difference between the two is the saturation
	
	// Extrapolate between luma and original by 1 + (1-saturation) - current
	float3 coeffVibrance = float3(VibranceRGBBalance * colourfulness);
	color = lerp(luma, color, 1.0 + (coeffVibrance * (1.0 - (sign(coeffVibrance) * color_saturation))));

	return color;
}

float3 MultiSmartNoise(float4 pos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
	float colorSum1 = color.r + color.g + color.b;
	float uniquePos = (ReShade::ScreenSize.x * (texcoord.y - 1.0)) + texcoord.x;
	
	if (colorSum1 > minDark && colorSum1 < maxDark){
		
		float igNoise = interleavedGradientNoise(texcoord, ReShade::ScreenSize);
		float n = colorSum1 > maxDark - 0.6 ? 0.01 : 0.02;//0.02
		color += (igNoise - 0.5) * n * noise; 
		igNoise = (pseudoNoise( float2(uniquePos, igNoise * colorSum1) ) - 0.5) * 0.0075 * noise; //0.0075
		////float igNoise = (((interleavedGradientNoise(texcoord, ReShade::ScreenSize) - 0.0) * 0.8) + ((pseudoNoise( float2(uniquePos, colorSum1) ) - 0.0) * 0.2) - 0.5) * 0.8;
		color += igNoise;
		
		if ((colorSum1 > minDark && colorSum1 < maxDark) && color.r - mdiff >= color.g 
			|| color.r + mdiff <= color.g || color.r - mdiff >= color.b || color.r + mdiff <= color.b 
				|| color.g - mdiff >= color.b || color.g + mdiff <= color.b){
				
			float2 texcoord2;
			float2 split = ReShade::ScreenSize / 2.0;
			if (texcoord.x > split.x){
				if (texcoord.y > split.y){
					texcoord2 = float2(texcoord.x - split.x, texcoord.y - split.y);
				} else {
					texcoord2 = float2(texcoord.x - split.x, texcoord.y + split.y);
				}
			} else {
				if (texcoord.y > split.y){
					texcoord2 = float2(texcoord.x + split.x, texcoord.y - split.y);
				} else {
					texcoord2 = float2(texcoord.x + split.x, texcoord.y + split.y);
				}
			}
			float uniquePos2 = (ReShade::ScreenSize.x * (texcoord2.y - 1)) + texcoord2.x;
			float3 colorTwo = tex2D(ReShade::BackBuffer, texcoord2).rgb;
			float colorSum2 = colorTwo.r + colorTwo.g + colorTwo.b;
			
			float ran = pseudoNoise( float2(colorSum1 * uniquePos, colorSum2) );
			
			// saturation
			n = colorSum1 > maxDark - 0.6 ? 0.03 : 0.06; //0.06
			ran *= n * noise;
			ran = (0 - (n * noise / 2)) + ran;
			if (color.r > 0.5 && color.g < 0.5 && color.b < 0.5){
				ran /= 2;
			} else if (color.r > 0.4 && color.g < 0.6 && color.b < 0.6){
				ran /= 1.5;
			}
			color = saturate(color * (1+ran));	 
			
			// brightness
			float ran2 = pseudoNoise( float2(pos.x + pos.z + ran + uniquePos - colorSum2 - 0.00137, pos.y + pos.w - ran + colorSum1 + colorSum2 + 0.00784) );
			n = colorSum1 > maxDark - 0.6 ? 0.006 : 0.012; //0.012
			ran2 *= n * noise;
			ran2 = (0.0 - (n * noise / 2)) + ran2;
			color += ran2;
		}
	}
	
	return color;
	//return float3(igNoise, igNoise, igNoise);
}

technique MultiSmartNoise
{
        pass
	{
		VertexShader = PostProcessVS;
		PixelShader  = MultiSmartNoise;
	}
}
