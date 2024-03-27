package sys

// foreign import lib "system:System"

// @(private)
// @(default_calling_convention="c")
// foreign lib
// { 
//   @(link_name="socket") _unix_socket :: proc(int, int, int) -> int ---
//   @(link_name="bind") _unix_bind :: proc(int, rawptr, int) -> int ---
//   @(link_name="listen") _unix_listen :: proc(int, int) -> int ---
//   @(link_name="accept") _unix_accept :: proc(int, rawptr, rawptr) -> int ---
// }

// create_socket :: proc(a: int, b: int, c: int) -> int
// {
//   return _unix_socket(a, b, c)
// }

// bind_socket :: proc(int, rawptr, int) -> int
// {
//   return _unix_bind(a, b, c)
// }

// listen :: proc(int, int) -> int
// {
//   return _unix_socket(a, b, c)
// }

// accept :: proc(int, rawptr, rawptr) -> int
// {
//   return _unix_socket(a, b, c)
// }
