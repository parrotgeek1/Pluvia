#!/bin/bash -e

extimg() {
	unzip -p 712.ipsw "$1" > "712/$1"
}

cd work
bcfg=`cat bcfg`
if [ -f 712/Firmware/all_flash/all_flash.${bcfg}.production/ok ] ; then
	exit 0
fi
echo "Downloading 7.1.2 IPSW for ${bcfg} to get bootchain files"
rm -f 712.ipsw
curl -# -L -o 712.ipsw https://api.ipsw.me/v4/ipsw/download/`cat ptype`/11D257
echo "Extracting 7.1.2 bootchain components"
mkdir -p 712/Firmware/all_flash/all_flash.${bcfg}.production/
for img in batterycharging0@2x~iphone.s5l8930x.img3 batterycharging1@2x~iphone.s5l8930x.img3 batteryfull@2x~iphone.s5l8930x.img3 batterylow0@2x~iphone.s5l8930x.img3 batterylow1@2x~iphone.s5l8930x.img3 glyphplugin@2x~iphone-30pin.s5l8930x.img3 iBoot.${bcfg}.RELEASE.img3 LLB.${bcfg}.RELEASE.img3 ; do
	extimg Firmware/all_flash/all_flash.${bcfg}.production/$img
done
touch 712/Firmware/all_flash/all_flash.${bcfg}.production/ok
rm -f 712.ipsw 
cd ..
