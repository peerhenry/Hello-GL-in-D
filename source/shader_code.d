module hello.shader_code;

immutable string tunnelProgramSource =
  q{#version 330 core

  #if VERTEX_SHADER
  in vec3 position;
  in vec2 coordinates;
  out vec2 fragmentUV;
  uniform mat4 mvpMatrix;
  void main()
  {
      gl_Position = mvpMatrix * vec4(position, 1.0);
      fragmentUV = coordinates;
  }
  #endif

  #if FRAGMENT_SHADER
  in vec2 fragmentUV;
  uniform float time;
  uniform sampler2D noiseTexture;
  out vec4 color;

  void main()
  {
    vec2 pos = fragmentUV - vec2(0.5, 0.5);
    vec4 noise = texture(noiseTexture, pos + vec2(0.5, 0.5));
    float u = length(pos);
    float v = atan(pos.y, pos.x) + noise.y * 0.04;
    float t = time / 0.5 + 1.0 / u;
    float intensity = abs(sin(t * 10.0 + v)+sin(v*8.0)) * .25 * u * 0.25 * (0.1 + noise.x);
    vec3 col = vec3(-sin(v*4.0+v*2.0+time), sin(u*8.0+v-time), cos(u+v*3.0+time))*16.0;
    color = vec4(col * intensity * (u * 4.0), 1.0);
  }
  #endif
};