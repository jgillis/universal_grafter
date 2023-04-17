#!/bin/bash

set -eo pipefail
PYTHONDIR=/opt/python/cp39-cp39/bin

patchelf_version=$(patchelf --version)

$PYTHONDIR/pip install pyelftools wheel==0.31.1
if [[ $patchelf_version == *"0.12"* ]]; then
    git -C /tmp clone -b fix https://github.com/jgillis/auditwheel/
else
    git -C /tmp clone -b test https://github.com/jgillis/auditwheel.git
fi
pushd /tmp/auditwheel && $PYTHONDIR/python setup.py install && popd

echo "1: $1"
$PYTHONDIR/auditwheel show $1
export LD_LIBRARY_PATH=`pwd`/casadi:`pwd`/dummy/casadi
excludes=""
for lib in $(echo $2 | tr ":" "\n")
do
    excludes="$excludes --exclude ${lib}.so"
done

$PYTHONDIR/auditwheel -vv repair -L . $excludes --no-update-tags -w . $1

