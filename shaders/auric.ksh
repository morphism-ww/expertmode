   auric      MatrixP                                                                                MatrixV                                                                                MatrixW                                                                             
   TIMEPARAMS                                SAMPLER    +         auric.vs  uniform mat4 MatrixP;
uniform mat4 MatrixV;
uniform mat4 MatrixW;
uniform vec4 TIMEPARAMS;


attribute vec4 POS2D_UV; // x, y, u + samplerIndex * 2, v

varying vec3 PS_TEXCOORD;
varying vec3 PS_POS;



void main()
{
    vec3 POSITION = vec3(POS2D_UV.xy, 0);
	// Take the samplerIndex out of the U.
    float samplerIndex = floor(POS2D_UV.z/2.0);
    vec3 TEXCOORD0 = vec3(POS2D_UV.z - 2.0*samplerIndex, POS2D_UV.w, samplerIndex);

	vec3 object_pos = POSITION.xyz;
	vec4 world_pos = MatrixW * vec4( object_pos, 1.0 );

	mat4 mtxPV = MatrixP * MatrixV;
	gl_Position = mtxPV * world_pos;
	

	PS_TEXCOORD = TEXCOORD0;
	PS_POS = world_pos.xyz;
}    auric.fs¼  #ifdef GL_ES
precision mediump float;
#endif


uniform vec4 TIMEPARAMS;
uniform sampler2D SAMPLER[1];

varying vec3 PS_TEXCOORD;


const vec3 BLUE_COLOR = vec3(0.5294,0.807,1.0);
const vec3 DEEP_BLUE = vec3(0.117,0.564,1.0);
const vec3 GOLD_COLOR = vec3(1.0, 0.874, 0.0);
const vec3 GREEN_COLOR = vec3(0.0,0.545,0.545);
const vec3 PINK_COLOR = vec3(1.0,0.07,0.57);


void main()
{   

    vec4 baseColor = texture2D(SAMPLER[0], PS_TEXCOORD.xy);

    // çææ¡çº¹ææ
    float stripe = mod(PS_TEXCOORD.x * 1.5  + TIMEPARAMS.x * 1.5,1.0);
    stripe = 1.1*stripe * step(0.9,stripe) * step(0.1,baseColor.a);

    float flicker = abs(sin(PS_TEXCOORD.y * 6.1));

    vec3 blue = mix(GREEN_COLOR,DEEP_BLUE,flicker);

    // å°æ¡çº¹é¢è²ä¸åºç¡é¢è²æ··åï¼å¹¶åºç¨éªçææ
    vec3 finalColor = mix(baseColor.rgb, blue, stripe);

    // è¾åºæç»é¢è²
    gl_FragColor = vec4(finalColor, baseColor.a);
}                       