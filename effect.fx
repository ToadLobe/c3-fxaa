/////////////////////////////////////////////////////////
// FXAA
precision mediump float;
varying mediump vec2 vTex; // The current foreground texture co-ordinate
uniform lowp sampler2D samplerFront; // The foreground texture sampler, to be sampled at vTex
uniform mediump vec2 pixelSize; // The size of a texel in the foreground texture in texture co-ordinates

const vec3 luma = vec3(0.299, 0.587, 0.114);

vec4 fxaa(vec2 p) {
  const float FXAA_SPAN_MAX = 8.0;
  const float FXAA_REDUCE_MUL = 1.0 / 8.0;
  const float FXAA_REDUCE_MIN = 1.0 / 128.0;
  const float BLEND_1 = 1.0 / 3.0 - 0.5;
  const float BLEND_2 = 2.0 / 3.0 - 0.5;
  const float BLEND_3 = -0.5;

  // Step 1: Edge Detection
  vec3 rgbNW = texture2D(samplerFront, p + vec2(-1., -1.) * pixelSize).rgb;
  vec3 rgbNE = texture2D(samplerFront, p + vec2(1., -1.) * pixelSize).rgb;
  vec3 rgbSW = texture2D(samplerFront, p + vec2(-1., 1.) * pixelSize).rgb;
  vec3 rgbSE = texture2D(samplerFront, p + vec2(1., 1.) * pixelSize).rgb;
  vec4 rgbaM = texture2D(samplerFront, p);
  vec3 rgbM = rgbaM.rgb;
  float lumaNW = dot(rgbNW, luma);
  float lumaNE = dot(rgbNE, luma);
  float lumaSW = dot(rgbSW, luma);
  float lumaSE = dot(rgbSE, luma);
  float lumaM = dot(rgbM, luma);
  vec2 dir;
  dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
  dir.y = ((lumaNW + lumaSW) - (lumaNE + lumaSE));
  float lumaSum = lumaNW + lumaNE + lumaSW + lumaSE;
  float dirReduce = max(lumaSum * (0.25 * FXAA_REDUCE_MUL), FXAA_REDUCE_MIN);
  float rcpDirMin = 1. / (min(abs(dir.x), abs(dir.y)) + dirReduce);
  dir = min(vec2(FXAA_SPAN_MAX), max(vec2(-FXAA_SPAN_MAX), dir * rcpDirMin)) * pixelSize;

  // Step 2: Blend Samples
  vec3 rgbA = .5 * (texture2D(samplerFront, p + dir * BLEND_1).rgb + texture2D(samplerFront, p + dir * BLEND_2).rgb);
  vec3 rgbB = rgbA * .5 + .25 * (texture2D(samplerFront, p + dir * BLEND_3).rgb + texture2D(samplerFront, p + dir * .5).rgb);
  float lumaB = dot(rgbB, luma);
  float lumaMin = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));
  float lumaMax = max(lumaM, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE)));
  vec3 finalRgb = ((lumaB < lumaMin) || (lumaB > lumaMax)) ? rgbA : rgbB;
  return vec4(finalRgb, rgbaM.a);
}

// Code by Pablo Galbraith, Nikos Papadopoulos & 4rknova

void main() {
  gl_FragColor = fxaa(vTex);
}