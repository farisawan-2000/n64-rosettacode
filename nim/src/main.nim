## ===============================
## Whole lot of C glue
## ===============================
import t3d

type
  color_t {.bycopy.} = object
    r, g, b, a: uint8
  resolution_t {.bycopy.} = object
    width, height, interlaced: cint
    aspect: cfloat
    overscan: cfloat

const
  FB_COUNT* = 3
  DFS_DEFAULT_LOCATION* = 0
  DEPTH_16_BPP* = 0
  GAMMA_NONE* = 0
  FILTERS_RESAMPLE_ANTIALIAS* = 3
  RESOLUTION_320x240: resolution_t = resolution_t(
    width: 320, height: 240, interlaced: 0,
  );


proc fm_sinf(val_radians: cfloat): cfloat {.importc: "fm_sinf".}
proc debug_init_isviewer() {.importc: "debug_init_isviewer".}
proc debug_init_usblog() {.importc: "debug_init_usblog".}

proc asset_init_compression_lvl2() {.importc: "__asset_init_compression_lvl2".}
proc asset_init_compression_lvl3() {.importc: "__asset_init_compression_lvl3".}
proc init_compression(level: int) =
  case level:
    of 0, 1: discard
    of 2: asset_init_compression_lvl2()
    of 3: asset_init_compression_lvl3()
    else: discard



proc dfs_init(location: cint) {.importc: "dfs_init".}
proc display_init(
  resolution: resolution_t,
  depth: cint,
  fb_count: cint,
  gamma: cint,
  filter: cint
) {.importc: "display_init".}

proc rdpq_init() {.importc: "rdpq_init".}
proc malloc_uncached(size: csize_t): ptr {.importc: "malloc_uncached".}
proc free_uncached(pr: ptr) {.importc: "free_uncached".}

## ===============================
## Now the start of the program
## ===============================



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

##
##  Simple example with a 3d-model file created in blender.
##  This uses the builtin model format for loading and drawing a model.
##

proc main*(): cint =
  debug_init_isviewer()
  debug_init_usblog()
  init_compression(2)
  dfs_init(DFS_DEFAULT_LOCATION)
  display_init(RESOLUTION_320x240, DEPTH_16_BPP, FB_COUNT, GAMMA_NONE,
               FILTERS_RESAMPLE_ANTIALIAS)
  rdpq_init()
  t3d_init(T3DInitParams())
  ##  Now allocate a fixed-point matrix, this is what t3d uses internally.
  ##  Note: this gets DMA'd to the RSP, so it needs to be uncached.
  ##  If you can't allocate uncached memory, remember to flush the cache after writing to it instead.
  var modelMatFP: ptr T3DMat4FP = cast[ptr T3DMat4FP](malloc_uncached(sizeof(T3DMat4FP) * FB_COUNT))
  ##  allocate one matrix for each framebuffer
  ##  Also create a buffered viewport to have a distinct matrix for each frame, avoiding corruptions if the CPU is too fast
  ##  In an actual game make sure to free this viewport via 't3d_viewport_destroy' if no longer needed.
  var viewport: T3DViewport = t3d_viewport_create_buffered(FB_COUNT)
  let camPos: T3DVec3 = [[0, 10.0f, 40.0f]]
  let camTarget: T3DVec3 = [[0, 0, 0]]
  var colorAmbient: array[4, uint8_t] = [80, 80, 100, 0xFF]
  var colorDir: array[4, uint8_t] = [0xEE, 0xAA, 0xAA, 0xFF]
  var lightDirVec: T3DVec3 = [[-1.0f, 1.0f, 1.0f]]
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
    t3d_viewport_look_at(addr(viewport), addr(camPos), addr(camTarget),
                         addr((T3DVec3)), ([0, 1, 0],))
    ##  slowly rotate model, for more information on matrices and how to draw objects
    ##  see the example: "03_objects"
    t3d_mat4fp_from_srt_euler(addr(modelMatFP[frameIdx]), (float[3]),
                              (modelScale, modelScale, modelScale), (float[3]),
                              (0.0f, rotAngle * 0.2f, rotAngle), (float[3]),
                              (0, 0, 0))
    ##  ======== Draw ======== //
    rdpq_attach(display_get(), display_get_zbuf())
    t3d_frame_start()
    t3d_viewport_attach(addr(viewport))
    t3d_screen_clear_color(RGBA32(100, 80, 80, 0xFF))
    t3d_screen_clear_depth()
    t3d_light_set_ambient(colorAmbient)
    t3d_light_set_directional(0, colorDir, addr(lightDirVec))
    t3d_light_set_count(1)
    ##  you can use the regular rdpq_* functions with t3d.
    ##  In this example, the colored-band in the 3d-model is using the prim-color,
    ##  even though the model is recorded, you change it here dynamically.
    rdpq_set_prim_color(get_rainbow_color(rotAngle * 0.42f))
    if not dplDraw:
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
