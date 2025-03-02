   mirror      SAMPLER    +         postprocess_base.vs�   // Vertex shader

attribute vec3 POSITION;
attribute vec2 TEXCOORD0;

varying vec2 PS_TEXCOORD0;

void main()
{
	gl_Position = vec4(POSITION.xyz, 1.0);
	PS_TEXCOORD0.xy = TEXCOORD0.xy;
} 	   mirror.fs	  #ifdef GL_ES
precision mediump float;
#endif

uniform sampler2D SAMPLER[2]; // Required for post processing shaders, holds samplers, [0] is always the CURRENT screen render
#define SRC_IMAGE      SAMPLER[0] // CURRENT screen render, before applying this shader
#define MASKED_SAMPLER SAMPLER[1] // The "cutout" of the ent

#define WINDOW_WIDTH  SCREEN_PARAMS.x // 屏幕宽度
#define WINDOW_HEIGHT SCREEN_PARAMS.y // 屏幕高度
#define SCREEN_CENTER vec2(0.5, 0.5) // 屏幕中心点坐标（归一化）

varying vec2 PS_TEXCOORD0; // 当前像素的位置，范围[0.0, 1.0]

void main()
{
    vec4 bgColor = texture2D(SRC_IMAGE, PS_TEXCOORD0.xy); // Here we're picking from the sampler of the original screen render, this is what we will modify
                                                          // texture2D() - Virtually the same as https://registry.khronos.org/OpenGL-Refpages/gl4/html/texture.xhtml
                                                          //               but only accepts sampler2D
    vec4 textureColor = texture2D(MASKED_SAMPLER, PS_TEXCOORD0.xy); 
    vec4 textureColorR = texture2D(MASKED_SAMPLER, vec2(1.0-PS_TEXCOORD0.x, PS_TEXCOORD0.y));
    vec4 textureColorL = texture2D(MASKED_SAMPLER, vec2(PS_TEXCOORD0.x, 1.0-PS_TEXCOORD0.y));
    vec4 textureColorU = texture2D(MASKED_SAMPLER, vec2(1.0-PS_TEXCOORD0.x, 1.0-PS_TEXCOORD0.y)); 

    textureColorR.a = 0.8*textureColorR.a;
    textureColorL.a = 0.8*textureColorL.a;
    textureColorU.a = 0.8*textureColorU.a;
                                                                                                       

    // gl_FragColor is our pixel output
    gl_FragColor = bgColor; // First we set the entire screen to the unmodified one
    gl_FragColor.rgb = mix(gl_FragColor.rgb, textureColor.rgb, textureColor.a); // Then we apply the modified version of our entity
                                                                                // Make sure to mix based on the "cutouts" alpha value

    gl_FragColor.rgb = mix(gl_FragColor.rgb, textureColorR.rgb, textureColorR.a); // Now mix the right mirror image  
    gl_FragColor.rgb = mix(gl_FragColor.rgb, textureColorL.rgb, textureColorL.a);
    gl_FragColor.rgb = mix(gl_FragColor.rgb, textureColorU.rgb, textureColorU.a);
 
}            