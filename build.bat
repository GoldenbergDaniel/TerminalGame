@echo Compiling project...
@odin build src -out=debug\Game.exe -debug -no-crt -o:none
@REM @odin build src -out=Game.exe -o:speed -no-crt -no-bounds-check -disable-assert
@echo Compilation complete.
