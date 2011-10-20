#!/bin/sh

WHAT=$1
CONTENTS=$2

curdate=`git show --date=iso8601 HEAD | sed -n "s/-//g; s/://g; s/^Date  *\(.*\) \(.*\).. +....$/\1T\2/p"`

cat $CONTENTS > Release$WHAT.wiki
cat >> Release$WHAT.wiki <<__EOF__

=== Download ===
You can download this release following [/download/V$WHAT/ this link].
Always cryptographically [wiki:Publickey verify images]!
__EOF__

echo "* [wiki:Release$WHAT $WHAT]" >> Releases.wiki

echo "= Release $WHAT =" > News_$curdate.wiki
echo >> News_$curdate.wiki
echo "== Release notes ==" >> News_$curdate.wiki
cat Release$WHAT.wiki >> News_$curdate.wiki

tmp=`mktemp`
echo "* [wiki:News_$curdate Release $WHAT]" > $tmp
cat News.wiki >> $tmp
mv $tmp News.wiki
rm -f $tmp
