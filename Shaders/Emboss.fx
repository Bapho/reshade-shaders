/*
	Full credits to the ReShade team
	Ported by Insomnia
*/

uniform float fEmbossPower <
	ui_type = "drag";
	ui_min = 0.01; ui_max = 2.0;
	ui_label = "Emboss Power";
> = 0.150;
uniform float fEmbossOffset <
	ui_type = "drag";
	ui_min = 0.1; ui_max = 5.0;
	ui_label = "Emboss Offset";
> = 1.00;
uniform float iEmbossAngle <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 360.0;
	ui_label = "Emboss Angle";
> = 90.00;

#include "ReShade.fxh"

float3 EmbossPass(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	//float4 res = 0;
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;

        float2 offset;
	sincos(radians( iEmbossAngle), offset.y, offset.x);
	float3 col1 = tex2D(ReShade::BackBuffer, texcoord - ReShade::PixelSize*fEmbossOffset*offset).rgb;
	float3 col2 = color.rgb;
	float3 col3 = tex2D(ReShade::BackBuffer, texcoord + ReShade::PixelSize*fEmbossOffset*offset).rgb;


	
	float3 colEmboss = col1 * 2.0 - col2 - col3;

	float colDot = max(0,dot(colEmboss, 0.333))*fEmbossPower;

	float3 colFinal = col2 - colDot;

	float luminance = dot( col2, float3( 0.6, 0.2, 0.2 ) );

	color.xyz = lerp( colFinal, col2, luminance * luminance ).xyz;

	return color;

}

technique Emboss_Tech
{
	pass Emboss
	{
		VertexShader = PostProcessVS;
		PixelShader = EmbossPass;
	}
}
