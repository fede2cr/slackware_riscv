#!/bin/sh
# $Id: mkinitrd_command_generator.sh,v 1.45 2011/02/17 09:27:05 eha Exp eha $
# Copyright 2013  Patrick J. Volkerding, Sebeka, Minnesota, USA
# Copyright 2008, 2009, 2010, 2011  Eric Hameleers, Eindhoven, Netherlands
#                                   Contact: <alien@slackware.com>
# Copyright 2008, 2009  PiterPUNK, Sao Paulo, SP, Brazil
#                       Contact: <piterpunk@slackware.com>
# All rights reserved.
#
#   Permission to use, copy, modify, and distribute this software for
#   any purpose with or without fee is hereby granted, provided that
#   the above copyright notice and this permission notice appear in all
#   copies.
#
#   THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESSED OR IMPLIED
#   WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
#   MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
#   IN NO EVENT SHALL THE AUTHORS AND COPYRIGHT HOLDERS AND THEIR
#   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
#   LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
#   USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#   ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
#   OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
#   OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
#   SUCH DAMAGE.
# -----------------------------------------------------------------------------
#
# Create an initrd which fits the system.
# Take into account the use of LVM/LUKS/RAID.
# Find out about any hardware drivers the system may need in an initrd when
# booting from a generic lightweight kernel.
#
# -----------------------------------------------------------------------------

# The script's revision number will be displayed in the help text:
REV=$( echo "$Revision: 1.45 $" | cut -d' '  -f2 )

# Define some essential parameter values:
USING_LVM=""
USING_LUKS=""
USING_RAID=""
MLIST=""
REALDEV=""   # The device that contains the LUKS volume
BASEDEV=""   # Lowest level device (raw block device or RAID volume)

FSTAB=${FSTAB:-"/etc/fstab"} # so we can test with alternate fstab files

# These are needed by -c and -i options:
SOURCE_TREE=${SOURCE_TREE:-"/boot/initrd-tree"}
CLEAR_TREE=${CLEAR_TREE:-1}
KEYMAP=${KEYMAP:-"us"}
UDEV=${UDEV:-1}
# ARM devices need more time:
case "$( uname -m )" in
  arm*) WAIT_DEFAULT=4;;
  *) WAIT_DEFAULT=1;;
esac
WAIT=${WAIT:-$WAIT_DEFAULT}

# A basic explanation of the commandline parameters:
basic_usage() {
  cat <<-EOT
	
	*** $(basename $0) revision $REV ***
	Usage:
	  $(basename $0) [ options ] [ kernel_filename ]
	Options:
	  -a <"additional params">  Additional parameters to pass to mkinitrd.
	  -c | --conf               Show a suitable mkinitrd configuration file.
	  -h | --help               Show this help.
	  -i | --interactive        Navigate through menus instead of using
	                            commandline arguments.  
	  --longhelp                Show more detailed information/examples.
	  -k <kernelversion>        Use specific kernel version.
	  -m <"additional mods">    Additional modules to pass to mkinitrd,
	                            separated by colons (:).
	  -l | --lilo               Only show lilo.conf section
	                            (requires a kernel_filename).
	  -r | --run                Only show 'mkinitrd' command.
	EOT
}

# More of a tutorial here:
extended_usage() {
  cat <<-EOT
	
	This script is useful in situations where you require an initrd image
	to boot your computer.
	For instance, when booting a kernel that does not have support for your
	storage or root filesystem built in (such as the Slackware 'generic'
	kernels').
	
	* When you run the script without parameters, it will examine your
	running system, your current kernel version and will output an example
	of a 'mkinitrd' commandline that you can use to generate an initrd
	image containing enough driver support to boot the computer.
	
	* You can make it more specific: when you add the filename of a kernel
	as parameter to the script, it will determine the kernel version from
	that kernel, and also give an example of the lines that you should add
	to your '/etc/lilo.conf' file.
	
	* If you want your initrd image to have a custom name instead of the
	default '/boot/initrd.gz' you can add it as another parameter to the
	script, as follows:
	
	  $(basename $0) -a "-o /boot/custom.gz"
	
	The arguments to the '-a' parameter will be used as additional arguments
	to the 'mkinitrd' command.
	
	* If you need additional modules in the initrd image, apart from what
	the script determines, you can pass then to the script using the '-m'
	parameter as follows:
	
	  $(basename $0) -m "uhci-hcd:usbhid:hid_generic"
	
	The above example adds support for USB keyboards to the initrd - you
	may need that if you have encrypted your root partition and need to
	enter a passphrase using a USB keyboard.
	
	* Instead of copying and pasting the script's output, you can create
	an initrd by directly executing the output, like in this example:
	
	EOT

  echo "  \$($(basename $0) --run /boot/vmlinuz-generic-smp-2.6.35.11-smp)"

  cat <<-EOT
	
	That used the '-r' or '--run' switch to make the script only write
	the 'mkinitrd' commandline to the terminal.
	
	* When you want to add a section for a specific kernel to
	'/etc/lilo.conf' directly, use the '-l' or '--lilo' switch and use a
	command like in this example:
	
	EOT

  echo "  $(basename $0) --lilo /boot/vmlinuz-generic-smp-2.6.35.11-smp >>/etc/lilo.conf"

  cat <<-EOT
	
	That command will result in the following lines being added to your
	'/etc/lilo.conf' file (example for my hardware):
	
	  # Linux bootable partition config begins
	  # initrd created with 'mkinitrd -c -k 2.6.35.11-smp -m ata_generic:pata_amd:mbcache:jbd:ext3 -f ext3 -r /dev/hda7'
	  image = /boot/vmlinuz-generic-smp-2.6.35.11-smp
	    initrd = /boot/initrd.gz
	    root = /dev/hda7
	    label = 2.6.35.11-smp
	    read-only
	  # Linux bootable partition config ends
	
	The last two examples show how easy it is to configure your computer
	for the use of an initrd if you need one. The only thing left to do
	afterwards is running 'lilo'.
	
	EOT
}

# Find the device that holds the root partition:
get_root_device() {
  if [ -e $FSTAB ]; then
    RD=$(cat $FSTAB |tr '\t' ' ' |grep -v '^ *#' |tr -s ' ' |grep ' / ' |cut -f1 -d' ')
    if [ "$(echo $RD | cut -f1 -d=)" = "LABEL" -o "$(echo $RD | cut -f1 -d=)" = "UUID" ]; then
      DKEY=$(echo $RD | cut -f1 -d=)
      # The value can be LABEL=foo or LABEL='foo' or LABEL="foo"
      DVAL=$(echo $RD | cut -f2 -d= | tr -d "'\042")
      RD=$(/sbin/blkid | grep -w $DKEY | grep -w $DVAL | cut -f1 -d:)
    fi
  else
    RD=$(grep -m1 "^/dev/.*[[:blank:]]/[[:blank:]]" /proc/mounts | cut -f1 -d' ')
  fi
  echo $RD
}

# Get the root fs information:
get_rootfs_type() {
  if $(type blkid 1>/dev/null 2>&1) ; then
   blkid -s TYPE -o value $ROOTDEV
  elif $(type vol_id 1>/dev/null 2>&1) ; then
   vol_id $ROOTDEV | grep ID_FS_TYPE | cut -f2 -d=
  else
   # As a fallback, use:
   cat $FSTAB |tr '\t' ' ' |grep -v '^ *#' |tr -s ' ' |grep ' / ' |cut -f3 -d' '
  fi
}

# Add the module(s) needed for the root filesystem:
add_rootfs_module() {
  local FSMOD
  FSMOD=$(/sbin/modprobe --set-version $KVER --show-depends ${ROOTFS} 2>/dev/null | while read LINE; do
    echo $(basename $(echo $LINE | cut -d' ' -f2) .ko )
  done)
  if [ -n "$FSMOD" ]; then
     [ -n "$MLIST" ] && echo "$MLIST:$(echo $FSMOD | tr ' ' ':')" \
                    || echo $FSMOD | tr ' ' ':'
  fi
}

# Determine the list of kernel modules needed to support the root device:
determine_blockdev_drivers() {
  # Walk the /sys tree to find kernel modules that are
  # required for our storage devices.
  # Thanks to PiterPUNK for help with this code.
  local MLIST
  MLIST=$(for i in $(find /sys/block/*/ -name "device" -print0 | xargs -0 -i'{}' readlink -f '{}' | sort -u); do
    /sbin/udevadm info --query=all --path=$i --attribute-walk | \
      sed -ne 's/^[[:blank:]]\+DRIVER[S]*=="\([^"]\+\)"$/\1/p' | \
      xargs -I@ /sbin/modprobe --set-version $KVER --show-depends @ \
      2>/dev/null | grep -v "builtin " | \
      while read LINE ; do 
        echo $(basename $(echo $LINE | cut -d' ' -f2) .ko )
      done
  done)
  MLIST=$( echo $MLIST | tr ' ' ':' )
  echo $MLIST
}

# Search for USB keyboards:
function add_usb_keyboard() {
  local USBMOD
  if cat /proc/bus/input/devices | sed -e 's/^$/\$/g' | \
     tr "\n$" " \n" | grep -q " Phys=.*usb.* .*Handlers=.*kbd.*B:"; then
     USBMOD="xhci-pci:ohci-pci:ehci-pci:xhci-hcd:uhci-hcd:ehci-hcd:hid:usbhid:i2c-hid:hid_generic:hid-cherry:hid-logitech:hid-logitech-dj:hid-logitech-hidpp:hid-lenovo:hid-microsoft:hid_multitouch"
     [ -n "$MLIST" ] && MLIST="$MLIST:$USBMOD" \
                     || MLIST="$USBMOD"
  fi
  echo $MLIST
}

# Determine what USB Host Controller is in use
function add_usb_hcd() {
  local USBMOD
  for i in $(ls -Ld /sys/module/*_hcd/drivers/* 2> /dev/null); do 
    if ls -L $i | grep -q "[0-9a-f]*:" ; then
      USBMOD=$( echo $i | cut -f4 -d/ | tr "_" "-")
      [ -n "$MLIST" ] && MLIST="$MLIST:$USBMOD" \
                      || MLIST="$USBMOD"
    fi
  done
  echo $MLIST
}

# Is the root partition on a (combination of) LVM/LUKS volume?
check_luks_lvm_raid() {
  if $( lvdisplay -c $ROOTDEV 1>/dev/null 2>/dev/null ); then
    # Our root partition is on a LV:
    USING_LVM=1
    # Search the Physical Volume of our Logical Volume:
    MYVG=$( echo $(lvdisplay -c $ROOTDEV 2>/dev/null) | cut -d: -f2 )
    for LINE in $(pvdisplay -c) ; do
      VG=$(echo $LINE | cut -d: -f2)
      [ "$VG" = "$MYVG" ] && break
    done 
    PV=$(echo $LINE | cut -d: -f1)
    # Check if there is a LUKS device underneath:
    if $( cryptsetup status $PV 1>/dev/null 2>/dev/null ) ; then
      # Our root partition's LV  is on a LUKS volume:
      USING_LUKS=1
      REALDEV=$( cryptsetup status $PV | grep 'device: ' | tr -d ' ' | cut -d: -f2 )
      BASEDEV=$REALDEV
    else
      BASEDEV=$PV
    fi
  elif $( cryptsetup status $ROOTDEV 1>/dev/null 2>/dev/null ) ; then
    # Our root device is on a LUKS volume:
    USING_LUKS=1
    REALDEV=$( cryptsetup status $ROOTDEV | grep 'device: ' | tr -d ' ' | cut -d: -f2 )
    ROOTDEV=$(basename $ROOTDEV)
    # Check for LVM:
    for LV in $(lvdisplay -c 2>/dev/null | tr -d ' ' | cut -f1 -d:) ; do
      # Note: cryptsetup shows the real device, whereas 
      # lvdisplay requires the /dev/<myvg>/... symlink to the real device.
      if [ "$(readlink $LV)" = "$REALDEV" ]; then
        REALDEV=$LV
        break
      fi
    done
    if $( lvdisplay -c $REALDEV 1>/dev/null 2>/dev/null ); then
      # Our root partition's LUKS device is on a LV:
      USING_LVM=1
      # Search the Physical Volume of our Logical Volume:
      MYVG=$( echo $(lvdisplay -c $REALDEV 2>/dev/null) | cut -d: -f2 )
      for LINE in $(pvdisplay -c) ; do
        VG=$(echo $LINE | cut -d: -f2)
        [ "$VG" = "$MYVG" ] && break
      done 
      PV=$(echo $LINE | cut -d: -f1)
      BASEDEV=$PV
    else
      BASEDEV=$REALDEV
    fi
  else
    BASEDEV=$ROOTDEV
  fi

  # Finally, we should check if base device is
  #   a real block device or a RAID volume:
  for MD in  $(cat /proc/mdstat | grep -w active | cut -d' ' -f1) ; do
    if [ "$BASEDEV" = "/dev/$MD" ]; then
      USING_RAID=1
      break
    fi
  done
}

# Before we start
[ -x /bin/id ] && CMD_ID="/bin/id" || CMD_ID="/usr/bin/id"
if [ "$($CMD_ID -u)" != "0" ]; then
  echo "You need to be root to run $(basename $0)."
  exit 1
fi

# Parse the commandline parameters:
while [ ! -z "$1" ]; do
  case $1 in
    --longhelp)
      basic_usage
      extended_usage
      exit 0
      ;;
    -a)
      MKINIT_PARAMS="$2"
      shift 2
      ;;
    -c|--conf)
      [ -n "$EMIT" ] && { echo "Do not mix incompatible parameters!"; exit 1; }
      EMIT="conf"
      shift
      ;;
    -h|--help)
      basic_usage
      exit 0
      ;;
    -i|--interactive)
      INTERACTIVE=1
      shift
      ;;
    -k)
      KVER=$2
      shift 2
      ;;
    -m)
      MKINIT_MODS=$2
      shift 2
      ;;
    -l|--lilo)
      [ -n "$EMIT" ] && { echo "Do not mix incompatible parameters!"; exit 1; }
      EMIT="lilo"
      shift
      ;;
    -L|--fromlilo)
      FROMLILO=1
      shift
      ;;
    -r|--run)
      [ -n "$EMIT" ] && { echo "Do not mix incompatible parameters!"; exit 1; }
      EMIT="run"
      shift
      ;;
    -R|--rootdev)
      ROOTDEV=$2
      shift 2
      ;;
    -*)
      echo "Unsupported parameter '$1'!"
      exit 1
      ;;
    *) # Everything else but switches (which start with '-') follows:
      if [ -f $1 ]; then
        KFILE=$1
        # Construction of KFILE's full filename:
        KFILEPATH=$(cd $(dirname $KFILE) && pwd)
        if [ -L $KFILE ]; then
          KFILE=$(readlink $KFILE)
        else
          KFILE=$(basename $KFILE)
        fi
        KFILE=${KFILEPATH}/$KFILE
        if [ -z "$(file $KFILE | grep -E 'Linux kernel x86 boot|x86 boot sector')" ]; then
          echo "File '$KFILE' does not look like it is a kernel file!"
          exit 1
        fi
      else
        echo "File $1 not found!"
        exit 1
      fi   
      shift
      ;;
  esac
done

# Determine what to show as output (other options may have set EMIT already)
EMIT=${EMIT:-"all"}

# An EMIT value of 'lilo' requires a kernel filename as script parameter:
if [ "$EMIT" = "lilo" ]; then
  if [ -z "$KFILE" ]; then
    echo "A kernel_filename is required with the '-l|--lilo' option!"
    exit 1
  fi
fi

# Determine kernel version to use,
# and check if modules for this kernel are actually present:
if [ -z "$KVER" ]; then
  if [ -n "$KFILE" ]; then
    KVER="$(strings $KFILE | grep '([^ ]*@[^ ]*) #' | cut -f1 -d' ')"
  else
    KVER="$(uname -r)"
  fi
fi
if [ ! -d /lib/modules/$KVER ]; then
  echo "Modules for kernel $KVER aren't installed."
  exit 1
fi  

# Determine whether the user passed an alternate filename for the initrd:
if [ -n "$MKINIT_PARAMS" ]; then
  SRCHLIST="$MKINIT_PARAMS"
  for ELEM in $MKINIT_PARAMS ; do
    SRCHLIST=$(echo $SRCHLIST | cut -d' ' -f2-) # cut ELEM from the list
    if [ "$ELEM" = "-o" ]; then
      IMGFILE=$(echo $SRCHLIST | cut -d' ' -f1)
      break
    fi
  done
fi
IMGFILE=${IMGFILE:-"/boot/initrd.gz"}

# Get information about the root device / root filesystem:
ROOTDEV=${ROOTDEV:-$(get_root_device)}
ROOTFS=$(get_rootfs_type)

# Determine the list of kernel modules needed to support the root device:
MLIST=$(determine_blockdev_drivers)

# Check if we are running in a kvm guest with virtio block device driver
# (add all virtio modules, we sort out the doubles later):
if echo $MLIST | grep -q "virtio"; then
  MLIST="$MLIST:virtio:virtio_balloon:virtio_blk:virtio_ring:virtio_pci:virtio_net"
fi

# Determine if a USB keyboard is in use and include usbhid and hid_generic
# to module list
MLIST=$(add_usb_keyboard)

# If we use any USB module, try to determine the Host Controller
if echo $MLIST | grep -q "usb"; then
  MLIST=$(add_usb_hcd)
fi

# Check what combination of LUKS/LVM/RAID we have to support:
# This sets values for USING_LUKS, USING_LVM, USING_RAID, REALDEV and BASEDEV.
check_luks_lvm_raid

# This is the interactive part:
if [ "$INTERACTIVE" = "1" ];  then
  if [ "$FROMLILO" != "1" ]; then
    dialog --stdout --title "WELCOME TO MKINITRD COMMAND GENERATOR" --msgbox "\
The main goal of this utility is to create a good initrd to \
fit your needs.  It can detect what kernel you are running, \
what is your root device, root filesystem, if you use encryption, \
LVM, RAID, etc. \
\n\n\
Usually the probed values are OK and they will be the \
defaults in all subsequent dialogs, but maybe you want \
to change something. \n\
If in doubt, leave the defaults." 0 0 

    KVER=$( ls -d1 --indicator-style=none /lib/modules/* | \
      awk -F/ -vVER=$KVER '{ 
                            if ( VER == $NF ) { 
                              ONOFF="on" 
                            } else { 
                              ONOFF="off" 
                            } ; printf("%s \"\" %s\n",$NF,ONOFF) }' | \
      xargs dialog --stdout --title "CHOOSE KERNEL VERSION" \
                   --default-item $KVER --radiolist "\
Please, select the kernel version you want to create this initrd for." 0 0 4 )
    [ -z "$KVER" ] && exit 1

    OLDROOTDEV=$ROOTDEV
    ROOTDEV=$( dialog --stdout --title "SELECT ROOT DEVICE" --inputbox "\
Enter your root device. Root device is the one where your '/' filesystem \
is mounted." 0 0 "$ROOTDEV" )
    [ -z "$ROOTDEV" ] && exit 1

    # We need to re-check our defaults in case the user changed the default
    # value for ROOTDEV:
    [ "$OLDROOTDEV" != "$ROOTDEV" ] && check_luks_lvm_raid
    ROOTFS=$(get_rootfs_type)

    ROOTFS=$( dialog --stdout --title "SELECT ROOT FILESYSTEM" --inputbox "\
Enter the type of your root filesystem." 0 0 "$ROOTFS" )
    [ -z "$ROOTFS" ] && exit 1
  fi

  MLIST=$(add_rootfs_module)

  LLR=$( dialog --stdout --title "LVM/LUKS/RAID" --checklist "\
Do you use some of those in your root filesystem?  \
If this is the case, please select one or more options." 12 45 3 \
"LVM" "Logical Volume Manager" $([ "$USING_LVM" = "1" ] && echo on || echo off) \
"LUKS" "Linux Unified Key Setup" $([ "$USING_LUKS" = "1" ] && echo on || echo off) \
"RAID" "Linux Software RAID" $([ "$USING_RAID" = "1" ] && echo on || echo off)) 

  if [ "$?" != "0" ]; then
    exit 1
  fi

  echo $LLR | grep -q LUKS && USING_LUKS="1"
  echo $LLR | grep -q LVM && USING_LVM="1"
  echo $LLR | grep -q RAID && USING_RAID="1"

  if [ "$USING_LUKS" = "1" ]; then
    REALDEV=$( dialog --stdout --title "LUKS ROOT DEVICE" --inputbox "\
Please, enter your LUKS root device:" 0 0 "$REALDEV" )
    [ -z "$REALDEV" ] && exit 1
  fi
fi

# Step out of the interactive loop for a moment. The next block needs to be
# executed in all cases.

# We need to 'undouble' the MLIST array. Some people report that walking the
# /sys tree produces duplicate modules in the list.
# The awk command elimitates doubles without changing the order:
MLIST=$( echo $MLIST | tr ':' '\n' | awk '!x[$0]++' | tr '\n' ' ' )
MLIST=$( echo $MLIST | tr ' ' ':' )
MLIST=$(echo ${MLIST%:}) # To weed out a trailing ':' which was reported once.

# Back to the interactive part:

if [ "$INTERACTIVE" = "1" ];  then
  MLIST=$( dialog --stdout --title "INITRD'S MODULE LIST" --inputbox "\
The list here shows all modules needed to support your root filesystem \
and boot from it.  But you can change the list to use some alternative \
or additional modules.  If you don't know what to do, the default is safe." \
0 0 "$MLIST" )
  if [ "$?" != "0" ]; then
    exit 1
  fi

  EXTRA=$( dialog --stdout --title "EXTRA CONFIGURATION" --checklist "\
Now is your chance for some additional configuration.  All of these \
configurations are optional and you can stick to the defaults." 11 72 3 \
"KEYMAP" "Select keyboard layout (default: US)" \
			   $([ $USING_LUKS = 1 ] && echo on || echo off) \
"RESUMEDEV" "Select device for 'suspend-to-disk' feature" off \
"UDEV" "Use UDEV in the initrd for device configuration" $(test $UDEV -eq 1 && echo on || echo off) \
"WAIT" "Add delay to allow detection of slow disks at boot" $(test $WAIT -gt $WAIT_DEFAULT && echo on || echo off) )
  if [ "$?" != "0" ]; then
    exit 1
  fi

  if echo $EXTRA | grep -q KEYMAP ; then
    KEYMAP=$( dialog --stdout --title "KEYBOARD LAYOUT SELECTION" \
      --cancel-label "Skip" \
      --menu "You may select one of the following keyboard layouts. \
If you do not select a keyboard map, 'us.map' \
(the US keyboard layout) is the default.  Use the UP/DOWN \
arrow keys and PageUp/PageDown to scroll \
through the whole list of choices." \
22 55 11 \
"qwerty/us.map" "" \
"azerty/azerty.map" "" \
"azerty/be-latin1.map" "" \
"azerty/fr-latin0.map" "" \
"azerty/fr-latin1.map" "" \
"azerty/fr-latin9.map" "" \
"azerty/fr-old.map" "" \
"azerty/fr-pc.map" "" \
"azerty/fr.map" "" \
"azerty/wangbe.map" "" \
"azerty/wangbe2.map" "" \
"dvorak/ANSI-dvorak.map" "" \
"dvorak/dvorak-l.map" "" \
"dvorak/dvorak-r.map" "" \
"dvorak/dvorak.map" "" \
"dvorak/no-dvorak.map" "" \
"fgGIod/tr_f-latin5.map" "" \
"fgGIod/trf-fgGIod.map" "" \
"olpc/es-olpc.map" "" \
"olpc/pt-olpc.map" "" \
"qwerty/bg-cp1251.map" "" \
"qwerty/bg-cp855.map" "" \
"qwerty/bg_bds-cp1251.map" "" \
"qwerty/bg_bds-utf8.map" "" \
"qwerty/bg_pho-cp1251.map" "" \
"qwerty/bg_pho-utf8.map" "" \
"qwerty/br-abnt.map" "" \
"qwerty/br-abnt2.map" "" \
"qwerty/br-latin1-abnt2.map" "" \
"qwerty/br-latin1-us.map" "" \
"qwerty/by-cp1251.map" "" \
"qwerty/by.map" "" \
"qwerty/bywin-cp1251.map" "" \
"qwerty/cf.map" "" \
"qwerty/cz-cp1250.map" "" \
"qwerty/cz-lat2-prog.map" "" \
"qwerty/cz-lat2.map" "" \
"qwerty/cz-qwerty.map" "" \
"qwerty/defkeymap.map" "" \
"qwerty/defkeymap_V1.0.map" "" \
"qwerty/dk-latin1.map" "" \
"qwerty/dk.map" "" \
"qwerty/emacs.map" "" \
"qwerty/emacs2.map" "" \
"qwerty/es-cp850.map" "" \
"qwerty/es.map" "" \
"qwerty/et-nodeadkeys.map" "" \
"qwerty/et.map" "" \
"qwerty/fi-latin1.map" "" \
"qwerty/fi-latin9.map" "" \
"qwerty/fi-old.map" "" \
"qwerty/fi.map" "" \
"qwerty/gr-pc.map" "" \
"qwerty/gr.map" "" \
"qwerty/hu101.map" "" \
"qwerty/il-heb.map" "" \
"qwerty/il-phonetic.map" "" \
"qwerty/il.map" "" \
"qwerty/is-latin1-us.map" "" \
"qwerty/is-latin1.map" "" \
"qwerty/it-ibm.map" "" \
"qwerty/it.map" "" \
"qwerty/it2.map" "" \
"qwerty/jp106.map" "" \
"qwerty/kazakh.map" "" \
"qwerty/kyrgyz.map" "" \
"qwerty/la-latin1.map" "" \
"qwerty/lt.baltic.map" "" \
"qwerty/lt.l4.map" "" \
"qwerty/lt.map" "" \
"qwerty/mk-cp1251.map" "" \
"qwerty/mk-utf.map" "" \
"qwerty/mk.map" "" \
"qwerty/mk0.map" "" \
"qwerty/nl.map" "" \
"qwerty/nl2.map" "" \
"qwerty/no-latin1.map" "" \
"qwerty/no.map" "" \
"qwerty/pc110.map" "" \
"qwerty/pl.map" "" \
"qwerty/pl1.map" "" \
"qwerty/pl2.map" "" \
"qwerty/pl3.map" "" \
"qwerty/pl4.map" "" \
"qwerty/pt-latin1.map" "" \
"qwerty/pt-latin9.map" "" \
"qwerty/pt.map" "" \
"qwerty/ro.map" "" \
"qwerty/ro_std.map" "" \
"qwerty/ru-cp1251.map" "" \
"qwerty/ru-ms.map" "" \
"qwerty/ru-yawerty.map" "" \
"qwerty/ru.map" "" \
"qwerty/ru1.map" "" \
"qwerty/ru2.map" "" \
"qwerty/ru3.map" "" \
"qwerty/ru4.map" "" \
"qwerty/ru_win.map" "" \
"qwerty/ruwin_alt-CP1251.map" "" \
"qwerty/ruwin_alt-KOI8-R.map" "" \
"qwerty/ruwin_alt-UTF-8.map" "" \
"qwerty/ruwin_cplk-CP1251.map" "" \
"qwerty/ruwin_cplk-KOI8-R.map" "" \
"qwerty/ruwin_cplk-UTF-8.map" "" \
"qwerty/ruwin_ct_sh-CP1251.map" "" \
"qwerty/ruwin_ct_sh-KOI8-R.map" "" \
"qwerty/ruwin_ct_sh-UTF-8.map" "" \
"qwerty/ruwin_ctrl-CP1251.map" "" \
"qwerty/ruwin_ctrl-KOI8-R.map" "" \
"qwerty/ruwin_ctrl-UTF-8.map" "" \
"qwerty/se-fi-ir209.map" "" \
"qwerty/se-fi-lat6.map" "" \
"qwerty/se-ir209.map" "" \
"qwerty/se-lat6.map" "" \
"qwerty/se-latin1.map" "" \
"qwerty/sk-prog-qwerty.map" "" \
"qwerty/sk-qwerty.map" "" \
"qwerty/speakup-jfw.map" "" \
"qwerty/speakupmap.map" "" \
"qwerty/sr-cy.map" "" \
"qwerty/sv-latin1.map" "" \
"qwerty/tr_q-latin5.map" "" \
"qwerty/tralt.map" "" \
"qwerty/trf.map" "" \
"qwerty/trq.map" "" \
"qwerty/ttwin_alt-UTF-8.map.gz" "" \
"qwerty/ttwin_cplk-UTF-8.map.gz" "" \
"qwerty/ttwin_ct_sh-UTF-8.map.gz" "" \
"qwerty/ttwin_ctrl-UTF-8.map.gz" "" \
"qwerty/ua-cp1251.map.gz" "" \
"qwerty/ua-utf-ws.map" "" \
"qwerty/ua-utf.map" "" \
"qwerty/ua-ws.map" "" \
"qwerty/ua.map" "" \
"qwerty/uk.map" "" \
"qwerty/us-acentos.map" "" \
"qwerty/us.map" "" \
"qwertz/croat.map" "" \
"qwertz/cz-us-qwertz.map" "" \
"qwertz/cz.map" "" \
"qwertz/de-latin1-nodeadkeys.map" "" \
"qwertz/de-latin1.map" "" \
"qwertz/de.map" "" \
"qwertz/de_CH-latin1.map" "" \
"qwertz/fr_CH-latin1.map" "" \
"qwertz/fr_CH.map" "" \
"qwertz/hu.map" "" \
"qwertz/sg-latin1-lk450.map" "" \
"qwertz/sg-latin1.map" "" \
"qwertz/sg.map" "" \
"qwertz/sk-prog-qwertz.map" "" \
"qwertz/sk-qwertz.map" "" \
"qwertz/slovene.map" "" )
    [ -n "$KEYMAP" ] && KEYMAP=$(basename $KEYMAP .map)
  fi

  if echo $EXTRA | grep -q UDEV ; then
    UDEV=1
  fi

  if echo $EXTRA | grep -q RESUMEDEV ; then
    # Print information about swap partitions:
    FREERAM=$(free -k | grep "^Mem:" | tr -s ' ' | cut -d' ' -f2)
    SWPINFO=""
    for SWPDEV in $(grep -w swap $FSTAB | cut -d' ' -f1) ; do
      SWPINFO="$SWPINFO  $SWPDEV    Linux swap partition    $(fdisk -s $SWPDEV) KB \\n"
      [ $(fdisk -s $SWPDEV) -gt $FREERAM ] && RESUMEDEV=$SWPDEV
    done
    FREERAM=$(free -m | grep "^Mem:" | tr -s ' ' | cut -d' ' -f2)
    RESUMEDEV=$( dialog --stdout --no-collapse --title "HIBERNATE RESUME DEVICE" --inputbox "\
When using suspend-to-disk feature (hibernate), your computer's RAM is copied \
to a swap device when it shuts down.  The kernel will resume from that RAM \
image at boot.  This means that the swap partition must not be smaller than \
the amount of RAM you have ($FREERAM MB). \n\
$SWPINFO \n\
Please specify a swap partition to be used for hibernation:" \
0 0 "$RESUMEDEV")
    [ -z "$RESUMEDEV" ] && exit 1
  fi

  if echo $EXTRA | grep -q WAIT ; then
    WAIT=$( dialog --stdout --title "WAIT FOR ROOT DEVICE" --inputbox "\
Some block devices are too slow to be detected properly at boot. USB storage \
devices and some disk arrays have this 'feature'. To make your machine \
boot properly, you can add some delay here, to wait until all your disks are \
probed and detected. The time is in seconds:" 0 0 "$WAIT")
    [ -z "$WAIT" ] && exit 1
  fi
  
  IMGFILE=$( dialog --stdout --title "INITRD IMAGE NAME" --inputbox "\
Enter your initrd image filename." 0 0 "$IMGFILE" )
  [ -z "$IMGFILE" ] && exit 1

else    
  MLIST=$(add_rootfs_module)
fi

# Add any modules passed along on the commandline:
if [ -n "$MKINIT_MODS" ]; then
  [ -n "$MLIST" ] && MLIST="$MLIST:$(echo $MKINIT_MODS | tr ' ' ':')" \
                  || MLIST="$(echo $MKINIT_MODS | tr ' ' ':')"
fi

# Constructing the mkinitrd command:
MKINIT="mkinitrd -c -k $KVER -f $ROOTFS -r $ROOTDEV"

# If we have a module list, add them:
if ! [ -z "$MLIST" -o "$MLIST" = ":" ]; then
  MKINIT="$MKINIT -m $MLIST"
fi

# Deal with LUKS/LVM/RAID:
if [ "$USING_LUKS" = "1" ]; then
  MKINIT="$MKINIT -C $REALDEV"
fi
if [ "$USING_LVM" = "1" ]; then
  MKINIT="$MKINIT -L"
fi
if [ "$USING_RAID" = "1" ]; then
  MKINIT="$MKINIT -R"
fi

if [ -n "$RESUMEDEV" ]; then
  # Add hibernation partition:
  MKINIT="$MKINIT -h $RESUMEDEV"
fi
if [ -n "$KEYMAP" -a "$KEYMAP" != "us" ]; then
  # Add non-us keyboard mapping:
  MKINIT="$MKINIT -l $KEYMAP"
fi
if [ $UDEV -eq 1 ]; then
  # Add UDEV support:
  MKINIT="$MKINIT -u"
fi
if [ -n "$WAIT" -a $WAIT -ne $WAIT_DEFAULT ]; then
  # Add non-default wait time:
  MKINIT="$MKINIT -w $WAIT"
fi
if ! echo "$MKINIT_PARAMS" | grep -q -- '-o ' ; then
  # Add default output filename:
  MKINIT="$MKINIT -o $IMGFILE"
fi
if [ -n "$MKINIT_PARAMS" ]; then
  # Add user-supplied additional parameters:
  MKINIT="$MKINIT $MKINIT_PARAMS"
fi

# Notify the user:
if [ "$EMIT" = "all" ]; then
  cat <<-EOT
	#
	# $(basename $0) revision $REV
	#
	# This script will now make a recommendation about the command to use
	# in case you require an initrd image to boot a kernel that does not
	# have support for your storage or root filesystem built in
	# (such as the Slackware 'generic' kernels').
	# A suitable 'mkinitrd' command will be:
	
	$MKINIT
	EOT
elif [ "$EMIT" = "run" ]; then
  echo "$MKINIT"
elif [ "$EMIT" = "conf" ]; then
  cat <<-EOT
	SOURCE_TREE="$SOURCE_TREE"
	CLEAR_TREE="$CLEAR_TREE"
	OUTPUT_IMAGE="$IMGFILE"
	KERNEL_VERSION="$KVER"
	KEYMAP="$KEYMAP"
	MODULE_LIST="$(echo $MLIST | cut -f2 -d\ )"
	LUKSDEV="$REALDEV"
	ROOTDEV="$ROOTDEV"
	ROOTFS="$ROOTFS"
	RESUMEDEV="$RESUMEDEV"
	RAID="$USING_RAID"
	LVM="$USING_LVM"
	UDEV="$UDEV"
	WAIT="$WAIT"
	EOT
fi

if [ -n "$KFILE" ]; then
  if [ "$EMIT" = "all" ]; then
    cat <<-EOT
	# An entry in 'etc/lilo.conf' for kernel '$KFILE' would look like this:
	EOT
  fi
  if  [ "$EMIT" = "all" -o "$EMIT" = "lilo" ]; then
  # Compensate for the syntax used for the LUKS-on-LVM case:
  [ "$(basename $ROOTDEV)" = "$ROOTDEV" ] && BASE="/dev/mapper/" || BASE=""
    cat <<-EOT
	# Linux bootable partition config begins
	# initrd created with '$MKINIT'
	image = $KFILE
	  initrd = $IMGFILE
	  root = $BASE$ROOTDEV
	  label = $KVER
	  read-only
	# Linux bootable partition config ends
	EOT
  fi
fi
