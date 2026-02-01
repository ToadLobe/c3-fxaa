/////////////////////////////////////////////////////////
// FXAA
// From https://www.shadertoy.com/view/4tf3D8 by 4rknova
precision mediump float;
//The current foreground texture co-ordinate
varying mediump vec2 vTex;
//The foreground texture sampler, to be sampled at vTex
uniform lowp sampler2D samplerFront;
//The current foreground source rectangle being rendered
uniform mediump vec2 srcOriginStart;
uniform mediump vec2 srcOriginEnd;
//The current foreground source rectangle being rendered, in layout 
uniform mediump vec2 layoutStart;
uniform mediump vec2 layoutEnd;
//The current background rectangle being rendered to, in texture co-ordinates, for background-blending effects
uniform mediump vec2 destStart;
uniform mediump vec2 destEnd;
//The size of a texel in the foreground texture in texture co-ordinates
uniform mediump vec2 pixelSize;
//The current layer scale as a factor (i.e. 1 is unscaled)
uniform mediump float layerScale;
//The current layer angle in radians.
uniform mediump float layerAngle;

// by Nikos Papadopoulos, 4rknova / 2015

// #define RES vec2(xResolution,yResolution)
#define RES vec2(1./pixelSize.x,1./pixelSize.y)

vec3 fxaa(vec2 p)
{
	  float FXAA_SPAN_MAX   = 8.0;
    float FXAA_REDUCE_MUL = 1.0 / 8.0;
    float FXAA_REDUCE_MIN = 1.0 / 128.0;

    // 1st stage - Find edge
    vec3 rgbNW = texture2D(samplerFront,p + (vec2(-1.,-1.) / RES)).rgb;
    vec3 rgbNE = texture2D(samplerFront,p + (vec2( 1.,-1.) / RES)).rgb;
    vec3 rgbSW = texture2D(samplerFront,p + (vec2(-1., 1.) / RES)).rgb;
    vec3 rgbSE = texture2D(samplerFront,p + (vec2( 1., 1.) / RES)).rgb;
    vec3 rgbM  = texture2D(samplerFront,p).rgb;

    vec3 luma = vec3(0.299, 0.587, 0.114);

    float lumaNW = dot(rgbNW, luma);
    float lumaNE = dot(rgbNE, luma);
    float lumaSW = dot(rgbSW, luma);
    float lumaSE = dot(rgbSE, luma);
    float lumaM  = dot(rgbM,  luma);

    vec2 dir;
    dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
    dir.y =  ((lumaNW + lumaSW) - (lumaNE + lumaSE));
    
    float lumaSum   = lumaNW + lumaNE + lumaSW + lumaSE;
    float dirReduce = max(lumaSum * (0.25 * FXAA_REDUCE_MUL), FXAA_REDUCE_MIN);
    float rcpDirMin = 1. / (min(abs(dir.x), abs(dir.y)) + dirReduce);

    dir = min(vec2(FXAA_SPAN_MAX), max(vec2(-FXAA_SPAN_MAX), dir * rcpDirMin)) / RES;

    // 2nd stage - Blur
    vec3 rgbA = .5 * (texture2D(samplerFront,p + dir * (1./3. - .5)).rgb +
        			  texture2D(samplerFront,p + dir * (2./3. - .5)).rgb);
    vec3 rgbB = rgbA * .5 + .25 * (
        			  texture2D(samplerFront,p + dir * (0./3. - .5)).rgb +
        			  texture2D(samplerFront,p + dir * (3./3. - .5)).rgb);
    
    float lumaB = dot(rgbB, luma);
    
    float lumaMin = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));
    float lumaMax = max(lumaM, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE)));

    return ((lumaB < lumaMin) || (lumaB > lumaMax)) ? rgbA : rgbB;
}

void main()
{
	// vec2 uv = (fragCoord.xy / iResolution.xy * 2. - 1.);
	// vec2 nv = uv * vec2(iResolution.x/iResolution.y, 1) * .4 + .05;
  // vec2 iResolution = vec2(1./pixelSize.x,1./pixelSize.y);    
  // vec2 iResolution = vec2(1280.,720.);
  // Normalize for spritesheeting
  // vec2 vTexN = (vTex-srcOriginStart)/(srcOriginEnd-srcOriginStart);
  // place 0,0 in center from -1 to 1 ndc
  // vec2 uv = vTexN * 2./iResolution.xy - 1.;
  // vec2 uv = vTexN * 2. - 1.;
            
  vec3  col = fxaa(vTex);

  float a = texture2D(samplerFront,vTex).a;    
	gl_FragColor = vec4(col, a);
}