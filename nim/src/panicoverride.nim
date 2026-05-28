import futhark

importc:
  path "/usr/mips64-elf/include/"
  define N64
  undef NDEBUG
  "libdragon.h"

# Tell Nim how to compile against the library. If you have a dynamic library
# this would simply be a `--passL:"-l<library name>`
static:
  writeFile("build/panicoverride.c", """
  #include "libdragon.h"
  """)
{.compile: "build/panicoverride.c".}

proc panic(msg: string) =
  assertf(0, msg)

proc rawoutput(msg: string) =
  assertf(0, msg)
