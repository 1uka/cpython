#!/bin/bash


usage() { echo "Usage: $0 -t <arch> -a <ABI> -o <directory>" 1>&2; exit 1; }

while getopts ":t:a:o:" o; do
    case "${o}" in
        t)
            HOSTARCH=${OPTARG}
            ;;
        a)
            ABI=${OPTARG}
            ;;
        o)
            OUTDIR=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${HOSTARCH}" ] || [ -z "${ABI}" ] || [ -z "${OUTDIR}" ]; then
    usage
    exit -1
fi

PYTHON=python3.7
OUTPUT=$OUTDIR/$PYTHON
TARGET=$HOSTARCH-$ABI
BUILDARCH=$(gcc -dumpmachine)
HOSTPATH=/opt/$PYTHON

# build Python version for host if it doesn't exist
# test for $PYTHON executable in PATH
if [ ! -f "$(which $PYTHON)" ]; then
    ./configure --prefix=$HOSTPATH
    make
    make install
fi

export PATH=$HOSTPATH/bin:$PATH

# now cross-compile
make distclean
echo "Compiling for ${TARGET}"

./configure ac_cv_file__dev_ptmx=no ac_cv_file__dev_ptc=no --enable-shared --prefix=$OUTPUT --host=$TARGET --build=$BUILDARCH --disable-ipv6 --without-ensurepip --enable-optimizations

make
make altinstall

# post install: package into tarball
tar -czf $OUTDIR/$PYTHON-$TARGET.tar.gz $OUTPUT

echo "Python build script done. Build output: ${OUTDIR}/${PYTHON}-${TARGET}.tar.gz"

