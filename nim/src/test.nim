import futhark, strutils

# Tell futhark where to find the C libraries you will compile with, and what
# header files you wish to import.
importc:
  path "/usr/mips64-elf/include/"
  define N64 # This define is required by the STB library
  rename FILE, CFile # Rename `FILE` that STB uses to `CFile` which is the Nim equivalent
  "libdragon.h"

# Tell Nim how to compile against the library. If you have a dynamic library
# this would simply be a `--passL:"-l<library name>`
static:
  writeFile("test.c", """
  #include "libdragon.h"
  """)
{.compile: "test.c".}

# Use the library just like you would in C!
var width, height, channels: cint

var image = load("futhark.png", width.addr, height.addr, channels.addr, STBI_default.cint)
if image.isNil:
  echo "Error in loading the image"
  quit 1

echo "Loaded image with a width of ", width, ", a height of ", height, " and ", channels, " channels"
image_free(image)