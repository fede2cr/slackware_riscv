#!/bin/sh

# Copyright 2017  Patrick J. Volkerding, Sebeka, MN, USA
# All rights reserved.
#
# Redistribution and use of this script, with or without modification, is
# permitted provided that the following conditions are met:
#
# 1. Redistributions of this script must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
#  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
#  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO
#  EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
#  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
#  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
#  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
#  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
#  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Convert github release in vX.XX.tar.gz format to exiv2-X.XX.tar.xz format
# and remove useless cruft.


GITHUB_RELEASE=$(echo v*.tar.gz)
if [ ! -r $GITHUB_RELEASE ]; then
  echo "$GITHUB_RELEASE is not a libwebp tarball. Exiting."
  exit 1
fi
SRCDIR=$(tar tf v*.tar.gz | head -n 1 | cut -f 1 -d /)

# Untar github sources:
rm -rf $SRCDIR
tar xvf $GITHUB_RELEASE

# HERE'S WHERE WE WOULD REMOVE STUFF FROM $SRCDIR, BUT WE AREN'T ACTUALLY
# USING THIS SCRIPT YET UNTIL WE SWITCH TO DOWNLOADING FROM GITHUB'S RELEASES

# Package it back up as a .tar.xz:
rm -f $SRCDIR.tar $SRCDIR.tar.xz
tar cf $SRCDIR.tar $SRCDIR
xz -9 $SRCDIR.tar
touch -d "$(tar tvf $GITHUB_RELEASE | head -n 1 | cut -f 2- -d 0 | cut -f 2,3 -d ' ')" $SRCDIR.tar.xz

# Cleanup:
rm -rf $SRCDIR

echo "Repacking of $SRCDIR.tar.xz complete."

