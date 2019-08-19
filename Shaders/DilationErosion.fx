//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ported and modified by Bapho - https://github.com/Bapho https://www.shadertoy.com/user/Bapho
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

uniform int type <
	ui_type = "combo";
	ui_items =	"Dilation" "\0"
				"Erosion" "\0";
	ui_label = "Choose a type";
> = 0;

uniform float amount <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 2.5;
    ui_label = "Amount of dilation/erosion";
> = 0.25;

#include "ReShade.fxh"

float3 dilateErode(float am, float2 texcoord) : SV_Target
{
	float2 dz = float2(am / ReShade::ScreenSize.x, am / ReShade::ScreenSize.y);
	
	/*
	
	A | B | C
	D | E | F
	G | H | I
	
	*/
	
	float3 A  = tex2D(ReShade::BackBuffer, texcoord + float2(-1, -1) * dz).rgb;
	float3 B;
	float3 C  = tex2D(ReShade::BackBuffer, texcoord + float2(+1, -1) * dz).rgb;
	float3 D;
	float3 E  = tex2D(ReShade::BackBuffer, texcoord + float2(+0, +0) * dz).rgb;
	float3 F;
	float3 G  = tex2D(ReShade::BackBuffer, texcoord + float2(-1, +1) * dz).rgb;
	float3 H;
	float3 I  = tex2D(ReShade::BackBuffer, texcoord + float2(+1, +1) * dz).rgb;
	
	bool exacter = am > 1.0;
	
	if (exacter){
		B  = tex2D(ReShade::BackBuffer, texcoord + float2(+0, -1) * dz).rgb;
		D  = tex2D(ReShade::BackBuffer, texcoord + float2(-1, +0) * dz).rgb;
		F  = tex2D(ReShade::BackBuffer, texcoord + float2(+1, +0) * dz).rgb;
		H  = tex2D(ReShade::BackBuffer, texcoord + float2(+0, +1) * dz).rgb;
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

float3 DilationErosion(float4 pos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
	float3 res;
	
	if (type <= 0){
		res = max(max(dilateErode(amount, texcoord), dilateErode(amount * 0.75, texcoord)), 
				  max(dilateErode(amount * 0.5, texcoord), dilateErode(amount * 0.25, texcoord)));
	} else {
		res = min(min(dilateErode(amount, texcoord), dilateErode(amount * 0.75, texcoord)), 
				  min(dilateErode(amount * 0.5, texcoord), dilateErode(amount * 0.25, texcoord)));
	}

	return res;
}

technique DilationErosion
{
	pass
	{
        VertexShader = PostProcessVS;
        PixelShader  = DilationErosion;
	}
}
