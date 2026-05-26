##
##  @copyright 2023 - Max Bebök
##  @license MIT
##  @file t3dmath.h
##

template T3D_DEG_TO_RAD*(deg: untyped): untyped =
  (deg * 0.01745329252f)

template T3D_F32_TO_FIXED*(val: untyped): untyped =
  (int32_t)((val) * (float)(1 shl 16))

const
  T3D_PI* = 3.14159265358979f

##  3D float vector

type
  T3DVec3* = array[3, float]
  T3DVec4* = array[4, float]
  T3DQuat* = fm_quat_t
  T3DMat4* = fm_mat4_t

##  3D s16.16 fixed-point vector, used as-is by the RSP.

type
  T3DVec4FP* {.bycopy.} = object
    i*: array[4, int16_t]
    f*: array[4, uint16_t]


##  4x4 Matrix of 16.16 fixed-point numbers, used as-is by the RSP.

type
  T3DMat4FP* {.bycopy.} = object
    m*: array[4, T3DVec4FP]


##  View frustum, used in culling functions

type
  T3DFrustum* {.bycopy.} = object
    planes*: array[6, T3DVec4]


##  @brief Converts a 16.16 fixed-point number to a float

proc s1616_to_float*(partI: int16_t; partF: uint16_t): cfloat {.inline.} =
  var res: cfloat = cast[cfloat](partI)
  inc(res, cast[cfloat](partF div 65536.f))
  return res

##  @brief Interpolates between two floats by 't'

proc t3d_lerp*(a: cfloat; b: cfloat; t: cfloat): cfloat {.inline.} =
  return a + (b - a) * t

##  @brief Interpolates between two angles (radians) by 't'

proc t3d_lerp_angle*(a: cfloat; b: cfloat; t: cfloat): cfloat {.inline.} =
  var angleDiff: cfloat = fmodf((b - a), T3D_PI * 2)
  var shortDist: cfloat = fmodf(angleDiff * 2, T3D_PI * 2) - angleDiff
  return a + shortDist * t

##  @brief Sets 'res' to 'a + b'

proc t3d_vec3_add*(res: ptr T3DVec3; a: ptr T3DVec3; b: ptr T3DVec3) {.inline.} =
  res.v[0] = a.v[0] + b.v[0]
  res.v[1] = a.v[1] + b.v[1]
  res.v[2] = a.v[2] + b.v[2]

##  @brief Sets 'res' to 'a + b'

proc t3d_vec3_mul*(res: ptr T3DVec3; a: ptr T3DVec3; b: ptr T3DVec3) {.inline.} =
  res.v[0] = a.v[0] * b.v[0]
  res.v[1] = a.v[1] * b.v[1]
  res.v[2] = a.v[2] * b.v[2]

##  @brief Sets 'res' to 'a * s'

proc t3d_vec3_scale*(res: ptr T3DVec3; a: ptr T3DVec3; s: cfloat) {.inline.} =
  res.v[0] = a.v[0] * s
  res.v[1] = a.v[1] * s
  res.v[2] = a.v[2] * s

##  @brief Set 'res' to 'a - b'

proc t3d_vec3_diff*(res: ptr T3DVec3; a: ptr T3DVec3; b: ptr T3DVec3) {.inline.} =
  res.v[0] = a.v[0] - b.v[0]
  res.v[1] = a.v[1] - b.v[1]
  res.v[2] = a.v[2] - b.v[2]

##  @brief Returns the squared length of 'v'

proc t3d_vec3_len2*(vec: ptr T3DVec3): cfloat {.inline.} =
  return vec.v[0] * vec.v[0] + vec.v[1] * vec.v[1] + vec.v[2] * vec.v[2]

##  @brief Returns the length of 'v'

proc t3d_vec3_len*(vec: ptr T3DVec3): cfloat {.inline.} =
  return sqrtf(t3d_vec3_len2(vec))

##  @brief Returns the squared distance between 'vecA' and 'vecB'

proc t3d_vec3_distance2*(vecA: ptr T3DVec3; vecB: ptr T3DVec3): cfloat {.inline.} =
  var diff: T3DVec3
  t3d_vec3_diff(addr(diff), vecA, vecB)
  return t3d_vec3_len2(addr(diff))

##  @brief Returns the distance between 'vecA' and 'vecB'

proc t3d_vec3_distance*(vecA: ptr T3DVec3; vecB: ptr T3DVec3): cfloat {.inline.} =
  return sqrtf(t3d_vec3_distance2(vecA, vecB))

##  @brief Normalizes 'res', this does NOT check for a zero-length vector

proc t3d_vec3_norm*(res: ptr T3DVec3) {.inline.} =
  var len: cfloat = sqrtf(t3d_vec3_len2(res))
  if len < 0.0001f:
    len = 0.0001f
  res.v[0] = res.v[0] / len
  res.v[1] = res.v[1] / len
  res.v[2] = res.v[2] / len

##  @brief Crosses 'a' with 'b' and stores it in 'res'

proc t3d_vec3_cross*(res: ptr T3DVec3; a: ptr T3DVec3; b: ptr T3DVec3) {.inline.} =
  res.v[0] = a.v[1] * b.v[2] - b.v[1] * a.v[2]
  res.v[1] = a.v[2] * b.v[0] - b.v[2] * a.v[0]
  res.v[2] = a.v[0] * b.v[1] - b.v[0] * a.v[1]

##  @brief Returns the dot product of 'a' and 'b'

proc t3d_vec3_dot*(a: ptr T3DVec3; b: ptr T3DVec3): cfloat {.inline.} =
  return a.v[0] * b.v[0] + a.v[1] * b.v[1] + a.v[2] * b.v[2]

##  @brief Linearly interpolates between 'a' and 'b' by 't' and stores it in 'res'

proc t3d_vec3_lerp*(res: ptr T3DVec3; a: ptr T3DVec3; b: ptr T3DVec3; t: cfloat) {.inline.} =
  res.v[0] = a.v[0] + (b.v[0] - a.v[0]) * t
  res.v[1] = a.v[1] + (b.v[1] - a.v[1]) * t
  res.v[2] = a.v[2] + (b.v[2] - a.v[2]) * t

##  @brief Resets a quaternion to the identity quaternion

proc t3d_quat_identity*(quat: ptr T3DQuat) {.inline.} =
  ## !!!Ignored construct:  * quat = ( T3DQuat ) { { 0 , 0 , 0 , 1 } } ;
  ## Error: expected ';'!!!

##
##  Creates a quaternion from euler angles (radians)
##  @param quat result (in XYZW order)
##  @param rotEuler
##

proc t3d_quat_from_euler*(quat: ptr T3DQuat; rotEuler: array[3, cfloat]) {.inline.} =
  var c1: cfloat = fm_cosf(rotEuler[0] div 2.0f)
  var s1: cfloat = fm_sinf(rotEuler[0] div 2.0f)
  var c2: cfloat = fm_cosf(rotEuler[1] div 2.0f)
  var s2: cfloat = fm_sinf(rotEuler[1] div 2.0f)
  var c3: cfloat = fm_cosf(rotEuler[2] div 2.0f)
  var s3: cfloat = fm_sinf(rotEuler[2] div 2.0f)
  quat.v[0] = c1 * c2 * s3 - s1 * s2 * c3
  quat.v[1] = s1 * c2 * c3 - c1 * s2 * s3
  quat.v[2] = c1 * s2 * c3 + s1 * c2 * s3
  quat.v[3] = c1 * c2 * c3 + s1 * s2 * s3

##
##  Creates a quaternion from a rotation (radians) around an axis
##  @param quat result
##  @param axis rotation axis
##  @param angleRad angle in radians
##

proc t3d_quat_from_rotation*(quat: ptr T3DQuat; axis: array[3, cfloat];
                            angleRad: cfloat) {.inline.} =
  var s: cfloat = fm_sinf(angleRad div 2.0f)
  var c: cfloat = fm_cosf(angleRad div 2.0f)
  ## !!!Ignored construct:  * quat = ( T3DQuat ) { { axis [ 0 ] * s , axis [ 1 ] * s , axis [ 2 ] * s , c } } ;
  ## Error: expected ';'!!!

##
##  Multiplies two quaternions and stores the result in 'res'.
##  NOTE: if 'a' or 'b' point to the same quat. as 'res', the result will be incorrect.
##
##  @param res result
##  @param a first quaternion
##  @param b second quaternion
##

proc t3d_quat_mul*(res: ptr T3DQuat; a: ptr T3DQuat; b: ptr T3DQuat) {.inline.} =
  res.v[0] = a.v[3] * b.v[0] + a.v[0] * b.v[3] + a.v[1] * b.v[2] - a.v[2] * b.v[1]
  res.v[1] = a.v[3] * b.v[1] - a.v[0] * b.v[2] + a.v[1] * b.v[3] + a.v[2] * b.v[0]
  res.v[2] = a.v[3] * b.v[2] + a.v[0] * b.v[1] - a.v[1] * b.v[0] + a.v[2] * b.v[3]
  res.v[3] = a.v[3] * b.v[3] - a.v[0] * b.v[0] - a.v[1] * b.v[1] - a.v[2] * b.v[2]

##
##  Rotates a quaternion around an axis
##  @param quat quat to modify
##  @param axis rotation axis
##  @param angleRad angle in radians
##

proc t3d_quat_rotate_euler*(quat: ptr T3DQuat; axis: array[3, cfloat]; angleRad: cfloat) {.
    inline.} =
  var
    tmp: T3DQuat
    quatRot: T3DQuat
  t3d_quat_from_rotation(addr(quatRot), axis, angleRad)
  t3d_quat_mul(addr(tmp), quat, addr(quatRot))
  quat[] = tmp

##
##  Dot product of a quaternion as a vec4
##  @param a quaternion
##  @param b quaternion
##  @return dot product
##

proc t3d_quat_dot*(a: ptr T3DQuat; b: ptr T3DQuat): cfloat {.inline.} =
  return a.v[0] * b.v[0] + a.v[1] * b.v[1] + a.v[2] * b.v[2] + a.v[3] * b.v[3]

##
##  Normalizes a quaternion
##  @param quat
##

proc t3d_quat_normalize*(quat: ptr T3DQuat) {.inline.} =
  var scale: cfloat = 1.0f div
      sqrtf(quat.v[0] * quat.v[0] + quat.v[1] * quat.v[1] + quat.v[2] * quat.v[2] +
      quat.v[3] * quat.v[3])
  quat.v[0] = quat.v[0] * scale
  quat.v[1] = quat.v[1] * scale
  quat.v[2] = quat.v[2] * scale
  quat.v[3] = quat.v[3] * scale

##
##  Interpolates between two quaternions using a normalized linear interpolation.
##  @param res interpolated quaternion
##  @param a first quaternion
##  @param b second quaternion
##  @param t interpolation factor
##

proc t3d_quat_nlerp*(res: ptr T3DQuat; a: ptr T3DQuat; b: ptr T3DQuat; t: cfloat)
proc t3d_quat_slerp*(res: ptr T3DQuat; a: ptr T3DQuat; b: ptr T3DQuat; t: cfloat)
##
##  @brief Initializes a matrix to the identity matrix
##  @param mat matrix to be changed
##

proc t3d_mat4_identity*(mat: ptr T3DMat4) {.inline.} =
  ## !!!Ignored construct:  * mat = ( T3DMat4 ) { { { 1 , 0 , 0 , 0 } , { 0 , 1 , 0 , 0 } , { 0 , 0 , 1 , 0 } , { 0 , 0 , 0 , 1 } , } } ;
  ## Error: expected ';'!!!

##
##  Scales a matrix by the given factors
##  @param mat result
##  @param scaleX
##  @param scaleY
##  @param scaleZ
##

proc t3d_mat4_scale*(mat: ptr T3DMat4; scaleX: cfloat; scaleY: cfloat; scaleZ: cfloat) {.
    inline.} =
  mat.m[0][0] = mat.m[0][0] * scaleX
  mat.m[0][1] = mat.m[0][1] * scaleX
  mat.m[0][2] = mat.m[0][2] * scaleX
  mat.m[0][3] = mat.m[0][3] * scaleX
  mat.m[1][0] = mat.m[1][0] * scaleY
  mat.m[1][1] = mat.m[1][1] * scaleY
  mat.m[1][2] = mat.m[1][2] * scaleY
  mat.m[1][3] = mat.m[1][3] * scaleY
  mat.m[2][0] = mat.m[2][0] * scaleZ
  mat.m[2][1] = mat.m[2][1] * scaleZ
  mat.m[2][2] = mat.m[2][2] * scaleZ
  mat.m[2][3] = mat.m[2][3] * scaleZ

##
##  Translates a matrix by the given offsets
##  @param mat result
##  @param offsetX
##  @param offsetY
##  @param offsetZ
##

proc t3d_mat4_translate*(mat: ptr T3DMat4; offsetX: cfloat; offsetY: cfloat;
                        offsetZ: cfloat) {.inline.} =
  inc(mat.m[3][0], offsetX)
  inc(mat.m[3][1], offsetY)
  inc(mat.m[3][2], offsetZ)

##
##  Rotates a matrix around an axis
##  @param mat result
##  @param axis axis to rotate around
##  @param angleRad angle in radians
##

proc t3d_mat4_rotate*(mat: ptr T3DMat4; axis: ptr T3DVec3; angleRad: cfloat)
##
##  Directly constructs a matrix from scale, rotation (quaternion) and translation
##  For a euler version, see 't3d_mat4_from_srt_euler'.
##
##  @param mat result
##  @param scale scale factors
##  @param rot rotation quaternion
##  @param translate offsets
##

proc t3d_mat4_from_srt*(mat: ptr T3DMat4; scale: array[3, cfloat];
                       quat: array[4, cfloat]; translate: array[3, cfloat])
##
##  Directly constructs a matrix from scale, rotation (euler) and translation
##  For a quaternion version, see 't3d_mat4_from_srt'.
##
##  @param mat
##  @param scale
##  @param rot
##  @param translate
##

proc t3d_mat4_from_srt_euler*(mat: ptr T3DMat4; scale: array[3, cfloat];
                             rot: array[3, cfloat]; translate: array[3, cfloat])
##
##  Constructs a matrix from a direction and up vector.
##  This will only create a rotation matrix, the translation part will be identity.
##  @param mat result
##  @param dir direction vector
##  @param up up vector
##

proc t3d_mat4_rot_from_dir*(mat: ptr T3DMat4; dir: ptr T3DVec3; up: ptr T3DVec3)
##
##  Directly constructs a matrix from scale, rotation (euler) and translation
##  Same as 't3d_mat4_from_srt_euler', but instead directly writes to a fixed-point matrix.
##  @param mat
##  @param scale
##  @param rot
##  @param translate
##

proc t3d_mat4fp_from_srt_euler*(mat: ptr T3DMat4FP; scale: array[3, cfloat];
                               rot: array[3, cfloat]; translate: array[3, cfloat])
##
##  Directly constructs a matrix from scale, rotation (quaternion) and translation
##  Same as 't3d_mat4_from_srt', but instead directly writes to a fixed-point matrix.
##  @param mat
##  @param scale
##  @param rot
##  @param translate
##

proc t3d_mat4fp_from_srt*(mat: ptr T3DMat4FP; scale: array[3, cfloat];
                         rotQuat: array[4, cfloat]; translate: array[3, cfloat])
##
##  @brief Sets a value in a fixed-point matrix
##  @param mat matrix to be changed
##  @param column
##  @param row
##  @param val value to be set as a float
##

proc t3d_mat4fp_set_float*(mat: ptr T3DMat4FP; column: uint32_t; row: uint32_t;
                          val: cfloat) {.inline.} =
  var fixed: int32_t = T3D_F32_TO_FIXED(val)
  mat.m[column].i[row] = (int16_t)(fixed shr 16)
  mat.m[column].f[row] = fixed and 0xFFFF

##
##  Sets the position of a fixed-point matrix.
##  Note: that this will just set the values without any further checks/calculations.
##  @param mat matrix to be changed
##  @param pos position as a float[3]
##

proc t3d_mat4fp_set_pos*(mat: ptr T3DMat4FP; pos: array[3, cfloat]) {.inline.} =
  t3d_mat4fp_set_float(mat, 3, 0, pos[0])
  t3d_mat4fp_set_float(mat, 3, 1, pos[1])
  t3d_mat4fp_set_float(mat, 3, 2, pos[2])

##
##  @brief Gets a value from a fixed-point matrix
##  @param mat matrix to be read
##  @param y row
##  @param x column
##  @return value as a float
##

proc t3d_mat4fp_get_float*(mat: ptr T3DMat4FP; y: uint32_t; x: uint32_t): cfloat {.inline.} =
  return s1616_to_float(mat.m[y].i[x], mat.m[y].f[x])

proc t3d_mat4fp_identity*(mat: ptr T3DMat4FP) {.inline.} =
  ## !!!Ignored construct:  * mat = ( T3DMat4FP ) { { { { 1 , 0 , 0 , 0 } , { 0 , 0 , 0 , 0 } } , { { 0 , 1 , 0 , 0 } , { 0 , 0 , 0 , 0 } } , { { 0 , 0 , 1 , 0 } , { 0 , 0 , 0 , 0 } } , { { 0 , 0 , 0 , 1 } , { 0 , 0 , 0 , 0 } } , } } ;
  ## Error: expected ';'!!!

##
##  Converts a float matrix to a fixed-point matrix.
##  @param matOut result
##  @param matIn input
##

proc t3d_mat4_to_fixed*(matOut: ptr T3DMat4FP; matIn: ptr T3DMat4)
##
##  Converts a float 4x4 matrix to a fixed-point 4x4 matrix.
##  The last row of the matrix is assumed to be {0,0,0,1}.
##  This should be preferred over 't3d_mat4_to_fixed' when possible as it is faster.
##  @param matOut result
##  @param matIn input
##

proc t3d_mat4_to_fixed_3x4*(matOut: ptr T3DMat4FP; matIn: ptr T3DMat4)
##
##  Constructs a perspective projection matrix
##  @param mat result
##  @param fov fov in radians
##  @param aspect aspect ratio
##  @param near near plane distance
##  @param far far plane distance
##

proc t3d_mat4_perspective*(mat: ptr T3DMat4; fov: cfloat; aspect: cfloat; near: cfloat;
                          far: cfloat)
##
##  Constructs an orthographic projection matrix
##  @param mat result
##  @param left
##  @param right
##  @param bottom
##  @param top
##  @param near near plane distance
##  @param far far plane distance
##

proc t3d_mat4_ortho*(mat: ptr T3DMat4; left: cfloat; right: cfloat; bottom: cfloat;
                    top: cfloat; near: cfloat; far: cfloat)
##
##  @brief Creates a look-at matrix from an eye and target vector
##  @param mat destination matrix
##  @param eye camera position
##  @param target camera target/focus point
##  @param up camera up vector, expected to be {0,1,0} by default
##

proc t3d_mat4_look_at*(mat: ptr T3DMat4; eye: ptr T3DVec3; target: ptr T3DVec3;
                      up: ptr T3DVec3)
##
##  Extracts the frustum planes from a 4x4 view/camera matrix
##  @param frustum result
##  @param mat view/camera matrix
##

proc t3d_mat4_to_frustum*(frustum: ptr T3DFrustum; mat: ptr T3DMat4)
##
##  Scales a frustum by a given factor.
##  This can be used if you need to check scaled objects without having to transform the AABBs
##  @param frustum frustum to scale
##  @param scale scale factor (use the same as the model scale)
##

proc t3d_frustum_scale*(frustum: ptr T3DFrustum; scale: cfloat)
##
##  Checks if an AABB is inside a frustum.
##  Note that this function *may* choose to return false positives in favor of speed.
##  So it should only be used where this is acceptable (e.g. culling) and not for collision detection.
##  @param frustum frustum
##  @param min AABB min
##  @param max AABB max
##  @return true if the AABB is inside the frustum
##

proc t3d_frustum_vs_aabb*(frustum: ptr T3DFrustum; min: ptr T3DVec3; max: ptr T3DVec3): bool
##
##  Checks if an s16 AABB is inside a frustum.
##  Note that this function *may* choose to return false positives in favor of speed.
##  So it should only be used where this is acceptable (e.g. culling) and not for collision detection.
##  @param frustum frustum
##  @param min AABB min
##  @param max AABB max
##  @return true if the AABB is inside the frustum
##

proc t3d_frustum_vs_aabb_s16*(frustum: ptr T3DFrustum; min: array[3, int16_t];
                             max: array[3, int16_t]): bool
##
##  Checks if a Sphere is inside a frustum.
##  Note that this function *may* choose to return false positives in favor of speed.
##  So it should only be used where this is acceptable (e.g. culling) and not for collision detection.
##  @param frustum frustum
##  @param center Sphere center
##  @param radius Sphere radius
##  @return true if the Sphere is inside the frustum
##

proc t3d_frustum_vs_sphere*(frustum: ptr T3DFrustum; center: ptr T3DVec3;
                           radius: cfloat): bool
##  @brief Multiplies the matrices 'matA' and 'matB' and stores it in 'matRes'

proc t3d_mat4_mul*(matRes: ptr T3DMat4; matA: ptr T3DMat4; matB: ptr T3DMat4) {.inline.} =
  var i: uint32_t = 0
  while i < 4:
    var j: uint32_t = 0
    while j < 4:
      matRes.m[j][i] = matA.m[0][i] * matB.m[j][0] + matA.m[1][i] * matB.m[j][1] +
          matA.m[2][i] * matB.m[j][2] + matA.m[3][i] * matB.m[j][3]
      inc(j)
    inc(i)

##
##  Multiplies a 3x3 matrix with a 3D vector
##  @param vecOut result
##  @param mat matrix
##  @param vec input-vector
##

proc t3d_mat3_mul_vec3*(vecOut: ptr T3DVec3; mat: ptr T3DMat4; vec: ptr T3DVec3) {.inline.} =
  var i: uint32_t = 0
  while i < 3:
    vecOut.v[i] = mat.m[0][i] * vec.v[0] + mat.m[1][i] * vec.v[1] +
        mat.m[2][i] * vec.v[2]
    inc(i)

##
##  Multiplies a 4x4 matrix with a 3D vector.
##  The W component of the vector is assumed to be 1.
##  @param vecOut result
##  @param mat matrix
##  @param vec input-vector
##

proc t3d_mat4_mul_vec3*(vecOut: ptr T3DVec4; mat: ptr T3DMat4; vec: ptr T3DVec3) {.inline.} =
  var i: uint32_t = 0
  while i < 4:
    vecOut.v[i] = mat.m[0][i] * vec.v[0] + mat.m[1][i] * vec.v[1] +
        mat.m[2][i] * vec.v[2] + mat.m[3][i]
    inc(i)

##  C++ wrappers that allow (const-)references to be passed instead of pointers
