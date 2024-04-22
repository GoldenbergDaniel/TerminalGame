@echo off
setlocal

set MODE=%1%

set RLS_FLAGS=-o:speed -microarch:native -disable-assert -no-bounds-check -no-crt -vet -warnings-as-errors

set DBG_FLAGS=-o:none -debug

set DEV_FLAGS=-o:none -no-crt -use-separate-modules

if "%MODE%"=="d" (
  echo Building windows debug...
  mkdir debug
  pushd debug
  odin build ../src -out=game.exe %DBG_FLAGS%
  popd
) else (
  if "%MODE%"=="r" (
    echo Building windows release...
    odin build src -out=game.exe %RLS_FLAGS%
  ) else (
    echo Building windows dev...
    odin build src -out=game.exe %DEV_FLAGS%
    game.exe
  )
)
