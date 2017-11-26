module hello.post_processing;

import gfm.opengl;

/// Basically a sharpening pass
class Postprocessing
{
public:
  this(OpenGL gl, int screenWidth, int screenHeight)
  {
    _screenBuf = new GLTexture2D(gl);
    _screenBuf.setMinFilter(GL_LINEAR_MIPMAP_LINEAR);
    _screenBuf.setMagFilter(GL_LINEAR);
    _screenBuf.setWrapS(GL_CLAMP_TO_EDGE);
    _screenBuf.setWrapT(GL_CLAMP_TO_EDGE);
    _screenBuf.setImage(0, GL_RGBA, screenWidth, screenHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, null);
    _screenBuf.generateMipmap();


    _fbo = new GLFBO(gl);
    _fbo.use();
    _fbo.color(0).attach(_screenBuf);
    _fbo.unuse();

    // create a shader program made of a single fragment shader
    string postprocProgramSource =
      q{#version 330 core

        #if VERTEX_SHADER
        in vec3 position;
        in vec2 coordinates;
        out vec2 fragmentUV;
        void main()
        {
          gl_Position = vec4(position, 1.0);
          fragmentUV = coordinates;
        }
        #endif

        #if FRAGMENT_SHADER
        in vec2 fragmentUV;
        uniform sampler2D fbTexture;
        out vec4 color;

        void main()
        {
          // basic glow
          vec3 base = texture(fbTexture, fragmentUV).rgb;

          vec3 filtered = texture(fbTexture, fragmentUV, 1.0).rgb * 0.5
                        + texture(fbTexture, fragmentUV, 2.0).rgb * 0.3
                        + texture(fbTexture, fragmentUV, 3.0).rgb * 0.2;

          color = vec4(base + (base - filtered) * 20.0, 1.0); // sharpen
        }
        #endif
      };

    _program = new GLProgram(gl, postprocProgramSource);
  }

  ~this()
  {
    _program.destroy();
    _fbo.destroy();
    _screenBuf.destroy();
  }

  void bindFBO()
  {
    _fbo.use();
  }

  // Post-processing pass
  void pass(void delegate() drawGeometry)
  {
    _fbo.unuse();
    _screenBuf.generateMipmap();

    int texUnit = 1;
    _screenBuf.use(texUnit);

    _program.uniform("fbTexture").set(texUnit);
    _program.uniform("sharpen").set(true);
    _program.use();

    drawGeometry();
  }
private:
  GLFBO _fbo;
  GLTexture2D _screenBuf;
  GLProgram _program;
}