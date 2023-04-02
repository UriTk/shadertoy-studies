vec2 N22(vec2 p)
{
    vec3 a = fract(p.xyx*vec3(123.34, 234.34, 345.45));
    a += dot(a, a+34.45);
    return fract(vec2(a.x*a.y, a.y*a.z));
    }

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (2.*fragCoord-iResolution.xy)/iResolution.xy;


    float t = iTime *.5;
    float m = 0.;
    float index = 0.;
    float minDist = 200.;
    vec3 col = vec3(0);
    
    //calculates each single point's distance individually
    if(false){
    for(float i=0.; i<50.; i++){
        vec2 n = N22(vec2(i));//N22 gives us a random value
        vec2 p = sin(n*t);
        
        float d = length(uv-p);
        m += smoothstep(0.03, .02, d);
        
        if(d<minDist){
            minDist = d;
            index = i;
            }
        }
    }
    //optimal, divides everything into cells
    else{
        uv *= 5.; // amount of cells calculated
        vec2 gv = fract(uv) -.5; //fract() returns a value in the float range of ]0., 1.[, we want a value of ]-.5, .5[
        vec2 id = floor(uv);
        vec2 cellid = vec2(0);
        for(float y=-1.; y<=1.; y++){
            for(float x=-1.; x<=1.; x++){
                vec2 offs = vec2(x, y);
                vec2 n = N22(id+offs);
                vec2 p = offs+(sin(n*t)*.5);//sin() returns a value in the float range of ]-1., 1.[, we multiply it by .5 to stay in the ]-.5, .5[ range
                float d = length(gv-p);
                if (d<minDist){
                    minDist=d;
                    cellid=id+offs;
                }
                
            }
        }
        //col.rg = cellid*.1;
    }
    col = vec3(minDist);

    // Output to screen
    fragColor = vec4(col,1.0);
}