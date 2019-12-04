#!/bin/bash -e

get_key() {
	cat "$1" | grep -A1 "<key>$2</key>" | tail -1 | cut -d '>' -f 2 | cut -d '<' -f 1
}

cd "$(dirname "$0")"

ecid=`ioreg -l -w0 | grep "USB Serial Number" | grep -m 1 "iBoot-574.4" | sed 's/^.*ECID://' | sed 's/ .*//'`
if [ "x$ecid" = x ]; then
	echo "Can't connect to your iPhone. It needs to be in DFU mode."
	exit 1
fi

unzip -p "$1" Restore.plist > Restore.plist
model=`get_key Restore.plist ProductType`
vers=`get_key Restore.plist ProductVersion`
rm -f Restore.plist

rm -f *.shsh2
./tools/tsschecker -e 0x$ecid -d $model -m BuildManifest.plist -s
ecidf=`echo *.shsh2 | cut -d _ -f 1-2 | tr _ -`-DG.shsh
mkdir -p shsh
rm -f "shsh/$ecidf"
mv *.shsh2 "shsh/$ecidf"
echo Downloaded SHSH
killall iTunes iTunesHelper >/dev/null 2>&1 || true
cd tools/ipwndfu
./ipwndfu -p
cd ../..
./tools/idevicerestore -e -w "$1"
rm -rf shsh "`echo "$1" | sed 's/\.ipsw$//'`"
rm -f version.xml
echo "Finished! Enjoy iOS $vers" 
