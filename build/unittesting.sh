#!/bin/bash -ex

WORK_DIR=`echo $0 | sed "s/\/unittesting.sh$//"`
pushd "$WORK_DIR"; WORK_DIR=`pwd`; popd
PROJECT_DIR="$WORK_DIR"/..
OUTPUT_LOG="$1"

create_test_directory()
{
	TEST_DIR=`mktemp -d`
}

create_libraries_directory()
{
	mkdir "$TEST_DIR"/astor2
}

make_astor2_libraries_links()
{
	for lib in `find "$PROJECT_DIR"/feeds/astor2/ -path '*astor2-lua*astor2/*.lua'`; do
		ln -s "$lib" "$TEST_DIR"/astor2/"`basename $lib`"
	done
}

create_uci_library()
{
	echo 'module("uci")' > "$TEST_DIR"/uci.lua
}

make_luanit_library_links()
{
	ln -s "$PROJECT_DIR"/remotetesting/lib/luaunit.lua "$TEST_DIR"/luaunit.lua
}

create_lua_tests_directory()
{
	mkdir "$TEST_DIR"/tests
}

make_astor2_tests_links()
{
	for lib_test in `find "$PROJECT_DIR"/feeds/astor2/ -path '*astor2-lua*tests/*.lua'`; do
		ln -s "$lib_test" "$TEST_DIR"/tests/"`basename $lib_test`"
	done
}

make_matrix_links()
{
	ln -s "$PROJECT_DIR"/feeds/luci/applications/luci-astor2-san/luasrc/controller/matrix.lua "$TEST_DIR"/matrix.lua
}

make_matrix_tests_links()
{
	local tests_path="$PROJECT_DIR"/feeds/luci/applications/luci-astor2-san/luasrc/controller/tests
	for lua_test in $tests_path/*.lua_; do
		link_name=`basename "$lua_test" .lua_`
		ln -s $lua_test "$TEST_DIR"/tests/"$link_name".lua
	done
}

unittesting()
{
	pushd "$TEST_DIR"
	for lua_test in tests/*.lua; do
		(lua "$lua_test" 2>&1 || is_failed=1) | tee -a $OUTPUT_LOG
	done
	popd
	[ "$is_failed" = "" ] || exit 1
	grep -q "^Failed" $OUTPUT_LOG && exit 1 || true
}

remove_test_directory()
{
	rm -rf "$TEST_DIR"
}

create_test_directory
create_libraries_directory
make_astor2_libraries_links
create_uci_library
make_luanit_library_links
make_matrix_links
create_lua_tests_directory
make_astor2_tests_links
make_matrix_tests_links
unittesting
remove_test_directory
