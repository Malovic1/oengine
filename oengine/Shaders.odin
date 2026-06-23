package oengine


import "core:fmt"

WAVE_VERT: cstring = `
#version 330

in vec3 vertexPosition;
in vec2 vertexTexCoord;
in vec4 vertexColor;

out vec2 fragTexCoord;
out vec4 fragColor;
out vec3 fragPosition;

uniform mat4 mvp;
uniform mat4 matModel;

void main() {
    vec4 worldPos = matModel * vec4(vertexPosition, 1.0);
    
    fragPosition = worldPos.xyz;
    fragTexCoord = vertexTexCoord;
    fragColor = vertexColor;

    gl_Position = mvp * vec4(vertexPosition, 1.0);
}
`;

WAVE_FRAG: cstring = `
#version 330

in vec3 fragPosition;
in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;
uniform vec4 colDiffuse;

out vec4 finalColor;

uniform float seconds;
uniform vec2 size; 

uniform float freqX;
uniform float freqY;
uniform float ampX;
uniform float ampY;
uniform float speedX;
uniform float speedY;

uniform vec3 viewPos;
uniform float fogDensity;
uniform vec4 fogColor;

void main() {
    float waveX = cos(fragTexCoord.y * freqX + seconds * speedX) * ampX;
    float waveY = sin(fragTexCoord.x * freqY + seconds * speedY) * ampY;
    vec2 wave_offset = vec2(waveX, waveY);

    // We use this specifically to tell the GPU how fast the animation is moving
    vec2 continuous_moving_uv = (fragTexCoord * size) + wave_offset;

    vec2 tiled_uv = fract(fragTexCoord * size);
    vec2 final_uv = tiled_uv + wave_offset;

    // This includes the velocity of the wave but avoids the sharp tile-edge cuts
    vec2 dx = dFdx(continuous_moving_uv);
    vec2 dy = dFdy(continuous_moving_uv);

    finalColor = textureGrad(texture0, final_uv, dx, dy) * colDiffuse * fragColor;

    float dist = length(viewPos - fragPosition);
    float fogFactor = 1.0 / exp((dist * fogDensity) * (dist * fogDensity));
    fogFactor = clamp(fogFactor, 0.0, 1.0);

    finalColor = mix(fogColor, finalColor, fogFactor);
}
`;

DEFAULT_VERT: cstring = `
#version 330

// Input vertex attributes
in vec3 vertexPosition;
in vec2 vertexTexCoord;
in vec3 vertexNormal;
in vec4 vertexColor;

// Input uniform values
uniform mat4 mvp;
uniform mat4 matModel;
uniform mat4 matNormal;

// Output vertex attributes (to fragment shader)
out vec3 fragPosition;
out vec2 fragTexCoord;
out vec4 fragColor;
out vec3 fragNormal;

uniform vec2 tiling;

out vec2 fragTiling;

void main()
{
    // Send vertex attributes to fragment shader
    fragPosition = vec3(matModel*vec4(vertexPosition, 1.0));
    fragTexCoord = vertexTexCoord * tiling;
    fragColor = vertexColor;
    fragNormal = normalize(vec3(matNormal*vec4(vertexNormal, 1.0)));
    fragTiling = tiling;

    // Calculate final vertex position
    gl_Position = mvp*vec4(vertexPosition, 1.0);
}
`;

DEFAULT_FRAG: cstring = `
#version 330

in vec3 fragPosition;
in vec2 fragTexCoord;
in vec4 fragColor;
in vec3 fragNormal;
in vec2 fragTiling;

uniform sampler2D texture0;
uniform vec4 colDiffuse;

#define MAX_LIGHTS        16
#define LIGHT_DIRECTIONAL 0
#define LIGHT_POINT       1
#define LIGHT_SPOT        2

#define SHADOWMAP_RES     4096

struct Light {
    int enabled;
    int type;
    vec3 position;
    vec3 target;
    vec4 color;
    float inner_cutoff;
    float outer_cutoff;
    float intensity;
    float range;
};

uniform Light lights[MAX_LIGHTS];
uniform vec4 ambient;
uniform vec3 viewPos;
uniform int light_count;
uniform float fogDensity;
uniform vec4 fogColor;
uniform int use_triplanar;

uniform sampler2D shadowMaps[MAX_LIGHTS];
uniform mat4 lightVPs[MAX_LIGHTS];
uniform int lightCastShadows[MAX_LIGHTS];

out vec4 finalColor;

float ComputeShadow(
    int lightIndex,
    vec3 fragPos,
    vec3 normal,
    vec3 lightDir
) {
    // Transform fragment into light clip space
    vec4 fragPosLight = lightVPs[lightIndex] * vec4(fragPos, 1.0);
    fragPosLight.xyz /= fragPosLight.w;
    fragPosLight.xyz = fragPosLight.xyz * 0.5 + 0.5;

    // Outside shadow map
    if (fragPosLight.x < 0.0 || fragPosLight.x > 1.0 ||
        fragPosLight.y < 0.0 || fragPosLight.y > 1.0 ||
        fragPosLight.z > 1.0)
        return 0.0;

    float currentDepth = fragPosLight.z;

    // Slope-scaled bias
    float bias = max(0.0005 * (1.0 - dot(normal, lightDir)), 0.00005);

    vec2 texelSize = 1.0 / vec2(float(SHADOWMAP_RES));
    float shadow = 0.0;

    // 3×3 PCF
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            float closestDepth = texture(
                shadowMaps[lightIndex],
                fragPosLight.xy + vec2(x, y) * texelSize
            ).r;

            if (currentDepth - bias > closestDepth)
                shadow += 1.0;
        }
    }

    return shadow / 9.0;
}

void main()
{
    vec4 texelColor;

    if (use_triplanar == 1) {
        vec3 blending = abs(normalize(fragNormal));
        blending = pow(blending, vec3(4.0));
        blending /= (blending.x + blending.y + blending.z);

        vec2 uvX = fragPosition.zy * fragTiling;
        vec2 uvY = fragPosition.xz * fragTiling;
        vec2 uvZ = fragPosition.xy * fragTiling;

        vec4 texX = texture(texture0, uvX);
        vec4 texY = texture(texture0, uvY);
        vec4 texZ = texture(texture0, uvZ);

        texelColor = texX * blending.x + texY * blending.y + texZ * blending.z;
    } else {
        texelColor = texture(texture0, fragTexCoord);
    }

    if (texelColor.a < 0.5) { discard; }

    vec3 normal = normalize(fragNormal);
    vec3 viewDir = normalize(viewPos - fragPosition);

    // Double-sided normals: flip if back-facing
    if (dot(normal, viewDir) < 0.0) {
        normal = -normal;
    }

    vec3 lightSum = vec3(0.0);
    vec3 specular = vec3(0.0);
    vec4 tint = colDiffuse * fragColor;

    for (int i = 0; i < light_count; i++)
    {
        if (lights[i].enabled != 1) continue;

        vec3 lightDir;
        float attenuation = 1.0;
        float intensity = lights[i].intensity;

        if (lights[i].type == LIGHT_DIRECTIONAL)
        {
            lightDir = -normalize(lights[i].target - lights[i].position);
        }
        else
        {
            lightDir = normalize(lights[i].position - fragPosition);

            if (lights[i].type == LIGHT_SPOT)
            {
                vec3 spotDir = normalize(lights[i].target - lights[i].position);
                vec3 fragToLight = normalize(fragPosition - lights[i].position);

                float theta = dot(spotDir, fragToLight);
                float epsilon = max(0.001, lights[i].inner_cutoff - lights[i].outer_cutoff);
                float spotlightIntensity = clamp((theta - lights[i].outer_cutoff) / epsilon, 0.0, 1.0);
                intensity *= spotlightIntensity;
            }

            float dist = length(lights[i].position - fragPosition);
            attenuation = 1.0 / (0.5 + 0.025 * dist + 0.005 * dist * dist);

            float fade = clamp(1.0 - dist / lights[i].range, 0.0, 1.0);
            attenuation *= fade;
        }

        float NdotL = max(dot(normal, lightDir), 0.0);

        float shadow = 0.0;
        if (lightCastShadows[i] == 1 && NdotL > 0.0)
        {
            shadow = ComputeShadow(i, fragPosition, normal, lightDir);
        }

        lightSum += lights[i].color.rgb
                * NdotL
                * intensity
                * attenuation
                * (1.0 - shadow);

        // if (NdotL > 0.0)
        // {
        //     vec3 reflectDir = reflect(-lightDir, normal);
        //     float spec = pow(max(dot(viewDir, reflectDir), 0.0), 16.0);
        //     specular += spec * lights[i].color.rgb * 0.25 * intensity * attenuation;
        // }
    }

    vec3 ambientLight = ambient.rgb * texelColor.rgb * tint.rgb * 0.1;
    vec3 lit = texelColor.rgb * tint.rgb * lightSum + specular + ambientLight;

    finalColor = vec4(lit, texelColor.a * tint.a);

    finalColor.rgb = pow(finalColor.rgb, vec3(1.0 / 2.2));
    finalColor.rgb = clamp(finalColor.rgb, 0.0, 1.0);

    float dist = length(viewPos - fragPosition);
    float fogFactor = 1.0/exp((dist*fogDensity)*(dist*fogDensity));
    fogFactor = clamp(fogFactor, 0.0, 1.0);

    vec4 final_texel = mix(fogColor, finalColor, fogFactor);
    finalColor = final_texel;
}`;

TRANSPARENT_FRAG: cstring = `
#version 330

// Input vertex attributes (from vertex shader)
in vec2 fragTexCoord;
in vec4 fragColor;

// Input uniform values
uniform sampler2D texture0;
uniform vec4 colDiffuse;

// Output fragment color
out vec4 finalColor;

// NOTE: Add your custom variables here

void main()
{
    vec4 texelColor = texture(texture0, fragTexCoord);

    if (texelColor.a < 0.5) { discard; }

    finalColor = texelColor*colDiffuse*fragColor;
}`;

SHADOWMAP_FRAG: cstring = `
#version 330
void main() { }
`;

shader_location :: proc(shader: rl_Shader, uniformName: cstring) -> rl_ShaderLocationIndex {
    loc := rl_GetShaderLocation(shader, uniformName);
    return loc;
}

vec_to_mulptr :: proc {
    vec2_to_mulptr,
    vec3_to_mulptr,
    vec4_to_mulptr,
}

vec3_to_mulptr :: proc(arr: [3]f32) -> rawptr {
    slice := []f32{arr.x, arr.y, arr.z};
    return raw_data(slice);
}

vec2_to_mulptr :: proc(arr: [2]f32) -> rawptr {
    slice := []f32{arr.x, arr.y};
    return raw_data(slice);
}

vec4_to_mulptr :: proc(arr: [4]f32) -> rawptr {
    slice := []f32{arr.x, arr.y, arr.z, arr.w};
    return raw_data(slice);
}
