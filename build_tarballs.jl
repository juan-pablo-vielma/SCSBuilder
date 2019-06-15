# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "SCSBuilder"
version = v"2.0.2"

# Collection of sources required to build SCSBuilder
sources = [
    "https://github.com/cvxgrp/scs/archive/v2.0.2.tar.gz" =>
    "8725291dfe952a1f117f1f725906843db392fe8d29eebd8feb14b49f25fc669e",

]

# Adapted from builder by kalmarek (https://github.com/JuliaPackaging/BinaryBuilder.jl/issues/313)
# Bash recipe for building across all platforms 
script = raw"""
cd $WORKSPACE/srcdir
cd scs-2.0.2/
# Mac OS and Windows do not have openmp by default
#if [ $target = "x86_64-apple-darwin14" ] || [ $target = "x86_64-w64-mingw32" ] || [ $target = "i686-w64-mingw32" ]; then
#    flags="DLONG=1"
#else
#    flags="DLONG=1 USE_OPENMP=1"
#fi
# GOMP 4.0 would be required for OPENMP, which makes travis fail because it only has gcc version 4.8.4 
flags="DLONG=1 USE_OPENMP=0"
#if [ $target = "x86_64-apple-darwin14" ]; then 
#    install_name_tool -id libopenblas64_.dylib ${prefix}/lib/libopenblas64_.0.3.0.dev.dylib
#fi
blasldflags="-L${prefix}/lib"
if [[ ${nbits} == 32 ]]; then     blasldflags="${blasldflags} -lopenblas"; else     flags="${flags} BLAS64=1 BLASSUFFIX=_64_";     blasldflags="${blasldflags} -lopenblas64_"; fi
make BLASLDFLAGS="${blasldflags}" ${flags} out/libscsdir.${dlext}
make BLASLDFLAGS="${blasldflags}" ${flags} out/libscsindir.${dlext}
mv out/libscs* ${prefix}/lib/

# Copied from https://github.com/JuliaLinearAlgebra/ArpackBuilder/blob/ed55085cd647b39fefb923c3dd95b03591522760/build_tarballs.jl#L72-L77
# Also see https://github.com/JuliaLang/julia/issues/27610
# For now, we'll have to adjust the name of the OpenBLAS library on macOS.
# Eventually, this should be fixed upstream
if [[ ${target} == "x86_64-apple-darwin14" ]]; then
    echo "-- Modifying library name for OpenBLAS"
    install_name_tool -change libopenblas64_.0.3.0.dev.dylib libopenblas64_.dylib ${prefix}/lib/libscsindir.dylib
    install_name_tool -change libopenblas64_.0.3.0.dev.dylib libopenblas64_.dylib ${prefix}/lib/libscsdir.dylib
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
    "https://github.com/JuliaLinearAlgebra/OpenBLASBuilder/releases/download/v0.3.0-3/build_OpenBLAS.v0.3.0.jl"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

