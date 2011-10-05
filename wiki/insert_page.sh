#!/bin/sh

TRAC_ADMIN=/usr/local/bin/trac-admin
TRAC_PATH=/srv/opensan-trac

pagename=`basename $1 .wiki`

$TRAC_ADMIN $TRAC_PATH wiki import "$pagename" $pagename.wiki

cd attachments
[ -d "$pagename" ] || exit

for attach in $pagename/*; do
	$TRAC_ADMIN $TRAC_PATH attachment remove wiki:"$pagename" `basename $attach` || true
	$TRAC_ADMIN $TRAC_PATH attachment add wiki:"$pagename" $attach
done
