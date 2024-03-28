package rt

import mem "core:mem"

// @Arena ////////////////////////////////////////////////////////////////////////////////

KIB :: 1 << 10
MIB :: 1 << 20
GIB :: 1 << 30

Arena :: struct
{
  using allocator : mem.Allocator,
  arena : mem.Arena,
  block : []byte,
}

create_arena :: proc(size: u64) -> ^Arena
{
  result: ^Arena = new(Arena)
  result.block = make([]byte, size)
  mem.arena_init(&result.arena, result.block)
  result.allocator = mem.arena_allocator(&result.arena)

  return result
}

clear_arena :: proc(arena: ^Arena)
{
  mem.free_all(arena)
}

destroy_arena :: proc(arena: ^Arena)
{
  delete(arena.block)
  free(arena)
}
