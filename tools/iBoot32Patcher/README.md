iBoot32Patcher - A Universal 32-bit iBoot patcher for iPhone OS 2.0 --> iOS 10 
----------------------------------------------------
	Copyright 2013-2016, iH8sn0w. <iH8sn0w@iH8sn0w.com>

	iBoot32Patcher is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	iBoot32Patcher is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with iBoot32Patcher.  If not, see <http://www.gnu.org/licenses/>.

Compiling
---------------------------------------------------
	clang iBoot32Patcher.c finders.c functions.c patchers.c -Wno-multichar -I. -o iBoot32Patcher

Sample Usage
---------------------------------------------------
	iBoot32Patcher iBoot.n49.RELEASE.dfu.decrypted iBoot.n49.RELEASE.dfu.patched -b "cs_enforcement_disable=1" -c "ticket" 0x80000000

Bugs
---------------------------------------------------
Be sure to file a bug report under Github's Issues tab if you run into any.
