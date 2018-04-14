#!/bin/sh

# Copyright 2011  Patrick J. Volkerding, Sebeka, MN, USA
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


PKGNAM=dhcp
VERSION=${VERSION:-4.2.1-P1}
BUILD=${BUILD:-1}

# This is not yet used, but eventually we would like to be able to purge
# the bundled BIND and use the system's instead.  Maybe wishful thinking.

CWD=$(pwd)
TMP=${TMP:-/tmp}

cd $TMP
rm -rf dhcp-$VERSION
tar xvf $CWD/dhcp-$VERSION.tar.?z* || exit 1
cd dhcp-$VERSION || exit 1

# good "bob" why? ...
rm -rf bind/*

# Generate a new .xz compressed tarball in /tmp:
cd $TMP
rm -f dhcp-$VERSION.tar*
tar cf dhcp-$VERSION.tar dhcp-$VERSION
xz -9 dhcp-$VERSION.tar

echo "$TMP/dhcp-$VERSION.tar.xz created"

