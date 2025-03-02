   postprocess_mirror_masked      SAMPLER_PARAMS                                SAMPLER    +         postprocess_base.vs�   // Vertex shader

attribute vec3 POSITION;
attribute vec2 TEXCOORD0;

varying vec2 PS_TEXCOORD0;

void main()
{
	gl_Position = vec4(POSITION.xyz, 1.0);
	PS_TEXCOORD0.xy = TEXCOORD0.xy;
}    postprocess_mirror_masked.fsq  
    #ifdef GL_ES
    precision highp float;
#endif

uniform vec4 SAMPLER_PARAMS;
#define PIXEL_SIZE_W SAMPLER_PARAMS.z
#define PIXEL_SIZE_H SAMPLER_PARAMS.w

uniform sampler2D SAMPLER[2];
#define BLOOM_SAMPLER SAMPLER[0]
#define POSTPROCESS_SAMPLER SAMPLER[1]

#define MASK_COLOR_FLOOR vec3(0.015,0.005,0.005) // Gets overriden by the generator
#define MASK_COLOR_CEIL vec3(0.025,0.015,0.015)  // Gets overriden by the generator

varying vec2 PS_TEXCOORD0;

void main() // [TODO]? Write a better system for outlining
{
    vec2 coord = PS_TEXCOORD0.xy;
    vec4 mask = texture2D(BLOOM_SAMPLER, coord);

    if(mask.r > MASK_COLOR_FLOOR.x && mask.r < MASK_COLOR_CEIL.x
    && mask.g > MASK_COLOR_FLOOR.y && mask.g < MASK_COLOR_CEIL.y
    && mask.b > MASK_COLOR_FLOOR.z && mask.b < MASK_COLOR_CEIL.z)
    {
        int dist = 0;
        for(int i = -1; i <= 1; i++)
        {
            for(int j = -1; j <= 1; j++)
            {
                if(texture2D(BLOOM_SAMPLER,
                                vec2(coord.x + float(i) * PIXEL_SIZE_W,
                                     coord.y - float(j) * PIXEL_SIZE_H)).rgb == vec3(0.0, 0.0, 0.0))
                {
                    dist = 1;
                }
            }
        }

        if(dist == 0)
        {
            for(int i = -2; i <= 2; i++)
            {
                for(int j = -2; j <= 2; j++)
                {
                    if(texture2D(BLOOM_SAMPLER,
                                    vec2(coord.x + float(i) * PIXEL_SIZE_W,
                                         coord.y - float(j) * PIXEL_SIZE_H)).rgb == vec3(0.0, 0.0, 0.0))
                    {
                        dist = 2;
                    }
                }
            }
        }

        if(dist == 0)
        {
            for(int i = -3; i <= 3; i++)
            {
                for(int j = -3; j <= 3; j++)
                {
                    if(texture2D(BLOOM_SAMPLER,
                                    vec2(coord.x + float(i) * PIXEL_SIZE_W,
                                         coord.y - float(j) * PIXEL_SIZE_H)).rgb == vec3(0.0, 0.0, 0.0))
                    {
                        dist = 3;
                    }
                }
            }
        }

        if(dist == 1)
        {
            gl_FragColor = vec4(texture2D(POSTPROCESS_SAMPLER, coord).rgb * 0.5, 0.5);
        }
        else if(dist == 2)
        {
            gl_FragColor = vec4(texture2D(POSTPROCESS_SAMPLER, coord).rgb * 0.8, 0.8);
        }
        else if(dist == 3)
        {
            gl_FragColor = vec4(texture2D(POSTPROCESS_SAMPLER, coord).rgb * 0.9, 0.9);
        }
        else
        {
            gl_FragColor = vec4(texture2D(POSTPROCESS_SAMPLER, coord).rgb      , 1.0);
        }
    }
    else
    {
        gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
    }
}
               