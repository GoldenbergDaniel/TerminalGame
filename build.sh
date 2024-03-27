echo Compiling project...
odin build src -out=Game -sanitize:address
# odin build src -out=Game -o:speed -no-bounds-check -microarch:native
echo Compilation complete.
