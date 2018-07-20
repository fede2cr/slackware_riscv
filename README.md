# RISCV port of the Slackware Distribution

This is my port of the Slackware Distribution for the RISCV ISA, following the slackware-current tree as close as posible.

# Hardware needed

**Important**: The project is looking for riscv64 hardware to test kernel packages and installer. For the moment we can only test on qemu-riscv envirmonment.

## Status

Packages in repo: 815
Chroot size: 4.4G

The bulk of the package building for all package series is done, with a small porcentage of packages which had compile error or are missing support completely, managed as issues on github. This is mostly a TODO to keep track of failed builds, but also to encourage anyone to contribute to the project.

## Install

There is no complete installer at the moment, but you can still get a workable Slackware environment in minutes with this dirty alternative:

```
git clone https://github.com/fede2cr/slackware_riscv.git
tar xJvf -C / slackware-current/slackware/a/pkgtools-*.txz
mkdir chroot
export CHROOT=$(pwd)/chroot
export SLACK_DIST=$(pwd)/
find $SLACK_DIST/slackware/ -type f -name aaa\*txz -exec installpkg --root $CHROOT {} \;
find $SLACK_DIST/slackware/ -type f -name *txz -exec installpkg --root $CHROOT {} \;
chroot chroot/
```

## Develpment

The base for this is the stage4 from Fedora, which you can learn how to install and use with ease in this [Jupyter Notebook](https://github.com/fede2cr/riscv_playground/blob/master/RISCV%20Qemu.ipynb) tutorial.

Feel free to submit any issues of parches/pull requests, excluding any binaries or complete packages (just changes in source/).

-- 
*Alvaro Figueroa*

[Greencore Solutions](https://www.greencore.co.cr)
