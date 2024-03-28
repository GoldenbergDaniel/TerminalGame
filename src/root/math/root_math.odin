package rt_math

// @Scalar ===============================================================================

min :: proc
{
  min_1i,
  min_1f32,
}

min_1i :: #force_inline proc(a: int, b: int) -> int
{
  if a < b do return a
  else do return b
}

min_1f32 :: #force_inline proc(a: f32, b: f32) -> f32
{
  if a < b do return a
  else do return b
}

max :: proc
{
  max_1i,
  max_1f32,
}

max_1i :: #force_inline proc(a: int, b: int) -> int
{
  if a > b do return a
  else do return b
}

max_1f32 :: #force_inline proc(a: f32, b: f32) -> f32
{
  if a > b do return a
  else do return b
}

clamp :: proc
{
  clamp_1i,
  clamp_1f32,
}

clamp_1i :: #force_inline proc(num: int, min: int, max: int) -> int
{
  if num < min do return min
  if num > max do return max
  else do return num
}

clamp_1f32 :: #force_inline proc(num: f32, min: f32, max: f32) -> f32
{
  if num < min do return min
  if num > max do return max
  else do return num
}

// @Vector ===============================================================================

Vec2F32 :: [2]f32
Vec3F32 :: [3]f32
Vec4F32 :: [4]f32

Vec2F :: Vec2F32
Vec3F :: Vec3F32
Vec4F :: Vec4F32

// Add ---------------

add :: proc
{
  add_2f32,
  add_3f32,
  add_4f32,
}

add_2f32 :: #force_inline proc(a: Vec2F32, b: Vec2F32) -> Vec2F32
{
  return {a.x + b.x, a.y + b.y}
}

add_3f32 :: #force_inline proc(a: Vec3F32, b: Vec3F32) -> Vec3F32
{
  return {a.x + b.x, a.y + b.y, a.z + b.z}
}

add_4f32 :: #force_inline proc(a: Vec4F32, b: Vec4F32) -> Vec4F32
{
  return {a.x + b.x, a.y + b.y, a.z + b.z, a.w + b.w}
}

// Sub ----------------

sub :: proc
{
  sub_2f32,
  sub_3f32,
  sub_4f32,
}

sub_2f32 :: #force_inline proc(a: Vec2F32, b: Vec2F32) -> Vec2F32
{
  return {a.x - b.x, a.y - b.y}
}

sub_3f32 :: #force_inline proc(a: Vec3F32, b: Vec3F32) -> Vec3F32
{
  return {a.x - b.x, a.y - b.y, a.z - b.z}
}

sub_4f32 :: #force_inline proc(a: Vec4F32, b: Vec4F32) -> Vec4F32
{
  return {a.x - b.x, a.y - b.y, a.z - b.z, a.w - b.w}
}

// Scale ----------------

scale :: proc
{
  scale_2f32,
  scale_3f32,
  scale_4f32,
}

scale_2f32 :: #force_inline proc(a: Vec2F32, b: f32) -> Vec2F32
{
  return {a.x * b, a.y * b}
}

scale_3f32 :: #force_inline proc(a: Vec3F32, b: f32) -> Vec3F32
{
  return {a.x * b, a.y * b, a.z * b}
}

scale_4f32 :: #force_inline proc(a: Vec4F32, b: f32) -> Vec4F32
{
  return {a.x * b, a.y * b, a.z * b, a.w * b}
}

// Dot ----------------

dot :: proc
{
  dot_2f32,
  dot_3f32,
  dot_4f32,
}

dot_2f32 :: #force_inline proc(a: Vec2F32, b: Vec2F32) -> f32
{
  return (a.x * b.x) + (a.y * b.y)
}

dot_3f32 :: #force_inline proc(a: Vec3F32, b: Vec3F32) -> f32
{
  return (a.x * b.x) + (a.y * b.y) + (a.z * b.z)
}

dot_4f32 :: #force_inline proc(a: Vec4F32, b: Vec4F32) -> f32
{
  return (a.x * b.x) + (a.y * b.y) + (a.z * b.z) + (a.w * b.w)
}

// Cross ----------------

cross :: proc
{
  cross_2f32,
  cross_3f32,
}

cross_2f32 :: #force_inline proc(a: Vec2F32, b: Vec2F32) -> f32
{
  return a.x * b.y + a.y * b.x
}

cross_3f32 :: #force_inline proc(a: Vec3F32, b: Vec3F32) -> Vec3F32
{
  return {
    (a.y * b.z) - (a.z * b.y), 
    -(a.x * b.z) + (a.z * b.x), 
    (a.x * b.y) - (a.y * b.x),
  }
}

// @Matrix ===============================================================================

Mat2F :: matrix[2, 2]f32
Mat3F :: matrix[3, 3]f32
Mat4F :: matrix[4, 4]f32 
