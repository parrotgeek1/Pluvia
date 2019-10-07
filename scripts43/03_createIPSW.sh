#!/bin/bash -e
if [ "x$3" = "xreset" ] ; then
echo "Creating NVRAM reset IPSW (this will take several minutes)"
./tools/ipsw "$1" work/tmp.ipsw -ramdiskgrow 600 >/dev/null
cd work
else
cd work
echo "Creating patched IPSW (this may take up to 10 minutes)"
cd ..
extras=fstab.tar
extrasbegin=
if [ "x$3" = "xjailbreak" ] ; then
	extras="jailbreak/Cydia.tar fstab.tar"
	extrasbegin="-S 20"
	iosver=4.3.5
	echo Installing iOS $iosver jailbreak
	extras="$extras jailbreak/unthredeh4il.tar"
fi
./tools/ipsw "$1" work/tmp.ipsw  -ramdiskgrow 2000 >/dev/null
echo Replacing bootchain components
cd work/712
bcfg=`cat ../bcfg`
zip -d -qq ../tmp.ipsw "Firmware/all_flash/all_flash.${bcfg}.production/battery*.img3"
zip -d -qq ../tmp.ipsw "Firmware/all_flash/all_flash.${bcfg}.production/glyph*.img3"
(zipinfo -1 ../tmp.ipsw | grep '^Firmware/all_flash/.*img3$'; ls -1 Firmware/all_flash/all_flash.${bcfg}.production/*.img3 )| cut -d/ -f4 | sort | uniq > Firmware/all_flash/all_flash.${bcfg}.production/manifest
zip -qq ../tmp.ipsw Firmware/all_flash/all_flash.${bcfg}.production/*.img3 Firmware/all_flash/all_flash.${bcfg}.production/manifest
rm -f Firmware/all_flash/all_flash.${bcfg}.production/manifest
cd ..
fi
echo Extracting ramdisk from IPSW
rramdisk=`cat rramdisk`
rm -f $rramdisk $rramdisk.orig
unzip -p tmp.ipsw $rramdisk > $rramdisk.orig
rm -f ramdisk.dmg
echo Patching ramdisk
../tools/xpwntool $rramdisk.orig ramdisk.dmg
MountRamdisk="$(hdiutil mount ramdisk.dmg | awk -F '\t' '{print $3}')"
mv "$MountRamdisk/sbin/reboot" "$MountRamdisk/sbin/reboot.real"
rda=ramdisk_add43
name=Patched
if [ "x$3" = "xreset" ] ; then
	rda=ramdisk_add_reset
	name=ResetNVRAM
fi
if [ "x$3" = "xjailbreak" ] ; then
	name=Patched_JB
fi
find ../$rda -type f -not -name '.*' | while read f; do
	dest="`echo "$f" | cut -d/ -f3-`"
	cat "$f" > "$MountRamdisk/$dest"
	chmod 0555 "$MountRamdisk/$dest" 
done
if [ "x$3" != "xreset" ] ; then
	cat "iBEC" > "$MountRamdisk/iBEC"
	chmod 0555 "$MountRamdisk/iBEC" 
	rm -f iBEC
fi
hdiutil detach "$MountRamdisk" >/dev/null
../tools/xpwntool ramdisk.dmg $rramdisk -t $rramdisk.orig
if [ "x$3" = "xreset" ]; then
	echo Cleaning IPSW
	zip -qq -d tmp.ipsw '*.dmg' 'Firmware/ICE3*'
	rm -f `cat sysimg`
	touch `cat sysimg`
	zip -qq tmp.ipsw `cat sysimg`
	rm -f `cat sysimg`
fi	
echo Adding patched ramdisk to IPSW
zip -qq tmp.ipsw $rramdisk
rm -f $rramdisk $rramdisk.orig

if [ "x$3" != "xreset" ]; then
echo "Making custom 4.3.5 IPSW to get system image"
rm -f tmp2.ipsw
cd ..
./tools/ipsw "$2" work/tmp2.ipsw $extrasbegin $extras >/dev/null
cd work

echo "Extracting the resulting system image"
unzip -qq tmp2.ipsw 038-2288-002.dmg
rm -f `cat sysimg`
mv 038-2288-002.dmg `cat sysimg`

echo "Replacing the system image in the base IPSW"
zip -qq tmp.ipsw `cat sysimg`

rm -f tmp2.ipsw `cat sysimg`
fi

iname="`echo "$1" | sed 's/5.1.1_9B206/4.3.5_8L1/' | sed "s/\.ipsw$/_$name.ipsw/"`"
rm -rf "$iname"
mv tmp.ipsw "$iname"
rm -f bcfg build ptype pvers rramdisk sysimg ramdisk.dmg
echo "Created patched IPSW at: $iname"
