NAME="game"
MODE=$1

RLS_FLAGS="-o:speed -lld -microarch:native -disable-assert -no-type-assert
  -no-bounds-check -vet -warnings-as-errors"

DBG_FLAGS="-o:none -lld -debug -sanitize=address"

DEV_FLAGS="-o:none -lld"

if [[ $MODE == "r" || $MODE == "-r" ]]
then
  echo "Building macOS release..."
  odin build src -out=$NAME $REL_FLAGS
elif [[ $MODE == "d" || $MODE == "-d" ]]
then
  echo "Building macOS debug..."
  mkdir debug
  pushd debug
  odin build ../src -out=$NAME 
  popd
else
  echo "Building macOS dev..."
  odin build src -out=$NAME 
  ./$NAME
fi
