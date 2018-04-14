#!/bin/csh
if ( $?PKG_CONFIG_PATH ) then
    setenv PKG_CONFIG_PATH ${PKG_CONFIG_PATH}:/usr/local/lib/pkgconfig:/usr/local/share/pkgconfig
else
    setenv PKG_CONFIG_PATH /usr/local/lib/pkgconfig:/usr/local/share/pkgconfig:/usr/lib/pkgconfig:/usr/share/pkgconfig
endif
