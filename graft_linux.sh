#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

docker run --rm ghcr.io/jgillis/${{ matrix.arch }}:production > /tmp/dockcross
chmod +x /tmp/dockcross
cp $SCRIPT_DIR/graft_manylinux.sh .
echo "2: $2"
/tmp/dockcross ./graft_manylinux.sh $2
rm graft_manylinux.sh
