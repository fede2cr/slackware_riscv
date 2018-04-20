#!/bin/sh
#  xinitrc.xfce - modified to work around xfce4session bug
#                 https://bugzilla.xfce.org/show_bug.cgi?id=8841


########################################################################
##  Merge in defaults and keymaps                                     ##
########################################################################

userresources=$HOME/.Xresources
usermodmap=$HOME/.Xmodmap
sysresources=/etc/X11/xinit/.Xresources
sysmodmap=/etc/X11/xinit/.Xmodmap

if [ -f $sysresources ]; then
    /usr/bin/xrdb -merge $sysresources
fi

if [ -f $sysmodmap ]; then
    /usr/bin/xmodmap $sysmodmap
fi

if [ -f $userresources ]; then
    /usr/bin/xrdb -merge $userresources
fi

if [ -f $usermodmap ]; then
    /usr/bin/xmodmap $usermodmap
fi

########################################################################
##  Start xfce Desktop Environment                                    ##
########################################################################

if [ -z "$DESKTOP_SESSION" -a -x /usr/bin/ck-launch-session ]; then
  exec ck-launch-session dbus-launch --exit-with-session /usr/bin/startxfce4
else
  exec dbus-launch --exit-with-session /usr/bin/startxfce4
fi

