   misc      SAMPLER    +         misc.vs&  attribute vec3 POSITION;
attribute vec2 TEXCOORD0;


varying vec2 PS_TEXCOORD0;
varying vec2 PS_TEXCOORD1;
varying vec2 PS_TEXCOORD2;
varying vec2 PS_TEXCOORD3;


void main()
{
    gl_Position = vec4( POSITION.xyz, 1.0 ); //整个屏幕都要用的情况.
    PS_TEXCOORD0.xy = TEXCOORD0.xy;

    PS_TEXCOORD1.x = 1.0 - TEXCOORD0.x;
    PS_TEXCOORD1.y = TEXCOORD0.y;

    PS_TEXCOORD2.x = TEXCOORD0.x;
    PS_TEXCOORD2.y = 1.0 - TEXCOORD0.y;

    PS_TEXCOORD3.x = 1.0 - TEXCOORD0.x;
    PS_TEXCOORD3.y = 1.0 - TEXCOORD0.y;

}    misc.fsH  #ifdef GL_ES
precision mediump float;
#endif



uniform sampler2D SAMPLER[1];

varying vec2 PS_TEXCOORD0;
varying vec2 PS_TEXCOORD1;
varying vec2 PS_TEXCOORD2;
varying vec2 PS_TEXCOORD3;
#define baseSampler SAMPLER[0]

void main()
{   

    //判断坐标范围
    vec4 color0 = texture2D(baseSampler,PS_TEXCOORD0.xy);
    vec4 color1 = texture2D(baseSampler,PS_TEXCOORD1.xy);
    vec4 color2 = texture2D(baseSampler,PS_TEXCOORD2.xy);
    vec4 color3 = texture2D(baseSampler,PS_TEXCOORD3.xy);

    gl_FragColor = 0.25 * (color0 + color1 + color2 + color3);
}            