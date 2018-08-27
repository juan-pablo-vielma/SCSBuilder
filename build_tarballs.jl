# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "GLPKBuilder"
version = v"2.0.2"

# Collection of sources required to build SCSBuilder
sources = [
    "https://github.com/cvxgrp/scs/archive/v2.0.2.tar.gz" =>
    "8725291dfe952a1f117f1f725906843db392fe8d29eebd8feb14b49f25fc669e",

]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd scs-2.0.2/
if [ $target = "x86_64-w64-mingw32" ] || [ $target = "i686-w64-mingw32" ]; then
    flags="DLONG=1"
else
    flags="DLONG=1 USE_OPENMP=1"
fi
blasldflags="-L${prefix}/lib"
if [[ ${nbits} == 32 ]]; then     blasldflags="${blasldflags} -lopenblas"; else     flags="${flags} BLAS64=1 BLASSUFFIX=_64_";     blasldflags="${blasldflags} -lopenblas64_"; fi
make BLASLDFLAGS="${blasldflags}" ${flags} out/libscsdir.${dlext}
make BLASLDFLAGS="${blasldflags}" ${flags} out/libscsindir.${dlext}
mv out/libscs* ${prefix}/lib/

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, :glibc),
    Linux(:x86_64, :glibc),
    Linux(:aarch64, :glibc),
    Linux(:armv7l, :glibc, :eabihf),
    Linux(:powerpc64le, :glibc),
    Linux(:i686, :musl),
    Linux(:x86_64, :musl),
    Linux(:aarch64, :musl),
    Linux(:armv7l, :musl, :eabihf),
    MacOS(:x86_64),
    FreeBSD(:x86_64),
    Windows(:i686),
    Windows(:x86_64)
]

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libscsindir", :indirect),
    LibraryProduct(prefix, "libscsdir", :direct)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/JuliaLinearAlgebra/OpenBLASBuilder/releases/download/v0.3.0-1/build_OpenBLAS.v0.3.0.jl"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

