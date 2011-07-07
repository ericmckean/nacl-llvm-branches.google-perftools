#!/bin/bash

readonly PNACL_TC_BASE=${NACL_ROOT}/native_client/toolchain/pnacl_linux_x86_64_newlib/bin
readonly PNACL_GCC=${PNACL_TC_BASE}/pnacl-gcc
readonly PNACL_CXX=${PNACL_TC_BASE}/pnacl-g++
readonly PNACL_AR=${PNACL_TC_BASE}/pnacl-ar
readonly PNACL_AS=${PNACL_TC_BASE}/pnacl-as
readonly PNACL_LD=${PNACL_TC_BASE}/pnacl-ld
readonly PNACL_RANLIB=${PNACL_TC_BASE}/pnacl-ranlib

readonly NACL_TC_BASE=${NACL_ROOT}/native_client/toolchain/linux_x86/bin
readonly NACL_TC_BASE_NEWLIB=${NACL_ROOT}/native_client/toolchain/linux_x86_newlib/bin

readonly INSTALL_DIR=$(pwd)/install
readonly BUILD_DIR=$(pwd)/build

readonly NACL_CC=${NACL_CC:-pnacl}
readonly NACL_ARCH=${NACL_ARCH:-x86-64}

NEXE_SUFFIX=pexe

tc-clean() {
  rm -rf ${BUILD_DIR} ${INSTALL_DIR}
}

tc-setup-pnacl() {
  local arch=$1
  local mode=$2
  local flags

  NEXE_SUFFIX=pexe

  flags="-static"

  CONFIGURE_ENV=(
    CC="${PNACL_GCC} ${flags}" \
    CXX="${PNACL_CXX} ${flags}" \
    LD="${PNACL_LD} ${flags}" \
    RANLIB="${PNACL_RANLIB}" )
}

tc-setup-naclgcc() {
  local arch=$1
  local mode=$2
  local flags
  local tc_base
  local gcc_suffix=64

  NEXE_SUFFIX=nexe
  case $arch in
    x86-32) 
      gcc_suffix=""
      ;;
    x86-64)
      gcc_suffix=64
    ;;
    *)
    echo "Bad naclgcc arch" $arch
    exit -1
  esac

  flags="-static"

  if [ $NACL_CC == "nacl-gcc" ]; then
    tc_base=${NACL_TC_BASE}
  elif [ $NACL_CC == "nacl-gcc-newlib" ]; then
    tc_base=${NACL_TC_BASE_NEWLIB}
  fi

  CONFIGURE_ENV=(
    CC="${tc_base}/nacl${gcc_suffix}-gcc ${flags}" \
    CXX="${tc_base}/nacl${gcc_suffix}-g++ ${flags}" \
    LD="${tc_base}/nacl${gcc_suffix}-ld ${flags}" \
    RANLIB="${tc_base}/nacl${gcc_suffix}-ranlib")
}

tc-configure() {
  mkdir -p ${BUILD_DIR}
  mkdir -p ${INSTALL_DIR}
  pushd ${BUILD_DIR}
  ../configure "${CONFIGURE_ENV[@]}" \
  --prefix=${INSTALL_DIR} \
  --enable-minimal \
  --host=nacl
  local ret=$?
  popd
  return $ret
}

tc-make() {
  pushd ${BUILD_DIR}
  make -j4 && make install
  local ret=$?
  popd
  return $ret
}

tc-install() {
  # TODO(dschuff) do the install step for gcc or decide we don't want it
  if [ $NACL_CC == "pnacl" ]; then
    cp ${INSTALL_DIR}/lib/libtcmalloc_minimal.a \
      ${PNACL_TC_BASE}/../libs-bitcode
      return $?
  fi
  return 0
}

make-nacl-test() {
  for t in $*; do
    mv $t ${t}.${NEXE_SUFFIX}
    echo "Testing" $t.${NEXE_SUFFIX}
    ${NACL_ROOT}/native_client/run.py -arch ${NACL_ARCH} ${t}.${NEXE_SUFFIX} &> $t.log ||
      echo "FAIL"
  done
}

tc-test() {
  # run this through the makefile to get the list of tests
  # TODO(dschuff) find out why some tests fail with opt,
  pushd ${BUILD_DIR}
  make nacl-test NACL_CC=$NACL_CC NACL_ARCH=$NACL_ARCH
  popd
}

if [ $# -lt 1 ]; then
  echo "Usage: $0 <tc-configure|tc-make|tc-test|tc-install|all|tc-clean>"
  exit 1
fi

if [  x${NACL_ROOT}x == "xx" ]; then
  echo 'Set $NACL_ROOT to root of nacl checkout'
  exit 1
fi

if [ $NACL_CC == "pnacl" ]; then
  tc-setup-pnacl $NACL_ARCH
elif [ $NACL_CC == "nacl-gcc" ] || 
      [ $NACL_CC == "nacl-gcc-newlib" ]; then
  tc-setup-naclgcc $NACL_ARCH
else 
  echo "Bad NACL_CC" $NACL_CC
fi

if [ $1 == "all" ]; then
  echo "Using" $NACL_CC $NACL_ARCH $NEXE_SUFFIX
  tc-configure && \
  tc-make && \
  tc-install
  exit $?
fi

"$@"