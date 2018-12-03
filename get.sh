#!/bin/bash -e
echo Downloading iPod 6.1.6
rm -rf 616 61*.zip 616b.txt 616.tar
cat 616.txt | sed 's@^AssetData/payload/replace/@@' > 616b.txt
cat dylibs.txt >> 616b.txt
echo usr/lib/libTelephonyIOKitDynamic.dylib >> 616b.txt
curl -# -L -o 616.zip http://appldnld.apple.com/iOS6.1/031-3209.20140221.VbP9o/com_apple_MobileAsset_SoftwareUpdate/0f3e181913166c8e828d946a545d02cfc08c8e02.zip
echo Extracting
mkdir 616
cd 616
tr '\n' '\0' <../616.txt | xargs -0 unzip -q ../616.zip
echo Downloading iPhone 6.1.3
curl -# -L -o 613.zip http://appldnld.apple.com/iOS6.1/091-3360.20130311.BmfR4/com_apple_MobileAsset_SoftwareUpdate/61e713aef9569240f29360ad242ff9d15bbace85.zip
echo Extracting dyld cache
unzip -qq -j 613.zip AssetData/payload/replace/System/Library/Caches/com.apple.dyld/dyld_shared_cache_armv7
for i in `cat ../dylibs.txt`; do
mkdir -p AssetData/payload/replace/`dirname $i`
../tools/decache/decache -c dyld_shared_cache_armv7 -x /$i -o AssetData/payload/replace/$i >/dev/null
../tools/ldid -S AssetData/payload/replace/$i
chmod 0755 AssetData/payload/replace/$i
done
echo Tarring
cd AssetData/payload/replace
../tools/gtar --owner 0 --group 0 -T ../../../../616b.txt -cf ../../../../616.tar
cd ../../../..
echo Cleaning
rm -rf 616 61*.zip 616b.txt dyld_shared_cache_armv7*
