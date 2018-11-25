#!/bin/bash -e
if [ "x$2" != "xreset" ] ; then
cd work
bcfg=`cat bcfg`
rm -f iBEC *.dec
echo Extracting iBoot from IPSW
unzip -p "$1" Firmware/all_flash/all_flash.${bcfg}.production/iBoot.${bcfg}.RELEASE.img3 > iBoot.img3
echo Patching iBoot
../tools/xpwntool iBoot.img3 iBoot.dec -k `cat key` -iv `cat iv` >/dev/null
../tools/iBoot32Patcher/iBoot32Patcher iBoot.dec PwnediBoot.dec -r -d >/dev/null
# boot-partition to l33t-partition - will never be found in nvram
../tools/hexpatch.sh PwnediBoot.dec 626f6f742d706172746974696f6e 6c3333742d706172746974696f6e
# boot-ramdisk to l33t-ramdisk - will never be found in nvram
../tools/hexpatch.sh PwnediBoot.dec 626f6f742d72616d6469736b 6c3333742d72616d6469736b
../tools/xpwntool PwnediBoot.dec iBEC -t iBoot.img3 -k `cat key` -iv `cat iv` >/dev/null
# ibot to ibec but little endian
../tools/hexpatch.sh iBEC 746f6269 63656269
rm -f *.dec iv key iBoot.img3
fi
