#!/bin/sh
# This script was used to extract the kdepim parts from the last kde-l10n
# release that contained them.  The resulting kdepim-l10n sources will be
# merged into our language packages.

# This should be run in the directory containing the kde-l10n-*-4.4.5
# source tarballs that you wish to create kdepim-l10n archives from.

for file in kde-l10n*.tar.bz2 ; do
  rm -rf $(basename $file .tar.bz2) kdepim-l10n-$(echo $file | cut -f 3 -d -)-4.4.5
  echo "Extracting $file"
  tar xf $file
  mkdir kdepim-l10n-$(echo $file | cut -f 3 -d -)-4.4.5
  ( cd $(basename $file .tar.bz2)
    find . -name "kdepim" -type d -exec cp -a --parents "{}" ../kdepim-l10n-$(echo $file | cut -f 3 -d -)-4.4.5 \;
  )
  ( cd kdepim-l10n-$(echo $file | cut -f 3 -d -)-4.4.5
    tar cf ../kdepim-l10n-$(echo $file | cut -f 3 -d -)-4.4.5.tar .
  )
  rm -f kdepim-l10n-$(echo $file | cut -f 3 -d -)-4.4.5.tar.bz2
  bzip2 -9 kdepim-l10n-$(echo $file | cut -f 3 -d -)-4.4.5.tar
  rm -r $(basename $file .tar.bz2) kdepim-l10n-$(echo $file | cut -f 3 -d -)-4.4.5
done
