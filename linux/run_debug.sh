clear
rm debug
# odin run ../src/ -out=./main -define:RAYLIB_USE_LINALG=false
odin run ../src/ -out=./debug -debug
