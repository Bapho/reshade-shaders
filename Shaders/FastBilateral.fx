//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Fast Bilateral Shader ported by Bapho 
// Github - https://github.com/Bapho
// ShaderToy - https://www.shadertoy.com/user/Bapho
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
/*
   Hyllian's Fast Bilateral Shader
   
   Source:
   https://github.com/libretro/glsl-shaders/blob/master/denoisers/shaders/fast-bilateral.glsl
   
   Copyright (C) 2011/2016 Hyllian - sergiogdb@gmail.com
   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is 
   furnished to do so, subject to the following conditions:
   The above copyright notice and this permission notice shall be included in
   all copies or substantial portions of the Software.
   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
   THE SOFTWARE.
*/
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

uniform float SIGMA_R <
    ui_type = "drag";
    ui_min = 0.01; ui_max = 1.0;
    ui_label = "Bilateral Blur";
> = 0.1;

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#include "ReShade.fxh"

#define BIL(M,K) {col=GET(M,K);ds=M*M+K*K;weight=exp(-ds/sd2)*exp(-(col-center)*(col-center)/si2);color+=(weight*col);wsum+=weight;}

#define GET(M,K) (tex2D(ReShade::BackBuffer, tc + M * dx + K * dy).xyz)

float3 FastBilateral(float4 pos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
    float ds, sd2, si2;
    float sigma_d = 3.0;
    float sigma_r = SIGMA_R * 0.04;

    float3 color = float3(0.0, 0.0, 0.0);
    float3 wsum = float3(0.0, 0.0, 0.0);
    float3 weight;
    
    float2 dx = float2(1.0, 0.0) * ReShade::PixelSize;
    float2 dy = float2(0.0, 1.0) * ReShade::PixelSize;
    
    sd2 = 2.0 * sigma_d * sigma_d;
    si2 = 2.0 * sigma_r * sigma_r;
      
    float2 tc = texcoord;
    
    float3 col;
    float3 center = GET(0., 0.);

    BIL(-2.,-2.);
    BIL(-1.,-2.);
    BIL( 0.,-2.);
    BIL( 1.,-2.);
    BIL( 2.,-2.);
    BIL(-2.,-1.);
    BIL(-1.,-1.);
    BIL( 0.,-1.);
    BIL( 1.,-1.);
    BIL( 2.,-1.);
    BIL(-2., 0.);
    BIL(-1., 0.);
    BIL( 0., 0.);
    BIL( 1., 0.);
    BIL( 2., 0.);
    BIL(-2., 1.);
    BIL(-1., 1.);
    BIL( 0., 1.);
    BIL( 1., 1.);
    BIL( 2., 1.);
    BIL(-2., 2.);
    BIL(-1., 2.);
    BIL( 0., 2.);
    BIL( 1., 2.);
    BIL( 2., 2.);

    // Weight normalization
    color /= wsum;
    
    return color;
}

technique FastBilateral
{
        pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = FastBilateral;
    }
}
