/////////////////////////////////////////////////////////
// FXAA

// Foreground texture and sampler bindings
%%TEXTUREFRONT_BINDING%%
%%SAMPLERFRONT_BINDING%%

// Construct-provided parameters and utilities
%%C3PARAMS_STRUCT%%
%%C3_UTILITY_FUNCTIONS%%

// Fragment shader input/output
%%FRAGMENTINPUT_STRUCT%%
%%FRAGMENTOUTPUT_STRUCT%%

// Luma coefficients for edge detection
const luma : vec3<f32> = vec3<f32>(0.299, 0.587, 0.114);

fn fxaa(p: vec2<f32>) -> vec4<f32> {
  const FXAA_SPAN_MAX : f32 = 8.0;
  const FXAA_REDUCE_MUL : f32 = 1.0 / 8.0;
  const FXAA_REDUCE_MIN : f32 = 1.0 / 128.0;
  const BLEND_1 : f32 = 1.0 / 3.0 - 0.5;
  const BLEND_2 : f32 = 2.0 / 3.0 - 0.5;
  const BLEND_3 : f32 = -0.5;

  // Step 1: Edge Detection
  let pixelSize : vec2<f32> = c3_getPixelSize(textureFront);

  let rgbNW : vec3<f32> = textureSample(textureFront, samplerFront, p + vec2<f32>(-1.0, -1.0) * pixelSize).rgb;
  let rgbNE : vec3<f32> = textureSample(textureFront, samplerFront, p + vec2<f32>(1.0, -1.0) * pixelSize).rgb;
  let rgbSW : vec3<f32> = textureSample(textureFront, samplerFront, p + vec2<f32>(-1.0, 1.0) * pixelSize).rgb;
  let rgbSE : vec3<f32> = textureSample(textureFront, samplerFront, p + vec2<f32>(1.0, 1.0) * pixelSize).rgb;
  let rgbaM : vec4<f32> = textureSample(textureFront, samplerFront, p);
  let rgbM : vec3<f32> = rgbaM.rgb;

  let lumaNW : f32 = dot(rgbNW, luma);
  let lumaNE : f32 = dot(rgbNE, luma);
  let lumaSW : f32 = dot(rgbSW, luma);
  let lumaSE : f32 = dot(rgbSE, luma);
  let lumaM : f32 = dot(rgbM, luma);

  var dir : vec2<f32>;
  dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
  dir.y = ((lumaNW + lumaSW) - (lumaNE + lumaSE));

  let lumaSum : f32 = lumaNW + lumaNE + lumaSW + lumaSE;
  let dirReduce : f32 = max(lumaSum * (0.25 * FXAA_REDUCE_MUL), FXAA_REDUCE_MIN);
  let rcpDirMin : f32 = 1.0 / (min(abs(dir.x), abs(dir.y)) + dirReduce);
  dir = min(vec2<f32>(FXAA_SPAN_MAX), max(vec2<f32>(-FXAA_SPAN_MAX), dir * rcpDirMin)) * pixelSize;

  // Step 2: Blend Samples
  let rgbA : vec3<f32> = 0.5 * (textureSample(textureFront, samplerFront, p + dir * BLEND_1).rgb + textureSample(textureFront, samplerFront, p + dir * BLEND_2).rgb);
  let rgbB : vec3<f32> = rgbA * 0.5 + 0.25 * (textureSample(textureFront, samplerFront, p + dir * BLEND_3).rgb + textureSample(textureFront, samplerFront, p + dir * 0.5).rgb);
  let lumaB : f32 = dot(rgbB, luma);

  let lumaMin : f32 = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));
  let lumaMax : f32 = max(lumaM, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE)));

  var finalRgb : vec3<f32>;
  if ((lumaB < lumaMin) || (lumaB > lumaMax)) {
    finalRgb = rgbA;
  } else {
    finalRgb = rgbB;
  }

  return vec4<f32>(finalRgb, rgbaM.a);
}

// Refactored by Pablo Galbraith
// Ported by Nikos Papadopoulos
// Shader written by 4rknova

@fragment
fn main(input: FragmentInput) -> FragmentOutput {
  var output: FragmentOutput;
  output.color = fxaa(input.fragUV);
  return output;
}
