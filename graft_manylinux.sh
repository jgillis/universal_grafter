#!/bin/bash

set -eo pipefail
PYTHONDIR=/opt/python/cp39-cp39/bin

patchelf_version=$(patchelf --version)



if [[ $patchelf_version == *"0.12"* ]]; then
   curl -OL https://github.com/NixOS/patchelf/releases/download/0.14.5/patchelf-0.14.5-x86_64.tar.gz
   sudo tar -xvf patchelf-0.14.5-x86_64.tar.gz -C /usr/local
fi

if [[ $CROSS_TRIPLE == *"aarch64"* ]]; then
    git -C /tmp clone https://github.com/jgillis/repairwheel.git
    pushd /tmp/repairwheel && $PYTHONDIR/pip install . && popd
else
    $PYTHONDIR/pip install pyelftools wheel==0.31.1
    
    git -C /tmp clone -b test https://github.com/jgillis/auditwheel.git
    pushd /tmp/auditwheel && $PYTHONDIR/python setup.py install && popd
    
    echo "1: $1"
    $PYTHONDIR/auditwheel show $1
fi




export LD_LIBRARY_PATH=`pwd`/casadi:`pwd`/dummy/casadi
# Check if rustc is available.
if command -v rustc >/dev/null 2>&1; then
    echo "rustc detected"
    # Append rustc's target library directory.
    rust_target_libdir="$(rustc --print target-libdir)"
    export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${rust_target_libdir}
fi

echo "debug_grafting LD_LIBRARY_PATH: ${LD_LIBRARY_PATH}"




if [[ $CROSS_TRIPLE == *"aarch64"* ]]; then
    excludes=""
    for lib in $(echo $2 | tr ":" "\n")
    do
        excludes="$excludes -x ${lib}.so"
    done
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$QEMU_LD_PREFIX/lib
    echo $LD_LIBRARY_PATH
    $PYTHONDIR/repairwheel $1 -l . $excludes -o /tmp
    cp /tmp/*.whl $1
else
    excludes=""
    for lib in $(echo $2 | tr ":" "\n")
    do
        excludes="$excludes --exclude ${lib}.so"
    done
    $PYTHONDIR/auditwheel -vv repair -L . $excludes --no-update-tags -w . $1
fi
