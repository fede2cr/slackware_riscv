#!/bin/sh
CWD=`pwd`

# Add the latest copy of the Subversion book:
( cd $CWD
  lftpget http://svnbook.red-bean.com/en/1.7/svn-book-html.tar.bz2
  chmod 644 svn-book-html.tar.bz2
)

