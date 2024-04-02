package main

BUF_SIZE :: 1 << 20 // 1 MiB
TOKEN_CAP :: 2000

// @Token //////////////////////////////////////////////////////////////////////////////// 

Token :: struct
{
  type : TokenType,
  str : string,
}

TokenList :: struct
{
  arena : ^rt.Arena,
  data : [^]Token,
  cap : int,
  count : int,
}

TokenType :: enum
{
  NONE,
  STRING,
  NUMBER,
  BOOLEAN,
  COLON,
  BRACE_OPEN,
  BRACE_CLOSED,
  BRACKET_OPEN,
  BRACKET_CLOSED,
}

push_token :: proc(list: ^TokenList, s: string, t: TokenType)
{
  assert(list.count < list.cap)

  list.data[list.count] = {str=str.clone(s, list.arena.allocator), type=t}
  list.count += 1
}

// @Lexer ////////////////////////////////////////////////////////////////////////////////

tokens_from_json_at_path :: proc(path: string, arena: ^rt.Arena) -> TokenList
{
  tokens: TokenList
<<<<<<< HEAD
  tokens.cap = TOKEN_CAP
  tokens.data = make([^]Token, tokens.cap, arena)
=======
  tokens.capacity = TOKEN_CAP
  tokens.data = rt.arena_push(arena, Token, tokens.capacity)
>>>>>>> 2c1390df7b3add31c48f6b8ee3a3cc3f4482f052
  tokens.arena = arena

  context.allocator = arena.allocator

  file, o_err := os.open(path, os.O_RDONLY)
  if o_err != os.ERROR_NONE
  {
    fmt.eprintln("Error opening file!", o_err)
    return {}
  }
  
  buf: [BUF_SIZE]byte
  stream_len, r_err := os.read(file, buf[:])
  if r_err != os.ERROR_NONE
  {
    fmt.eprintln("Error reading file!", r_err)
    return {}
  }

  stream := cast(string) buf[:stream_len]

  for i := 0; i < stream_len;
  {
    // Lex grammar ----------------
    {
      token_type: TokenType
      switch stream[i]
      {
        case ':': token_type = .COLON
        case '{': token_type = .BRACE_OPEN
        case '}': token_type = .BRACE_CLOSED
        case '[': token_type = .BRACKET_OPEN
        case ']': token_type = .BRACKET_CLOSED
      }
  
      if token_type != .NONE
      {
        push_token(&tokens, stream[i:i+1], token_type)
        i += 1
        continue
      }
    }

    // Lex string ----------------
    if stream[i] == '\"'
    {
      i += 1
      closing_quote_idx: int = str.index_byte(stream[i:], '\"')
      if closing_quote_idx != -1
      {
        push_token(&tokens, stream[i:i+closing_quote_idx], .STRING)
        i += closing_quote_idx + 1
        continue
      }
    }

    // Lex number ----------------
    if stream[i] >= '0' && stream[i] <= '9'
    {
      substr := stream[i:i+1]
      for j := 1; j < stream_len-i; j += 1
      {
        if stream[i+j] >= '0' && stream[i+j] <= '9'
        {
          substr = stream[i:i+1+j]
        }
        else do break
      }
      
      push_token(&tokens, substr, .NUMBER)
      i += len(substr) + 1
      continue
    }

    // Lex boolean ----------------
    if stream[i] == 'f' || stream[i] == 't'
    {
      substr: string
      if str.compare(stream[i:i+5], "false") == 0
      {
        substr = "false"
      }
      else if str.compare(stream[i:i+4], "true") == 0
      {
        substr = "true"
      }

      push_token(&tokens, substr, .BOOLEAN)
      i += len(substr)
      continue
    }

    i += 1
  }

  return tokens
}

// @Parser ///////////////////////////////////////////////////////////////////////////////

Parser :: struct
{
  
}

items_from_tokens :: proc(tokens: TokenList, arena: ^rt.Arena) -> ItemStore
{
  IDX_OF_COUNT_TOKEN :: 3

  result: ItemStore
  result.arena = arena

  // Get item count ----------------
  item_count: int
  {
    ok: bool
    item_count, ok = strconv.parse_int(tokens.data[IDX_OF_COUNT_TOKEN].str)
    if ok
    {
      result.item_count = item_count
    }
    else
    {
      fmt.eprint("Error parsing item count!\n")
      return {}
    }
  }

  // Get index of first item ----------------
  first_item_idx: int
  {
    for i in 0 ..< tokens.count
    {
      token := tokens.data[i]
      if token.type == .STRING && str.compare(token.str, "items") == 0
      {
        first_item_idx = i + 3
      }
    }
  }

  token_idx := first_item_idx + 1
  for i := 0; i < item_count; i += 1
  {
    token := tokens.data[token_idx]

    #partial switch token.type
    {
      case .BRACE_OPEN:
      {
        // start of item
      }
      case .BRACE_CLOSED:
      {
        // end of item
      }
      case .BRACKET_OPEN:
      {  
        // start of list
      }
      case .BRACKET_CLOSED:
      {
        // end of list
      }
      case:
      {
        token_idx += 1
      }
    }
  }

  return result
}

// @Test /////////////////////////////////////////////////////////////////////////////////

test_parser :: proc()
{
  arena: ^rt.Arena = rt.create_arena(rt.MIB * 4)
  
  tokens := tokens_from_json_at_path("res/test.json", arena)
  for i in 0..< tokens.count
  {
    fmt.printf("%s", tokens.data[i].str)

    if i < tokens.count - 1
    {
      fmt.print(", ")
    }
  }

  fmt.print("\n")

  items: ItemStore = items_from_tokens(tokens, arena)
}

// @Imports //////////////////////////////////////////////////////////////////////////////

import fmt "core:fmt"
import str "core:strings"
import strconv "core:strconv"
import os "core:os"

import rt "root"
