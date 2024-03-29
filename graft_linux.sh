#!/bin/bash
set -eo pipefail
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

docker run --rm --env DEFAULT_DOCKCROSS_IMAGE=ghcr.io/jgillis/$1:production ghcr.io/jgillis/$1:production > /tmp/dockcross
chmod +x /tmp/dockcross
cp $SCRIPT_DIR/graft_manylinux.sh .
echo "2: $2"
/tmp/dockcross ./graft_manylinux.sh $2 $3
rm graft_manylinux.sh
