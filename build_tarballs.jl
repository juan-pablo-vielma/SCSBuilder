# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "SCSBuilder"
version = v"2.1.1"

# Collection of sources required to build SCSBuilder
sources = [
    "https://github.com/cvxgrp/scs/archive/$(version).tar.gz" =>
    "0e20b91e8caf744b84aa985ba4e98cc7235ee33612b2bad2bf31ea5ad4e07d93",

]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/scs-*
flags="DLONG=1 USE_OPENMP=0"
blasldflags="-L${prefix}/lib"
# see https://github.com/JuliaPackaging/Yggdrasil/blob/0bc1abd56fa176e3d2cc2e48e7bf85a26c948c40/OpenBLAS/build_tarballs.jl#L23
if [[ ${nbits} == 64 ]] && [[ ${target} != aarch64* ]]; then
    flags="${flags} BLAS64=1 BLASSUFFIX=_64_"
    blasldflags+=" -lopenblas64_"
else
    blasldflags+=" -lopenblas"
fi
make BLASLDFLAGS="${blasldflags}" ${flags} out/libscsdir.${dlext}
make BLASLDFLAGS="${blasldflags}" ${flags} out/libscsindir.${dlext}
mv out/libscs* ${prefix}/lib/

# Copied from https://github.com/JuliaLinearAlgebra/ArpackBuilder/blob/ed55085cd647b39fefb923c3dd95b03591522760/build_tarballs.jl#L72-L77
# Also see https://github.com/JuliaLang/julia/issues/27610
# For now, we'll have to adjust the name of the OpenBLAS library on macOS.
# Eventually, this should be fixed upstream
if [[ ${target} == "x86_64-apple-darwin14" ]]; then
    echo "-- Modifying library name for OpenBLAS"
    install_name_tool -change libopenblas64_.0.3.5.dylib libopenblas64_.dylib ${prefix}/lib/libscsindir.dylib
    install_name_tool -change libopenblas64_.0.3.5.dylib libopenblas64_.dylib ${prefix}/lib/libscsdir.dylib
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc),
    Linux(:aarch64, libc=:glibc),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    Linux(:powerpc64le, libc=:glibc),
    Linux(:i686, libc=:musl),
    Linux(:x86_64, libc=:musl),
    Linux(:aarch64, libc=:musl),
    Linux(:armv7l, libc=:musl, call_abi=:eabihf),
    MacOS(:x86_64),
    FreeBSD(:x86_64),
    Windows(:i686),
    Windows(:x86_64)
]
platforms = expand_gcc_versions(platforms)

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libscsindir", :indirect),
    LibraryProduct(prefix, "libscsdir", :direct)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/OpenBLAS-v0.3.5-2/build_OpenBLAS.v0.3.5.jl"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
