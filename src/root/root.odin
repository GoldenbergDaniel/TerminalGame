package rt

import mem "core:mem"

// @Arena ////////////////////////////////////////////////////////////////////////////////

KIB :: 1 << 10
MIB :: 1 << 20
GIB :: 1 << 30

Arena :: struct
{
  data : []byte,
  capacity : int,
  offset : int,

  allocator : mem.Allocator,
}

create_arena :: proc(size: int) -> ^Arena
{
  result: ^Arena = new(Arena)
  result.data = make([]byte, size)
  result.capacity = size
  result.allocator = {
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

arena_push_bytes :: proc(arena: ^Arena,  size: int) -> rawptr
{
  result: rawptr = &arena.data[arena.offset]
  arena.offset += size
  return result
}

arena_push_item :: proc(arena: ^Arena, $T: typeid) -> ^T
{
  result := cast(^T) &arena.data[arena.offset]
  arena.offset += size_of(T)

  return result
}

arena_push_array :: proc(arena: ^Arena, $T: typeid,  count: int) -> ^T
{
  result := cast(^T) &arena.data[arena.offset]
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
                             mode: mem.Allocator_Mode,
                             size, alignment: int,
                             old_memory: rawptr, old_size: int,
                             location := #caller_location
                        ) -> ([]byte, mem.Allocator_Error)
{
	arena := cast(^Arena) allocator_data
	switch mode
  {
	  case .Alloc, .Alloc_Non_Zeroed:
    {
      ptr := arena_push_bytes(arena, size)
      return mem.byte_slice(ptr, size), nil
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
