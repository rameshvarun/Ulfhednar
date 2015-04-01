extern int samples = 3;
extern float size = 10;
extern vec2 imageSize = vec2(1280, 720);

extern float bloom_amount = 0.5;
extern float source_amount = 0.6;

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 pc)
{
	vec4 source = Texel(tex, tc);

	vec4 sum = vec4(0);
	
	for(int x = -samples; x <= samples; x++) {
		for(int y = -samples; y <= samples; y++) {
			vec2 offset = (size/samples) * vec2(x, y) / imageSize;
			sum += Texel(tex, tc + offset);
		}
	}
	
	vec4 blur = (sum/( (2*samples+1)*(2*samples+1) ));
	
	return ( blur*bloom_amount + source*source_amount )*color;
}