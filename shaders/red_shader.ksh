
   shadername
      MatrixP                                                                                MatrixV                                                                                MatrixW                                                                             
   TIMEPARAMS                                FLOAT_PARAMS                            SAMPLER    +         LIGHTMAP_WORLD_EXTENTS                                PARAMS                        OCEAN_BLEND_PARAMS                                OCEAN_WORLD_EXTENTS                                exampleVertexShader_test_1.vso  uniform mat4 MatrixP;
uniform mat4 MatrixV;
uniform mat4 MatrixW;
uniform vec4 TIMEPARAMS;
uniform vec3 FLOAT_PARAMS;

attribute vec4 POS2D_UV; // x, y, u + samplerIndex * 2, v

varying vec3 PS_TEXCOORD;
varying vec3 PS_POS;

#if defined( FADE_OUT )
    uniform mat4 STATIC_WORLD_MATRIX;
    varying vec2 FADE_UV;
#endif

void main()
{
    vec3 POSITION = vec3(POS2D_UV.xy, 0);
	// Take the samplerIndex out of the U.
    float samplerIndex = floor(POS2D_UV.z/2.0);
    vec3 TEXCOORD0 = vec3(POS2D_UV.z - 2.0*samplerIndex, POS2D_UV.w, samplerIndex);

	vec3 object_pos = POSITION.xyz;
	vec4 world_pos = MatrixW * vec4( object_pos, 1.0 );

	if(FLOAT_PARAMS.z > 0.0)
	{
		float world_x = MatrixW[3][0];
		float world_z = MatrixW[3][2];
		world_pos.y += sin(world_x + world_z + TIMEPARAMS.x * 3.0) * 0.025;
	}

	mat4 mtxPV = MatrixP * MatrixV;
	gl_Position = mtxPV * world_pos;
	

	PS_TEXCOORD = TEXCOORD0;
	PS_POS = world_pos.xyz;

	#if defined( FADE_OUT )
		vec4 static_world_pos = STATIC_WORLD_MATRIX * vec4( POSITION.xyz, 1.0 );
		vec3 forward = normalize( vec3( MatrixV[2][0], 0.0, MatrixV[2][2] ) );
		float d = dot( static_world_pos.xyz, forward );
		vec3 pos = static_world_pos.xyz + ( forward * -d );
		vec3 left = cross( forward, vec3( 0.0, 1.0, 0.0 ) );

		FADE_UV = vec2( dot( pos, left ) / 4.0, static_world_pos.y / 8.0 );
	#endif
}    examplePixelShader_test_1.psa  //ShaderCompiler.exe -little “shadername” “exampleVertexShader.vs” “examplePixelShader.ps” “shadername.ksh” -oglsl
//ThePlayer.AnimState:SetBloomEffectHandle(resolvefilepath("shaders/shadertest.ksh"))
#if defined(GL_ES)
	precision mediump float;
#endif

uniform vec4 TIMEPARAMS;
uniform mat4 MatrixW;
uniform sampler2D SAMPLER[5];

#ifndef LIGHTING_H
	#define LIGHTING_H

	// Lighting
	varying vec3 PS_POS;

	// xy = min, zw = max
	uniform vec4 LIGHTMAP_WORLD_EXTENTS;

	#define LIGHTMAP_TEXTURE SAMPLER[3]

	#ifndef LIGHTMAP_TEXTURE
		#error If you use lighting, you must #define the sampler that the lightmap belongs to
	#endif

	vec3 CalculateLightingContribution(){
		vec2 uv = (PS_POS.xz - LIGHTMAP_WORLD_EXTENTS.xy) * LIGHTMAP_WORLD_EXTENTS.zw;
		return texture2D(LIGHTMAP_TEXTURE, uv.xy).rgb;
	}

	vec3 CalculateLightingContribution(vec3 normal){
		return vec3( 1, 1, 1 );
	}

#endif //LIGHTING.h

varying vec3 PS_TEXCOORD;

uniform vec4 TINT_ADD;
uniform vec4 TINT_MULT;
uniform vec2 PARAMS;
uniform vec3 FLOAT_PARAMS;
uniform vec4 OCEAN_BLEND_PARAMS;
uniform vec3 CAMERARIGHT;

#define ALPHA_TEST PARAMS.x
#define LIGHT_OVERRIDE PARAMS.y

#if defined(FADE_OUT)
    uniform vec3 EROSION_PARAMS; 
    varying vec2 FADE_UV;

    #define ERODE_SAMPLER SAMPLER[2]
    #define EROSION_MIN EROSION_PARAMS.x
    #define EROSION_RANGE EROSION_PARAMS.y
    #define EROSION_LERP EROSION_PARAMS.z
#endif

uniform vec4 OCEAN_WORLD_EXTENTS;
#define OCEAN_SAMPLER SAMPLER[4]

vec3 colorRed    = vec3(1.0,0.0,0.0);
vec3 colorLime   = vec3(0.0,1.0,0.0);
vec3 colorGreen  = vec3(0.0,0.5,0.0);
vec3 colorBlue   = vec3(0.0,0.0,1.0);
vec3 colorYellow = vec3(1.0,1.0,0.0);
vec3 colorOrange = vec3(1.0,0.5,0.0);
vec3 colorPurple = vec3(0.5,0.0,0.5);
vec3 colorBlack  = vec3(0,0,0);
vec3 colorWhite  = vec3(1,1,1);

void main(){
	vec4 colour;
	//if(PS_TEXCOORD.z < 0.5){
		colour.rgba = texture2D(SAMPLER[0], PS_TEXCOORD.xy);
	//}else{
		//colour.rgba = texture2D(SAMPLER[1], PS_TEXCOORD.xy);
	//}

	if(FLOAT_PARAMS.y > 0.0){
		if(PS_POS.y < FLOAT_PARAMS.x){
			discard;
		}
	}

	if(colour.a >= ALPHA_TEST){
		gl_FragColor.rgba = colour.rgba;
		//gl_FragColor.rgba *= TINT_MULT.rgba;
		//gl_FragColor.rgb += vec3( TINT_ADD.rgb * colour.a );
		gl_FragColor.rgb = mix(gl_FragColor.rgb, colorRed, 0.8);

		#if defined(FADE_OUT)
			float height = texture2D(ERODE_SAMPLER, FADE_UV.xy).a;
			float erode_val = clamp((height - EROSION_MIN) / EROSION_RANGE, 0.0, 1.0);
			gl_FragColor.rgba = mix(gl_FragColor.rgba, gl_FragColor.rgba * erode_val, EROSION_LERP);
		#endif
		
		vec2 world_uv = (PS_POS.xz - OCEAN_WORLD_EXTENTS.xy) * OCEAN_WORLD_EXTENTS.zw;
		vec3 world_tint = texture2D(OCEAN_SAMPLER, world_uv).rgb;
		gl_FragColor.rgb = mix(gl_FragColor.rgb, gl_FragColor.rgb * world_tint.rgb, OCEAN_BLEND_PARAMS.x);

		// Apply Lighting
		vec3 light = CalculateLightingContribution();
		gl_FragColor.rgb *= max(light.rgb, vec3(LIGHT_OVERRIDE, LIGHT_OVERRIDE, LIGHT_OVERRIDE));
		
		float pct = abs(sin(TIMEPARAMS.x));
		gl_FragColor.a *= pct;
	}else{
		discard;
	}
}                                         	   