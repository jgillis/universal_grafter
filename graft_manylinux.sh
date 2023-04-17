#!/bin/bash

set -eo pipefail
PYTHONDIR=/opt/python/cp39-cp39/bin

$PYTHONDIR/pip install pyelftools wheel==0.31.1
#git -C /tmp clone -b fix https://github.com/jgillis/auditwheel/
git -C /tmp clone -b main https://github.com/jgillis/auditwheel.git
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

