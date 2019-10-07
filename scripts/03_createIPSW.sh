#!/bin/bash -e
if [ "x$2" = "xreset" ] ; then
echo "Creating NVRAM reset IPSW (this will take several minutes)"
./tools/ipsw "$1" work/tmp.ipsw -ramdiskgrow 600 >/dev/null
cd work
else
cd work
echo "Creating patched IPSW (this will take several minutes)"
rm -f iBEC.tar
chmod 0400 iBEC
../tools/root_tar/mytar cRf iBEC.tar iBEC
rm -f iBEC
cd ..
extras=
extrasbegin=
if [ "x$2" = "xjailbreak" ] ; then
	extras="jailbreak/Cydia.tar"
	extrasbegin="-S 20"
	iosver=`cat work/pvers`
	if [ $iosver = 6.1.3 ]; then
		echo Installing iOS $iosver jailbreak
		extras="$extras jailbreak/p0sixspwn.tar"
	elif [ $iosver = 5.1.1 ]; then
		echo Installing iOS $iosver jailbreak
		extras="$extras jailbreak/unthredeh4il.tar"
	else
		extras=
		extrasbegin=
		echo "WARNING: Pluvia can't jailbreak iOS $iosver yet. Skipping."
	fi
fi
./tools/ipsw "$1" work/tmp.ipsw $extrasbegin -ramdiskgrow 600 work/iBEC.tar $extras >/dev/null
rm -f work/iBEC.tar
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
rda=ramdisk_add
name=Patched
if [ "x$2" = "xreset" ] ; then
	rda=ramdisk_add_reset
	name=ResetNVRAM
fi
if [ "x$2" = "xjailbreak" ] ; then
	name=Patched_JB
fi
find ../$rda -type f -not -name '.*' | while read f; do
	dest="`echo "$f" | cut -d/ -f3-`"
	cat "$f" > "$MountRamdisk/$dest"
	chmod 0555 "$MountRamdisk/$dest" 
done
hdiutil detach "$MountRamdisk" >/dev/null
../tools/xpwntool ramdisk.dmg $rramdisk -t $rramdisk.orig
if [ "x$2" = "xreset" ]; then
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
iname="`echo "$1" | sed "s/\.ipsw$/_$name.ipsw/"`"
rm -rf "$iname"
mv tmp.ipsw "$iname"
rm -f bcfg build ptype pvers rramdisk sysimg
echo "Created patched IPSW at: $iname"
