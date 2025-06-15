shader_type canvas_item;

uniform sampler2D mask_texture; // grayscale texture as alpha mask
uniform vec2 mask_scale = vec2(1.0, 1.0);
uniform vec2 mask_offset = vec2(0.0, 0.0);

void fragment() {
    vec4 albedo = texture(TEXTURE, UV);
    
    // Sample alpha mask texture with optional scale/offset
    vec2 mask_uv = UV * mask_scale + mask_offset;
    float mask_alpha = texture(mask_texture, mask_uv).r; // use red channel for grayscale

    // Multiply base alpha by mask alpha
    albedo.a *= mask_alpha;

    COLOR = albedo;
}
