#!/usr/bin/env bash

TARGET=target
TOOLS_DIR=tools
TOOLCHAIN_ROOT=""
TOOLCHAIN_NAME=arm-linux-gnueabihf

VERSION=$1

if [ -z $VERSION ]
then
	echo "please provide the version tag to build"
	exit 1
fi

mkdir -p $TARGET

CURRENT_DIR=$(pwd)

# Get Toolchain
# TODO

# Start Compile (toolchain root, toolchain name, tensorflow version)
./cross-compile.sh /usr $TOOLCHAIN_NAME $VERSION
