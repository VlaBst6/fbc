#!/bin/sh


usage()
{
	cat <<EOF
	
Usage: 
./install.sh -i [dest]
./install.sh -u [dest]

-i	Install FreeBASIC at the compiler configured prefix, unless dest is 
specified, then PREFIX=dest.
-u	Uninstall FreeBASIC from the compiler configured prefix, unless dest is 
specified, then PREFIX=dest.

Installation creates PREFIX/lib/freebasic and PREFIX/include/freebasic, where 
library and header files are copied to, respectively. 

If necessary, PREFIX/bin will be created. A copy (not a symlink) of fbc will 
be placed at PREFIX/bin

The man page is copied to PREFIX/man/man1. 

Uninstallation removes these directories, and their contents, in addition 
to the man file and fbc.

EOF
	exit 1
}


i_success_msg()
{
	echo
	echo "================================================================================"
	echo "***** FreeBASIC compiler successfully installed in $INSTALLDIR *****"
	echo "================================================================================"
	echo
}
install()
{
	mkdir -p -m 0755 "$INSTALLDIR"/lib/freebasic && \
	mkdir -p -m 0755 "$INSTALLDIR"/include/freebasic && \
	mkdir -p -m 0755 "$INSTALLDIR"/bin && \
	mkdir -p -m 0755 "$INSTALLDIR"/share/freebasic && \
	mkdir -p -m 0755 "$INSTALLDIR"/share/freebasic/docs && \
	mkdir -p -m 0755 "$INSTALLDIR"/share/freebasic/examples && \
	mkdir -p -m 0755 "$INSTALLDIR"/man/man1 && \
	cp lib/linux/* "$INSTALLDIR"/lib/freebasic/ && \
	cp -ru inc/* "$INSTALLDIR"/include/freebasic/ && \
	cp -ru examples/* "$INSTALLDIR"/share/freebasic/examples/ && \
	cp -ru docs/* "$INSTALLDIR"/share/freebasic/docs/ && \
	cp -ru readme.txt "$INSTALLDIR"/share/freebasic/ && \
	cp -ru migrating.txt "$INSTALLDIR"/share/freebasic/ && \
	gzip -c docs/fbc.1 > "$INSTALLDIR"/man/man1/fbc.1.gz && \
	cp fbc "$INSTALLDIR"/bin/ && \
	chmod a+x "$INSTALLDIR"/bin/fbc && \
	i_success_msg
}

u_success_msg()
{
	echo
	echo "================================================================================"
	echo "***** FreeBASIC compiler successfully uninstalled from $INSTALLDIR *****"
	echo "================================================================================"
	echo
}
uninstall()
{
	rm -fr "$INSTALLDIR"/lib/freebasic && \
	rm -fr "$INSTALLDIR"/include/freebasic && \
	rm -f "$INSTALLDIR"/bin/fbc && \
	rm -fr "$INSTALLDIR"/share/freebasic && \
	rm -f "$INSTALLDIR"/man/man1/fbc.1.gz && \
	u_success_msg
}

case "$1" in
	"-i")	ACTION="install";;
	"-u")	ACTION="uninstall";;
	*)		usage;;
esac

if [ ! -e ./fbc ]; then
	echo
	echo "ERROR: Unable to find ./fbc"
	echo
	exit 1
fi

INSTALLDIR=`./fbc -version | grep prefix | cut -c24- -`
if [ "$INSTALLDIR" == "" ]; then
	if [ "$2" == "" ]; then
		echo
		echo "ERROR: Unable to determine the configured prefix from ./fbc -version"
		echo "ERROR: Need destination path"
		echo
		exit 1
	fi
	INSTALLDIR="$2"
fi

if [ "$2" != "" ]; then
	if [ "$INSTALLDIR" != "$2" ]; then
		echo "WARNING: Using destination ["$2"] even though configured prefix is ["$INSTALLDIR"]"
		INSTALLDIR="$2"
	fi
fi

if [ ! -d $INSTALLDIR ]; then
	echo
	echo "$INSTALLDIR is not a valid directory"
	echo
	exit 1
fi

if [ ! -w $INSTALLDIR ]; then
	echo
	echo "You need root priviledges to access $INSTALLDIR"
	echo
	exit 1
fi

case $ACTION in
	"install")	install;;
	"uninstall")	uninstall;;
esac


