module hello.main;

import std.math,
       std.random,
       std.typecons;

import derelict.util.loader;

import gfm.logger,
       gfm.sdl2,
       gfm.opengl,
			 gfm.math;

import hello.shader_code,
			 hello.noise,
			 hello.post_processing;

void main()
{
	int width = 1280;
	int height = 720;
	double ratio = width / cast(double)height;

	// create a coloured console logger
	auto log = new ConsoleLogger();

	// load dynamic libraries
	auto sdl2 = scoped!SDL2(log, SharedLibVersion(2, 0, 0));
	auto gl = scoped!OpenGL(log);

	// You have to initialize each SDL subsystem you want by hand
	sdl2.subSystemInit(SDL_INIT_VIDEO);
	sdl2.subSystemInit(SDL_INIT_EVENTS);

	SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);

	// create an OpenGL-enabled SDL window
	auto window = scoped!SDL2Window(sdl2,
																	SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
																	width, height,
																	SDL_WINDOW_OPENGL);

	// Reload OpenGL now that a context exists
	// Always provide a maximum version else the maximum known 
	// OpenGL 4.5 may be loaded and you risk hitting missing
	// functions bugs from drivers.
	gl.reload( GLVersion.None, GLVersion.GL33 );

	// redirect OpenGL output to our Logger
	gl.redirectDebugOutput();

	auto program = scoped!GLProgram(gl, tunnelProgramSource);

	int texWidth = 1024;
  int texHeight = 1024;
	ubyte* noise = generateNoise(texWidth, texHeight);
	auto noiseTexture = scoped!GLTexture2D(gl);
	noiseTexture.setMinFilter(GL_LINEAR_MIPMAP_LINEAR);
	noiseTexture.setMagFilter(GL_LINEAR);
	noiseTexture.setWrapS(GL_REPEAT);
	noiseTexture.setWrapT(GL_REPEAT);
	noiseTexture.setImage(0, GL_RGB, texWidth, texHeight, 0, GL_RGB, GL_UNSIGNED_BYTE, noise);
	noiseTexture.generateMipmap();

	static struct Vertex
	{
		vec3f position;
		vec2f coordinates;
	}

	Vertex[] quad;
	quad ~= Vertex(vec3f(-1, -1, 0), vec2f(0, 0));
	quad ~= Vertex(vec3f(+1, -1, 0), vec2f(1, 0));
	quad ~= Vertex(vec3f(+1, +1, 0), vec2f(1, 1));
	quad ~= Vertex(vec3f(+1, +1, 0), vec2f(1, 1));
	quad ~= Vertex(vec3f(-1, +1, 0), vec2f(0, 1));
	quad ~= Vertex(vec3f(-1, -1, 0), vec2f(0, 0));

	auto quadVBO = scoped!GLBuffer(gl, GL_ARRAY_BUFFER, GL_STATIC_DRAW, quad[]);

	// Create an OpenGL vertex description from the Vertex structure.
	auto quadVS = new VertexSpecification!Vertex(program);

	auto vao = scoped!GLVAO(gl);
	double time = 0;

	uint lastTime = SDL_GetTicks();

	Postprocessing postprocessing = new Postprocessing(gl, width, height);
	scope(exit) postprocessing.destroy();
	bool activatePostprocessing;

	// prepare VAO
	{
		vao.bind();
		quadVBO.bind();
		quadVS.use();
		vao.unbind();
	}

	window.setTitle("Hello whatever the fuck this is");

	bool shouldQuit = false;
	while(!shouldQuit)
	{
		sdl2.processEvents();

		bool doPostprocessing = !sdl2.keyboard.isPressed(SDLK_SPACE);

		uint now = SDL_GetTicks();
		double dt = now - lastTime;
		lastTime = now;
		time += 0.001 * dt;

		// clear the whole window
		glViewport(0, 0, width, height);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

		int texUnit = 0;
		noiseTexture.use(texUnit);

		// uniform variables must be set before program use
		program.uniform("time").set(cast(float)time);
		program.uniform("noiseTexture").set(texUnit);
		program.uniform("mvpMatrix").set(mat4f.identity);
		program.use();

		if (doPostprocessing) postprocessing.bindFBO();

		void drawFullQuad()
		{
				vao.bind();
				glDrawArrays(GL_TRIANGLES, 0, cast(int)(quadVBO.size() / quadVS.vertexSize()));
				vao.unbind();
		}
		drawFullQuad();
		program.unuse();

		if (doPostprocessing) postprocessing.pass(&drawFullQuad); // we reuse the quad geometry here for shortness purpose

		window.swapBuffers();
		shouldQuit = sdl2.keyboard.isPressed(SDLK_ESCAPE);
	}
}