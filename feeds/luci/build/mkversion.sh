#!/bin/bash
WORK_DIR=`echo $0 | sed "s/\/mkversion.sh$//"`
pushd "$WORK_DIR"; WORK_DIR=`pwd`; popd
commit=`$WORK_DIR/opensan-version.sh | sed -n '1p'`
datestamp=`$WORK_DIR/opensan-version.sh | sed -n '2p'`

if [ "${4%%/*}" = "branches" ]; then
	variant="LuCI ${4##*[-/]} Branch"
elif [ "${4%%/*}" = "tags" ]; then
	variant="LuCI ${4##*[-/]} Release"
else
	variant="LuCI Trunk"
fi

cat <<EOF > $1
local pcall, dofile, _G = pcall, dofile, _G

module "luci.version"

if pcall(dofile, "/etc/openwrt_release") and _G.DISTRIB_DESCRIPTION then
	distname    = ""
	distversion = _G.DISTRIB_DESCRIPTION
else
	distname    = "OpenSAN"
	distversion = "$commit"
end

luciname    = ""
luciversion = "$datestamp"
EOF
