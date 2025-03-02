   adamantitepulse   
   TIMEPARAMS                                SAMPLER    +         SCREEN_PARAMS                                postprocess_base.vs�   // Vertex shader

attribute vec3 POSITION;
attribute vec2 TEXCOORD0;

varying vec2 PS_TEXCOORD0;

void main()
{
	gl_Position = vec4(POSITION.xyz, 1.0);
	PS_TEXCOORD0.xy = TEXCOORD0.xy;
}    adamantitepulse.ps�  // Fragment shader

#ifdef GL_ES
    precision highp float; // Sets the precision of the float, not important in the long run, possible values include lowp, mediump, highp
#endif

uniform vec4 TIMEPARAMS; // TIMEPARAMS.x holds the games time

uniform sampler2D SAMPLER[2]; // Required for post processing shaders, holds samplers, [0] is always the CURRENT screen render
#define SRC_IMAGE      SAMPLER[0] // CURRENT screen render, before applying this shader
#define MASKED_SAMPLER SAMPLER[1] // The "cutout" of the entity affected by this shader

uniform vec4 SCREEN_PARAMS; // SCREEN_PARAMS holds information about the screen size (in pixels)
#define WINDOW_WIDTH  SCREEN_PARAMS.x // Screens width
#define WINDOW_HEIGHT SCREEN_PARAMS.y // Screens height
#define SCREEN_RATIO WINDOW_WIDTH / WINDOW_HEIGHT // Calculate the width/height ratio

varying vec2 PS_TEXCOORD0; // Current pixels position, (x, y), values [0.0, 1.0] for x and y where x is the horizontal position 0.0 - left, 1.0 - right
                           // and y is the vertical position 0.0 - bottom, 1.0 - top

void main()
{
    vec4 bgColor = texture2D(SRC_IMAGE, PS_TEXCOORD0.xy); // Here we're picking from the sampler of the original screen render, this is what we will modify
                                                          // texture2D() - Virtually the same as https://registry.khronos.org/OpenGL-Refpages/gl4/html/texture.xhtml
                                                          //               but only accepts sampler2D
    vec4 textureColor = texture2D(MASKED_SAMPLER, PS_TEXCOORD0.xy); // Here we're picking the color of the "cutout", so, our affected entity
                                                                    // We will apply the shader only in this area
    // We'll create 4 mirror images of the entity, we can achieve this by offsetting the pixel coordinates
    vec4 textureColorR = texture2D(MASKED_SAMPLER, PS_TEXCOORD0.xy +                            // We're gonna pick from the same "cutout" sampler
                                                   vec2(0.005 * sin(TIMEPARAMS.x * 8.0), 0.0)); // Here we're offsetting the coordinates on the X axis by
                                                                                                // 0.005 * sin(TIMEPARAMS.x * 8.0) where the sin function
                                                                                                // gives us the oscillating effect based on passed time
                                                                                                // sin() - https://registry.khronos.org/OpenGL-Refpages/gl4/html/sin.xhtml
    // Repeat for the other 3 mirror images changing the offset
    vec4 textureColorL = texture2D(MASKED_SAMPLER, PS_TEXCOORD0.xy + vec2(-0.005 * sin(TIMEPARAMS.x * 8.0), 0.0));
    vec4 textureColorU = texture2D(MASKED_SAMPLER, PS_TEXCOORD0.xy + vec2(0.0,  0.005 * sin(TIMEPARAMS.x * 8.0) * SCREEN_RATIO)); // Make sure to multiply the y offset
    vec4 textureColorD = texture2D(MASKED_SAMPLER, PS_TEXCOORD0.xy + vec2(0.0, -0.005 * sin(TIMEPARAMS.x * 8.0) * SCREEN_RATIO)); // by the screen width/height ratio otherwise
                                                                                                                                  // the effect will look stretched on the x axis
    textureColorR.a = max(textureColorR.a - 0.5, 0.0); // Lowering the opacity, using max() to keep it from going below 0.0
    textureColorL.a = max(textureColorL.a - 0.5, 0.0); // max() - https://registry.khronos.org/OpenGL-Refpages/gl4/html/max.xhtml
    textureColorU.a = max(textureColorU.a - 0.5, 0.0);
    textureColorD.a = max(textureColorD.a - 0.5, 0.0);

    // gl_FragColor is our pixel output
    gl_FragColor = bgColor; // First we set the entire screen to the unmodified one
    gl_FragColor.rgb = mix(gl_FragColor.rgb, textureColor.rgb, textureColor.a); // Then we apply the modified version of our entity
                                                                                // Make sure to mix based on the "cutouts" alpha value

    if(textureColor.a <= 0.5) // To place the mirror images behind the real entity only modify when the originals alpha value is lower than 0.5
    {
        gl_FragColor.rgb = mix(gl_FragColor.rgb, textureColorR.rgb, textureColorR.a); // Now mix the right mirror image
        gl_FragColor.rgb = mix(gl_FragColor.rgb, textureColorL.rgb, textureColorL.a); // Then the left one
        gl_FragColor.rgb = mix(gl_FragColor.rgb, textureColorU.rgb, textureColorU.a); // Then the up one
        gl_FragColor.rgb = mix(gl_FragColor.rgb, textureColorD.rgb, textureColorD.a); // Then the down one
    }
}                  