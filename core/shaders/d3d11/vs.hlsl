struct VS_INPUT {
    float3 Pos: POSITION;
    float3 Tex: TEXCOORD;
};

struct VS_OUTPUT {
    float4 Pos: SV_POSITION;
    float3 Tex: TEXCOORD;
};

VS_OUTPUT main(VS_INPUT input) {
    VS_OUTPUT output;
    output.Pos = float4(input.Pos, 1.0);
    output.Tex = input.Tex;
    return output;
}