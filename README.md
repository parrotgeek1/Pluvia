Important Notice
================

Development of Pluvia is now discontinued, and no support is available for it.

What is Pluvia?
===============
Pluvia allows you to untethered downgrade your iPhone 4 without SHSH blobs!

It uses the iOS 7.1.2 iBoot exploit "De Rebus Antiquis" by @xerub and @dora2-iOS.

This is a special version for porting iOS 6.1.6 from the iPod touch 4 to the iPhone 4, enabling FaceTime and security fixes. It requires an iPhone 4 6.1.3 IPSW as input.

Limitations
===========
* Only for Mac!
* Only supports iPhone3,1.
  - Support for iPhone3,2 and 3,3 is not easily possible because the iBoot exploit utilized by Pluvia has not been ported to those devices, and there is almost no documentation of how to do so.

How to use Pluvia
=================
1) Creating the patched IPSW

Run ./make_ipsw.sh <Input_6.1.3_IPSW> jailbreak (if you want to jailbreak)

Or run ./make_ipsw.sh <Input_6.1.3_IPSW> (if you don't want to jailbreak)

2) Restoring the firmware

Connect your iPhone 4 and put it in DFU mode.

Run ./restore.sh <Patched_IPSW>

Wait for that to complete.

When your phone reboots the Apple logo should blink and then it will boot 6.1.6!

Getting out of recovery mode after restoring to stock iOS
=========================================================
Run ./make_ipsw.sh <Input_6.1.3_IPSW> reset


Connect your iPhone 4 and put it in DFU mode.

Run ./restore.sh <Reset_NVRAM_IPSW>

Credits
=======
@xerub for De Rebus Antiquis iBoot exploit

@dora2-iOS for ramdiskH.dmg, part of the partitioning script in the ramdisk, the binaries in the ramdisk (which are likely from Cydia packages), and the firmware bundles

@a8q for the original partitioning script in the ramdisk

@saurik for Cydia.tar

p0sixspwn (@ih8sn0w, @squiffy, @winocm) for the untether

s0uthwest, libimobiledevice, and @tihmstar for idevicerestore, which I patched in a hex editor to remove several error messages and skip checks that would make the restore fail

@axi0mx for ipwndfu

@ih8sn0w, @NyanSatan, and @Merculous for iBoot32Patcher

@tihmstar and @encounter for tsschecker

The GNU Project and Apple for GNU tar (gtar) - see https://github.com/apple-open-source/macos/tree/master/gnutar

@danzatt for ios-dualboot (hfs_resize)

https://github.com/mkropat/sh-realpath for realpath code used in scripts

libusb and pyusb

Licensing notes
===============
The ParrotGeek Software logo shown during the restore process is NOT licensed under the GPL and must be removed in any publicly released modifications of this project.

Furthermore, any publicly released modifications of this project must not use the word Pluvia anywhere in their name, or purport to be endorsed by ParrotGeek Software.

The code and files created by @dora2-iOS are licensed under the GPLv3 or the MIT License, and were present in commit 316d2cdc5351c918e9db9650247b91632af3f11f of https://github.com/dora2-iOS/ch3rryflower, and commits 06262f41d0677feec0f03ff2f0496d63898a346f and 26cb118bde7ad0198df08a2b0af9f319c0de511c of https://github.com/dora2-iOS/s0meiyoshino, which no longer exist publicly.

Proof that these files were previously licensed under GPLv3 or the MIT License is available at the following URLs: https://archive.is/xk2tP https://archive.is/FN7hi https://archive.is/DZKRa https://archive.is/xq3IE https://archive.is/Qx1U1 https://archive.is/ylOn9 (the last four are from a forked repository, since the original was deleted before it was archived, but the committer is visible as @dora2-iOS).
