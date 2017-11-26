module hello.noise;

import std.math,
       std.random,
       std.typecons;

import gfm.math;

/// Creates a byte array intended for a noise texture
public pure ubyte* generateNoise(int texWidth, int texHeight)
{
  auto random = Random();
  ubyte[] texData = new ubyte[texWidth * texHeight * 3];
  int ind = 0;
  for (int y = 0; y < texHeight; ++y)
    for (int x = 0; x < texWidth; ++x)
    {
      float sample = 0;
      float amplitude = 100;
      float freq = 1;
      for (int level = 0; level < 8; ++level)
      {
        sample += sin(freq * x / cast(float)texWidth) * cos(freq * y / cast(float)texHeight);
        amplitude /= 2;
        freq *= 2;
      }
      ubyte grey = cast(ubyte)(clamp(128.0 + 128.0 * sample, 0.0, 255.0));
      texData[ind++] = grey;
      texData[ind++] = grey;
      texData[ind++] = grey;
    }
  
  return texData.ptr;
}