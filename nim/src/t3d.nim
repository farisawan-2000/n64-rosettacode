##
##  @copyright 2023 - Max Bebök
##  @license MIT
##  @file t3d.h
##
import t3dmath

const
  T3D_VERTEX_CACHE_SIZE* = 70

var T3D_RSP_ID*: uint32

##  RSP commands, must match with the commands defined in `rsp/rsp_tiny3d.rspl`

type
  T3DCmd* = enum
    T3D_CMD_TRI_DRAW = 0x0, T3D_CMD_SCREEN_SIZE = 0x1, T3D_CMD_MATRIX_STACK = 0x2,
    T3D_CMD_SET_WORD = 0x3, T3D_CMD_VERT_LOAD = 0x4, T3D_CMD_LIGHT_SET = 0x5,
    T3D_CMD_DRAWFLAGS = 0x6, T3D_CMD_PROJ_SET = 0x7, T3D_CMD_PATCH = 0x8,
    T3D_CMD_FOG_STATE = 0x9, T3D_CMD_TRI_SYNC = 0xA, T3D_CMD_TRI_STRIP = 0xB, T3D_CMD_TRI_SEQ = 0xC ##
                                                                                        ## =
                                                                                        ## 0xD,
                                                                                        ##
                                                                                        ## =
                                                                                        ## 0xE,
                                                                                        ##
                                                                                        ## =
                                                                                        ## 0xF,


##  Internal vertex format, interleaves two vertices

type
  T3DVertPacked* {.bycopy.} = object
    ##  0x00
    posA*: array[3, int16]
    ##  s16 (used in the ucode as the int. part of a s16.16)
    ##  0x06
    normA*: uint16
    ##  5,6,5 packed normal
    ##  0x08
    posB*: array[3, int16]
    ##  s16 (used in the ucode as the int. part of a s16.16)
    ##  0x0E
    normB*: uint16
    ##  5,6,5 packed normal
    ##  0x10
    rgbaA*: uint32
    ##  RGBA8 color
    ##  0x14
    rgbaB*: uint32
    ##  RGBA8 color
    ##  0x18
    stA*: array[2, int16]
    ##  UV fixed point 10.5 (pixel coords)
    ##  0x1C
    stB*: array[2, int16]
    ##  UV fixed point 10.5 (pixel coords)

type
  T3DDrawFlags* = enum
    T3D_FLAG_DEPTH = 1 shl 0, T3D_FLAG_TEXTURED = 1 shl 1, T3D_FLAG_SHADED = 1 shl 2,
    T3D_FLAG_CULL_FRONT = 1 shl 3, T3D_FLAG_CULL_BACK = 1 shl 4,
    T3D_FLAG_NO_LIGHT = 1 shl 16


##  Segment addresses, some are used internally but can be set by the user too

type
  T3DSegment* = enum
    T3D_SEGMENT_1 = 1, T3D_SEGMENT_2 = 2, T3D_SEGMENT_3 = 3, T3D_SEGMENT_4 = 4,
    T3D_SEGMENT_5 = 5, T3D_SEGMENT_6 = 6, T3D_SEGMENT_SKELETON = 7


##  Vertex effect functions

type
  T3DVertexFX* = enum
    T3D_VERTEX_FX_NONE = 0, T3D_VERTEX_FX_SPHERICAL_UV = 1,
    T3D_VERTEX_FX_CELSHADE_COLOR = 2, T3D_VERTEX_FX_CELSHADE_ALPHA = 3,
    T3D_VERTEX_FX_OUTLINE = 4, T3D_VERTEX_FX_UV_OFFSET = 5


##  computation to use to combine lighting and vertex color

type
  T3DLightingMode* = enum
    T3D_LIGHTING_MODE_MUL = 0, T3D_LIGHTING_MODE_ADD = 1


##
##  Viewport, combines several settings which are usually used together.
##  This includes the screen-rect, camera-matrix and projection-matrix.
##
##  Note: members considered private are prefixed with an underscore.
##

type
  T3DViewport* {.bycopy.} = object
    matCameraFP*: T3DMat4FP   ## deprecated("Use t3d_viewport_set_view_matrix()")
    matProjFP*: T3DMat4FP     ## deprecated("Use t3d_viewport_set_projection_matrix()")
    matCamera*: T3DMat4
    ##  view matrix, can be set via `t3d_viewport_look_at`
    matProj*: T3DMat4
    ##  projection matrix, can be set via `t3d_viewport_set_projection`
    matCamProj*: T3DMat4
    ##  combined view-projection matrix, calculated automatically on demand
    viewFrustum*: T3DFrustum
    ##  frustum, calculated from the combined matrix
    isCamProjDirty*: bool
    ##  flag to indicate if the combined matrix needs to be recalculated
    offset*: array[2, int32]
    ##  screen offset in pixel, [0,0] by default
    size*: array[2, int32]
    ##  screen size in pixel, same as the allocated framebuffer size by default
    guardBandScale*: cint
    ##  guard band for clipping, 2 by default
    useRejection*: cint
    ##  use rejection instead of clipping, false by default
    normScaleW*: cfloat
    ##  factor to normalize W in the ucode, set automatically
    bufferCount*: uint16
    ##  amount of matrices / framebuffers
    bufferIdx*: uint16
    ##  current buffer index
    matFP*: ptr T3DMat4FP
    ##  stores both camera and projection matrices


##
##  Settings to configure t3d during initialization.
##

type
  T3DInitParams* {.bycopy.} = object
    ##  Internal matrix stack size, must be at least 2.
    ##  If set two zero, 8 will be used by default.
    matrixStackSize*: cint


##
##  Struct containing rendering metrics.
##  Retrieved via `t3d_metrics_fetch`.
##

type
  T3DMetrics* {.bycopy.} = object
    trisPreCull*: uint32
    trisPostCull*: uint32


##
##  @brief Initializes the tiny3d library
##  @param params settings to configure the library
##

proc t3d_init(params: T3DInitParams) {.importc: "t3d_init".}
##
##  @brief Destroys the tiny3d library
##

proc t3d_destroy*()
##
##  @brief Starts a new frame, this will setup some default states
##

proc t3d_frame_start*()
##  @brief Clears the entire screen with a given color

proc t3d_screen_clear_color*(color: color_t)
##  @brief Clears the entire depth buffer with a fixed value (0xFFFC)

proc t3d_screen_clear_depth*()
##
##  NOTE: This function is a stub and does nothing for now!
##
##  Fetches rendering metrics into the given struct.
##  @param data pointer to struct to fill
##  @deprecated DO NOT USE
##

proc t3d_metrics_fetch*(data: ptr T3DMetrics)
##
##  Creates a viewport struct, this only creates a struct and doesn't change any setting.
##  Most likely you want to update the camera and projection matrix over time,
##  in which case you should use 't3d_viewport_create_buffered' instead.
##
##  Once done, free the viewports internal data via 't3d_viewport_destroy'.
##  (Note that for compatibility reasons, this is not strictly necessary unless buffered)
##
##  @return struct with the documented default values
##

proc t3d_viewport_create*(): T3DViewport {.inline.} =
  ## !!!Ignored construct:  return ( T3DViewport ) { . _isCamProjDirty = true , . offset = { 0 , 0 } , . size = { ( int32 ) display_get_width ( ) , ( int32 ) display_get_height ( ) } , . guardBandScale = 2 , . useRejection = false , . _bufferCount = 0 , . _matFP = NULL , } ;
  ## Error: token expected: ; but got: {!!!

##
##  Same as 't3d_viewport_create' but buffered.
##  This will allow you to change matrices over time without running into race-conditions
##  with the RSP.
##
##  Once done, free the viewports internal data via 't3d_viewport_destroy'.
##
##  @param count amount of buffered matrices (usually amount of framebuffers)
##  @return struct with the documented default values
##

proc t3d_viewport_create_buffered*(count: uint16): T3DViewport {.inline.} =
  var vp: T3DViewport = t3d_viewport_create()
  vp.bufferCount = count
  vp.bufferIdx = 0
  vp.matFP = cast[ptr T3DMat4FP](malloc_uncached(sizeof((T3DMat4FP) * 2 * count)))
  return vp

##
##  Destroys a viewport and frees allocated internal data.
##
##  Note that since you still hold the struct itself, any further use of it is undefined behavior.
##  To create a new viewport overwrite the struct with a new one from 't3d_viewport_create' instead.
##
##  @param viewport viewport to destroy
##

proc t3d_viewport_destroy*(viewport: ptr T3DViewport) {.inline.} =
  if viewport.matFP:
    free_uncached(viewport.matFP)
    viewport.matFP = nil
    viewport.bufferCount = 0
    viewport.bufferIdx = 0

##
##  Uses the given viewport for further rendering and applies its settings.
##  This will set the visible screen-rect, and apply the camera and projection matrix.
##
##  Note that you may have to re-apply directional lights if you are using multiple viewports,
##  as they are depend on the view matrix.
##
##  @param viewport viewport, pointer must be valid until the next `t3d_viewport_attach` call
##

proc t3d_viewport_attach*(viewport: ptr T3DViewport)
##
##  Returns the currently attached viewport.
##  @return viewport or NULL if none is attached
##

proc t3d_viewport_get*(): ptr T3DViewport
##
##  Convenience function to set the area of a viewport.
##  @param viewport
##  @param x position (0 by default)
##  @param y
##  @param width size (display width by default)
##  @param height
##

proc t3d_viewport_set_area*(viewport: ptr T3DViewport; x: int32; y: int32;
                           width: int32; height: int32) {.inline.} =
  viewport.offset[0] = x
  viewport.offset[1] = y
  viewport.size[0] = width
  viewport.size[1] = height

##
##  Updates the projection matrix of the given viewport using a perspective projection.
##  The proj. matrix gets auto. applied at the next `t3d_viewport_attach` call.
##
##  @param viewport
##  @param fov fov in radians
##  @param aspectRatio aspect ratio (= width / height)
##  @param near near plane distance
##  @param far far plane distance (should be >=40 to avoid depth-precision issues)
##

proc t3d_viewport_set_perspective*(viewport: ptr T3DViewport; fov: cfloat;
                                  aspectRatio: cfloat; near: cfloat; far: cfloat)
##
##  Updates the projection matrix of the given viewport.
##  The proj. matrix gets auto. applied at the next `t3d_viewport_attach` call.
##
##  NOTE: if you need a custom aspect ratio, use 't3d_viewport_set_perspective' instead.
##
##  @param viewport
##  @param fov fov in radians
##  @param near near plane distance
##  @param far far plane distance (should be >=40 to avoid depth-precision issues)
##

proc t3d_viewport_set_projection*(viewport: ptr T3DViewport; fov: cfloat;
                                 near: cfloat; far: cfloat)
##
##  Sets an orthographic projection matrix for the given viewport.
##  The matrix gets auto. applied at the next `t3d_viewport_attach` call.
##  @param viewport
##  @param left
##  @param right
##  @param bottom
##  @param top
##  @param near near plane distance
##  @param far far plane distance (should be >=40 to avoid depth-precision issues)
##

proc t3d_viewport_set_ortho*(viewport: ptr T3DViewport; left: cfloat; right: cfloat;
                            bottom: cfloat; top: cfloat; near: cfloat; far: cfloat)
##
##  Sets the normalization factor for W in the ucode.
##  NOTE: this gets called automatically by `t3d_viewport_set_projection`.
##  You only need to call this if you want to provide your own projection matrix.
##
##  @param viewport
##  @param near
##  @param far
##

proc t3d_viewport_set_w_normalize*(viewport: ptr T3DViewport; near: cfloat;
                                  far: cfloat) {.inline.} =
  viewport.normScaleW = 2.0f div (far + near)

##
##  Sets a new camera position and direction for the given viewport.
##  The view matrix gets auto. applied at the next `t3d_viewport_attach` call.
##
##  @param eye camera position
##  @param target camera target/look-at
##  @param up camera up vector, expected to be {0,1,0} by default
##

proc t3d_viewport_look_at*(viewport: ptr T3DViewport; eye: ptr T3DVec3;
                          target: ptr T3DVec3; up: ptr T3DVec3)
##
##  Sets a new view (aka camera) matrix for the given viewport.
##  If you have a look-at based camera prefer using 't3d_viewport_look_at'.
##
##  @param viewport viewport to set for
##  @param mat new view matrix
##

proc t3d_viewport_set_view_matrix*(viewport: ptr T3DViewport; mat: ptr T3DMat4)
##
##  Sets a new projection matrix for the given viewport.
##  If you have a perspective or orthographic projection prefer using
##  't3d_viewport_set_projection' or 't3d_viewport_set_ortho'.
##
##  @param viewport viewport to set for
##  @param mat new projection matrix
##

proc t3d_viewport_set_projection_matrix*(viewport: ptr T3DViewport; mat: ptr T3DMat4)
##
##  Calculates the view-space position of a given world-space position.
##  This will also handle offset viewports (e.g. for splitscreens)
##
##  @param viewport viewport to calculate for
##  @param out output screen-space vector
##  @param pos input world-space position
##

proc t3d_viewport_calc_viewspace_pos*(viewport: ptr T3DViewport; `out`: ptr T3DVec3;
                                     pos: ptr T3DVec3)
##
##  @brief Draws a single triangle, referencing loaded vertices
##  @param v0 vertex index 0
##  @param v1 vertex index 1
##  @param v2 vertex index 2
##

proc t3d_tri_draw*(v0: uint32; v1: uint32; v2: uint32)
##
##  Draws multiple triangles, assuming sequential indices.
##  For example with baseIndex=4 and triCount=2, we would get
##   -> 4,5,6  7,8,9
##  This is effectively performing an un-indexed draw of triangles,
##  but without the overhead of loading an index-buffer.
##  This method is faster than going through 't3d_tri_draw_strip'.
##
##  @param baseIndex first index
##  @param triCount amount of triangles to draw
##

proc t3d_tri_draw_unindexed*(baseIndex: uint32; triCount: uint32)
##
##  Draws multiple quads, assuming sequential indices.
##  For example with baseIndex=4 and quadCount=2, we would get
##   -> 4,5,6  7,6,5,  8,9,10, 11,10,9
##  This is effectively performing an un-indexed draw of quads,
##  but without the overhead of loading an index-buffer.
##  This method is faster than going through 't3d_tri_draw_strip'.
##
##  @param baseIndex first index
##  @param triCount amount of quads to draw
##

proc t3d_quad_draw_unindexed*(baseIndex: uint32; quadCount: uint32)
##
##  Draws a strip of triangles by loading an index buffer.
##  Note that this data must be in an internal format, so use 't3d_indexbuffer_convert' to convert it first.
##  The docs of 't3d_indexbuffer_convert' also describe the format of the input data.
##
##  The data behind 'indexBuff' will be DMA'd by the ucode, so it must be aligned to 8 bytes,
##  and persist in memory until the triangles are drawn.
##  The target location of the DMA in DMEM is shared with the vertex cache, aligned to the end.
##  Make sure that there is enough space left to load the indices to not corrupt the vertices.
##  E.g. if you loaded 68 vertices, you have 2 slots free or 36*2 bytes, meaning you can load 36 indices.
##  Note that due to alignment reasons, a safety margin of 4 indices should be added if the free vertex count is odd.
##
##  The built-in model format will use this function internally, if you plan on manually using it for model data,
##  check out 'tools/gltf_importer/src/optimizer/meshOptimizer.cpp' for an algorithm to do so.
##
##  @param indexBuff index buffer to load
##  @param count amount of indices to load
##

proc t3d_tri_draw_strip*(indexBuff: ptr int16; count: cint)
##
##  Combined `t3d_tri_draw_strip` + `t3d_tri_sync`.
##  See individual functions for more details.
##
##  @param indexBuff index buffer to load
##  @param count amount of indices to load
##

proc t3d_tri_draw_strip_and_sync*(indexBuff: ptr int16; count: cint)
##
##  Syncs pending triangles.
##  This needs to be called after triangles where drawn and a different overlay
##  which also generates RDP commands will be used. (e.g. RDPQ)
##

proc t3d_tri_sync*() {.inline.} =
  rspq_write(T3D_RSP_ID, T3D_CMD_TRI_SYNC, 0)

##
##  Directly loads a matrix, overwriting the current stack position.
##
##  With 'doMultiply' set to false, this lets you completely replace the current matrix.
##  With 'doMultiply' set to true, it serves as a faster version of a pop+push combination.
##
##  @param mat address to load matrix from
##  @param doMultiply if true, the matrix will be multiplied with the previous stack entry
##

proc t3d_matrix_set*(mat: ptr T3DMat4FP; doMultiply: bool)
##
##  Multiplies a matrix with the current stack position, then pushes it onto the stack.
##  @param mat address to load matrix from
##

proc t3d_matrix_push*(mat: ptr T3DMat4FP)
##
##  Pops the current matrix from the stack.
##  @param count how many matrices to pop
##

proc t3d_matrix_pop*(count: cint)
##
##  Moves the stack pos. without changing a matrix or causing re-calculations.
##  This should only be used in preparation for 't3d_matrix_set' calls.
##
##  E.g. instead of multiple push/pop combis, use:
##  - 't3d_matrix_push_pos(1)' once
##  - then multiple 't3d_matrix_set'
##  - finish with 't3d_matrix_pop'
##
##  This is the most efficient way to set multiple matrices at the same level.
##  @param count relative change (matrix count), should usually be 1
##

proc t3d_matrix_push_pos*(count: cint)
##
##  Sets the projection matrix, this is stored outside of the matrix stack.
##  @param mat address to load matrix from
##

proc t3d_matrix_set_proj*(mat: ptr T3DMat4FP)
##
##  Loads a vertex buffer with a given size, this can then be used to draw triangles.
##
##  @param vertices vertex buffer
##  @param offset offset in the target buffer (0-68)
##  @param count how many vertices to load (1-70)
##

proc t3d_vert_load*(vertices: ptr T3DVertPacked; offset: uint32; count: uint32)
##
##  Sets the global ambient light color.
##  This color is always active and applied to all objects.
##  To disable the ambient light, set the color to black.
##  @param color color in RGBA8 format
##

proc t3d_light_set_ambient*(color: ptr uint8_t)
##
##  Sets a directional light.
##  You can set up to 7 directional lights, the amount can be set with 't3d_light_set_count'.
##  Note that directional and point lights share the same space.
##
##  @param index index (0-6)
##  @param color color in RGBA8 format
##  @param dir direction vector
##

proc t3d_light_set_directional*(index: cint; color: ptr uint8_t; dir: ptr T3DVec3)
##
##  Sets a point light.
##  You can set up to 7 point lights, the amount can be set with 't3d_light_set_count'.
##  Note that point and directional lights share the same space.
##
##  The position is expected to be in world-space, and will be transformed internally.
##  Before calling this function, make sure to have a viewport attached.
##
##  The size argument is roughly the maximum radius in world-space the light will cover.
##  Note that due to precision limitations and the fact lighting happens per vertex, the size is not exact.
##
##  @param index index (0-6)
##  @param color color in RGBA8 format
##  @param pos position in world-space
##  @param size distance, in world-space
##  @param ignoreNormals if true, the light will only check the distance, not the angle (useful for cutouts)
##

proc t3d_light_set_point*(index: cint; color: ptr uint8_t; pos: ptr T3DVec3;
                         size: cfloat; ignoreNormals: bool)
##
##  Sets the amount of active lights (excl. ambient light).
##  Note that the ambient light does not count towards this limit and is always applied.
##  @param count amount of lights (0-6)
##

proc t3d_light_set_count*(count: cint)
##
##  Sets the final color exposure.
##  This will be applied to the combined light + vertex color as a simple scaling factor.
##  Any value above 1.0 after scaling will be clamped.
##  This setting can be used to implement a simple form of HDR.
##
##  Note that negative values are allowed and will invert the color to some extend.
##
##  @param exposure factor, 1.0 by default
##

proc t3d_light_set_exposure*(exposure: cfloat)
##
##  Sets the range of the fog.
##  To disable fog, use 't3d_fog_disable' or set 'near' and 'far' to 0.
##  Note: in order for fog itself to work, make sure to setup the needed RSPQ commands.
##
##  @param near start of the fog effect
##  @param far end of the fog effect
##

proc t3d_fog_set_range*(near: cfloat; far: cfloat)
##
##  Enables or disables fog, this can be set independently from the range.
##  @param isEnabled
##

proc t3d_fog_set_enabled*(isEnabled: bool) {.inline.} =
  ##  0xB/0xC are the offsets of attributes (color/UV) in a vertex on the RSP side
  ##  this allows the code to do a branch-less save.
  ##  0xB points to alpha of the current vertex, 0xC to the UV which get overwritten later
  rspq_write(T3D_RSP_ID, T3D_CMD_FOG_STATE, if isEnabled: 0x0B else: 0x0C)

##
##  Packs a floating-point normal into the internal 5.6.5 format.
##  @param normal normal vector
##  @return packed normal
##

proc t3d_vert_pack_normal*(normal: ptr T3DVec3): uint16
##
##  Sets various draw flags, this will affect how triangles are drawn.
##  @param drawFlags
##

proc t3d_state_set_drawflags*(drawFlags: T3DDrawFlags)
##
##  Offsets the final screen-space depth by a fixed amount.
##  This can be used as an alternative to decals by drawing normally with an offset instead.
##  E.g.: t3d_state_set_depth_offset(-0x40);
##
##  @param offset relative offset, negative value to pull depth closer. Pass '0' to reset.
##

proc t3d_state_set_depth_offset*(offset: int16)
##
##  Enables or disables the alpha-to-tile feature.
##  This will cause the 3 MSBs of the input vertex alpha to be stored as the base tile.
##  Which is later used during triangle draws to define what TEX0 is (by default TILE0).
##  This feature is completely free and adds no extra time.
##
##  This can be useful if you can preload a tile-set into TMEM containing multiple textures.
##  By setting up distinct tiles you can still take advantage of repeating UVs.
##  Each triangle can then select its own tile without a costly texture or state switches inbetween.
##
##  NOTE: since a triangle can only have one tile, it is expected that all vertices have the same tile set.
##  Otherwise it is considered undefined behavior.
##  Furthermore, When loading vertices it is expected that both vertices in the interleaved struct
##  must contain the same tile value.
##
##  @param enable true to enable for future vertex loads, false to disable.
##

proc t3d_state_set_alpha_to_tile*(enable: bool)
##
##  Sets a function for vertex effects.
##  To disable it, set the function to 'T3D_VERTEX_FX_NONE'.
##  The arg0/arg1 values are stored ín DMEM and are used by the ucode.
##
##  The meaning of those arguments depends on the type:
##  - T3D_VERTEX_FX_NONE          : (no arguments)
##  - T3D_VERTEX_FX_SPHERICAL_UV  : texture width/height
##  - T3D_VERTEX_FX_CELSHADE_COLOR: (no arguments)
##  - T3D_VERTEX_FX_CELSHADE_ALPHA: (no arguments)
##  - T3D_VERTEX_FX_OUTLINE       : pixel size X/Y
##  - T3D_VERTEX_FX_UV_OFFSET     : UV offset, same 10.5 format as vertex
##
##  @param func vertex effect function
##  @param arg0 first argument
##  @param arg1 second argument
##

proc t3d_state_set_vertex_fx*(`func`: T3DVertexFX; arg0: int16; arg1: int16)
##
##  Overrides the scale factor for some vertex effects.
##  This is currently only used by the 'T3D_VERTEX_FX_SPHERICAL_UV' function
##  to create an offset based on screen-space position.
##  This is automatically calculated by the ucode when setting the screen-size.
##  However if you see distortions near the edge of the screen, you can set this manually.
##  @param scale scale factor
##

proc t3d_state_set_vertex_fx_scale*(scale: uint16)
##
##  Changes the way lighting is combined with vertex color in the ucode.
##  Each light source is always added together to form the total light intensity per vertex.
##  This color is then multiplied by the vertex color to produce the final SHADE value for the CC.
##  This function allows changing this to do a (saturated) addition instead.
##
##  Use-cases can be baking lighting into vertex colors to have dynamic lighting on top.
##  Note that you are still able to preserve the original vertex alpha by setting all
##  light sources alpha value to 0.
##  That allows you to even bake AO into alpha in the model, and then later do a multiplication in the CC.
##
##  NOTE:<br>
##  Changing this mode internally patches the ucode.
##  The process is not particularly expensive, but still a lot more than other settings.
##  It should not be used on a per-material basis, but rather as a global setting you set once per scene or draw layer.
##
##  Since the ucode is only refreshed on the next ucode switch, you have to make sure this happens before any draws.
##  This can be done by making sure that after this call, and before the next vertex load, any RDPQ call was made.
##
##  @param mode additive or multiplicative lighting, multiplicative by default
##

proc t3d_state_set_lighting_mode*(mode: T3DLightingMode)
##
##  Sets a new address in the segment table.
##  This acts as a base-address for addresses in matrices/vertices
##  with a matching segment index.
##  Segment 0 is reserved and always has a zero value.
##  @param segmentId id (1-7)
##  @param address base RDRAM address
##

proc t3d_segment_set*(segmentId: uint8_t; address: pointer)
##
##  Creates a dummy address to be used for vertex/matrix loads.
##  This will cause the address in the segment table to be used instead.
##  If you need relative addressing instead, use 't3d_segment_address'
##  @param segmentId id (1-7)
##  @return segmented address
##

proc t3d_segment_placeholder*(segmentId: uint8_t): pointer {.inline.} =
  return cast[pointer]((uint32)(segmentId shl (8 * 3 + 2)))

##
##  Converts an address into a segmented one.
##  If used in a vertex/matrix load, it will cause the segment table to be used
##  and the address in there to be added on top.
##  To set entries in the segment table use 't3d_segment_set'.
##  @param segmentId id (1-7)
##  @param ptr pointer, can be NULL for absolute addressing
##  @return segmented address
##

proc t3d_segment_address*(segmentId: uint8_t; `ptr`: pointer): pointer {.inline.} =
  return cast[pointer]((PhysicalAddr(`ptr`) or (segmentId shl (8 * 3 + 2))))

##  Index-buffer helpers:
##
##  Converts an index buffer for triangle strips from indices to encoded DMEM pointers.
##  This is necessary in order for 't3d_tri_draw_strip' to work.
##  Internally this data will be DMA'd by the ucode later on.
##
##  Format:
##  The input data is expected to be an array of local indices (0-69) as s16 values.
##  The first 3 values define the initial triangle.
##  Every index afterwards will extend the strip by one triangle (winding order flipped).
##  Degenerate triangles are NOT supported, since it is always more efficient to use a restart flag.
##  To start a new strip, set the MSB of the next index, so: 'idx | (1<<15)'
##  meaning the flagged value and the 2 following values will form a new triangle, re-starting the strip.
##  Since restarting does not need a special index value, non-stripped indices (triangle lists)
##  can be encoded too without overhead.
##
##  Examples:   (original triangles -> expected input of this function)
##  [4,5,6] [0,1,2] [7,8,9]         -> [4,5,6,(0x8000|0),1,2,(0x8000|7),8,9]
##  [0,1,2] [3,0,2] [0,3,4] [5,0,4] -> [1,2,0,3,0,4,5]
##
##  @param indices index buffer of local indices, will be modified in-place
##  @param count index count
##

proc t3d_indexbuffer_convert*(indices: ptr int16; count: cint)
##  Vertex-buffer helpers:
##
##  Returns the pointer to a position of a vertex in a buffer
##  @param vert vertex buffer
##  @param idx vertex index
##

proc t3d_vertbuffer_get_pos*(vert: ptr T3DVertPacked; idx: cint): ptr int16 {.inline.} =
  return if (idx and 1): vert[idx div 2].posB else: vert[idx div 2].posA

##
##  Returns the pointer to the UV of a vertex in a buffer
##  @param vert vertex buffer
##  @param idx vertex index
##

proc t3d_vertbuffer_get_uv*(vert: ptr T3DVertPacked; idx: cint): ptr int16 {.inline.} =
  return if (idx and 1): vert[idx div 2].stB else: vert[idx div 2].stA

##
##  Returns the pointer to the color (as a u32) of a vertex in a buffer
##  @param vert vertex buffer
##  @param idx vertex index
##

proc t3d_vertbuffer_get_color*(vert: ptr T3DVertPacked; idx: cint): ptr uint32 {.
    inline.} =
  return if (idx and 1): addr(vert[idx div 2].rgbaB) else: addr(vert[idx div 2].rgbaA)

##
##  Returns the pointer to the color (as a u8[4]) of a vertex in a buffer
##  @param vert vertex buffer
##  @param idx vertex index
##

proc t3d_vertbuffer_get_rgba*(vert: ptr T3DVertPacked; idx: cint): ptr uint8_t {.inline.} =
  return if (idx and 1): cast[ptr uint8_t](addr(vert[idx div 2].rgbaB)) else: cast[ptr uint8_t](addr(vert[
      idx div 2].rgbaA))

##
##  Returns the pointer to the packed normal of a vertex in a buffer
##  @param vert vertex buffer
##  @param idx vertex index
##

proc t3d_vertbuffer_get_norm*(vert: ptr T3DVertPacked; idx: cint): ptr uint16 {.inline.} =
  return if (idx and 1): addr(vert[idx div 2].normB) else: addr(vert[idx div 2].normA)

##  C++ wrappers that allow (const-)references to be passed instead of pointers
