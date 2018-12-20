What is Pluvia?
===============
Pluvia allows you to untethered downgrade your iPhone 4 without SHSH blobs! 
It uses the iOS 7.1.2 iBoot exploit "De Rebus Antiquis" by @xerub and @dora2-iOS.

This is a special version for porting iOS 6.1.6 from the iPod touch 4 to the iPhone 4, enabling FaceTime and security fixes. It requires an iPhone 4 6.1.3 IPSW as input.

Limitations
===========
Only for Mac!
Only supports iPhone3,1. 

How to use Pluvia
=================
1) Downloading required files

Run ./get.sh and wait up to 15 minutes

2) Creating the patched IPSW

Run ./make_ipsw.sh <Input_6.1.3_IPSW> jailbreak (if you want to jailbreak)
Or run ./make_ipsw.sh <Input_6.1.3_IPSW> (if you don't want to jailbreak)

3) Restoring the firmware

Connect your iPhone 4 and put it in DFU mode.
Run ./restore.sh <Patched_IPSW>
Wait for that to complete.
When your phone reboots the Apple logo should blink and then it will boot 6.1.6!
IMPORTANT: The second time you open Cydia (right after "Preparing Filesystem"), it will crash. I don't know why. Just reboot your iPhone and it will work.

Getting out of recovery mode after restoring to stock iOS
=========================================================
Run ./make_ipsw.sh <Input_6.1.3_IPSW> reset
Connect your iPhone 4 and put it in DFU mode.
Run ./restore.sh <Reset_NVRAM_IPSW>

Credits
=======
@xerub for De Rebus Antiquis iBoot exploit
@dora2-iOS for the auto-booting version of the exploit (ramdiskH_beta4.dmg), and the firmware bundles (https://github.com/dora2-iOS/s0meiyoshino)
@a8q for partitioning script in ramdisk
@saurik for Cydia.tar
p0sixspwn (@ih8sn0w, @squiffy, @winocm) for the untether
libimobiledevice and @tihmstar for idevicerestore
@axi0mx for ipwndfu
@ih8sn0w, @NyanSatan, and @Merculous for iBoot32Patcher
@tihmstar and @encounter for tsschecker
@sequinn and @parrotgeek1 for root_tar
The GNU Project for GNU tar (gtar)
@danzatt for ios-dualboot (hfs_resize)
