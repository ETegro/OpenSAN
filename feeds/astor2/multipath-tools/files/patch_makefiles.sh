sed -i "s#^\(OPTFLAGS.*\)\$#\1 $CPPFLAGS $LDFLAGS#" $1/Makefile.inc
sed -i "s#^\(SHARED_FLAGS.*\)\$#\1 $CPPFLAGS $LDFLAGS#" $1/Makefile.inc
sed -i "s#^\(LDFLAGS.*\)\$#\1 $CPPFLAGS $LDFLAGS#" $1/kpartx/Makefile
