NAME="game"
MODE=$1

if [[ $MODE == "r" || $MODE == "-r" ]]
then
  echo "Building macOS release..."
  odin build src -out=$NAME -lld -o:speed -microarch:native -disable-assert -no-type-assert \
  -no-bounds-check -vet -warnings-as-errors
elif [[ $MODE == "d" || $MODE == "-d" ]]
then
  echo "Building macOS debug..."
  mkdir debug
  pushd debug
  odin build ../src -out=$NAME -lld -o:none -debug -sanitize=address
  popd
else
  echo "Building macOS dev..."
  odin build src -out=$NAME -lld -o:none
  ./$NAME
fi

echo "Done!"
