package rt

import runtime "base:runtime"

import "base:intrinsics"
import "core:unicode/utf16"

// @Arena ////////////////////////////////////////////////////////////////////////////////

KIB :: 1 << 10
MIB :: 1 << 20
GIB :: 1 << 30

Allocator :: runtime.Allocator

Arena :: struct
{
  data : []byte,
  capacity : int,
  offset : int,

  allocator : runtime.Allocator,
}

create_arena :: proc(size: int) -> ^Arena
{
  result: ^Arena = new(Arena, runtime.default_allocator())
  result.data = make([]byte, size, runtime.default_allocator())
  result.capacity = size
  result.allocator =
  {
    data=result, 
    procedure=arena_allocator_proc,
  }

  return result
}

arena_push :: proc
{
  arena_push_bytes,
  arena_push_item,
  arena_push_array,
}

arena_push_bytes :: proc(arena: ^Arena, size: int) -> rawptr
{
  result: rawptr

  align :: 8
  if arena.offset % align == 0
  {
    arena.offset += align - (arena.offset % align)
  }

  result = &arena.data[arena.offset]
  arena.offset += size

  return result
}

arena_push_item :: proc(arena: ^Arena, $T: typeid) -> ^T
{
  result: ^T

  align :: align_of(T)
  if arena.offset % align == 0
  {
    arena.offset += align - (arena.offset % align)
  }

  result = cast(^T) &arena.data[arena.offset]
  arena.offset += size_of(T)

  return result
}

arena_push_array :: proc(arena: ^Arena, $T: typeid, count: int) -> ^T
{
  result: ^T

  align :: align_of(T)
  if arena.offset % align == 0
  {
    arena.offset += align - (arena.offset % align)
  }

  result = cast(^T) &arena.data[arena.offset]
  arena.offset += size_of(T) * count

  return result
}

arena_pop :: proc
{
  arena_pop_bytes,
  arena_pop_item,
  arena_pop_array,
}

arena_pop_bytes :: #force_inline proc(arena: ^Arena, size: int)
{
  arena.offset -= size
}

arena_pop_item :: #force_inline proc(arena: ^Arena, $T: typeid)
{
  arena.offset -= size_of(T)
}

arena_pop_array :: #force_inline proc(arena: ^Arena, $T: typeid, count: u64)
{
  arena.offset -= size_of(T) * count
}

arena_clear :: #force_inline proc(arena: ^Arena)
{
  arena.offset = 0
}

destroy_arena :: proc(arena: ^Arena)
{
  delete(arena.data)
}

arena_allocator_proc :: proc(allocator_data: rawptr, 
                             mode: runtime.Allocator_Mode,
                             size, alignment: int,
                             old_memory: rawptr, old_size: int,
                             location := #caller_location
                        ) -> ([]byte, runtime.Allocator_Error)
{
	arena := cast(^Arena) allocator_data
	switch mode
  {
	  case .Alloc, .Alloc_Non_Zeroed:
    {
      ptr := arena_push_bytes(arena, size)
      byte_slice := ([^]u8) (ptr)[:max(size, 0)]
      return byte_slice, nil
    }
    case .Free:
    {
      arena_pop_bytes(arena, size)
    }
    case .Free_All:
    {
      arena_clear(arena)
    }
    case .Query_Features, .Query_Info, .Resize, .Resize_Non_Zeroed:
    {
      return nil, .Mode_Not_Implemented
    }
	}

	return nil, nil
}
