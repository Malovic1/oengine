package oengine

import rl "vendor:raylib"
import "core:fmt"

WAVE_FRAG: cstring = `
#version 330

// Input vertex attributes (from vertex shader)
in vec2 fragTexCoord;
in vec4 fragColor;

// Input uniform values
uniform sampler2D texture0;
uniform vec4 colDiffuse;

// Output fragment color
out vec4 finalColor;

uniform float seconds;

uniform vec2 size;

uniform float freqX;
uniform float freqY;
uniform float ampX;
uniform float ampY;
uniform float speedX;
uniform float speedY;

void main() {
    float pixelWidth = 1.0 / size.x;
    float pixelHeight = 1.0 / size.y;
    float aspect = pixelHeight / pixelWidth;
    float boxLeft = 0.0;
    float boxTop = 0.0;

    vec2 p = fragTexCoord;
    p.x += cos((fragTexCoord.y - boxTop) * freqX / ( pixelWidth * 750.0) + (seconds * speedX)) * ampX * pixelWidth;
    p.y += sin((fragTexCoord.x - boxLeft) * freqY * aspect / ( pixelHeight * 750.0) + (seconds * speedY)) * ampY * pixelHeight;

    finalColor = texture(texture0, p)*colDiffuse*fragColor;
}`;

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

out vec4 finalColor;

void main()
{
    vec4 texelColor;

    if (use_triplanar == 1) {
        // triplanar mapping
        vec3 blending = abs(normalize(fragNormal));
        blending = pow(blending, vec3(4.0)); // Sharpen blend
        blending /= (blending.x + blending.y + blending.z); // Normalize

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

    vec3 normal = normalize(fragNormal);
    vec3 viewDir = normalize(viewPos - fragPosition);
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

                float theta = dot(spotDir, fragToLight);  // Don't invert fragToLight
                float epsilon = max(0.001, lights[i].inner_cutoff - lights[i].outer_cutoff);
                float spotlightIntensity = clamp((theta - lights[i].outer_cutoff) / epsilon, 0.0, 1.0);
                intensity *= spotlightIntensity;
            }

            // Simple distance attenuation
            float dist = length(lights[i].position - fragPosition);
            attenuation = 1.0 / (0.5 + 0.025 * dist + 0.005 * dist * dist);

            float fade = clamp(1.0 - dist / lights[i].range, 0.0, 1.0);
            attenuation *= fade;
        }

        float NdotL = max(dot(normal, lightDir), 0.0);
        lightSum += lights[i].color.rgb * NdotL * intensity * attenuation;

        if (NdotL > 0.0)
        {
            vec3 reflectDir = reflect(-lightDir, normal);
            float spec = pow(max(dot(viewDir, reflectDir), 0.0), 16.0); // shininess = 16
            specular += spec * lights[i].color.rgb * 0.25 * intensity * attenuation;
        }
    }

    vec3 ambientLight = ambient.rgb * texelColor.rgb * tint.rgb * 0.1;
    vec3 lit = texelColor.rgb * tint.rgb * lightSum + specular + ambientLight;

    finalColor = vec4(lit, texelColor.a * tint.a);

    // Gamma correction (comment out if your pipeline is sRGB)
    finalColor.rgb = pow(finalColor.rgb, vec3(1.0 / 2.2));

    finalColor.rgb = clamp(finalColor.rgb, 0.0, 1.0);

    // Fog calculation
    float dist = length(viewPos - fragPosition);

    // Exponential fog
    float fogFactor = 1.0/exp((dist*fogDensity)*(dist*fogDensity));

    fogFactor = clamp(fogFactor, 0.0, 1.0);

    finalColor = mix(fogColor, finalColor, fogFactor);
}
`;

shader_location :: proc(shader: rl.Shader, uniformName: cstring) -> rl.ShaderLocationIndex {
    loc := rl.GetShaderLocation(shader, uniformName);
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
