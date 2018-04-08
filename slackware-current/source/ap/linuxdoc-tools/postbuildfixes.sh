#!/bin/bash

# Once slacktrack has determined what the contents of the package
# should be, it copies them into $SLACKTRACKFAKEROOT and creates
# an entry in /var/log/packages.
# Subsequently, within $SLACKTRACKFAKEROOT, it performs the requested
# packaging operations (gzipping man pages, setting permissions and ownerships,
# etc.) and then runs _this_ script.
#
# From here we can make modifications to the package's contents
# immediately prior to the invocation of makepkg: slacktrack will
# perform no other operations upon the contents of the package after
# the execution of _this_ script.
# It also means that when we rename the conf files to ".new", it does not
# affect the ability to ''removepkg linuxdoc-tools'' on the build box,
# as the entry in /var/log/packages still matches what was installed
# into /etc by the 'linuxdoc-tools.build' script.
#
# If you modify anything here, be careful *not* to include the full
# path name - only use relative paths (ie rm usr/bin/foo *not* rm /usr/bin/foo).

# Enter the package's contents:
cd $SLACKTRACKFAKEROOT || exit 1

# Remove .la files:
echo "Deleting .la files..."
find . -type f -name '*.la' -print | while read lafile ; do
  # Remove it from the build box itself to prevent other packages potentially referencing it.
  # This wouldn't be a problem if you removepkg linuxdoc-tools (the version created by slacktrack
  # that contains everything prior to _this_ post build script running) before building any other
  # packages; but in case you don't, let's remove it from the OS file system:
  rm "/${lafile}"
  # Remove it from the distributable package t?z file:
  rm -fv "${lafile}"
done

# OpenSP creates this symlink; we delete it.
if [ -L usr/share/doc ]; then
   rm -f usr/share/doc
fi

# Incase you had CUPS running:
rm -rf etc/cups etc/printcap
# crond & mail (just incase you got a delivery!)
rm -rf var/spool/{cron,mail}
rmdir var/spool

# perllocal.pod files don't belong in packages.
# SGMLSPL creates this:
find . -name perllocal.pod -print0 | xargs -0 rm -f

# Some doc dirs have attracted setuid.
# We don't need setuid for anything in this package:
chmod -R a-s .

# Remove dangling symlinks from /usr/doc.  asciidoc-8.6.7 was a culprit.
find usr/doc -xtype l -print0 | xargs -0 rm -fv

# Ensure some permissions.
# I don't know why but these dirs are installed chmod 1755:
#drwxr-xr-t root/root         0 2006-05-27 15:42:44 var/lib/texmf/
#drwxr-xr-t root/root         0 2006-05-27 15:42:44 var/lib/texmf/pk/
#drwxr-xr-t root/root         0 2006-05-27 15:42:44 var/lib/texmf/pk/ljfour/
#drwxr-xr-t root/root         0 2006-05-27 15:42:44 var/lib/texmf/pk/ljfour/jknappen/
#drwxr-xr-t root/root         0 2006-05-27 15:42:44 var/lib/texmf/pk/ljfour/jknappen/ec/
#drwxr-xr-t root/root         0 2006-05-27 15:42:44 var/lib/texmf/source/
#drwxr-xr-t root/root         0 2006-05-27 15:42:44 var/lib/texmf/source/jknappen/
#drwxr-xr-t root/root         0 2006-05-27 15:42:44 var/lib/texmf/source/jknappen/ec/
#drwxr-xr-t root/root         0 2006-05-27 15:42:44 var/lib/texmf/tfm/
#drwxr-xr-t root/root         0 2006-05-27 15:42:44 var/lib/texmf/tfm/jknappen/
#drwxr-xr-t root/root         0 2006-05-27 15:42:44 var/lib/texmf/tfm/jknappen/ec/
#find var/lib/texmf -type d -print0 | xargs -0 chmod 755
# This directory needs these permissions to permit pleb accounts to make
# fonts:
#chmod 1777 var/lib/texmf
#
# Never mind: I think this stuff is surplus to requirements:
rm -rf var/lib/texmf
# Now to prevent deletion of anything else that lives in the package's '/var'
rmdir var/lib
rmdir var

# There's no reason to include huge redundant documentation:
pushd usr/doc
find . -name "*.txt" | while read docfile ; do
  basedocname=$(echo $docfile | rev | cut -f 2- -d . | rev)
  rm -fv ${basedocname}.{html,pdf,xml}
  rm -fv docbook-xsl*/reference.pdf.gz
done
popd

# Allow preservation of conf files for ascii-doc.  Some of the other bundled
# packages may benefit from this treatment, but nobody's asked for anything
# other than asciidoc in over 10 years!
echo "Renaming configuration files to '.conf.new'.."
find etc/asciidoc -type f -name '*.conf' -print0 | xargs -0i mv -fv '{}' '{}.new'
# Search for any dangling symlinks created by renaming the files:
if [ ! -z "$( find -L etc/asciidoc -type l -print )" ]; then
   echo "WARNING: Dangling symlinks in etc/asciidoc -- you need to fix them!"
   find -L etc/asciidoc -type l -print
fi
# Populate the doinst.sh script
find etc/asciidoc -type f -name '*.conf.new' | while read cfile ; do
  echo "config $cfile" >> install/doinst.sh
done

# Now you should manually extract the .t?z
# - check through the install/doinst.sh script;
# - check the contents, permissions and ownerships in the package archive.
