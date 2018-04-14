#!/bin/sh
if [ ! "$PKG_CONFIG_PATH" = "" ]; then
  PKG_CONFIG_PATH=${PKG_CONFIG_PATH}:/usr/local/lib/pkgconfig:/usr/local/share/pkgconfig
else
  PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:/usr/local/share/pkgconfig:/usr/lib/pkgconfig:/usr/share/pkgconfig
fi
export PKG_CONFIG_PATH
