#!/usr/bin/bash

SCRIPTDIR="$(unset CDPATH && cd "`dirname "$0"`" && pwd)"
GITHUB_ACTION_PATH="${GITHUB_ACTION_PATH:-${SCRIPTDIR}}"

getSemverTool() {
  destdir="$1"
  if [ -z "${destdir}" ]; then
    destdir="."
  fi
  destfile="${destdir}/semver"
  wget -O $destfile https://raw.githubusercontent.com/fsaintjacques/semver-tool/master/src/semver
  chmod +x $destfile
  $destfile --version
}

catIfExists() {
  if [ -f "$1" ]; then
    cat "$1"
  else
    echo "WARNING: File $1 does not exist"
  fi
}

getReleaseVersion() {
  local __result=$1
  next_version="$( source "${GITHUB_ACTION_PATH}/semtag" final -pfos "auto" )"
  eval "${__result}=${next_version}"
}

setVersionTag() {
  local version_tag="$1"
  "${GITHUB_ACTION_PATH}"/semtag final -v "${version_tag}"
}

calcJavaVers() {
  jdkver="$1"
  prefix="$2"
  for ver in 8 11 17 21 ; do
    if [[ $ver -le $jdkver ]]; then
      printf '%s%s\n' "$prefix" "$ver"
    fi
  done
}

testCalcJavaVers() {
  JDK_VER="17"
  JAVA_SDK_VERSIONS="$( calcJavaVers $JDK_VER )"
  MVN_TOOLCHAIN_IDS="$( calcJavaVers $JDK_VER 'temurin_' )"
  echo JAVA_SDK_VERSIONS="${JAVA_SDK_VERSIONS}"
  echo MVN_TOOLCHAIN_IDS="${MVN_TOOLCHAIN_IDS}"
}

#"$@"
