#!/bin/bash

# Inspired by https://github.com/blukat29/docker-cross

[ -z "$BINUTILS_VERSION" ] && BINUTILS_VERSION="2.25.1"
[ -z "$GDB_VERSION" ]      && GDB_VERSION="7.10"
[ -z "${MAKE_PARALLEL}" ]  && MAKE_PARALLEL=2
[ -z "$TARGET" ]           && TARGET="sh-elf"
[ -z "$WORKDIR" ]          && WORKDIR="/tmp"

_dbg() {
	echo "$@" >&2
}

_download_src() {
	local force="$1"

	if [ ! -e "$WORKDIR/binutils.tar.bz2" ] || [ -n "$force" ]; then
		curl -o "$WORKDIR/binutils.tar.bz2" "http://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS_VERSION.tar.bz2"
		if [ $? -ne 0 ]; then
			_dbg "Failed to download binutils to $WORKDIR"
			return 1
		fi
	fi

	if [ ! -e "$WORKDIR/gdb.tar.xz" ] || [ -n "$force" ]; then
		curl -o "$WORKDIR/gdb.tar.xz" "http://ftp.gnu.org/gnu/gdb/gdb-$GDB_VERSION.tar.xz"
		if [ $? -ne 0 ]; then
			_dbg "Failed to download gdb to $WORKDIR"
			return 2
		fi
	fi

	return 0
}

_extract_src() {
	local _fail=0
	pushd "$WORKDIR" || { _dbg "Can't change to directory $WORKDIR"; return 1; }
	tar -xf "binutils.tar.bz2" || { _dbg "Failed to extract binutils: error=$?"; _fail=2; }
	tar -xf "gdb.tar.xz" || { _dbg "Failed to extract gdb: error=$?"; _fail=2; }
	popd

	return ${_fail}
}

_compile() {
	local package="$1"
	local version="$2"
	local arch="$3"

	local path="$WORKDIR/$package-$arch"

	rm -rf "$path" 2>/dev/null
	mkdir -p "$path" || { _dbg "Failed to create directory: $path"; return 1; }
	pushd "$path" || { _dbg "Can't switch to directory $path"; return 2; }
	../$package-${version}/configure --target=$arch \
		                         --prefix=$PREFIX  \
	                                 --disable-nls \
	        || { _dbg "Failed to configure $package"; popd; return 3; }
	make -j ${MAKE_PARALLEL} || { _dbg "Failed to build $package"; popd; return 4; }

	popd
	return 0
}

_compile_all() {
	_compile binutils "${BINUTILS_VERSION}" "$TARGET" || return $?
	_compile gdb "${GDB_VERSION}" "$TARGET" || return $?

	return 0
}

_generate_environment() {
	local arch="$1"
	local e="$WORKDIR/environment"
	echo "_CROSS_GDB_VERSION=\"${GDB_VERSION}\"" > "$e"
	echo "_CROSS_BINUTILS_VERSION=\"${BINUTILS_VERSION}\"" >> "$e"
	echo "_CROSS_WORKDIR=\"${WORKDIR}\"" >> "$e"

	echo "_CROSS_PATH=\"$$PATH\"" >> "$e"
	echo "_CROSS_PS1=\"$$PS1\"" >> "$e"
	echo "export PATH=\"$WORKDIR/binutils-$arch/binutils:$WORKDIR/gdb-$arch/gdb:$$PATH\"" >> "$e"
	echo "export PS1=\"(X) $$PS1" >> "$e"
	echo "cross_deactivate() { export PATH=\"$${_CROSS_PATH}\"; export PS1=\"$${_CROSS_PS1}\"; }" >> "$e"
}

main() {
	_download_src || exit 1
	_extract_src || exit 1
	_compile_all || exit 1
	_generate_environment "$TARGET" || exit 1
}

main $@
