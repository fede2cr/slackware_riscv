#!/bin/sh
# Repacks the xscreensaver tarball to remove the unneeded OSX sources.

VERSION=${VERSION:-$(echo xscreensaver-*.tar.?z | rev | cut -f 3- -d . | cut -f 1 -d - | rev)}

tar xf xscreensaver-${VERSION}.tar.?z || exit 1
mv xscreensaver-${VERSION}.tar.?z xscreensaver-${VERSION}.tarball.orig
rm -r xscreensaver-${VERSION}/OSX/*
rm -r xscreensaver-${VERSION}/android/*
tar cf xscreensaver-${VERSION}.tar xscreensaver-${VERSION}
rm -r xscreensaver-${VERSION}
plzip -9 xscreensaver-${VERSION}.tar
touch -r xscreensaver-${VERSION}.tarball.orig xscreensaver-${VERSION}.tar.lz
rm xscreensaver-${VERSION}.tarball.orig
