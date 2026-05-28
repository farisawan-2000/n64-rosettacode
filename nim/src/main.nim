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
  writeFile("build/test.c", """
  #include "libdragon.h"
  #include "t3d/t3d.h"
  #include "t3d/t3dmath.h"
  #include "t3d/t3dmodel.h"
  """)
{.compile: "build/test.c".}

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

##
##  Simple example with a 3d-model file created in blender.
##  This uses the builtin model format for loading and drawing a model.
##

proc main*(): cint =
  # debug_init_isviewer()
  discard debug_init_usblog()
  init_compression(2)
  discard dfs_init(DFS_DEFAULT_LOCATION)
  display_init(RESOLUTION_320x240, DEPTH_16_BPP, FB_COUNT, GAMMA_NONE,
               FILTERS_RESAMPLE_ANTIALIAS)
  rdpq_init()
  t3d_init(T3DInitParams())
  ##  Now allocate a fixed-point matrix, this is what t3d uses internally.
  ##  Note: this gets DMA'd to the RSP, so it needs to be uncached.
  ##  If you can't allocate uncached memory, remember to flush the cache after writing to it instead.
  var modelMatFP: seq[T3DMat4FP] = cast[seq[T3DMat4FP]](malloc_uncached(sizeof(T3DMat4FP) * FB_COUNT))
  ##  allocate one matrix for each framebuffer
  ##  Also create a buffered viewport to have a distinct matrix for each frame, avoiding corruptions if the CPU is too fast
  ##  In an actual game make sure to free this viewport via 't3d_viewport_destroy' if no longer needed.
  var viewport: T3DViewport = t3d_viewport_create_buffered(FB_COUNT)
  let camPos = T3DVec3(v: [0.0f, 10.0f, 40.0f])
  let camTarget = T3DVec3(v: [0, 0, 0])
  var colorAmbient: array[4, uint8] = [80, 80, 100, 0xFF]
  var colorDir: array[4, uint8] = [0xEE, 0xAA, 0xAA, 0xFF]
  var lightDirVec = T3DVec3(v: [-1.0, 1.0, 1.0])
  t3d_vec3_norm(addr(lightDirVec))
  ##  Load a model-file, this contains the geometry and some metadata
  var model: ptr T3DModel = t3d_model_load("rom:/model.t3dm")
  var rotAngle: float = 0.0f
  var dplDraw: ptr rspq_block_t = nil
  var frameIdx: cint = 0
  while true:
    ##  ======== Update ======== //
    ##  cycle through FP matrices to avoid overwriting what the RSP may still need to load
    frameIdx = (frameIdx + 1) mod FB_COUNT
    rotAngle -= 0.02f
    var modelScale: cfloat = 0.1f
    t3d_viewport_set_projection(addr(viewport), T3D_DEG_TO_RAD(85.0f), 10.0f,
                                150.0f)

    var upvec = T3DVec3(v: [0, 1, 0])
    t3d_viewport_look_at(addr(viewport), addr(camPos), addr(camTarget),
                         addr(upvec))
    ##  slowly rotate model, for more information on matrices and how to draw objects
    ##  see the example: "03_objects"

    t3d_mat4fp_from_srt_euler(addr(modelMatFP[frameIdx]),
                              [modelScale, modelScale, modelScale],
                              [0.0f, rotAngle * 0.2f, rotAngle],
                              [0'f32, 0'f32, 0'f32])
    ##  ======== Draw ======== //
    rdpq_attach(display_get(), display_get_zbuf())
    t3d_frame_start()
    t3d_viewport_attach(addr(viewport))
    t3d_screen_clear_color(RGBA32(100, 80, 80, 0xFF))
    t3d_screen_clear_depth()
    t3d_light_set_ambient(addr(colorAmbient[0]))
    t3d_light_set_directional(0, addr(colorDir[0]), addr(lightDirVec))
    t3d_light_set_count(1)
    ##  you can use the regular rdpq_* functions with t3d.
    ##  In this example, the colored-band in the 3d-model is using the prim-color,
    ##  even though the model is recorded, you change it here dynamically.
    rdpq_set_prim_color(get_rainbow_color(rotAngle * 0.42f))
    if dplDraw != nil:
      rspq_block_begin()
      ##  Draw the model, material settings (e.g. textures, color-combiner) are handled internally
      t3d_model_draw(model)
      t3d_matrix_pop(1)
      dplDraw = rspq_block_end()
    t3d_matrix_push(addr(modelMatFP[frameIdx]))
    ##  for the actual draw, you can use the generic rspq-api.
    rspq_block_run(dplDraw)
    rdpq_detach_show()
  t3d_destroy()
  return 0
