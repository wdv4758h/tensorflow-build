#!/usr/bin/env bash

PATCH_ORIG=tf-crosscompile.patch
BUILD_DIR=target

CT_DIR=$1
CT_NAME=$2
TENSORFLOW_VERSION=$3

GCC=$1/bin/$2-gcc
GCC_VERSION=$($GCC -dumpversion)
if [ ! -f $GCC ] || [ -z $TENSORFLOW_VERSION ]
then
	echo "usage: $0 <absolute cross toolchain path> <toolchain prefix> <tensorflow tag/commit>"
	echo "seaching gcc here : $GCC"
	exit
fi

GCC_VERSION=$($GCC -dumpversion)
echo "using gcc : $GCC version $GCC_VERSION"

PATCH_NAME=tf-crosscompile-$CT_NAME.patch
mkdir $BUILD_DIR

cp $PATCH_ORIG $BUILD_DIR/$PATCH_NAME

cd $BUILD_DIR

sed -i "s#%%CT_NAME%%#$CT_NAME#g" $PATCH_NAME
sed -i "s#%%CT_ROOT_DIR%%#$CT_DIR#g" $PATCH_NAME
sed -i "s#%%CT_GCC_VERSION%%#$GCC_VERSION#g" $PATCH_NAME

mkdir -p tensorflow
cd tensorflow
git init
git remote add origin https://github.com/tensorflow/tensorflow.git
git fetch
git reset HEAD --hard
git clean -f -d

git checkout $TENSORFLOW_VERSION || exit 1

git apply ../$PATCH_NAME || exit 1

grep -Rl 'lib64' | xargs sed -i 's/lib64/lib/g'

########################################
# TensorFlow Settings (this will apply automatically by TensorFlow's configure)

export PYTHON_BIN_PATH=/usr/bin/python3
export USE_DEFAULT_PYTHON_LIB_PATH=1

export TF_NEED_CUDA=0

## CUDA
#export GCC_HOST_COMPILER_PATH=/usr/bin/gcc
#export TF_UNOFFICIAL_SETTING=1
#export CUDA_TOOLKIT_PATH=/usr/local/cuda-8.0/
#export TF_CUDA_VERSION=$($CUDA_TOOLKIT_PATH/bin/nvcc --version | sed -n 's/^.*release \(.*\),.*/\1/p')
#export TF_CUDA_COMPUTE_CAPABILITIES=3.2     # TK1
#export _build_opts="--config=cuda"
#
## cuDNN
#export CUDNN_INSTALL_PATH=/usr/local/cuda-8.0/
#export TF_CUDNN_VERSION=$(sed -n 's/^#define CUDNN_MAJOR\s*\(.*\).*/\1/p' $CUDNN_INSTALL_PATH/include/cudnn.h)

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
export CC_OPT_FLAGS="-O0"

# make sure the proxy variables are in all caps, otherwise bazel ignores them
export HTTP_PROXY=`echo $http_proxy | sed -e 's/\/$//'`
export HTTPS_PROXY=`echo $https_proxy | sed -e 's/\/$//'`

########################################

./configure

BAZEL_FLAGS="$BAZEL_FLAGS -c opt ${_build_opts} --copt=${CC_OPT_FLAGS}"

echo "launching bazel with flags '$BAZEL_FLAGS'"

bazel build $BAZEL_FLAGS -c opt --copt="-march=armv7l" --copt="-mfpu=vfp" --copt="-funsafe-math-optimizations" --copt="-ftree-vectorize" --copt="-fomit-frame-pointer" //tensorflow/tools/pip_package:build_pip_package  --cpu=armeabi --crosstool_top=//tools/arm_compiler:toolchain --verbose_failures
