What is Pluvia?
===============
Pluvia allows you to untethered downgrade your iPhone 4 without SHSH blobs! 
It uses the iOS 7.1.2 iBoot exploit "De Rebus Antiquis" by @xerub and @dora2-iOS.

Beta 1 Limitations
==================
Only for Mac!
Only supports iPhone3,1. 
Only supports a few firmwares (see FirmwareBundles folder for list)

NOTE: 8GB iPhone 4's can only run iOS 6 and newer, NOT iOS 4 or 5. This almost certainly can't be fixed.

How to use Pluvia
=================
1) Creating the patched IPSW

Run ./make_ipsw.sh <Input_IPSW>

2) Restoring the firmware

Connect your iPhone 4 and put it in DFU mode.
Run ./restore.sh <Patched_IPSW>
Wait for that to complete.
When your phone reboots the Apple logo should blink and then it will boot the older iOS!

Getting out of recovery mode after restoring to stock iOS
=========================================================
Run ./make_ipsw.sh <Any_Supported_Input_IPSW> reset
Connect your iPhone 4 and put it in DFU mode.
Run ./restore.sh <Reset_NVRAM_IPSW>
