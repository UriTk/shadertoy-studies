float N21(vec2 p){
    p = fract(p*vec2(234.23, 435.2));
    p += dot(p, p+24.2);
    return fract(p.x*p.y);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (fragCoord-.5*iResolution.xy)/iResolution.y+vec2(.1);
    
    // Time varying pixel color
    vec3 col = vec3(0);
    float linewidth = .1;
    uv += iTime*0.05;
    uv *= 7.;
    vec2 gv = fract(uv)-.5;
    vec2 id = floor(uv);
    float n = N21(id);
    if (sin(iTime*.25)<=.5){
        if (n<=.5){gv.x*=-1.;}
        }
    else
        if(gv.x>.47 || gv.y>.47){col = vec3(1,0,0);}
    float d = abs(abs(gv.x+gv.y)-.5);
    float cd = .0;
    vec2 cUv = gv-.5*sign(gv.x+gv.y+.001);
    cd = length(cUv)-.5;
    
    float linemask = smoothstep(.01, -.01, abs(d)-linewidth);
    float circlemask = smoothstep(.01, -.01, abs(cd)-linewidth);
    float mask = mix(linemask, circlemask, sin(iTime*0.5)*.5+.5);
    float angle = atan(cUv.x, cUv.y);
    float checker = mod(id.x+id.y, 2.)*2.-1.;
    
    //messing with some colours:
    col.r += (sin(iTime*4.+checker*angle*2.)+.9)*mask;
    //col.g += (sin(iTime*2.+checker*angle*5.)+.9)*mask;
    col.b += (sin(iTime*24.+checker*angle*12.)+.9)*mask;
    //just black and white:
    //col += (sin(iTime*24.+checker*angle*12.)+.9)*mask;
    //visual representation of the outlines:
    //if(gv.x>.47 || gv.y>.47){col = vec3(1,0,0);}
    
    // Output to screen
    fragColor = vec4(col,1.0);
}