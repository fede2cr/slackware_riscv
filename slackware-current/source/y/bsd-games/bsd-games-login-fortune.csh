#!/bin/csh
# Print a fortune cookie for login shells:

if ( { tty --silent } ) then >& /dev/null
  echo "" ; fortune fortunes fortunes2 linuxcookie ; echo ""
endif
