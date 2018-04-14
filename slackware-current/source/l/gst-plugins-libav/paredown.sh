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

# Remove the stale libav sources from the tarball, since we use the system
# ffmpeg libraries.  Also trim or dump a few other things.
#
# If you really need them for some reason, you can fetch the original tarball
# from https://gstreamer.freedesktop.org/src/gst-libav
#
# Removing these files reduces the size of the source tarball by 94%.

PKGNAM=gst-libav
VERSION=${VERSION:-$(echo $PKGNAM-*.tar.xz | rev | cut -f 3- -d . | cut -f 1 -d - | rev)}

if [ ! -r $PKGNAM-$VERSION.tar.xz ]; then
  echo "$PKGNAM-$VERSION.tar.xz is not a gst-libav tarball.  Exiting."
  exit 1
fi

touch -r $PKGNAM-$VERSION.tar.xz tmp-timestamp || exit 1

rm -rf $PKGNAM-$VERSION
tar xvf $PKGNAM-$VERSION.tar.xz || exit 1

rm -rf $PKGNAM-$VERSION/gst-libs/ext/libav
cat $PKGNAM-$VERSION/ChangeLog | head -n 1000 > $PKGNAM-$VERSION/ChangeLog.pared
touch -r $PKGNAM-$VERSION/ChangeLog $PKGNAM-$VERSION/ChangeLog.pared
mv $PKGNAM-$VERSION/ChangeLog.pared $PKGNAM-$VERSION/ChangeLog
rm -f $PKGNAM-$VERSION/docs/plugins/inspect/plugin-libav.xml
rm -f $PKGNAM-$VERSION/docs/plugins/gst-libav-plugins.args

rm -f $PKGNAM-$VERSION.tar.xz
tar cvf $PKGNAM-$VERSION.tar $PKGNAM-$VERSION
touch -r tmp-timestamp $PKGNAM-$VERSION.tar
xz -9 -v $PKGNAM-$VERSION.tar
rm -rf $PKGNAM-$VERSION tmp-timestamp

echo "Repacking of $PKGNAM-$VERSION.tar.xz complete."

