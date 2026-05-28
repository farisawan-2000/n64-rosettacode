## ===============================
## Whole lot of C glue
## ===============================
import futhark

importc:
  path "/usr/mips64-elf/include/"
  define N64
  undef NDEBUG
  "libdragon.h"
  "t3d/t3d.h"
  "t3d/t3dmath.h"
  "t3d/t3dmodel.h"

# Tell Nim how to compile against the library. If you have a dynamic library
# this would simply be a `--passL:"-l<library name>`
static:
  writeFile("build/main.c", """
  #include "libdragon.h"
  #include "t3d/t3d.h"
  #include "t3d/t3dmath.h"
  #include "t3d/t3dmodel.h"
  """)
{.compile: "build/main.c".}

## ===============================
## Now the start of the program
## ===============================

const
  FB_COUNT* = 3

proc asset_init_compression_lvl2() {.importc: "__asset_init_compression_lvl2".}
proc asset_init_compression_lvl3() {.importc: "__asset_init_compression_lvl3".}
proc rspq_block_begin() {.importc: "rspq_block_begin".}

proc init_compression(level: int) =
  case level:
    of 0, 1: discard
    of 2: asset_init_compression_lvl2()
    of 3: asset_init_compression_lvl3()
    else: discard

proc get_rainbow_color*(s: cfloat): color_t =
  var r: cfloat = fm_sinf(s + 0.0f) * 127.0f + 128.0f
  var g: cfloat = fm_sinf(s + 2.0f) * 127.0f + 128.0f
  var b: cfloat = fm_sinf(s + 4.0f) * 127.0f + 128.0f
  return color_t(
    r: cast[uint8](r),
    g: cast[uint8](g),
    b: cast[uint8](b),
    a: 255
  )

proc RGBA32(rx: uint8, gx: uint8, bx: uint8, ax: uint8): color_t = 
  result.r = rx
  result.g = gx
  result.b = bx
  result.a = ax

# proc t3d_viewport_create(): T3DViewport =
#   T3DViewport {
#     internal_isCamProjDirty: true,
#     offset: [0, 0],
#     size: [(int32)display_get_width(), (int32)display_get_height()],
#     guardBandScale: 2,
#     useRejection: false,
#     internal_bufferCount: 0,
#     internal_matFP: nil,
#   };

proc t3d_viewport_create_buffered(count: uint16): T3DViewport =
  result.internal_isCamProjDirty = true
  result.offset = [int32(0), int32(0)]
  result.size = [int32(display_get_width()), int32(display_get_height())]
  result.guardBandScale = cint(2)
  result.useRejection = 0
  result.internal_bufferCount = count
  result.internal_bufferIdx = 0
  result.internal_matFP = cast[ptr T3DMat4FP](malloc_uncached(sizeof(T3DMat4FP) * 2 * count))

proc t3d_vec3_len2(vec: ptr T3DVec3): float =
  return (vec.v[0] * vec.v[0]) + (vec.v[1] * vec.v[1]) + (vec.v[2] * vec.v[2])

proc t3d_vec3_norm(res: ptr T3DVec3) =
  var len = sqrtf(t3d_vec3_len2(res))
  if (len < 0.0001f):
    len = 0.0001f
  res.v[0] /= len
  res.v[1] /= len
  res.v[2] /= len


proc T3D_DEG_TO_RAD(deg: float): float = (deg * 0.01745329252f)

proc color_to_packed32(c: color_t): uint32 =
    return (c.r shl 24) or (c.g shl 16) or (c.b shl 8) or c.a;

proc rdpq_fixup_write8_syncchange(a: uint32, b: uint32, c: uint32, d: uint32) {.importc: "__rdpq_fixup_write8_syncchange".}
proc rdpq_set_prim_color(color: color_t) =
    rdpq_fixup_write8_syncchange(RDPQ_CMD_SET_PRIM_COLOR_COMPONENT, (0 shl 16), color_to_packed32(color), 0)

proc t3d_model_draw(model: ptr T3DModel) =
  t3d_model_draw_custom(model, T3DModelDrawConf(
    userData: nil,
    tileCb: nil,
    filterCb: nil
  ));
