#!/bin/sh
# This script must be sourced, not executed.

IPBB_VERSION='2021j'
IPBB_DIRECTORY='ipbb-dev-'$IPBB_VERSION'/'

VIVADO_VERSION='2020.1'
VIVADO_DIRECTORY='/opt/Xilinx/Vivado/'$VIVADO_VERSION'/'

if [ ! -d "$IPBB_DIRECTORY" ]; then
  curl -L https://github.com/ipbus/ipbb/archive/dev/$IPBB_VERSION.tar.gz | tar xvz
fi

source $IPBB_DIRECTORY'env.sh'

source $VIVADO_DIRECTORY'settings64.sh'
# To run the ``ipbus gendecoders`` command later on
export PATH=/opt/cactus/bin/uhal/tools:$PATH LD_LIBRARY_PATH=/opt/cactus/lib:$LD_LIBRARY_PATH
