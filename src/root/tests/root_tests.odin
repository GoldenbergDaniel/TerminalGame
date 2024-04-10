package rt_tests

import fmt "core:fmt"
import rt "../"

MAX_TESTS :: 64

State :: struct
{
  title : string,
  started : bool,
  tests : [MAX_TESTS]Test,
  test_count : int,
  pass_count : int,
}

Value :: union
{
  int,
  f32,
  bool,
  string,
}

Test :: struct
{
  name : string,
  a : Value,
  b : Value,
  comp : string,
  passed : bool,
  is_slice : bool,
}

STATE: State

begin :: proc(title: string = "TESTS")
{
  assert(!STATE.started, "Tests already in progress.")

  STATE.started = true
  STATE.title = title
}

push :: proc
{
  push_int,
  push_f32,
  push_bool,
  push_string,
  push_slice,
}

push_int :: proc(name: string, a, b: int, comp: string = "==")
{
  assert(STATE.test_count < MAX_TESTS)
  
  result := compare(int, a, b, comp)

  STATE.tests[STATE.test_count] = {name, a, b, comp, result, false}
  STATE.pass_count += 1 if result else 0
  STATE.test_count += 1
}

push_f32 :: proc(name: string, a, b: f32, comp: string = "==")
{
  assert(STATE.test_count < MAX_TESTS)

  result := compare(f32, a, b, comp)

  STATE.tests[STATE.test_count] = {name, a, b, comp, result, false}
  STATE.pass_count += 1 if result else 0
  STATE.test_count += 1
}

push_bool :: proc(name: string, a, b: bool)
{
  assert(STATE.test_count < MAX_TESTS)
  
  result := a == b

  STATE.tests[STATE.test_count] = {name, a, b, "==", result, false}
  STATE.pass_count += 1 if result else 0
  STATE.test_count += 1
}

push_string :: proc(name: string, a, b: string, comp: string = "==")
{
  assert(STATE.test_count < MAX_TESTS)
  
  result := compare(string, a, b, comp)

  STATE.tests[STATE.test_count] = {name, a, b, comp, result, false}
  STATE.pass_count += 1 if result else 0
  STATE.test_count += 1
}

push_slice :: proc(name: string, a, b: []$T, comp: string = "==")
{
  assert(comp == "==" || comp == "~=", "Invalid comparison operator!")

  result: bool
  count := len(a)
  
  if len(a) != len(b)
  {
    for i in 0..<count
    {
      if a[i] != b[i]
      {
        result = false
        break
      }
    }
  }
  else
  {
    if comp == "~="
    {
      // sort
      for i := 0; i < count; i+=1
      {
        for j := i; j > 0; j-=1
        {
          if a[j] < a[j-1]
          {
            a[j], a[j-1] = a[j-1], a[j]
          }

          if b[j] < b[j-1]
          {
            b[j], b[j-1] = b[j-1], b[j]
          }
        }
      }
    }

    result = true
    for i in 0..<count
    {
      if a[i] != b[i]
      {
        result = false
        break
      }
    }
  }

  STATE.tests[STATE.test_count] = {name, 0, 0, comp, result, true}
  STATE.pass_count += 1 if result else 0
  STATE.test_count += 1
}

@(private)
compare :: proc($T: typeid, a, b: T, comp: string) -> bool
{
  result: bool

  switch comp
  {
    case "==":
      result = a == b
    case "!=":
      result = a != b
    case "<":
      result = a < b
    case ">":
      result = a > b
    case "<=":
      result = a <= b
    case ">=":
      result = a >= b
    case:
      panic("Invalid comparison operator!")
  }

  return result
}

end :: proc()
{
  assert(STATE.started, "Tests not in progress.")

  fmt.printf("-------------- %s --------------\n", STATE.title)
  
  for test, i in STATE.tests
  {
    if i >= STATE.test_count do break

    fmt.printf("(%i) ", i+1)

    if test.passed
    {
      fmt.print("\u001b[38;5;2m") // green
      fmt.print("PASSED ")
    }
    else
    {
      fmt.print("\u001b[38;5;1m") // red
      fmt.print("FAILED ")
    }

    fmt.print("\u001b[0m")

    if test.is_slice
    {
      fmt.println(test.name, ":", "{...}", test.comp, "{...}")
    }
    else
    {
      fmt.println(test.name, ":", test.a, test.comp, test.b)
    }
  }

  percent := cast(int) ((f32(STATE.pass_count) / f32(STATE.test_count)) * 100 + 0.5)
  if percent == 100
  {
    fmt.print("\u001b[38;5;2m") // green
  }
  else
  {
    fmt.print("\u001b[38;5;1m") // red
  }

  fmt.printf("\nResult: %i/%i (%i%%)\n", STATE.pass_count, STATE.test_count, percent)
  fmt.print("\u001b[0m")

  for i in 0 ..< (30 + len(STATE.title))
  {
    fmt.print("-")
  }

  fmt.print("\n")

  STATE = {}
}
