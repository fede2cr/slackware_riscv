#!/bin/sh

# Copyright 2016, 2017  Patrick J. Volkerding, Sebeka, Minnesota, USA
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

# Pull a stable branch + patches
BRANCH=${1:-master}

# Clear download area:
rm -rf urw-core35-fonts

# Clone repository:
git clone git://git.ghostscript.com/urw-core35-fonts.git

# checkout $BRANCH:
( cd urw-core35-fonts 
  git checkout $BRANCH || exit 1
)

# For now, we will only be packaging the OTF fonts:
( cd urw-core35-fonts
  rm -f *.{afm,t1,ttf}
)

HEADISAT="$( cd urw-core35-fonts && git log -1 --format=%h )"
DATE="$( cd urw-core35-fonts && git log -1 --format=%ad --date=format:%Y%m%d )"
# Cleanup.  We're not packing up the whole git repo.
( cd urw-core35-fonts && find . -type d -name ".git*" -exec rm -rf {} \; 2> /dev/null )
mv urw-core35-fonts urw-core35-fonts-otf-${DATE}_${HEADISAT}_git
tar cf urw-core35-fonts-otf-${DATE}_${HEADISAT}_git.tar urw-core35-fonts-otf-${DATE}_${HEADISAT}_git
xz -9 -f urw-core35-fonts-otf-${DATE}_${HEADISAT}_git.tar
rm -rf urw-core35-fonts-otf-${DATE}_${HEADISAT}_git
echo
echo "OTF fonts from urw-core35-fonts branch $BRANCH with HEAD at $HEADISAT packaged as urw-core35-fonts-otf-${DATE}_${HEADISAT}_git.tar.xz"
echo
