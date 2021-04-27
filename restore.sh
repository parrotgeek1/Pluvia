#!/bin/bash

realpath() {
    canonicalize_path "$(resolve_symlinks "$1")"
}

resolve_symlinks() {
    _resolve_symlinks "$1"
}

_resolve_symlinks() {
    _assert_no_path_cycles "$@" || return

    local dir_context path
    path=$(readlink -- "$1")
    if [ $? -eq 0 ]; then
        dir_context=$(dirname -- "$1")
        _resolve_symlinks "$(_prepend_dir_context_if_necessary "$dir_context" "$path")" "$@"
    else
        printf '%s\n' "$1"
    fi
}

_prepend_dir_context_if_necessary() {
    if [ "$1" = . ]; then
        printf '%s\n' "$2"
    else
        _prepend_path_if_relative "$1" "$2"
    fi
}

_prepend_path_if_relative() {
    case "$2" in
        /* ) printf '%s\n' "$2" ;;
         * ) printf '%s\n' "$1/$2" ;;
    esac
}

_assert_no_path_cycles() {
    local target path

    target=$1
    shift

    for path in "$@"; do
        if [ "$path" = "$target" ]; then
            return 1
        fi
    done
}

canonicalize_path() {
    if [ -d "$1" ]; then
        _canonicalize_dir_path "$1"
    else
        _canonicalize_file_path "$1"
    fi
}

_canonicalize_dir_path() {
    (cd "$1" 2>/dev/null && pwd -P)
}

_canonicalize_file_path() {
    local dir file
    dir=$(dirname -- "$1")
    file=$(basename -- "$1")
    (cd "$dir" 2>/dev/null && printf '%s/%s\n' "$(pwd -P)" "$file")
}

if [ "x`uname`" != "xDarwin" ] ; then
	echo "Only Mac OS X is supported."
	exit 1
fi

if [ "x`uname -m`" = "xi386" ] ; then
	echo "Only 64-bit Macs are supported."
	exit 1
fi

get_key() {
	cat "$1" | grep -A1 "<key>$2</key>" | tail -1 | cut -d '>' -f 2 | cut -d '<' -f 1
}

usage() {
	echo "Usage: $1 <input.ipsw>"
}

_exit() {
	rm -f Restore.plist *.shsh2
	exit 1
}

if [ "x$1" = "x" ]; then
	usage "$0"
	exit 1
fi

cd "$(dirname "$0")"

trap _exit SIGINT SIGTERM

if [ ! -f "`realpath "$1"`" ] ; then
	echo "Can't read IPSW file: $1"
	exit 1
fi

unzip -p "`realpath "$1"`" Restore.plist > Restore.plist 2>/dev/null
if [ ! -s Restore.plist ] ; then
	echo "Not an IPSW file: $1"
	rm -f Restore.plist
	exit 1
fi

ecid=`ioreg -l -w0 | grep "USB Serial Number" | grep -m 1 "iBoot-574.4" | sed 's/^.*ECID://' | sed 's/ .*//'`
if [ "x$ecid" = x ]; then
	echo "Can't connect to your iPhone. It needs to be in DFU mode."
	rm -f Restore.plist
	exit 1
fi

set -e

model=`get_key Restore.plist ProductType`
vers=`get_key Restore.plist ProductVersion`
rm -f Restore.plist
rm -f *.shsh2
mkdir -p shsh
ecidf="shsh/$(printf "%d" 0x$ecid)-${model}-DG.shsh"
if [ ! -f "$ecidf" ]; then
	echo Downloading SHSH for ECID 0x$ecid
	./tools/tsschecker -e 0x$ecid -d $model -m BuildManifest.plist -s
	mv *.shsh2 "$ecidf"
else
	echo Using cached SHSH for ECID 0x$ecid
fi
rm -rf "`realpath "$1" | sed 's/\.ipsw$//'`"
killall iTunes iTunesHelper >/dev/null 2>&1 || true
killall -STOP AMPDeviceDiscoveryAgent >/dev/null 2>&1 || true
cd tools/ipwndfu
arch -x86_64 /usr/bin/python ./ipwndfu -p
cd ../..
echo
echo 'IMPORTANT: an "FDR" error is normal, ignore it'
echo
set +e
./tools/idevicerestore -y -e -w "`realpath "$1"`"
ex=$?
rm -rf "`realpath "$1" | sed 's/\.ipsw$//'`"
killall -CONT AMPDeviceDiscoveryAgent >/dev/null 2>&1 || true
if [ $ex != 0 ]; then
exit $ex
fi
echo "Finished! Enjoy iOS $vers" 
