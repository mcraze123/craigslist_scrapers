#!/bin/bash
#
# Executes the script given as argument #2,
# then if there is anything printed to stdout,
# it will email the text as the body of the email
# 
# &copy; Michael Craze -- http://projectcraze.us.to

if [ "$#" -ne 2 ] ; then
	echo "Usage: $0 <subject> <craigslist_perl_script>"
	exit
fi

EMAIL="mcraze123@gmail.com"
SUBJECT=$1
CLSCRIPT=$2
PERL=`which perl`
MAIL=`which mail`
BODY=`$PERL $CLSCRIPT`

# send email if something was posted today
#$PERL $CLSCRIPT | $MAIL -s $SUBJECT $EMAIL
if [ -n "$BODY" ] ; then
	echo $BODY | $MAIL -s $SUBJECT $EMAIL
fi
