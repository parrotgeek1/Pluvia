#!/bin/bash -e
search="$2" 
replace="$3"
xxd -p "$1" | tr -d "\n\r" | sed "s/$search/$replace/g" | xxd -r -p > "$1.patched"
cat "$1.patched" > "$1"
rm -f "$1.patched" 
