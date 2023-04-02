#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURFACE_DIST .25

#define BPM 103.

float sdCapsule(vec3 p, vec3 a, vec3 b, float r){
    vec3 ab = b-a;
    vec3 ap = p-a;
    
    float t = dot(ab, ap) / dot(ab, ab);
    t = clamp(t, 0., 1.);
    
    vec3 c = a + t*ab;
    
    return length(p-c)-r;
}

float getBPMVis(float bpm){
    
    // this function can be found graphed out here :https://www.desmos.com/calculator/rx86e6ymw7
	float bps = 60./bpm; // beats per second
	float bpmVis = cos((iTime*3.14)/bps);
	// multiply it by PI so that tan has a regular spike every 1 instead of PI
	// divide by the beat per second so there are that many spikes per second
	bpmVis = clamp(bpmVis,0.,15.); 
	// tan goes to infinity so lets clamp it at 10
	// tan goes up and down but we only want it to go up 
	// (so it looks like a spike) so we take the absolute value
	// dividing by 20 makes the tan function more spiking than smoothly going 
	// up and down, check out the desmos link to see what i mean
	
	return bpmVis;
}


float GetDist(vec3 p){
    vec4 sphere = vec4(0, 2, 6, 1.25);
    float beat = getBPMVis(BPM);
    sphere.w += sin(iTime*1.5 + beat*.5 );
    sphere.x += sin(iTime*2. + beat*.5 );
    float sphereD = length(p-sphere.xyz)-sphere.w;
    
    float planeD = p.y;
    vec3 c1 = vec3(3, 1, 6);
    vec3 c2 = vec3(-3, 1, 6);
    c1.y += sin(iTime*4. + beat*.7 );
    c2.y += cos(iTime*7. + beat*.3 );
    float capsuled = sdCapsule(p, c1, c2, .4);
    float cd = min(capsuled, planeD);
    float sd = min(sphereD, planeD);
    
    float d = mix(sd, cd, (sin(iTime + beat*.5 )+1.)/2.);
    return d;
}

float RayMarch(vec3 cam, vec3 cdir) {
    float dO = 0.;
    for(int i=0; i<MAX_STEPS; i++){
        vec3 p = cam+cdir*dO;
        float dS = GetDist(p);
        dO += dS;
        if(dO>MAX_DIST || dS<SURFACE_DIST ) break;
    }
    return dO;
}

vec3 GetNormal(vec3 p){
    float d = GetDist(p);
    vec2 e = vec2(.01, 0.);
    
    vec3 n = d - vec3(
        GetDist(p-e.xyy),
        GetDist(p-e.yxy),
        GetDist(p-e.yyx));
        
    return normalize(n);
}

float GetLight(vec3 p){
    vec3 lPos = vec3(4, 15, 6);
    float beat = getBPMVis(142.);
    vec3 l = normalize(lPos-p);
    vec3 n = GetNormal(p);
    
    float dif = clamp(dot(n, l), 0., 1.);
    float d = RayMarch(p+n*SURFACE_DIST*6., l);
    if(d<length(lPos-p)) dif = 0.;
    
    return dif;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (fragCoord-.5*iResolution.xy)/iResolution.y;

    
    // Camera position and camera ray direction
    vec3 cam = vec3(0, 1, 0);
    vec3 cdir = normalize(vec3(uv.x, uv.y, 1));
    
    float d = RayMarch(cam, cdir);
    vec3 p = cam + cdir *d;
    float dif = GetLight(p);
    vec3 col = vec3(dif);
    fragColor = vec4(col,1.0);
}