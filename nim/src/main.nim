import libdragon
## ##
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
