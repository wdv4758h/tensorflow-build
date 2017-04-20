#!/usr/bin/env bash

BUILD_DIR=target

TENSORFLOW_VERSION=$1

if [ -z $TENSORFLOW_VERSION ]
then
	echo "usage: $0 <tensorflow tag/commit>"
	exit
fi

mkdir $BUILD_DIR

cd $BUILD_DIR

git clone https://github.com/tensorflow/tensorflow.git

cd tensorflow

git checkout $TENSORFLOW_VERSION || exit 1

########################################
# TensorFlow Settings (this will apply automatically by TensorFlow's configure)

export PYTHON_BIN_PATH=/usr/bin/python3
export USE_DEFAULT_PYTHON_LIB_PATH=1

export TF_NEED_CUDA=1

# CUDA
export GCC_HOST_COMPILER_PATH=/usr/bin/gcc
export TF_UNOFFICIAL_SETTING=1
export CUDA_TOOLKIT_PATH=/usr/local/cuda-6.5/
export TF_CUDA_VERSION=$($CUDA_TOOLKIT_PATH/bin/nvcc --version | sed -n 's/^.*release \(.*\),.*/\1/p')
export TF_CUDA_COMPUTE_CAPABILITIES=3.2     # TK1
export _build_opts="--config=cuda"

# cuDNN
export CUDNN_INSTALL_PATH=/usr/local/cuda-6.5/
export TF_CUDNN_VERSION=$(sed -n 's/^#define CUDNN_MAJOR\s*\(.*\).*/\1/p' $CUDNN_INSTALL_PATH/include/cudnn.h)

# disable Google Cloud Platform support
export TF_NEED_GCP=0
# disable Hadoop File System support
export TF_NEED_HDFS=0
# disable OpenCL support
export TF_NEED_OPENCL=0
# disable XLA JIT compiler
export TF_ENABLE_XLA=0
# enable jemalloc support
export TF_NEED_JEMALLOC=1
# set up architecture dependent optimization flags
# export CC_OPT_FLAGS="-march=native"
export CC_OPT_FLAGS=""

# make sure the proxy variables are in all caps, otherwise bazel ignores them
export HTTP_PROXY=`echo $http_proxy | sed -e 's/\/$//'`
export HTTPS_PROXY=`echo $https_proxy | sed -e 's/\/$//'`

########################################

./configure

BAZEL_FLAGS="$BAZEL_FLAGS -c opt ${_build_opts} --copt=${CC_OPT_FLAGS}"

echo "launching bazel with flags '$BAZEL_FLAGS'"

bazel build $BAZEL_FLAGS //tensorflow/tools/pip_package:build_pip_package --verbose_failures
