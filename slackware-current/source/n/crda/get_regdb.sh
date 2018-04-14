#!/bin/sh

_DATE="$(date +%Y%m%d)"

rm -rf wireless-regdb-git_${_DATE} wireless-regdb-git_${_DATE}.tar.bz2

git clone \
  git://git.kernel.org/pub/scm/linux/kernel/git/sforshee/wireless-regdb.git \
  wireless-regdb-git_${_DATE}

chown -R root:root wireless-regdb-git_${_DATE}
rm -rf wireless-regdb-git_${_DATE}/.git*
tar cjf wireless-regdb-git_${_DATE}.tar.bz2 wireless-regdb-git_${_DATE}
rm -rf wireless-regdb-git_${_DATE}

