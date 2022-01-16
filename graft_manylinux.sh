#!/bin/bash
PYTHONDIR=/opt/python/cp39-cp39/bin

$PYTHONDIR/pip install pyelftools wheel==0.31.1
git -C /tmp clone https://github.com/jgillis/auditwheel/
pushd /tmp/auditwheel && $PYTHONDIR/python setup.py install && popd

echo "1: $1"
$PYTHONDIR/auditwheel repair -g gfortran -L . --no-update-tags -w . $1

