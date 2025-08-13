#!/usr/bin/bash

catIfExists() {
  if [ -f "$1" ]; then
    cat "$1"
  else
    echo "WARNING: File $1 does not exist"
  fi
}

calcJavaVers() {
  jdkver="$1"
  prefix="$2"
  printf '['
  local valsep=""
  for ver in 8 11 17 21 ; do
    if [[ $ver -le $jdkver ]]; then
      printf '%s"%s%s"' "$valsep" "$prefix" "$ver"
      if [[ -z "${valsep}" ]]; then
        valsep=", "
      fi
    fi
  done
  printf ']\n'
}

testCalcJavaVers() {
  JDK_VER="17"
  JAVA_SDK_VERSIONS="$( calcJavaVers $JDK_VER )"
  MVN_TOOLCHAIN_IDS="$( calcJavaVers $JDK_VER 'temurin_' )"
  echo JAVA_SDK_VERSIONS="${JAVA_SDK_VERSIONS}"
  echo MVN_TOOLCHAIN_IDS="${MVN_TOOLCHAIN_IDS}"
}

"$@"