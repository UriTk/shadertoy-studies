// User-defined parameters
#define TORUS_MAJOR_RADIUS 1.0
#define TORUS_MINOR_RADIUS 0.2
#define PLANE_HEIGHT -1.6
#define ROTATION_SPEED_X 1.5
#define ROTATION_SPEED_Y 1.0
#define STRIPES 15.0
#define MAX_JUMP 800
#define MAX_DIST 800.
#define NOISE_VAL1 .002
#define NOISE_VAL2 100.
#define CAM_SPEED 0.03
#define MOUSE_SENSITIVITY 0.002

struct Material {
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    float shininess;
};

struct Light {
    vec3 position;
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};

uniform vec4 iKeyboard;

vec4 taylorInvSqrt(vec4 r) {
    return 1.79284291400159 - 0.85373472095314 * r;
}

vec4 permute(vec4 x) {
    return mod(((x * 34.0) + 1.0) * x, 289.0);
}

mat3 rotationMatrix(vec2 angles) {
    float cx = cos(angles.x);
    float sx = sin(angles.x);
    float cy = cos(angles.y);
    float sy = sin(angles.y);
    return mat3(
        cy, 0.0, -sy,
        -sx * sy, cx, -sx * cy,
        cx * sy, sx, cx * cy
    );
}

vec3 moveCamera(vec3 camPos, vec4 keys, vec2 angles, float delta) {
    vec3 forward = rotationMatrix(angles) * vec3(0.0, 0.0, -1.0);
    vec3 right = rotationMatrix(angles) * vec3(1.0, 0.0, 0.0);
    vec3 up = rotationMatrix(angles) * vec3(0.0, 1.0, 0.0);
    
    //unused
    if (keys.x > 0.0) camPos += right * delta; // D
    if (keys.y > 0.0) camPos -= right * delta; // A
    if (keys.z > 0.0) camPos -= forward * delta; // W
    if (keys.w > 0.0) camPos += forward * delta; // S

    return camPos;
}

// Rotate a 3D point p around the Y axis by the given angle
vec3 rotateY(vec3 p, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    mat3 rotationMatrix = mat3(
        c, 0.0, -s,
        0.0, 1.0, 0.0,
        s, 0.0, c
    );
    return rotationMatrix * p;
}

vec3 rotateX(vec3 p, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    mat3 rotationMatrix = mat3(
        1.0, 0.0, 0.0,
        0.0, c, s,
        0.0, -s, c
    );
    return rotationMatrix * p;
}

// Simplex Noise function by iq (https://www.shadertoy.com/view/XslGRr)
float snoise(vec3 v) {
    const vec3 C = vec3(1.0 / 6.0, 1.0 / 3.0, 1.0 / 289.0);
    const vec4 D = vec4(0.0, 0.5, 1.0, 2.0);
    
    vec3 i = floor(v + dot(v, C.yyy));
    vec3 x0 = v - i + dot(i, C.xxx);
    
    vec3 g = step(x0.yzx, x0.xyz);
    vec3 l = 1.0 - g;
    vec3 i1 = min(g.xyz, l.zxy);
    vec3 i2 = max(g.xyz, l.zxy);
    
    vec3 x1 = x0 - i1 + C.x;
    vec3 x2 = x0 - i2 + 2.0 * C.x;
    vec3 x3 = x0 - 1.0 + 3.0 * C.x;
    
    i = mod(i, 289.0);
    vec4 p = permute(permute(permute(i.z + vec4(0.0, i1.z, i2.z, 1.0)) + i.y + vec4(0.0, i1.y, i2.y, 1.0)) + i.x + vec4(0.0, i1.x, i2.x, 1.0));
    vec4 j = p - 49.0 * floor(p * C.z);
    
    vec4 x_ = floor(j * C.z);
    vec4 y_ = floor(j - 7.0 * x_);
    
    vec4 x = x_ * C.x + C.y;
    vec4 y = y_ * C.x + C.y;
    vec4 h = 1.0 - abs(x) - abs(y);
    
    vec4 b0 = vec4(x.xy, y.xy);
    vec4 b1 = vec4(x.zw, y.zw);
    
    vec4 s0 = floor(b0) * 2.0 + 1.0;
    vec4 s1 = floor(b1) * 2.0 + 1.0;
    vec4 sh = -step(h, vec4(0.0));
    
    vec4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
    vec4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
    
    vec3 p0 = vec3(a0.xy, h.x);
    vec3 p1 = vec3(a0.zw, h.y);
    vec3 p2 = vec3(a1.xy, h.z);
    vec3 p3 = vec3(a1.zw, h.w);
    
    vec4 norm = taylorInvSqrt(vec4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
    p0 *= norm.x;
    p1 *= norm.y;
    p2 *= norm.z;
    p3 *= norm.w;
    
    vec4 m = max(0.6 - vec4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
    m = m * m;
    return 42.0 * dot(m*m, vec4(dot(p0, x0), dot(p1, x1), dot(p2, x2), dot(p3, x3)));
}

// Signed distance function for a torus
// p: 3D point
// torusParams: vec2(x, y), where x is the distance from the center of the torus to the center of the tube, and y is the radius of the tube
// angle: rotation angle around the Y axis
float torusSDF(vec3 p, vec2 torusParams, float angleY, float angleX) {
    vec3 rotatedP = rotateY(p, angleY);
    rotatedP = rotateX(rotatedP, angleX); // Apply rotation around X-axis
    vec2 q = vec2(length(rotatedP.xz) - torusParams.x, rotatedP.y);
    return length(q) - torusParams.y;
}


vec3 torusTexture(vec3 p, vec3 color, float angleY, float angleX, float stripes) {
    p = rotateY(p, angleY);
    p = rotateX(p, angleX); // Rotate the position before calculating the stripe pattern
    float stripeAngle = atan(p.z, p.x);
    float stripePattern = sin(stripes * stripeAngle);
    vec3 textureColor = mix(color, vec3(1.0, 1.0, 1.0), (stripePattern + 1.0) * 0.5);
    return textureColor;
}


// Signed distance function for a horizontal plane
// p: 3D point
// height: height of the plane along the Y axis
float planeSDF(vec3 p, float height) {
    return p.y - height;
}

// Calculate the normal at point p
// p: 3D point
// torusParams: vec2(x, y), where x is the distance from the center of the torus to the center of the tube, and y is the radius of the tube
// planeHeight: height of the plane along the Y axis
// angle: rotation angle around the Y axis
vec3 calculateNormal(vec3 p, vec2 torusParams, float planeHeight, float angleY, float angleX) {
    vec2 eps = vec2(0.001, 0.0);
    vec3 n = vec3(
        torusSDF(p + vec3(eps.x, eps.y, eps.y), torusParams, angleY, angleX) - torusSDF(p - vec3(eps.x, eps.y, eps.y), torusParams, angleY, angleX),
        torusSDF(p + vec3(eps.y, eps.x, eps.y), torusParams, angleY, angleX) - torusSDF(p - vec3(eps.y, eps.x, eps.y), torusParams, angleY, angleX),
        torusSDF(p + vec3(eps.y, eps.y, eps.x), torusParams, angleY, angleX) - torusSDF(p - vec3(eps.y, eps.y, eps.x), torusParams, angleY, angleX)
    );
    if (abs(planeSDF(p, planeHeight)) < 0.001) {
        n = vec3(0.0, 1.0, 0.0);
    }
    return normalize(n);
}

// Raymarching function
// rayOrigin: origin of the ray
// rayDirection: direction of the ray
// torusParams: vec2(x, y), where x is the distance from the center of the torus to the center of the tube, and y is the radius of the tube
// planeHeight: height of the plane along the Y axis

float raymarch(vec3 rayOrigin, vec3 rayDirection, vec2 torusParams, float planeHeight, float angleY, float angleX) {
    float t = 0.0;
    for (int i = 0; i < MAX_JUMP; ++i) {
        vec3 p = rayOrigin + rayDirection * t;
        float distTorus = torusSDF(p, torusParams, angleY, angleX); // Pass both angles to the torusSDF function
        float distPlane = planeSDF(p, planeHeight);
        float dist = min(distTorus, distPlane);

        if (dist < 0.001) {
            return t;
        }
        t += dist;
        if (t > MAX_DIST) {
            break;
        }
    }
    return -1.0;
}

// Phong lighting model function
// normal: surface normal
// viewDir: view direction
// material: material properties
// light: light properties
vec3 phongLighting(vec3 normal, vec3 viewDir, Material material, Light light) {
    vec3 lightDir = normalize(light.position - viewDir);
    vec3 reflectDir = reflect(-lightDir, normal);
    
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);
    float diffuse = max(dot(normal, lightDir), 0.0);
    
    vec3 ambient = light.ambient * material.ambient;
    vec3 diff = light.diffuse * material.diffuse * diffuse;
    vec3 specu = light.specular * material.specular * spec;
    
    return ambient + diff + specu;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord.xy - 0.5 * iResolution.xy) / iResolution.y;
    float angleX = iTime * ROTATION_SPEED_X;
    float angleY = iTime * ROTATION_SPEED_Y;
    vec3 camPos = vec3(0, 0, 5);
    
    
    // Update camera rotation based on mouse input
    vec2 camRot = vec2(
        -0.005 * (iMouse.y - 0.5 * iResolution.y),
        -0.005 * (iMouse.x - 0.5 * iResolution.x)
    );
    
    vec3 rayDirection = rotationMatrix(camRot) * normalize(vec3(uv, -1.0));
    
    // Update camera position based on WASD input
    camPos = moveCamera(camPos, iKeyboard, camRot, 0.02);
    
    vec2 torusParams = vec2(TORUS_MAJOR_RADIUS, TORUS_MINOR_RADIUS);
    float planeHeight = PLANE_HEIGHT;
    float t = raymarch(camPos, rayDirection, torusParams, planeHeight, angleY, angleX);
    
    vec3 color = vec3(0);
    if (t > 0.0) {
        vec3 p = camPos + rayDirection * t;
        vec3 surfaceNormal = calculateNormal(p, torusParams, planeHeight, angleY, angleX);

        // Add Simplex Noise to the torus surface
        float noiseValue = snoise(p * NOISE_VAL1);
        p += surfaceNormal * noiseValue * NOISE_VAL2+1.;

        // Recalculate the surfaceNormal after perturbing the surface
        surfaceNormal = calculateNormal(p, torusParams, planeHeight, angleY, angleX);

        Material material = Material(
            vec3(0.6, 0.0, 0.3), // ambient
            vec3(0.5, 0.2, 0.8), // diffuse
            vec3(1.0, 1.0, 1.0), // specular
            12.0                 // shininess
        );
        
        Light light = Light(
            vec3(2.0, 2.0, 5.0), // position
            vec3(0.4, 0.1, 0.4), // ambient
            vec3(2.0, 1.0, 1.0), // diffuse
            vec3(7.0, 1.0, 1.0)  // specular
        );
        
        // Modify the color of the torus based on the noise value
        float colorFactor = (noiseValue + 1.0) * 0.5;
        material.diffuse = mix(material.diffuse, vec3(0.2, 0.6, 0.3), colorFactor);
        
        vec3 viewDir = normalize(p - camPos);
        color = phongLighting(surfaceNormal, viewDir, material, light);
        
        if (abs(planeSDF(p, planeHeight)) < 0.001) {
            float s = 0.5 * (1.0 + sin(p.x) * cos(p.z));
            color = vec3(s);
        } else {
            color = torusTexture(p, color, angleY, angleX, STRIPES); // Pass both angles to the torusTexture function

        }
    }
    
    fragColor = vec4(color, 1.0);
}