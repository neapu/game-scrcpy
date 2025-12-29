struct PS_INPUT {
    float4 Pos: SV_POSITION;
    float3 Tex: TEXCOORD;
};

Texture2D YTexture : register(t0);
Texture2D UTexture : register(t1);
Texture2D VTexture : register(t2);
SamplerState Sampler : register(s0);

float4 main(PS_INPUT input) : SV_TARGET {
    float y = YTexture.Sample(Sampler, input.Tex.xy).r;
    float u = UTexture.Sample(Sampler, input.Tex.xy).r - 0.5;
    float v = VTexture.Sample(Sampler, input.Tex.xy).r - 0.5;

    float3 rgb;
    rgb.r = y + 1.402 * v;
    rgb.g = y - 0.344136 * u - 0.714136 * v;
    rgb.b = y + 1.772 * u;

    return float4(rgb, 1.0);
}