echo Compiling project...
odin build src -out=debug/Game -o:none
# odin build src -out=debug/Game -debug -o:none
# odin build src -out=Game -o:speed -no-bounds-check -microarch:native
echo Compilation complete.
