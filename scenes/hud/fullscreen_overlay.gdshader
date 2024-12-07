// CRT shader, for Godot 4.x
// This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to
//  Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
// Adapted from https://www.shadertoy.com/view/4sSGDK
//
// Loosely based on postprocessing shader by inigo quilez, License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// See https://docs.godotengine.org/en/4.1/tutorials/shaders/custom_postprocessing.html for instructions on how to use this shader.
// --------------------------------------------------------------------------------------------------------------------------------------------

shader_type canvas_item;

const vec2 iResolution = vec2(1920,1080);
uniform sampler2D InputTexture : hint_screen_texture, repeat_disable, filter_nearest;
uniform bool curved_display = true;
uniform bool vignette = true;
uniform bool vlines = true;
uniform bool flicker = true;
uniform bool noise = true;
uniform bool tonemap = true;
uniform bool glow = true;
uniform bool ghosting = true;
uniform bool scanlines = true;
uniform bool level_adjustment = true;
uniform bool wiggle = true;
uniform bool bleed = true;
uniform float timer_multiplier = 1.0;

uniform float horizontal_chromatic_abberation_r = 0.0009;
uniform float horizontal_chromatic_abberation_g = 0.0000;
uniform float horizontal_chromatic_abberation_b = -0.0015;
uniform float vertical_chromatic_abberation_r = 0.0009;
uniform float vertical_chromatic_abberation_g = -0.0011;
uniform float vertical_chromatic_abberation_b = 0.0000;

vec3 xsample( sampler2D tex, vec2 tc )
{
  vec3 s = pow(texture(tex,vec2(tc.x, tc.y)).rgb, vec3(2.2));
  return s;
}

vec3 filmic( vec3 LinearColor )
{
  vec3 x = max(vec3(0.0), LinearColor-0.004);
  return (x*(6.2*x+0.5))/(x*(6.2*x+1.7)+0.06);
}

vec3 blur(sampler2D tex, vec2 tc, float offs)
{
  vec4 xoffs = offs * vec4(-2.0, -1.0, 1.0, 2.0) / iResolution.x;
  vec4 yoffs = offs * vec4(-2.0, -1.0, 1.0, 2.0) / iResolution.y;
  
  vec3 color = vec3(0.0, 0.0, 0.0);
  color += xsample(tex,tc + vec2(xoffs.x, yoffs.x)) * 0.00366;
  color += xsample(tex,tc + vec2(xoffs.y, yoffs.x)) * 0.01465;
  color += xsample(tex,tc + vec2(    0.0, yoffs.x)) * 0.02564;
  color += xsample(tex,tc + vec2(xoffs.z, yoffs.x)) * 0.01465;
  color += xsample(tex,tc + vec2(xoffs.w, yoffs.x)) * 0.00366;
  
  color += xsample(tex,tc + vec2(xoffs.x, yoffs.y)) * 0.01465;
  color += xsample(tex,tc + vec2(xoffs.y, yoffs.y)) * 0.05861;
  color += xsample(tex,tc + vec2(    0.0, yoffs.y)) * 0.09524;
  color += xsample(tex,tc + vec2(xoffs.z, yoffs.y)) * 0.05861;
  color += xsample(tex,tc + vec2(xoffs.w, yoffs.y)) * 0.01465;
  
  color += xsample(tex,tc + vec2(xoffs.x, 0.0)) * 0.02564;
  color += xsample(tex,tc + vec2(xoffs.y, 0.0)) * 0.09524;
  color += xsample(tex,tc + vec2(    0.0, 0.0)) * 0.15018;
  color += xsample(tex,tc + vec2(xoffs.z, 0.0)) * 0.09524;
  color += xsample(tex,tc + vec2(xoffs.w, 0.0)) * 0.02564;
  
  color += xsample(tex,tc + vec2(xoffs.x, yoffs.z)) * 0.01465;
  color += xsample(tex,tc + vec2(xoffs.y, yoffs.z)) * 0.05861;
  color += xsample(tex,tc + vec2(    0.0, yoffs.z)) * 0.09524;
  color += xsample(tex,tc + vec2(xoffs.z, yoffs.z)) * 0.05861;
  color += xsample(tex,tc + vec2(xoffs.w, yoffs.z)) * 0.01465;
  
  color += xsample(tex,tc + vec2(xoffs.x, yoffs.w)) * 0.00366;
  color += xsample(tex,tc + vec2(xoffs.y, yoffs.w)) * 0.01465;
  color += xsample(tex,tc + vec2(    0.0, yoffs.w)) * 0.02564;
  color += xsample(tex,tc + vec2(xoffs.z, yoffs.w)) * 0.01465;
  color += xsample(tex,tc + vec2(xoffs.w, yoffs.w)) * 0.00366;

  return color;
}

//Credit: http://stackoverflow.com/questions/4200224/random-noise-functions-for-glsl
float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

vec2 curve(vec2 uv)
{
  uv = (uv - 0.5) * 2.0;
  uv *= 1.1;
  uv.x *= 1.0 + pow((abs(uv.y) / 5.0), 2.0);
  uv.y *= 1.0 + pow((abs(uv.x) / 4.0), 2.0);
  uv  = (uv / 2.0) + 0.5;
  uv =  uv *0.92 + 0.04;
  return uv;
}

void fragment()
{
  // Set up variables to be used further along, these primarily provide compatibility with the original codebase and Godot's shader specifics
  float Timer = TIME * timer_multiplier;
  vec2 FragCoord = SCREEN_UV;
  vec2 q = FragCoord.xy;
  vec2 uv = q;
  if (curved_display) {
    uv = mix( curve( uv ), uv, 0.5 );
  }
  vec3 oricol = texture( InputTexture, vec2(q.x,q.y) ).xyz;
    
  // Main color, Bleed
  vec3 col = oricol;
  float x = sin(0.1*Timer+uv.y*13.0)*sin(0.23*Timer+uv.y*19.0)*sin(0.3+0.11*Timer+uv.y*23.0)*0.0012;
  float o = sin(FragCoord.y*1.5)/iResolution.x;
  x+=o*0.25;
  if (!wiggle) {
    x = 0.0;
  }
  if (bleed) {
    col.r = blur(InputTexture,vec2(x+uv.x+horizontal_chromatic_abberation_r,uv.y+vertical_chromatic_abberation_r),iResolution.y/800.0).x+0.02;
    col.g = blur(InputTexture,vec2(x+uv.x+horizontal_chromatic_abberation_g,uv.y+vertical_chromatic_abberation_g),iResolution.y/800.0).y+0.02;
    col.b = blur(InputTexture,vec2(x+uv.x+horizontal_chromatic_abberation_b,uv.y+vertical_chromatic_abberation_b),iResolution.y/800.0).z+0.02;
  }
  float i = clamp(col.r*0.299 + col.g*0.587 + col.b*0.114, 0.0, 1.0 );
  
  // Glow
  vec3 glow_v = (12.5*i*i)*pow(clamp(blur(InputTexture,vec2(x+uv.x+0.2*sin(uv.x + 10.0*Timer)*0.012,uv.y + 0.2*sin( uv.y + 7.3*Timer)*0.012),4.0)-0.3,0.0,1.0),vec3(5.0));
  glow_v = 0.75*clamp( glow_v, 0.0, 1.0 );
  if (glow) {
    col += glow_v;
  }
  
  i = pow( 1.0 - pow(i,2.0), 1.0 );
  i = (1.0-i) * 0.96 + 0.04;

  // Ghosting
  float ghs = 0.6;
  vec3 r = blur(InputTexture,vec2(x-0.014*1.0, -0.027)+0.003*vec2( 0.35*sin(1.0/7.0 + 35.0*uv.y + 0.9*Timer), 0.55*sin( 2.0/7.0 + 10.0*uv.y + 2.37*Timer) )+vec2(uv.x+0.001,uv.y+0.001),5.5+1.3*sin( 3.0/9.0 + 31.0*uv.y + 1.70*Timer)).xyz*vec3(0.5,0.25,0.25);
  vec3 g = blur(InputTexture,vec2(x-0.019*1.0, -0.020)+0.003*vec2( 0.35*sin(1.0/9.0 + 35.0*uv.y + 0.5*Timer), 0.55*sin( 2.0/9.0 + 10.0*uv.y + 2.50*Timer) )+vec2(uv.x+0.000,uv.y-0.002),5.4+1.3*sin( 3.0/3.0 + 71.0*uv.y + 1.90*Timer)).xyz*vec3(0.25,0.5,0.25);
  vec3 b = blur(InputTexture,vec2(x-0.017*1.0, -0.003)+0.003*vec2( 0.35*sin(2.0/3.0 + 35.0*uv.y + 0.7*Timer), 0.55*sin( 2.0/3.0 + 10.0*uv.y + 2.63*Timer) )+vec2(uv.x-0.002,uv.y+0.000),5.3+1.3*sin( 3.0/7.0 + 91.0*uv.y + 1.65*Timer)).xyz*vec3(0.25,0.25,0.5);
  if (ghosting) {
    col += vec3(ghs*(1.0-0.299))*pow(clamp(3.0*r,0.0,1.0),vec3(2.0))*i;
    col += vec3(ghs*(1.0-0.587))*pow(clamp(3.0*g,0.0,1.0),vec3(2.0))*i;
    col += vec3(ghs*(1.0-0.114))*pow(clamp(3.0*b,0.0,1.0),vec3(2.0))*i;
  }
  
  // Level adjustment (curves)
  if (level_adjustment) {
    col = clamp(col*1.7 + 1.4*col*col + 2.5*col*col*col*col*col,0.0,10.0);
  }
  
  // Vignette
  if (vignette) {
    float vig = (0.1 + 1.0*16.0*uv.x*uv.y*(1.0-uv.x)*(1.0-uv.y));
    vig = 1.0*pow(vig,0.5);
    col *= vec3(vig);
  }

  // Scanlines
  if (scanlines) {
    float scans = clamp(0.35+0.18*sin(6.0*Timer+uv.y*iResolution.y*1.5), 0.0, 1.0);
    float s = pow(scans, 0.9);
    col = col*vec3(s);
  }

  // Vertical lines (aperture)
  if (vlines) {
    col*=1.0-0.23*vec3(clamp((mod(VERTEX.x, 2.0)-1.0)*2.0,0.0,1.0));
  }

  // Flicker
  if (flicker) {
    col *= 1.0+0.0017*sin(300.0*Timer);
  }

  // Noise
  if (noise) {
    vec2 seed = floor(uv*iResolution.xy*0.5)/iResolution.xy;
    col *= vec3( 1.0 ) - 0.15*vec3( rand( seed+0.00001*Timer),  rand( seed+0.000011*Timer + 0.3 ),  rand( seed+0.000012*Timer+ 0.5 )  );
  }
  
  // Tone map
  if (tonemap) {
    col = filmic(col);
  }

  // Clamp
  if (uv.x < 0.0 || uv.x > 1.0)
    col *= 0.0;
  if (uv.y < 0.0 || uv.y > 1.0)
    col *= 0.0;
  
  COLOR = vec4(col,1.0);
}
