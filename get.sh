#!/bin/bash -e
echo Downloading iPod 4 6.1.6
rm -rf 616 61*.zip 616b.txt 616.tar dyld_shared_cache_armv7*
cat 616.txt | sed 's@^AssetData/payload/replace/@@' > 616b.txt
cat dylibs.txt dylibs4.txt >> 616b.txt
curl -# -L -o 616.zip http://appldnld.apple.com/iOS6.1/031-3209.20140221.VbP9o/com_apple_MobileAsset_SoftwareUpdate/0f3e181913166c8e828d946a545d02cfc08c8e02.zip
echo Downloading iPhone 3GS 6.1.6
curl -# -L -o 6163gs.zip http://appldnld.apple.com/iOS6.1/091-3486.20140221.Poy65/com_apple_MobileAsset_SoftwareUpdate/903b149c839c0650fd072d47c52599a52cbdd292.zip
echo Downloading iPhone 4 6.1.3
curl -# -L -o 613.zip http://appldnld.apple.com/iOS6.1/091-3360.20130311.BmfR4/com_apple_MobileAsset_SoftwareUpdate/61e713aef9569240f29360ad242ff9d15bbace85.zip
echo Extracting changed files
mkdir 616
cd 616
tr '\n' '\0' <../616.txt | xargs -0 unzip -q ../616.zip
echo Extracting dyld caches
unzip -qq -j 613.zip AssetData/payload/replace/System/Library/Caches/com.apple.dyld/dyld_shared_cache_armv7
mv dyld_shared_cache_armv7 dyld_shared_cache_armv7_i4
unzip -qq -j 6163gs.zip AssetData/payload/replace/System/Library/Caches/com.apple.dyld/dyld_shared_cache_armv7
for i in `cat ../dylibs.txt`; do
mkdir -p AssetData/payload/replace/`dirname $i`
../tools/decache/decache -c dyld_shared_cache_armv7 -x /$i -o AssetData/payload/replace/$i >/dev/null
../tools/ldid -S AssetData/payload/replace/$i
done
for i in `cat ../dylibs4.txt`; do
mkdir -p AssetData/payload/replace/`dirname $i`
../tools/decache/decache -c dyld_shared_cache_armv7_i4 -x /$i -o AssetData/payload/replace/$i >/dev/null
../tools/ldid -S AssetData/payload/replace/$i
done
cd AssetData/payload/replace
echo Setting permissions
# this list was extracted by: lsbom AssetData/payload.bom  | grep -f 616b.txt | cut -d/ -f4- | awk '{print "chmod " $2 " " $1}' | sed 's/ 100/ 0/'
chmod 0775 Library/Audio/Plug-Ins/HAL/VirtualAudio.plugin/VirtualAudio
chmod 0644 System/Library/Caches/com.apple.dyld/dyld_shared_cache_armv7
chmod 0444 System/Library/CoreServices/SystemVersion.plist
chmod 0644 System/Library/DataClassMigrators/FaceTimeMigrator.migrator/Info.plist
chmod 0644 System/Library/LaunchDaemons/com.apple.mobileactivation.recert.plist
chmod 0644 System/Library/PrivateFrameworks/ApplePushService.framework/Info.plist
chmod 0755 System/Library/PrivateFrameworks/ApplePushService.framework/apsd
chmod 0644 System/Library/PrivateFrameworks/FTAWD.framework/Info.plist
chmod 0644 System/Library/PrivateFrameworks/FTClientServices.framework/Info.plist
chmod 0644 System/Library/PrivateFrameworks/FTServices.framework/Info.plist
chmod 0644 System/Library/PrivateFrameworks/GameKitServices.framework/Frameworks/AVConference.framework/Info.plist
chmod 0644 System/Library/PrivateFrameworks/GameKitServices.framework/Frameworks/GKSPerformance.framework/Info.plist
chmod 0644 System/Library/PrivateFrameworks/GameKitServices.framework/Frameworks/ICE.framework/Info.plist
chmod 0644 System/Library/PrivateFrameworks/GameKitServices.framework/Frameworks/LegacyHandle.framework/Info.plist
chmod 0644 System/Library/PrivateFrameworks/GameKitServices.framework/Frameworks/SimpleKeyExchange.framework/Info.plist
chmod 0644 System/Library/PrivateFrameworks/GameKitServices.framework/Frameworks/ViceroyTrace.framework/Info.plist
chmod 0644 System/Library/PrivateFrameworks/GameKitServices.framework/Frameworks/snatmap.framework/Info.plist
chmod 0644 System/Library/PrivateFrameworks/GameKitServices.framework/Info.plist
chmod 0644 System/Library/PrivateFrameworks/IMCore.framework/Info.plist
chmod 0644 System/Library/PrivateFrameworks/IMCore.framework/imagent.app/Info.plist
chmod 0755 System/Library/PrivateFrameworks/IMCore.framework/imagent.app/imagent
chmod 0644 System/Library/PrivateFrameworks/IMDAppleServices.framework/Info.plist
chmod 0644 System/Library/PrivateFrameworks/IMDMessageServices.framework/Info.plist
chmod 0755 System/Library/PrivateFrameworks/IMDMessageServices.framework/XPCServices/IMDMessageServicesAgent.xpc/IMDMessageServicesAgent
chmod 0644 System/Library/PrivateFrameworks/IMDMessageServices.framework/XPCServices/IMDMessageServicesAgent.xpc/Info.plist
chmod 0644 System/Library/PrivateFrameworks/IMDPersistence.framework/Info.plist
chmod 0644 System/Library/PrivateFrameworks/IMDaemonCore.framework/Info.plist
chmod 0644 System/Library/PrivateFrameworks/IMFoundation.framework/Info.plist
chmod 0755 System/Library/PrivateFrameworks/IMFoundation.framework/XPCServices/IMRemoteURLConnectionAgent.xpc/IMRemoteURLConnectionAgent
chmod 0644 System/Library/PrivateFrameworks/IMFoundation.framework/XPCServices/IMRemoteURLConnectionAgent.xpc/Info.plist
chmod 0644 System/Library/PrivateFrameworks/IMTranscoding.framework/Info.plist
chmod 0755 System/Library/PrivateFrameworks/IMTranscoding.framework/XPCServices/IMTranscoderAgent.xpc/IMTranscoderAgent
chmod 0644 System/Library/PrivateFrameworks/IMTranscoding.framework/XPCServices/IMTranscoderAgent.xpc/Info.plist
chmod 0644 System/Library/PrivateFrameworks/IMTransferServices.framework/Info.plist
chmod 0755 System/Library/PrivateFrameworks/IMTransferServices.framework/XPCServices/IMTransferAgent.xpc/IMTransferAgent
chmod 0644 System/Library/PrivateFrameworks/IMTransferServices.framework/XPCServices/IMTransferAgent.xpc/Info.plist
chmod 0644 System/Library/PrivateFrameworks/IncomingCallFilter.framework/Info.plist
chmod 0644 System/Library/PrivateFrameworks/MMCSServices.framework/Info.plist
chmod 0644 System/Library/PrivateFrameworks/Marco.framework/Info.plist
chmod 0755 System/Library/PrivateFrameworks/Marco.framework/marcoagent
chmod 0644 System/Library/PrivateFrameworks/MobileActivation.framework/Info.plist
chmod 0644 System/Library/PrivateFrameworks/OpenCL.framework/cl_kernel.armv7.pch
chmod 0755 usr/libexec/lockbot
chmod 0755 usr/libexec/lockdownd
chmod 0755 usr/libexec/mobile_recert
chmod 0755 usr/libexec/securityd
chmod 0755 usr/libexec/vpnagent
chmod 0644 usr/standalone/update/ramdisk/H3SURamDisk.dmg
chmod 0644 System/Library/Messages/PlugIns/SMS.imservice/SMS
chmod 0644 System/Library/SpringBoardPlugins/SIMToolkitUI.servicebundle/SIMToolkitUI
chmod 0644 System/Library/VideoProcessors/Highlight.videoprocessor
chmod 0644 usr/lib/libTelephonyIOKitDynamic.dylib
echo Tarring
../../../../tools/gtar --owner 0 --group 0 -T ../../../../616b.txt -cf ../../../../616.tar
cd ../../../..
echo Cleaning
rm -rf 616 61*.zip 616b.txt dyld_shared_cache_armv7*
echo "Done! Please run ./make_ipsw.sh <6.1.3.ipsw>"
