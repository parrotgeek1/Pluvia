What is Pluvia?
===============
Pluvia allows you to untethered downgrade your iPhone 4 without SHSH blobs! 
It uses the iOS 7.1.2 iBoot exploit "De Rebus Antiquis" by @xerub and @dora2-iOS.

Beta 1.5 Limitations
====================
Only for Mac!
Only supports iPhone3,1. 
Only supports iOS 5.1.1 (9B206), 6.x, and 7.x.
Can only jailbreak iOS 5.1.1 and 6.1.3

NOTE: 8GB iPhone 4's that shipped with iOS 6 can only run iOS 6 and newer, NOT iOS 4 or 5. This almost certainly can't be fixed.

How to use Pluvia
=================
1) Creating the patched IPSW

Run ./make_ipsw.sh <Input_IPSW> jailbreak (if you want to jailbreak)
Or run ./make_ipsw.sh <Input_IPSW> (if you don't want to jailbreak)

2) Restoring the firmware

Connect your iPhone 4 and put it in DFU mode.
Run ./restore.sh <Patched_IPSW>
Wait for that to complete.
When your phone reboots the Apple logo should blink and then it will boot the older iOS!

IMPORTANT: The second time you open Cydia (right after "Preparing Filesystem"), it will crash. I don't know why. Just reboot your iPhone and it will work.

Getting out of recovery mode after restoring to stock iOS
=========================================================
Run ./make_ipsw.sh <Any_Supported_Input_IPSW> reset
Connect your iPhone 4 and put it in DFU mode.
Run ./restore.sh <Reset_NVRAM_IPSW>

Credits
=======
@xerub for De Rebus Antiquis iBoot exploit
@dora2-iOS for the auto-booting version of the exploit (ramdiskH_beta4.dmg), and the firmware bundles (https://github.com/dora2-iOS/s0meiyoshino)
@a8q for partitioning script in ramdisk
@saurik for Cydia.tar
p0sixspwn (@ih8sn0w, @squiffy, @winocm) for the iOS 6 bootstrap
libimobiledevice and @tihmstar for idevicerestore
@axi0mx for ipwndfu
@ih8sn0w, @NyanSatan, and @Merculous for iBoot32Patcher
@tihmstar and @encounter for tsschecker
@sequinn and @parrotgeek1 for root_tar
