package main

// @GameState ////////////////////////////////////////////////////////////////////////////

MAX_SCAVANGE_STEPS :: 10
RANDOM_ENCOUNTER_CHANCE :: 4
COMBAT_FLEE_CHANCE :: 5

Game :: struct
{
  running : bool,
  started : bool,
  day : int,
 
  player_name : string,
  
  perception : u8,
  endurance : u8,
  dexterity : u8,
  luck : u8,

  faith : int,
  max_health : int,
  health : int,
  food : int,
  water : int,

  items : [ItemType.COUNT]Item,
  item_count : uint,
  item_capacity : uint,

  activities : bit_set[Activity],
  override_action : Action,
  
  current_scavange_step : int,
  remaining_scavange_steps : int,

  entity_in_combat : EntityType,
}

Activity :: enum
{
  SCAVANGE,
  ENCOUNTER,
  COMBAT,
}

Action :: enum
{
  NONE,
  QUIT_GAME,
  NEW_GAME,
  NEXT_DAY,
  SCAVANGE_BEGIN,
  SCAVANGE_STEP_F,
  SCAVANGE_STEP_B,
  COMBAT_FLEE,
  COMBAT_BEGIN,
  PRINT_ITEMS,
  PRINT_HELP,
  PRINT_CHARACTER,
}

// @Main /////////////////////////////////////////////////////////////////////////////////

main :: proc()
{
  perm_arena := rt.create_arena(rt.MIB * 16)
  defer rt.destroy_arena(perm_arena)

  frame_arena := rt.create_arena(rt.MIB * 4)
  defer rt.destroy_arena(frame_arena)

  temp_arena := rt.create_arena(rt.MIB * 16)
  defer rt.destroy_arena(temp_arena)

  context.allocator = perm_arena.allocator
  context.temp_allocator = temp_arena.allocator

  test_parser()
  // if true do return

  commands := make(map[string]Action, 32, perm_arena.allocator)
  defer rt.arena_pop_map(perm_arena, type_of(commands), commands)

  commands["quit"] = .QUIT_GAME
  commands["exit"] = .QUIT_GAME
  commands["new"] = .NEW_GAME
  commands["sleep"] = .NEXT_DAY
  commands["scav"] = .SCAVANGE_BEGIN
  commands["scavange"] = .SCAVANGE_BEGIN
  commands["mf"] = .SCAVANGE_STEP_F
  commands["mb"] = .SCAVANGE_STEP_B
  commands["flee"] = .COMBAT_FLEE
  commands["fight"] = .COMBAT_BEGIN
  commands["inv"] = .PRINT_ITEMS
  commands["inventory"] = .PRINT_ITEMS
  commands["char"] = .PRINT_CHARACTER
  commands["character"] = .PRINT_CHARACTER
  commands["stats"] = .PRINT_CHARACTER
  commands["help"] = .PRINT_HELP

  action: Action

  entities: [EntityType.COUNT]Entity
  init_entities(entities[:])

  gm: Game
  gm.running = true
  init_items(gm.items[:])

  rng: rand.Rand
  seed := cast(u64) runtime.read_cycle_counter()
  rand.init(&rng, seed)

  // Title message ----------------
  set_color(.GRAY)
  set_bold(true)
  fmt.print("===== Unnamed Survival Game =====\n")
  set_bold(false)
  fmt.print("Type 'new' to start a new game. Type 'continue' to continue last save.\n\n")

  for gm.running
  {
    if gm.override_action == .NONE
    {
      fmt.print("> ")
      cmd_input_buf: [64]byte
      slc: []byte = cmd_input_buf[2:5]
      cmd_input_len, _ := os.read(os.stdin, cmd_input_buf[:])
      cmd_input_len -= 1

      cmd_str: string = cast(string) cmd_input_buf[:cmd_input_len]
      cmd_end: int = str.index_byte(cmd_str, ' ')
      if cmd_end == -1
      {
        cmd_end = cmd_input_len
      }
  
      cmd, err := str.to_lower(cmd_str[:cmd_end], frame_arena.allocator)
      if err != nil
      {
        fmt.println(err)
      }

      // Remove carriage return if applicable
      if cmd[len(cmd)-1] == '\r'
      {
        cmd = cmd[:len(cmd)-1]
      }
      
      if cmd not_in commands
      {
        fmt.print("Please enter a valid command.\n")
        continue
      }

      action = commands[cmd]
    }
    else
    {
      action = gm.override_action
    }

    gm.override_action = .NONE

    // Action select ----------------
    switch action
    {
      case .QUIT_GAME:
      {
        gm.running = false
        fmt.print("Exiting game.\n")
        set_color(.WHITE)
      }
      case .NEW_GAME:
      {
        fmt.print("Create your character.\n")

        fmt.print("\n--- Name ---\n")
        fmt.print("Name: ")
        name_buf: [64]byte
        name_len, _ := os.read(os.stdin, name_buf[:])
        gm.player_name = str.clone_from_bytes(name_buf[:name_len-1])

        fmt.print("\n--- Attributes ---\n")
        fmt.print("PERCEPTION   : affects your weapon accuracy and alertness.\n")
        fmt.print("ENDURANCE    : affects your health and faith.\n")
        fmt.print("DEXTERITY    : affects your ability to use complex items.\n")
        fmt.print("LUCK         : affects your chance of getting good draws.\n")
        fmt.print("You have 20 points to distribute.\n\n")

        attrib_points: u8 = 20

        // Perception
        {
          val := ask_for_attribute_until_valid("Perception: ", attrib_points)
          gm.perception = val
          attrib_points -= val

          fmt.printf("Allocated %i points to perception. ", gm.perception)
          fmt.printf("%i points remaining.\n\n", attrib_points)
        }

        // Endurance
        {
          val := ask_for_attribute_until_valid("Endurance: ", attrib_points)
          gm.endurance = val
          attrib_points -= val

          fmt.printf("Allocated %i points to endurance. ", gm.endurance)
          fmt.printf("%i points remaining.\n\n", attrib_points)
        }

        // Dexterity
        {
          val := ask_for_attribute_until_valid("Dexterity: ", attrib_points)
          gm.dexterity = val
          attrib_points -= val

          fmt.printf("Allocated %i points to dexterity. ", gm.dexterity)
          fmt.printf("%i points remaining.\n\n", attrib_points)
        }

        // Luck
        {
          val := ask_for_attribute_until_valid("Luck: ", attrib_points)
          gm.luck = val
          attrib_points -= val

          fmt.printf("Allocated %i points to luck.\n\n", gm.luck)
        }

        gm.day = 1
        gm.started = true
        gm.remaining_scavange_steps = MAX_SCAVANGE_STEPS

        gm.faith = rm.clamp(int(gm.endurance), 3, 9)
        gm.max_health = rm.clamp(int(20 * (f32(gm.endurance) / 5.0)), 10, 40)
        gm.health = gm.max_health
        gm.food = 20
        gm.water = 20

        add_item(&gm, .HEALTH_WATER, 10)
        add_item(&gm, .HEALTH_APPLE, 8)
        add_item(&gm, .HEALTH_SANDWICH, 4)
        add_item(&gm, .WEAPON_POCKET_KNIFE, 1)

        fmt.printf("\nSuccessfully created character. Welcome, %s!\n\n", gm.player_name)

        set_bold(true)
        fmt.print("Day 1\n")
        set_bold(false)
      }
      case .NEXT_DAY:
      {
        if !gm.started
        {
          fmt.print("Please start a new game before proceeding.\n")
          continue
        }
        else if .SCAVANGE in gm.activities || .COMBAT in gm.activities
        {
          fmt.print("Cannot sleep during scavange or in combat!\n")
          continue
        }

        gm.day += 1
        set_bold(true)
        fmt.println("Day", gm.day)
        set_bold(false)

        if gm.day == 30
        {
          fmt.print("\nIt has now been 100 days. ")

          if gm.faith >= 90
          {
            // good ending
            fmt.print("The military has arrived, and you've been safely evacuated.\n")
          }
          else if gm.faith >= 30
          {
            // bad ending
            fmt.print("You waited so long, but the military never came.\n")
          }
          else
          {
            // evil ending
            fmt.print("You decided to join the forces of darkness.\n")
          }
        }
        else
        {
          fmt.print("The sun rises. A brand new day awaits.\n")

          // roll for random encounter at home
        }
      }
      case .SCAVANGE_BEGIN:
      {
        if gm.started != true
        {
          fmt.print("Please start a new game before proceeding.\n")
          continue
        }
        else if .SCAVANGE in gm.activities || .COMBAT in gm.activities
        {
          fmt.print("Cannot start new scavange during scavange or in combat!\n")
          continue
        }

        fmt.print("You are are about to start a scavange. ")
        fmt.print("On a scavange, you can find food, water, and weapons.\n")
        fmt.print("You may also encounter dangerous monsters, such as possessed.\n")

        fmt.print("Are you sure you want to proceed? (y/n)\n")
        input_buf: [8]byte
        input_len, err := os.read(os.stdin, input_buf[:])
        if str.compare(string(input_buf[:input_len-1]), "y") == 0 ||
           str.compare(string(input_buf[:input_len-1]), "Y") == 0
        {
          gm.activities |= {.SCAVANGE}
          fmt.print("Proceeding with nge. Type `mf` and `mb` to move.\n")
        }
      }
      case .SCAVANGE_STEP_F:
      {
        if gm.started != true
        {
          fmt.print("Please start a new game before proceeding.\n")
          continue
        }
        else if .SCAVANGE not_in gm.activities
        {
          fmt.print("Please start a new scavange before proceeding.\n")
          continue
        }

        fmt.print("You moved one step forward.\n")

        if gm.remaining_scavange_steps > 0
        {
          gm.current_scavange_step += 1
          gm.remaining_scavange_steps -= 1

          // random encounter
          roll := rand.int31(&rng) % RANDOM_ENCOUNTER_CHANCE
          if roll == 1
          {
            generate_random_encounter(&gm, entities[:])
          }
        }
        else
        {
          // cannot travel any further
          fmt.print("You are too far from home. Time to turn back.\n")
        }
      }
      case .SCAVANGE_STEP_B:
      {
        if gm.started != true
        {
          fmt.print("Please start a new game before proceeding.\n")
          continue
        }
        else if .SCAVANGE not_in gm.activities
        {
          fmt.print("Please start a new scavange before proceeding.\n")
          continue
        }

        fmt.print("You moved one step back.\n")
        gm.current_scavange_step -= 1
        
        if gm.current_scavange_step == 0
        {
          // we go back home
          gm.activities -= {.SCAVANGE}
          gm.current_scavange_step = 0
          gm.remaining_scavange_steps = MAX_SCAVANGE_STEPS
          fmt.print("You are back in the safety of your home.\n")
        }
        else
        {
          // random encounter
          roll := rand.int31(&rng) % (RANDOM_ENCOUNTER_CHANCE + 2)
          if roll == 1
          {
            generate_random_encounter(&gm, entities[:])
          }
        }
      }
      case .COMBAT_FLEE:
      {
        if .ENCOUNTER not_in gm.activities
        {
          fmt.print("Please input a valid command.\n")
          continue
        }

        gm.activities -= {.ENCOUNTER}

        roll := rand.int31(&rng) % COMBAT_FLEE_CHANCE
        if roll != 1
        {
          fmt.print("Successfully fled combat!\n")
        }
        else
        {
          gm.override_action = .COMBAT_BEGIN
          fmt.print("Failed to flee! Engaging combat.\n")
        }
      }
      case .COMBAT_BEGIN:
      {
        if .COMBAT not_in gm.activities
        {
          fmt.print("Please input a valid command.\n")
          continue
        }

        fmt.print("Started combat.\n")        
      }
      case .PRINT_ITEMS:
      {
        for item in gm.items
        {
          if item.count != 0
          {
            item_name := string_from_item_type(item.type)
            fmt.printf("%s (%i)", item_name, item.count)
          }
        }
      }
      case .PRINT_CHARACTER:
      {
        fmt.printf("Name        :   %s\n", gm.player_name)
        fmt.print("\n")
        fmt.printf("Peception   :   %i/10\n", gm.perception)
        fmt.printf("Endurance   :   %i/10\n", gm.endurance)
        fmt.printf("Dexterity   :   %i/10\n", gm.dexterity)
        fmt.printf("Luck        :   %i/10\n", gm.luck)
        fmt.print("\n")
        fmt.printf("Faith       :   %i/10\n", gm.faith)
        fmt.printf("Health      :   %i/%i\n", gm.health, gm.max_health)
        fmt.printf("Food        :   %i/20\n", gm.food)
        fmt.printf("Water       :   %i/20\n", gm.water)
      }
      case .PRINT_HELP:
      {
        fmt.print("exit        :   exits the game\n")
        fmt.print("new         :   starts a new game\n")
        fmt.print("help        :   lists actions\n")
        fmt.print("character   :   prints character info\n")
      }
      case .NONE: continue
    }

    if !gm.running do break

    rt.arena_clear(frame_arena)
  }
}

ask_for_attribute_until_valid :: proc(prompt: string, remaining: u8) -> u8
{
  result: u8
  buf: [8]byte

  for true
  {
    fmt.print(prompt)
    input_len, input_err := os.read(os.stdin, buf[:])

    // Remove carriage return if applicable
    if buf[input_len-2] == '\r'
    {
      buf[input_len-2] = 0
    }

    buf[input_len-1] = 0

    val, ok := strconv.parse_int(string(buf[:1]), 10)
    if ok && val >= 1 && val <= 10 && (int(remaining) - val >= 0)
    {
      result = cast(u8) val
      break
    }
    else
    {
      fmt.print("Invalid input! Please enter a number between 1 and 10.\n")
    }
  }

  return result
}

// @Item /////////////////////////////////////////////////////////////////////////////////

Item :: struct
{
  type : ItemType,
  name : string,
  health : int,
  food : int,
  water : int,
  damage : int,
  rarity : u8,
  
  count : int
}

ItemStore :: struct
{
  arena : ^rt.Arena,
  items : []Item,
  count : int,
}

ItemType :: enum
{
  // Health
  HEALTH_APPLE,
  HEALTH_SANDWICH,
  HEALTH_STEW,
  HEALTH_WATER,

  // Ammo
  AMMO_BULLET,
  AMMO_SHELL,

  // Weapons
  WEAPON_POCKET_KNIFE,
  WEAPON_BASEBALL_BAT,
  WEAPON_MACHETE,
  WEAPON_M1911,
  WEAPON_M1915,
  WEAPON_M3,
  WEAPON_M16,
  WEAPON_MOSSBERG_500,

  COUNT,
}

init_items :: proc(items: []Item)
{
  items[ItemType.HEALTH_APPLE] = {
    type = .HEALTH_APPLE,
  }
  items[ItemType.HEALTH_SANDWICH] = {
    type = .HEALTH_SANDWICH,
  }
  items[ItemType.HEALTH_STEW] = {
    type = .HEALTH_STEW,
  }
  items[ItemType.HEALTH_WATER] = {
    type = .HEALTH_WATER,
  }
  items[ItemType.AMMO_BULLET] = {
    type = .AMMO_BULLET,
  }
  items[ItemType.AMMO_SHELL] = {
    type = .AMMO_SHELL,
  }
  items[ItemType.WEAPON_POCKET_KNIFE] = {
    type = .WEAPON_POCKET_KNIFE,
  }
  items[ItemType.WEAPON_BASEBALL_BAT] = {
    type = .WEAPON_BASEBALL_BAT,
  }
  items[ItemType.WEAPON_MACHETE] = {
    type = .WEAPON_MACHETE,
  }
  items[ItemType.WEAPON_M1911] = {
    type = .WEAPON_M1911,
  }
  items[ItemType.WEAPON_M1915] = {
    type = .WEAPON_M1915,
  }
  items[ItemType.WEAPON_M3] = {
    type = .WEAPON_M3,
  }
  items[ItemType.WEAPON_M16] = {
    type = .WEAPON_M16,
  }
}

add_item :: proc(gm: ^Game, type: ItemType, count: int)
{
  item := &gm.items[type]
  item.count += count
  item_name := string_from_item_type(item.type)

  set_color(.GREEN)
  fmt.printf(" + added %s (%i)\n", item_name, count)
  set_color(.GRAY)
}

remove_item :: proc(gm: ^Game, type: ItemType, count: int)
{
  item := &gm.items[type]
  item.count -= count
  item_name := string_from_item_type(type)

  set_color(.RED)
  fmt.printf(" - removed %s (%i)\n", item_name, count)
  set_color(.GRAY)
}

generate_random_location :: proc(gm: ^Game)
{
  @(static) locations: [2]string = {
    0 = "Grocery Store",
    1 = "Police Station",
  }

  location_roll: i32
  for true
  {
    location_roll = rand.int31() % len(locations) 
    name := locations[location_roll]
  
    fmt.printf("You discovered an abandoned %s\n", name)
    set_color(.GRAY)

    break
  }

  switch location_roll
  {
    case 0:
    {
      // food items
    }
    case 1:
    {
      // weapon items
    }
  }
}

string_from_item_type :: proc(type: ItemType) -> string
{
  @(static) items: [ItemType.COUNT]string = {
    ItemType.HEALTH_APPLE = "Apple",
    ItemType.HEALTH_SANDWICH = "Sandwich",
    ItemType.HEALTH_STEW = "Stew",
    ItemType.HEALTH_WATER = "Water Bottle",
    ItemType.AMMO_BULLET = "Bullets",
    ItemType.AMMO_SHELL = "Shotgun Shells",
    ItemType.WEAPON_POCKET_KNIFE = "Pocket Knife",
    ItemType.WEAPON_BASEBALL_BAT = "Baseball Bat",
    ItemType.WEAPON_MACHETE = "Machete",
    ItemType.WEAPON_M1911 = "M1911 Pistol",
    ItemType.WEAPON_M1915 = "M1915 Pistol",
    ItemType.WEAPON_M3 = "M3 SMG",
    ItemType.WEAPON_M16 = "M16A1 Rifle",
    ItemType.WEAPON_MOSSBERG_500 = "Mossberg 500 Shotgun",
  }

  return items[type]
}

// @Entity ///////////////////////////////////////////////////////////////////////////////

Entity :: struct
{
  type : EntityType,
  passive : bool,
  health : int,
  damage : int,
}

EntityType :: enum
{
  POSSESSED_SQUIRREL,
  POSSESSED_DOG,
  CULTIST,
  DEMON,

  COUNT,
}

init_entities :: proc(entities: []Entity)
{
  entities[EntityType.POSSESSED_SQUIRREL] = {
    type = .POSSESSED_SQUIRREL,
    health = 10,
    damage = 3,
  }
  entities[EntityType.POSSESSED_DOG] = {
    type = .POSSESSED_DOG,
    health = 10,
    damage = 5,
  }
  entities[EntityType.CULTIST] = {
    type = .CULTIST,
    health = 20,
    damage = 7,
  }
  entities[EntityType.DEMON] = {
    type = .DEMON,
    health = 50,
    damage = 10,
  }
}

generate_random_encounter :: proc(gm: ^Game, entities: []Entity)
{
  for true
  {
    roll: EntityType = cast(EntityType) (rand.int31() % i32(EntityType.COUNT))
    name := string_from_entity_type(roll)

    if roll == .CULTIST && gm.day < 5 do continue
    if roll == .DEMON && gm.day < 20 do continue
  
    set_color(.RED)
    fmt.printf("You encountered a %s\n", name)
    set_color(.GRAY)

    if entities[roll].passive
    {
      // entity is passive. trade maybe?
    }
    else
    {
      gm.activities += {.ENCOUNTER}

      fmt.print("Entity appears hostile. ")
      fmt.print("Type 'fight' to enter combat. Type 'flee' to attempt to flee.\n")
    }

    break
  }
}

string_from_entity_type :: proc(type: EntityType) -> string
{
  @(static) items: [EntityType.COUNT]string = {
    EntityType.POSSESSED_SQUIRREL = "Possessed Squirrel",
    EntityType.POSSESSED_DOG = "Possessed Dog",
    EntityType.CULTIST = "Cultist",
    EntityType.DEMON = "Demon",
  }

  return items[type]
}

// @Terminal /////////////////////////////////////////////////////////////////////////////

Color :: enum
{
  BLACK,
  BLUE,
  GRAY,
  GREEN,
  RED,
  WHITE,
  YELLOW,
}

set_color :: proc(color: Color)
{
  switch color
  {
    case .BLACK:
      fmt.print("\u001b[38;5;16m")
    case .BLUE:
      fmt.print("\u001b[38;5;4m")
    case .GRAY:
      fmt.print("\u001b[38;5;7m")
    case .GREEN:
      fmt.print("\u001b[38;5;2m")
    case .RED:
      fmt.print("\u001b[38;5;1m")
    case .WHITE:
      fmt.print("\u001b[38;5;15m")
    case .YELLOW:
      fmt.print("\u001b[38;5;3m")
  }
}

set_bold :: proc(bold: bool)
{
  if bold
  {
    fmt.print("\u001b[1m")
  }
  else
  {
    fmt.print("\u001b[0m")
    fmt.print("\u001b[38;5;7m")
  }
}

// @Imports //////////////////////////////////////////////////////////////////////////////

import runtime "base:runtime"
import fmt "core:fmt"
import os "core:os"
import str "core:strings"
import strconv "core:strconv"
import rand "core:math/rand"

import rt "root"
import rm "root/math"
