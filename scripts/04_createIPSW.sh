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
../tools/gtar --owner 0 --group 0 -cf iBEC.tar iBEC
rm -f iBEC
cd ..
extras=616.tar
if [ "x$2" = "xjailbreak" ] ; then
	extras="616.tar jailbreak/Cydia.tar"
	iosver=`cat work/pvers`
	if [ $iosver = 6.1.3 ]; then
		echo Installing iOS $iosver jailbreak
		extras="$extras jailbreak/p0sixspwn.tar jailbreak/fstab_rw.tar"
	else
		echo "WARNING: Pluvia can't jailbreak iOS $iosver yet. Skipping."
	fi
fi
./tools/ipsw "$1" work/tmp.ipsw -ramdiskgrow 600 work/iBEC.tar $extras >/dev/null
rm -f work/iBEC.tar
echo Replacing bootchain components
cd work/712
bcfg=`cat ../bcfg`
if [ "x$2" != "xreset" ] ; then
	zip -d -qq ../tmp.ipsw "Firmware/all_flash/all_flash.${bcfg}.production/battery*.img3"
	zip -d -qq ../tmp.ipsw "Firmware/all_flash/all_flash.${bcfg}.production/glyph*.img3"
fi
(zipinfo -1 ../tmp.ipsw | grep '^Firmware/all_flash/.*img3$'; ls -1 Firmware/all_flash/	all_flash.${bcfg}.production/*.img3 )| cut -d/ -f4 | sort | uniq > Firmware/all_flash/all_flash.${bcfg}.production/manifest
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
name=
if [ "x$2" = "xreset" ] ; then
	rda=ramdisk_add_reset
	name=_ResetNVRAM
fi
if [ "x$2" = "xjailbreak" ] ; then
	name=_JB
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
	zip -qq -d tmp.ipsw '*.dmg'
	rm -f `cat sysimg`
	touch `cat sysimg`
	zip -qq tmp.ipsw `cat sysimg`
	rm -f `cat sysimg`
fi	
echo Adding patched ramdisk to IPSW
zip -qq tmp.ipsw $rramdisk
rm -f $rramdisk $rramdisk.orig
echo Patching Restore.plist
rm -f Restore.plist
unzip -qq tmp.ipsw Restore.plist
/usr/bin/sed -i '' 's/6\.1\.3/6.1.6/g' Restore.plist
/usr/bin/sed -i '' 's/10B329/10B500/g' Restore.plist
zip -qq tmp.ipsw Restore.plist
rm -f Restore.plist
iname="`echo "$1" | sed -e "s/6.1.3/6.1.6/" -e "s/10B329/10B500/" -e "s/\.ipsw$/$name.ipsw/"`"
rm -rf "$iname"
mv tmp.ipsw "$iname"
rm -f bcfg build ptype pvers rramdisk sysimg ramdisk.dmg
echo "Created patched IPSW at: $iname"
