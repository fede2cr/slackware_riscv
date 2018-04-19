#!/bin/sh

CHROOT=/mnt/chroot/
SLACK_DIST=/mnt/git/slackware_riscv/slackware-current/

rm -rf $CHROOT
find $SLACK_DIST/slackware/ -type f -name aaa\*txz -exec installpkg --root $CHROOT {} \;
find $SLACK_DIST/slackware/ -type f -name *txz -exec installpkg --root $CHROOT {} \;

echo "Packages in repo: $(find $SLACK_DIST/slackware/ -type f -name *txz|wc -l)"
echo "Chroot size: $(du -sh $CHROOT | awk '{print $1}' )"
